-- Opération Artemis : chaîne radio militaire « ARTEMIS » (fréquence réglable, 108,0 MHz par défaut).
-- Serveur ou solo : sur un client multijoueur, le gestionnaire de scripts radio vaut nil.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Store = require "Artemis/Artemis_Store"
local State = require "Artemis/Artemis_State"
local Extraction = require "Artemis/Artemis_Extraction"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Story = require "Artemis/Artemis_Story"

-- Couleur des lignes, proche du vert pâle des transmissions militaires.
local LINE_COLOR = { r = 0.70, g = 0.85, b = 0.55 }

-- Diffusions. « raw » : texte tel quel (les parasites doivent valoir exactement
-- <fzzt>, <bzzt>, <szzt> ou <wzzt>, ZomboidRadio.java:106-114). « key » : clé de traduction.

-- Avant la lecture du carnet : une station de chiffres, sans rien d'explicite ni de code.
-- Le joueur peut tomber dessus en balayant les fréquences, comme sur la station vanilla
-- « Classified M1A1 » (95,0 MHz), sans que l'intrigue soit dévoilée.
local NUMBERS_STATION = {
    { raw = "<fzzt>" },
    { key = "IGUI_Artemis_Radio_Numbers" },
    { raw = "<wzzt>" },
    { key = "IGUI_Artemis_Radio_Numbers2" },
    { raw = "<szzt>" },
}

-- Après la lecture : la diffusion complète. Les lignes clés portent le code SIGNAL_CODE,
-- détecté par le client (Artemis_RadioListener), qui fait passer à l'acte II.
local FULL_BROADCAST = {
    { raw = "<fzzt>" },
    { key = "IGUI_Artemis_Radio_Numbers" },
    { key = "IGUI_Artemis_Radio_Relay", codes = Const.RADIO.SIGNAL_CODE },
    { raw = "<bzzt>" },
    { key = "IGUI_Artemis_Radio_Plea", codes = Const.RADIO.SIGNAL_CODE },
    { key = "IGUI_Artemis_Radio_Numbers" },
    { raw = "<szzt>" },
}

-- Acte III, avant l'appel : la base attend l'appel du porteur du dossier.
local EXFIL_BROADCAST = {
    { raw = "<fzzt>" },
    { key = "IGUI_Artemis_Radio_Exfil" },
    { raw = "<wzzt>" },
    { key = "IGUI_Artemis_Radio_Exfil2" },
    { raw = "<szzt>" },
}

-- Acte III, appel accepté : le rendez-vous est rappelé.
local RENDEZVOUS_BROADCAST = {
    { raw = "<fzzt>" },
    { key = "IGUI_Artemis_Radio_Rendezvous" },
    { raw = "<bzzt>" },
    { key = "IGUI_Artemis_Radio_Rendezvous2" },
    { raw = "<szzt>" },
}

-- Stérilisation annoncée (option) : l'avis de l'armée, relayé par la base, avant la diffusion habituelle.
local STERILIZATION_WARNING = {
    { raw = "<bzzt>" },
    { key = "IGUI_Artemis_Radio_Sterilization" },
    { key = "IGUI_Artemis_Radio_Sterilization2" },
}

-- Zone stérilisée : la base est partie ; V, seul, ne voit plus que le fleuve.
local STERILIZED_BROADCAST = {
    { raw = "<fzzt>" },
    { key = "IGUI_Artemis_Radio_Sterilized" },
    { raw = "<wzzt>" },
    { key = "IGUI_Artemis_Radio_Sterilized2" },
    { raw = "<szzt>" },
}

-- Lignes « first » diffusées avant « lines ».
local function withLines(first, lines)
    local out = {}
    for _, line in ipairs(first) do
        out[#out + 1] = line
    end
    for _, line in ipairs(lines) do
        out[#out + 1] = line
    end
    return out
end

local function withWarning(lines)
    return withLines(STERILIZATION_WARNING, lines)
end

-- Passeur appelé (route A sans mod de bateau) : le rendez-vous de Brandenburg est rappelé.
local FERRY_BROADCAST = {
    { raw = "<fzzt>" },
    { key = "IGUI_Artemis_Radio_Ferry" },
    { raw = "<bzzt>" },
    { key = "IGUI_Artemis_Radio_Ferry2" },
    { raw = "<szzt>" },
}

-- Siège programmé le soir du dossier (Siege Night) : V prévient, jusqu'à la fin de la nuit.
local SIEGE_WARNING = {
    { raw = "<bzzt>" },
    { key = "IGUI_Artemis_Radio_Siege" },
    { key = "IGUI_Artemis_Radio_Siege2" },
}

local function isSiegeWarning(state)
    local entry = State.flagValue(state, "siegeNight", "fileSiege")
    return type(entry) == "table" and getGameTime():getWorldAgeHours() < (entry.untilHours or 0)
end

-- Épilogue : le dernier message de V.
local FAREWELL_BROADCAST = {
    { raw = "<fzzt>" },
    { key = "IGUI_Artemis_Radio_Farewell" },
    { key = "IGUI_Artemis_Radio_Farewell2" },
    { key = "IGUI_Artemis_Radio_Farewell3" },
    { raw = "<wzzt>" },
}

local function linesFor(state)
    if state.act < Const.ACT.SIGNAL then
        return NUMBERS_STATION
    end
    if state.act == Const.ACT.EXFILTRATION then
        local stage = Sterilization.stage(Sterilization.entry(state.flags), getGameTime():getWorldAgeHours())
        if stage == Sterilization.STRUCK then
            return STERILIZED_BROADCAST
        end
        local called = Extraction.isCalled(State.flagValue(state, "extraction", Extraction.KEY))
        local ferryCalled = Extraction.isCalled(State.flagValue(state, "extraction", Story.FERRY.key))
        local lines = called and RENDEZVOUS_BROADCAST or (ferryCalled and FERRY_BROADCAST or EXFIL_BROADCAST)
        if isSiegeWarning(state) then
            lines = withLines(SIEGE_WARNING, lines)
        end
        return stage ~= nil and withWarning(lines) or lines
    end
    if state.act >= Const.ACT.DONE then
        return FAREWELL_BROADCAST
    end
    return FULL_BROADCAST
end

-- La chaîne est retrouvée à chaque fois : OnLoadRadioScripts ne se redéclenche pas après
-- un rechargement Lua, une référence mise en cache deviendrait invalide.
local function findChannel()
    local radio = getZomboidRadio()
    local manager = radio and radio:getScriptManager()
    return manager and manager:getRadioChannel(Const.RADIO.UUID)
end

local function lineText(line)
    if line.raw then
        return line.raw
    end
    -- Texte composé ici, donc dans la langue du serveur et non dans celle de chaque auditeur. En
    -- multijoueur, les traductions du mod n'existent sur le serveur qu'après leur rechargement
    -- (Artemis_ServerTranslations) ; sans lui, la clé brute serait diffusée.
    return getText(line.key)
end

local function buildBroadcast(lines)
    local id = "ART-" .. tostring(math.floor(getGameTime():getWorldAgeHours() * 60))
    local broadcast = RadioBroadCast.new(id, -1, -1)
    for _, line in ipairs(lines) do
        local radioLine = RadioLine.new(lineText(line), LINE_COLOR.r, LINE_COLOR.g, LINE_COLOR.b, line.codes or "")
        broadcast:AddRadioLine(radioLine)
    end
    return broadcast
end

-- Déclenché à chaque chargement du monde (ZomboidRadio.java:246), y compris pour une
-- sauvegarde existante : la chaîne n'est pas persistée, elle est recréée à chaque fois avec la
-- fréquence des options sandbox (déjà chargées : SandboxOptions.load précède ZomboidRadio.Init,
-- IsoWorld.java:1801 et 1905).
local function onLoadRadioScripts(scriptManager, _isNewGame)
    local frequency = Config.radioFrequency()
    local label = Config.radioFrequencyLabel() .. " MHz"
    local channel = DynamicRadioChannel.new(Const.RADIO.NAME, frequency, ChannelCategory.Military, Const.RADIO.UUID)
    scriptManager:AddChannel(channel, false)
    if scriptManager:getRadioChannel(Const.RADIO.UUID) == nil then
        Const.log("ERROR: radio channel not created on " .. label
            .. ": frequency already used by another channel; choose another one in the sandbox options")
        return
    end
    Const.log("radio channel created on " .. label)
end

-- Relance la diffusion quand elle est terminée, ou perdue au rechargement
-- (DynamicRadioChannel.LoadAiringBroadcast est vide). La station émet toujours, que le joueur
-- l'écoute ou non : son contenu dépend de l'acte (chiffres seuls avant la lecture du carnet).
local function onEveryTenMinutes()
    if not Config.isEnabled() then return end
    local channel = findChannel()
    if channel and channel:getAiringBroadcast() == nil then
        channel:setAiringBroadcast(buildBroadcast(linesFor(Store.load())))
    end
end

Events.OnLoadRadioScripts.Add(onLoadRadioScripts)
Events.EveryTenMinutes.Add(onEveryTenMinutes)
