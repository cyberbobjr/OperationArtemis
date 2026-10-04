-- Opération Artemis : route C, le checkpoint du pont Clark Memorial (décisions de la phase 5).
-- Serveur ou solo, sondage à la seconde réelle, à l'acte III :
-- - pose le site (enclos, portail, poste, haut-parleur) quand ses cases sont chargées, une fois ;
-- - joueur autorisé (test d'entrée négatif, Artemis_Checkpoint) qui entre dans l'enclos : la
--   quarantaine commence (une heure de jeu maximum), le portail se verrouille, un détenu mort
--   est posé ; vagues de civils attirés par le bruit (Artemis_Waves) ; après 30 minutes, le détenu se
--   relève et réveille le joueur ;
-- - sortir de l'enclos interrompt la quarantaine ;
-- - à la fin, test final sur l'état réel (BodyDamage:isInfected, synchronisé en multijoueur) :
--   négatif, le portail s'ouvre et un passage s'ouvre dans le barrage du pont ; positif, refus
--   (avec ZVirusVaccine, se soigner puis refaire le test d'entrée) ;
-- - un joueur passé qui franchit la ligne du barrage sort de la zone (fin de l'opération).
-- Après la stérilisation de la zone (option), l'armée est partie : le portail reste ouvert, plus rien.
-- Hors de l'acte III (fin de l'opération par un autre joueur, mod désactivé), le portail est déverrouillé :
-- personne ne reste enfermé. Un joueur en quarantaine peut demander à sortir (Artemis_CheckpointClient).
-- Règles pures : Artemis_Quarantine ; objets : Artemis_CheckpointSite.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Clock = require "Artemis/Artemis_Clock"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Players = require "Artemis/Artemis_Players"
local Progress = require "Artemis/Artemis_Progress"
local Quarantine = require "Artemis/Artemis_Quarantine"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Vaccine = require "Artemis/Artemis_Vaccine"
local Waves = require "Artemis/Artemis_Waves"
local Site = require "Artemis/Artemis_CheckpointSite"

local CHECK_INTERVAL_MS = 1000
-- Passage du barrage : nouvel essai tant que ses cases ne sont pas chargées.
local LANE_INTERVAL_MS = 5000
-- Registre de pose du site (state.placed), gardé au redémarrage de l'opération.
local SITE_GROUP = "checkpoint_site"

local cfg = Story.CHECKPOINT
local penWaves = Waves.new(cfg.waves, { x = math.floor((cfg.pen.x1 + cfg.pen.x2) / 2),
    y = math.floor((cfg.pen.y1 + cfg.pen.y2) / 2), z = cfg.pen.z })
local lastCheckMs = 0
local lastLaneMs = 0

local function ensureSite(data)
    if type(data.placed) == "table" and data.placed[SITE_GROUP] then return end
    if not Site.isLoaded(cfg) then return end
    -- Registre écrit avant la pose : une erreur ne doit pas la faire recommencer (objets doublés).
    Store.save(State.withPlaced(Store.load(), SITE_GROUP))
    Site.build(cfg, Vaccine.isActive())
end

local function position(player)
    return math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
end

local function startQuarantine(player, nowHours)
    local hasDossier = player:getInventory():containsTypeRecurse(Const.ITEM.DOSSIER)
    penWaves:reset()
    Site.placeDetainee(cfg)
    Progress.setCheckpointEntry(player, Quarantine.started(cfg, nowHours, hasDossier), "quarantine_start",
        hasDossier and "IGUI_Artemis_J_QuarantineStart" or "IGUI_Artemis_J_QuarantineStartNoDossier")
    Const.log("checkpoint : quarantaine de " .. Quarantine.hoursFor(cfg, hasDossier) .. " h pour "
        .. tostring(player:getUsername()))
end

-- Test final sur l'état réel du personnage.
local function finalTest(player)
    if player:getBodyDamage():isInfected() then
        Progress.setCheckpointEntry(player, { phase = Quarantine.REFUSED }, "quarantine_refused",
            "IGUI_Artemis_J_QuarantineRefused")
        Const.log("checkpoint : test final positif, refus (" .. tostring(player:getUsername()) .. ")")
        return
    end
    Progress.setCheckpointEntry(player, { phase = Quarantine.PASSED }, "quarantine_passed",
        "IGUI_Artemis_J_QuarantinePassed")
    Progress.openCheckpointLane()
    lastLaneMs = 0
    Const.log("checkpoint : test final negatif, barrage ouvert (" .. tostring(player:getUsername()) .. ")")
end

local function updateRunning(player, entry, nowHours, nowMs)
    -- Anciennes parties : conserver le début, le résultat et l'incident déjà joué.
    -- La réduction passe par la même autorité et synchronisation que les autres changements.
    if entry.hours > Quarantine.MAX_HOURS then
        local changed = State.copy(entry)
        changed.hours = Quarantine.MAX_HOURS
        Progress.setCheckpointEntry(player, changed)
        entry = changed
    end
    if Quarantine.isOver(entry, nowHours) then
        finalTest(player)
        return
    end
    if Quarantine.isReanimationDue(cfg, entry, nowHours) then
        local changed = State.copy(entry)
        changed.reanimated = true
        local hasRisen = Site.reanimateDetainee(cfg)
        if player:isAsleep() then
            player:forceAwake()
        end
        Progress.setCheckpointEntry(player, changed, hasRisen and "quarantine_reanimate" or nil)
        return
    end
    penWaves:update(Quarantine.fraction(entry, nowHours), nowMs)
end

-- Un joueur : renvoie true s'il est dans l'enclos.
local function updatePlayer(player, entry, nowHours, nowMs)
    local x, y, z = position(player)
    local isInPen = Quarantine.isInPen(cfg, x, y, z)
    if type(entry) ~= "table" then return isInPen end
    if entry.phase == Quarantine.CLEARED then
        if not Quarantine.isClearValid(entry, nowHours) then
            Progress.setCheckpointEntry(player, nil)
        elseif isInPen then
            startQuarantine(player, nowHours)
        end
    elseif entry.phase == Quarantine.RUNNING then
        if not isInPen then
            Progress.setCheckpointEntry(player, nil, "quarantine_broken", "IGUI_Artemis_J_QuarantineBroken")
            Const.log("checkpoint : quarantaine interrompue (" .. tostring(player:getUsername()) .. ")")
        else
            updateRunning(player, entry, nowHours, nowMs)
        end
    elseif entry.phase == Quarantine.PASSED and Quarantine.isPastExitLine(cfg, x, y) then
        Progress.onExit(player, "C", nil)
    end
    return isInPen
end

local function entriesOf(data)
    local entries = data.flags[Quarantine.FLAG]
    return type(entries) == "table" and entries or {}
end

local function updateGate(inPen, online, nowHours, isClosedRoute)
    local gate = Site.findGate(cfg)
    if gate == nil then return end
    local data = ModData.get(Const.MODDATA_KEY)
    local isOpen = isClosedRoute or Quarantine.isGateOpen(entriesOf(data), inPen, online, nowHours)
    Site.setGateLocked(gate, not isOpen)
end

-- Hors de l'acte III : portail déverrouillé (s'il est chargé et verrouillé).
local function releaseGate(data)
    if type(data) ~= "table" or type(data.placed) ~= "table" or not data.placed[SITE_GROUP] then return end
    local gate = Site.findGate(cfg)
    if gate and Site.setGateLocked(gate, false) then
        Const.log("checkpoint : portail deverrouille (operation hors de l'acte III)")
    end
end

local function updateLane(data, nowMs)
    if entriesOf(data)[Quarantine.LANE_KEY] ~= true or nowMs - lastLaneMs < LANE_INTERVAL_MS then return end
    lastLaneMs = nowMs
    local removed = Site.openLane(cfg)
    if removed > 0 then
        Const.log("checkpoint : passage ouvert dans le barrage du pont (" .. removed .. " objet(s) retires)")
    end
end

local function onTick()
    local nowMs = getTimestampMs()
    if nowMs - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = nowMs
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" or data.act ~= Const.ACT.EXFILTRATION or not Config.isEnabled() then
        releaseGate(data)
        return
    end
    local players = Players.list()
    if #players == 0 then return end
    ensureSite(data)
    local nowHours = Clock.now().worldHours
    local isClosedRoute = Sterilization.closesRoute(data.flags, "C")
    local inPen, online = {}, {}
    if not isClosedRoute then
        for _, player in ipairs(players) do
            if not player:isDead() then
                local name = player:getUsername()
                online[name] = true
                if updatePlayer(player, entriesOf(ModData.get(Const.MODDATA_KEY))[name], nowHours, nowMs) then
                    inPen[name] = true
                end
            end
        end
    end
    updateGate(inPen, online, nowHours, isClosedRoute)
    updateLane(ModData.get(Const.MODDATA_KEY), nowMs)
end

Events.OnTick.Add(onTick)
