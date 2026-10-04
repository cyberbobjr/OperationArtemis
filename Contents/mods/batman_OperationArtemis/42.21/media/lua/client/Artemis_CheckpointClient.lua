-- Opération Artemis : checkpoint de la route C, côté client (décisions de la phase 5).
-- - Sans ZVirusVaccine, le test d'entrée de l'armée se fait sur la caisse du poste (menu contextuel) ;
--   le serveur lit l'état réel du personnage (Artemis_Checkpoint). Avec ce mod, c'est son propre test
--   (seringue, spectromètre posé au poste) qui compte.
-- - Pendant la quarantaine du joueur local, le haut-parleur de l'enclos (radio posée) fait des annonces
--   (bulle vanilla d'AddDeviceText, qui fait aussi un bruit). Couleurs en entiers 0-255 : un appareil
--   posé a les surcharges float et int, Kahlua peut prendre la seconde (kahlua-lua.md).

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local State = require "Artemis/Artemis_State"
local ClientState = require "Artemis/Artemis_ClientState"
local Quarantine = require "Artemis/Artemis_Quarantine"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Vaccine = require "Artemis/Artemis_Vaccine"

local cfg = Story.CHECKPOINT

local SPEAKER_COLOR = { r = 230, g = 200, b = 120 }
local CHECK_INTERVAL_MS = 2000
-- Annonces réparties sur une heure de jeu. L'incident suit la réanimation à 30 minutes.
local ANNOUNCEMENTS = {
    { hour = 0.02, key = "IGUI_Artemis_Speaker_Start" },
    { hour = 0.2, key = "IGUI_Artemis_Speaker_Routine" },
    { hour = 0.4, key = "IGUI_Artemis_Speaker_Stay" },
    { hour = 0.55, key = "IGUI_Artemis_Speaker_Incident" },
    { hour = 0.8, key = "IGUI_Artemis_Speaker_Routine" },
}

local lastCheckMs = 0
-- Annonces déjà faites pour la quarantaine en cours : { startHours, done = { [index] = true } }.
local announced = { startHours = nil, done = {} }

local function isRouteOpen(state)
    return Config.isEnabled() and state.act == Const.ACT.EXFILTRATION
        and not Sterilization.closesRoute(state.flags, "C")
end

-- Menu contextuel : test de l'armée sur la caisse du poste --------------------------------------

local function onModTest(player)
    player:Say(getText("IGUI_Artemis_Checkpoint_TestSay"))
    sendClientCommand(player, Const.NET_MODULE, Const.COMMAND.CHECKPOINT_TEST, {})
end

local function isPostSquare(square)
    local post = cfg.post
    return square:getX() == post.x and square:getY() == post.y and square:getZ() == post.z
end

local function onLeave(player)
    sendClientCommand(player, Const.NET_MODULE, Const.COMMAND.CHECKPOINT_LEAVE, {})
end

-- En quarantaine dans l'enclos : on peut demander à sortir (la quarantaine est abandonnée).
local function isQuarantinedInPen(player, state)
    local entry = State.flagValue(state, Quarantine.FLAG, player:getUsername())
    local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    return type(entry) == "table" and entry.phase == Quarantine.RUNNING and Quarantine.isInPen(cfg, x, y, z)
end

local function hasPostSquare(worldObjects)
    for _, object in ipairs(worldObjects) do
        local square = object and object:getSquare()
        if square and isPostSquare(square) then
            return true
        end
    end
    return false
end

local function onFillWorldObjectContextMenu(playerNum, context, worldObjects, test)
    local player = getSpecificPlayer(playerNum)
    local state = ClientState.get()
    if not player or not isRouteOpen(state) then return end
    local canLeave = isQuarantinedInPen(player, state)
    local canTest = not Vaccine.isActive() and hasPostSquare(worldObjects)
    if not canLeave and not canTest then return end
    -- Sondage des manettes : signaler qu'il y a des options (ISWorldObjectContextMenu.lua:122-128).
    if test then return ISWorldObjectContextMenu.setTest() end
    if canLeave then
        context:addOption(getText("ContextMenu_Artemis_CheckpointLeave"), player, onLeave)
    end
    if canTest then
        local option = context:addOption(getText("ContextMenu_Artemis_CheckpointTest"), player, onModTest)
        local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
        if not Quarantine.isAtPost(cfg, x, y, z) then
            option.notAvailable = true
        end
        local tooltip = ISToolTip:new()
        tooltip:initialise()
        tooltip:setVisible(false)
        tooltip.description = getText("IGUI_Artemis_Checkpoint_TestTooltip")
        option.toolTip = tooltip
    end
end

-- Haut-parleur de l'enclos ----------------------------------------------------------------------

local function findSpeaker()
    local speaker = cfg.speaker
    local square = getCell():getGridSquare(speaker.x, speaker.y, speaker.z)
    if square == nil then return nil end
    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local object = objects:get(index)
        if instanceof(object, "IsoRadio") then
            return object
        end
    end
    return nil
end

local function announce(key)
    local radio = findSpeaker()
    if radio == nil then return end
    local data = radio:getDeviceData()
    -- Allumée à la pose ; l'état « allumé » d'un appareil n'est pas transmis par le serveur : on
    -- l'allume localement si besoin (sans son ni synchronisation).
    if not data:getIsTurnedOn() then
        data:setTurnedOnRaw(true)
    end
    radio:AddDeviceText(getText(key), SPEAKER_COLOR.r, SPEAKER_COLOR.g, SPEAKER_COLOR.b, nil, nil, -1)
end

local function updateAnnouncements(player, state)
    local entry = State.flagValue(state, Quarantine.FLAG, player:getUsername())
    if type(entry) ~= "table" or entry.phase ~= Quarantine.RUNNING then
        announced = { startHours = nil, done = {} }
        return
    end
    if announced.startHours ~= entry.startHours then
        announced = { startHours = entry.startHours, done = {} }
    end
    local elapsed = Quarantine.elapsedHours(entry, getGameTime():getWorldAgeHours())
    -- Une seule annonce à la fois : la plus récente due ; les plus anciennes, manquées (sommeil,
    -- rechargement), sont sautées.
    local due = nil
    for index, item in ipairs(ANNOUNCEMENTS) do
        if not announced.done[index] and elapsed >= item.hour and item.hour < entry.hours then
            announced.done[index] = true
            due = item
        end
    end
    if due then
        announce(due.key)
    end
end

local function onTick()
    local now = getTimestampMs()
    if now - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = now
    local player = getPlayer()
    if player == nil then return end
    local state = ClientState.get()
    if not isRouteOpen(state) then return end
    updateAnnouncements(player, state)
end

Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
Events.OnTick.Add(onTick)
