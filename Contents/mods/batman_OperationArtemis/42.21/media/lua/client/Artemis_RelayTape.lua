-- Opération Artemis : la bande de V, rejouée par une radio allumée dans la salle de contrôle du relais
-- (données « tape » du chapitre en cours, Artemis_Story). Côté client, pour le joueur qui l'allume.
-- Aucun événement vanilla ne signale qu'une radio est allumée (OnRadioInteraction est déclaré mais
-- jamais déclenché, LuaEventManager.java:800) : on enveloppe ISRadioAction:performToggleOnOff, exécuté
-- côté client au perform (ISRadioAction.lua:60-71).
-- La salle doit avoir du courant : une radio à pile apportée ne suffit pas, la « machine » de la bande
-- est branchée sur le relais. Chaque allumage relance la bande du début ;
-- éteindre la radio l'interrompt. Les lignes s'affichent au-dessus de la radio (bulle vanilla de
-- AddDeviceText, qui fait aussi un bruit : c'est une vraie radio qui parle). À la fin, le serveur est
-- prévenu (HEARD_TAPE) et revérifie la salle et le courant.

require "RadioCom/ISRadioAction"

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local Tape = require "Artemis/Artemis_Tape"
local Timeline = require "Artemis/Artemis_Timeline"

-- Lecture en cours : { radio, tape, session } ; session augmente à chaque allumage, pour ignorer les
-- repères d'une lecture précédente.
local current = { session = 0 }

local function isPlaying(context)
    local radio = context.radio
    return context.session == current.session and radio:getSquare() ~= nil
        and radio:getDeviceData():getIsTurnedOn()
end

local HANDLERS = {
    line = function(cue, context)
        if not isPlaying(context) then return end
        local text = cue.raw or getText(cue.key)
        local color = context.tape.color
        -- IsoRadio hérite des surcharges float/int d'IsoWaveSignal : Kahlua peut choisir int
        -- même avec des fractions (tronquées à zéro, texte noir). Couleurs 0-255 comme les
        -- réponses radio et le haut-parleur du checkpoint ; volume, codes et bruit restent natifs.
        context.radio:AddDeviceText(text, math.floor(color.r * 255 + 0.5),
            math.floor(color.g * 255 + 0.5), math.floor(color.b * 255 + 0.5), nil, nil, -1)
    end,
    tapeEnd = function(_cue, context)
        if not isPlaying(context) then
            Const.log("bande " .. context.tape.key .. " : interrompue")
            return
        end
        Const.log("bande " .. context.tape.key .. " : terminee")
        sendClientCommand(context.player, Const.NET_MODULE, Const.COMMAND.HEARD_TAPE, {})
    end,
}

local timeline = Timeline.new(HANDLERS)

-- Bande dont la salle contient cette radio, sinon nil. Toutes les bandes des chapitres : la bande
-- reste rejouable après la fin du chapitre (seule la première écoute du chapitre en cours compte).
local function tapeFor(radio)
    local square = radio:getSquare()
    if square == nil then
        return nil
    end
    for _, chapter in pairs(Story.CHAPTERS) do
        local tape = chapter.tape
        if tape and Tape.isInRoom(tape.room, square:getX(), square:getY(), square:getZ()) then
            return tape
        end
    end
    return nil
end

-- La case de la radio a-t-elle du courant ? Même règle que l'objectif (Artemis_Goals) : générateur,
-- ou réseau dans une pièce. canBePoweredHere ne suffit pas : il est toujours vrai pour un appareil
-- à pile (DeviceData.java:506-509).
local function isRoomPowered(radio)
    local square = radio:getSquare()
    return square:haveElectricity() or (square:hasGridPower() and square:getRoom() ~= nil)
end

-- Fréquences FM où cherche une fréquence libre (plage de la radio d'urgence vanilla).
local FREE_FREQUENCY_MIN, FREE_FREQUENCY_MAX = 88000, 108000

-- La bande ne doit pas se mêler à une émission : si une station occupe la fréquence de la radio
-- (station au hasard d'une partie, ou réglée par le joueur), la radio passe sur une fréquence libre,
-- tirée par le jeu parmi celles qu'aucune station n'utilise (ZomboidRadio.java:179-184).
local function ensureSilentChannel(data)
    local zomboidRadio = getZomboidRadio()
    if zomboidRadio == nil or zomboidRadio:getChannelName(data:getChannel()) == nil then return end
    local free = zomboidRadio:getRandomFrequency(FREE_FREQUENCY_MIN, FREE_FREQUENCY_MAX)
    data:setChannelRaw(free)
    Const.log("bande : radio reglee sur une frequence libre (" .. tostring(free) .. ")")
end

local function onToggled(action)
    local radio = action.device
    if not Config.isEnabled() or not instanceof(radio, "IsoRadio") then return end
    local tape = tapeFor(radio)
    -- Une autre radio, ailleurs, n'interrompt pas la bande.
    if tape == nil then return end
    current.session = current.session + 1
    if not radio:getDeviceData():getIsTurnedOn() or not isRoomPowered(radio) then return end
    ensureSilentChannel(radio:getDeviceData())
    Const.log("bande " .. tape.key .. " : lecture")
    timeline:play(Tape.cues(tape.lines), { radio = radio, tape = tape, player = action.character,
        session = current.session })
end

-- La fonction d'origine est conservée sur la table vanilla : un rechargement du fichier n'empile pas
-- une seconde enveloppe.
ISRadioAction.batmanArtemisOriginalToggle = ISRadioAction.batmanArtemisOriginalToggle
    or ISRadioAction.performToggleOnOff

function ISRadioAction:performToggleOnOff()
    local result = ISRadioAction.batmanArtemisOriginalToggle(self)
    onToggled(self)
    return result
end

Events.OnTick.Add(function() timeline:update() end)
