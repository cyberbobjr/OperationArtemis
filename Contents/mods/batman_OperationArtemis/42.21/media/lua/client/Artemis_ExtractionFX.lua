-- Opération Artemis : zone d'embarquement vue par le client, une fois le transport arrivé
-- (hélicoptère de la route B, passeur de la route A ; Artemis_Rendezvous côté serveur).
-- - Zone marquée au sol : cercle vert pulsé (marqueur vanilla « circle_highlight », WorldMarkers,
--   local au client) sur la zone où se tenir pour embarquer ;
-- - compte à rebours d'embarquement à l'écran, tant que le joueur local est dans la zone avec le
--   dossier. Affichage seulement : c'est le serveur qui décide de l'embarquement (même durée).
-- La fumée verte et la fusée au sol viennent du mod requis batman_SignalSmoke (côté serveur).

local Const = require "Artemis/Artemis_Const"
local Story = require "Artemis/Artemis_Story"
local State = require "Artemis/Artemis_State"
local Extraction = require "Artemis/Artemis_Extraction"
local StateWatcher = require "Artemis/Artemis_StateWatcher"

local ZONE_COLOR = { r = 0.2, g = 1.0, b = 0.3 }
local ZONE_FADE_SPEED = 0.05
local ZONE_ALPHA_MIN = 0.35
local ZONE_ALPHA_MAX = 0.9
local TEXT_COLOR = { r = 0.6, g = 1.0, b = 0.6, a = 1.0 }
local TEXT_TOP = 120

-- Rendez-vous suivis : clé de l'état et données de la zone.
local RENDEZVOUS = {
    { key = Extraction.KEY, cfg = Story.EXTRACTION },
    { key = Story.FERRY.key, cfg = Story.FERRY },
}

-- Zones arrivées : { [clé] = { cfg, marker } } ; compte à rebours commun (une zone à la fois).
local landed = {}
local isTicking = false
local enteredAtMs = nil
local boardingCfg = nil

-- Bandeau du compte à rebours : élément sans fond, qui ne bloque pas la souris.
local Countdown = ISUIElement:derive("ArtemisExtractionCountdown")
local countdownPanel = nil

function Countdown:render()
    if not enteredAtMs or not boardingCfg then return end
    local left = math.max(0, math.ceil(boardingCfg.boardSeconds - (getTimestampMs() - enteredAtMs) / 1000))
    self:drawTextCentre(getText("IGUI_Artemis_Boarding", left), self.width / 2, 0,
        TEXT_COLOR.r, TEXT_COLOR.g, TEXT_COLOR.b, TEXT_COLOR.a, UIFont.Title)
end

local function showCountdown()
    if countdownPanel then return end
    countdownPanel = Countdown:new(0, TEXT_TOP, getCore():getScreenWidth(), 40)
    countdownPanel:initialise()
    countdownPanel:addToUIManager()
    countdownPanel.javaObject:setConsumeMouseEvents(false)
end

local function hideCountdown()
    if countdownPanel then
        countdownPanel:removeFromUIManager()
        countdownPanel = nil
    end
    enteredAtMs = nil
    boardingCfg = nil
end

local function removeZone(zone)
    if zone.marker then
        getWorldMarkers():removeGridSquareMarker(zone.marker)
        zone.marker = nil
    end
end

local function ensureZone(zone)
    if zone.marker then return end
    local landing = zone.cfg.landing
    local square = getCell():getGridSquare(landing.x, landing.y, landing.z)
    if square then
        -- Taille du marqueur : le diamètre de la zone marquée, en cases.
        zone.marker = getWorldMarkers():addGridSquareMarker("circle_highlight", "circle_only_highlight", square,
            ZONE_COLOR.r, ZONE_COLOR.g, ZONE_COLOR.b, true, zone.cfg.boardRadius * 2 + 1,
            ZONE_FADE_SPEED, ZONE_ALPHA_MIN, ZONE_ALPHA_MAX)
    end
end

-- Zone où le joueur local embarque (dans la zone, avec le dossier), ou nil.
local function boardingZone(player)
    if not player or player:isDead() then return nil end
    if not player:getInventory():containsTypeRecurse(Const.ITEM.DOSSIER) then return nil end
    local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    for _, zone in pairs(landed) do
        if Extraction.isInBoardZone(zone.cfg, x, y, z) then
            return zone
        end
    end
    return nil
end

local function onTick()
    for _, zone in pairs(landed) do
        ensureZone(zone)
    end
    local zone = boardingZone(getPlayer())
    if zone then
        if boardingCfg ~= zone.cfg then
            enteredAtMs = getTimestampMs()
            boardingCfg = zone.cfg
        end
        showCountdown()
    else
        hideCountdown()
    end
end

local function onState(state, _isFirst)
    local isExfiltration = state.act == Const.ACT.EXFILTRATION
    for _, rendezvous in ipairs(RENDEZVOUS) do
        local entry = State.flagValue(state, "extraction", rendezvous.key)
        local isLanded = isExfiltration and Extraction.isCalled(entry) and entry.phase == Extraction.LANDED
        if isLanded and landed[rendezvous.key] == nil then
            landed[rendezvous.key] = { cfg = rendezvous.cfg }
        elseif not isLanded and landed[rendezvous.key] then
            removeZone(landed[rendezvous.key])
            landed[rendezvous.key] = nil
        end
    end
    local hasZone = false
    for _ in pairs(landed) do
        hasZone = true
    end
    if hasZone and not isTicking then
        isTicking = true
        Events.OnTick.Add(onTick)
    elseif not hasZone and isTicking then
        isTicking = false
        Events.OnTick.Remove(onTick)
        hideCountdown()
    end
end

StateWatcher.subscribe(onState)
