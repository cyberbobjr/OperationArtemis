-- Opération Artemis : appel d'évacuation par radio militaire (acte III, route B ; près du quai de
-- Brandenburg et sans mod de bateau : appel du passeur de la route A).
-- Menu contextuel sur une radio militaire (en main, sur le dos, ou posée à 2 cases) : le personnage
-- prononce l'indicatif ; la radio transmet vraiment la phrase sur sa fréquence (émission vanilla de
-- la parole, radio-dynamic.md). Le serveur revérifie tout (Progress.onExtractionCall) et ouvre le
-- créneau quotidien. La base répond sur la radio quelques secondes plus tard : « reçu » si le créneau
-- est ouvert (état lu dans la ModData : sendServerCommand ne fait rien en solo), sinon rien que des
-- parasites.

local Const = require "Artemis/Artemis_Const"
local RadioLib = require "Artemis/Artemis_RadioLib"
local Config = require "Artemis/Artemis_Config"
local ClientState = require "Artemis/Artemis_ClientState"
local State = require "Artemis/Artemis_State"
local Extraction = require "Artemis/Artemis_Extraction"
local MilRadio = require "Artemis/Artemis_MilRadio"
local Bridge = require "Artemis/Artemis_Bridge"
local Story = require "Artemis/Artemis_Story"
local Boats = require "Artemis/Artemis_Boats"
local Sterilization = require "Artemis/Artemis_Sterilization"

-- Délai (ms réelles) avant la réponse de la base : le temps que le serveur traite l'appel.
local REPLY_DELAY_MS = 4000
-- Couleur des lignes de la base, celle de la chaîne Artemis (Artemis_Radio).
local REPLY_COLOR = { r = 0.70, g = 0.85, b = 0.55 }
-- Indicatif par défaut si l'état n'en a pas (partie arrivée à l'acte III par le debug).
local DEFAULT_CALL_CODE = "7149"

-- Motif de refus -> clé de l'infobulle (sans jamais cacher la fréquence : le joueur la connaît).
local REASON_KEYS = {
    notCarried = "IGUI_Artemis_Call_NotCarried",
    tooFar = "IGUI_Artemis_Call_TooFar",
    radioOff = "IGUI_Artemis_Call_RadioOff",
    wrongFrequency = "IGUI_Artemis_Call_WrongFrequency",
    micMuted = "IGUI_Artemis_Call_MicMuted",
}

local pendingReplies = {}

local function runReplies()
    local now = getTimestampMs()
    for index = #pendingReplies, 1, -1 do
        local reply = pendingReplies[index]
        if now >= reply.at then
            table.remove(pendingReplies, index)
            reply.fn()
        end
    end
    if #pendingReplies == 0 then
        Events.OnTick.Remove(runReplies)
    end
end

local function later(delayMs, fn)
    if #pendingReplies == 0 then
        Events.OnTick.Add(runReplies)
    end
    pendingReplies[#pendingReplies + 1] = { at = getTimestampMs() + delayMs, fn = fn }
end

local function isCalled(rendezvousKey)
    return Extraction.isCalled(State.flagValue(ClientState.get(), "extraction", rendezvousKey))
end

-- Près du quai de Brandenburg, sans mod de bateau, l'appel s'adresse au passeur (route A).
local function isFerryCall(player)
    local landing = Story.FERRY.landing
    return Boats.vBoatScript() == nil
        and Extraction.distance(player:getX(), player:getY(), landing.x, landing.y) <= Story.FERRY.callRadius
end

-- Réponse de la base, affichée par la radio si elle est toujours allumée.
local function reply(device, isFerry)
    local data = device and device:getDeviceData()
    if not data or not data:getIsTurnedOn() then return end
    local key
    if isFerry then
        key = isCalled(Story.FERRY.key) and "IGUI_Artemis_Call_FerryReply" or "IGUI_Artemis_Call_NoReply"
    else
        -- Zone stérilisée : la base est partie, même si l'hélicoptère avait été appelé avant.
        local isOpen = not Sterilization.closesRoute(ClientState.get().flags, "B")
        key = (isOpen and isCalled(Extraction.KEY)) and "IGUI_Artemis_Call_Reply" or "IGUI_Artemis_Call_NoReply"
    end
    -- Radio posée : AddDeviceText existe en float et en int, Kahlua peut prendre la version entière
    -- (texte noir) ; on passe des entiers 0-255, justes dans les deux cas (kahlua-lua.md). Radio
    -- d'inventaire : version float seulement.
    if instanceof(device, "IsoWaveSignal") then
        device:AddDeviceText(getText(key), math.floor(REPLY_COLOR.r * 255 + 0.5), math.floor(REPLY_COLOR.g * 255 + 0.5),
            math.floor(REPLY_COLOR.b * 255 + 0.5), nil, nil, -1)
    else
        device:AddDeviceText(getText(key), REPLY_COLOR.r, REPLY_COLOR.g, REPLY_COLOR.b, nil, nil, -1)
    end
end

local function onCall(player, device)
    local code = ClientState.get().callCode or DEFAULT_CALL_CODE
    local isFerry = isFerryCall(player)
    RadioLib.compat().say(player, getText("IGUI_Artemis_Call_Say", code))
    local command = isFerry and Const.COMMAND.CALL_FERRY or Const.COMMAND.CALL_EXTRACTION
    sendClientCommand(player, Const.NET_MODULE, command, { radio = MilRadio.makeRef(device) })
    later(REPLY_DELAY_MS, function() reply(device, isFerry) end)
end

local function addTooltip(option, text)
    local tooltip = ISToolTip:new()
    tooltip:initialise()
    tooltip:setVisible(false)
    tooltip.description = text
    option.toolTip = tooltip
end

local function addOption(player, context, device)
    local label = isFerryCall(player) and "ContextMenu_Artemis_CallFerry" or "ContextMenu_Artemis_CallExtraction"
    local option = context:addOption(getText(label), player, onCall, device)
    local reason = MilRadio.status(player, device, Config.radioFrequency())
    if reason then
        option.notAvailable = true
        addTooltip(option, getText(REASON_KEYS[reason] or "IGUI_Artemis_Call_NotCarried", Config.radioFrequencyLabel()))
    else
        addTooltip(option, getText("IGUI_Artemis_Call_Tooltip"))
    end
end

-- Si Military Drop assure le transport (pont), c'est son appel qui sert pour l'hélicoptère : pas de
-- menu ici, sauf pour appeler le passeur depuis son quai.
local function isExfiltration(player)
    return Config.isEnabled() and ClientState.get().act == Const.ACT.EXFILTRATION
        and (not Bridge.hasTransport() or isFerryCall(player))
end

local function onFillInventoryObjectContextMenu(playerNum, context, items)
    local player = getSpecificPlayer(playerNum)
    if not player or not isExfiltration(player) then return end
    for _, entry in ipairs(items) do
        local item = entry
        if not instanceof(entry, "InventoryItem") then
            item = entry.items and entry.items[1]
        end
        if MilRadio.isInventoryRadio(item) and MilRadio.isMilitary(item) then
            addOption(player, context, item)
            return
        end
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    local player = getSpecificPlayer(playerNum)
    if not player or not isExfiltration(player) then return end
    local seen = {}
    for _, object in ipairs(worldObjects) do
        local square = object and object:getSquare()
        if square and not seen[square] then
            seen[square] = true
            local objects = square:getObjects()
            for index = 0, objects:size() - 1 do
                local candidate = objects:get(index)
                if MilRadio.isWorldRadio(candidate) and MilRadio.isMilitary(candidate) then
                    -- Sondage des manettes : signaler qu'il y a une option (ISWorldObjectContextMenu.lua:122-128).
                    if test then return ISWorldObjectContextMenu.setTest() end
                    addOption(player, context, candidate)
                    return
                end
            end
        end
    end
end

Events.OnFillInventoryObjectContextMenu.Add(onFillInventoryObjectContextMenu)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
