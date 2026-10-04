-- Opération Artemis : route A, le fleuve en bateau (décisions de la phase 5). Serveur ou solo, sondage
-- à la seconde réelle, à l'acte III :
-- - bateaux de V (un par bassin, l'Ohio étant coupé par le Clark Memorial), posés sur l'eau quand leur
--   case est chargée, si un mod de bateau est actif (Artemis_Boats) : carburant, clé posée sur le ponton.
--   Pose par addVehicleDebug (case extérieure sans autre véhicule ; réussite si getSqlId() ~= -1,
--   LuaManager.java:8505-8537) ; la flottaison est laissée au mod de bateau ;
-- - postes gardés (Story.RIVER.guards) : groupe électrogène en marche et projecteurs en décor ; leurs
--   lampes sont entretenues par chaque client tant que le groupe tourne (Artemis_WorldLights) ;
-- - un bateau occupé qui traverse la zone d'un poste pendant que son groupe tourne déclenche la sirène
--   (Artemis_RiverFX) et rabat une horde sur les berges ; groupe coupé (option vanilla « Éteindre »,
--   sans compétence), on passe dans le noir ;
-- - un joueur à bord d'un bateau, avec le dossier, qui franchit une ligne de sortie quitte la zone.
--   À la nage (mod de nage), la sortie ne compte pas : une pensée le dit.
-- Aucun événement ne signale l'arrêt d'un groupe (IsoGenerator.java:462) : on lit son état quand sa
-- case est chargée, et on garde le dernier état vu (state.flags.river[poste].cut).
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Clock = require "Artemis/Artemis_Clock"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Players = require "Artemis/Artemis_Players"
local Progress = require "Artemis/Artemis_Progress"
local River = require "Artemis/Artemis_River"
local Boats = require "Artemis/Artemis_Boats"
local Waves = require "Artemis/Artemis_Waves"

local CHECK_INTERVAL_MS = 1000
-- Nouvel essai de pose d'un bateau refusée (case occupée par un autre véhicule), en ms réelles.
local BOAT_RETRY_MS = 60000
local GENERATOR_FUEL = 10
local SOLDIER_RADIUS = 6

local cfg = Story.RIVER
local lastCheckMs = 0
local boatRetryAt = {}

local function worldMinutes()
    return math.floor(Clock.now().worldHours * 60)
end

local function isPlaced(data, group)
    return type(data.placed) == "table" and data.placed[group] == true
end

local function square(point)
    return getCell():getGridSquare(point.x, point.y, point.z or 0)
end

-- Bateaux de V -----------------------------------------------------------------------------------

local function fillTank(vehicle)
    local tank = vehicle:getPartById("GasTank")
    if tank == nil then return end
    tank:setContainerContentAmount(tank:getContainerCapacity() * cfg.fuelFraction)
    vehicle:transmitPartModData(tank)
end

local function placeBoat(spot, script, nowMs)
    local boatSquare, keySquare = square(spot), square(spot.key)
    if boatSquare == nil or keySquare == nil or (boatRetryAt[spot.group] or 0) > nowMs then return end
    -- Case déjà occupée par un véhicule (bateau d'un mod) : on réessaiera, sans écrire l'état.
    if boatSquare:getVehicleContainer() ~= nil then
        boatRetryAt[spot.group] = nowMs + BOAT_RETRY_MS
        return
    end
    -- Registre écrit avant la pose : une erreur ne doit pas doubler le bateau.
    Store.save(State.withPlaced(Store.load(), spot.group))
    local vehicle = addVehicleDebug(script, IsoDirections.N, nil, boatSquare)
    if vehicle == nil or vehicle:getSqlId() == -1 then
        Store.save(State.withoutPlaced(Store.load(), spot.group))
        boatRetryAt[spot.group] = nowMs + BOAT_RETRY_MS
        Const.log("fleuve : pose du bateau " .. spot.group .. " refusee (case occupee ?), nouvel essai plus tard")
        return
    end
    fillTank(vehicle)
    local key = vehicle:createVehicleKey()
    if key then
        keySquare:AddWorldInventoryItem(key, 0.5, 0.5, 0, true)
    end
    Const.log("fleuve : bateau de V pose (" .. script .. ") en " .. spot.x .. "," .. spot.y .. ", cle sur le ponton")
end

local function ensureBoats(data, nowMs)
    local script = Boats.vBoatScript()
    if script == nil then return end
    for _, spot in pairs(cfg.boats) do
        if not isPlaced(data, spot.group) then
            placeBoat(spot, script, nowMs)
        end
    end
end

-- Postes gardés ----------------------------------------------------------------------------------

local function placeSoldiers(guard)
    local generator = guard.generator
    for _ = 1, guard.soldiers do
        local x = generator.x + ZombRand(-SOLDIER_RADIUS, SOLDIER_RADIUS + 1)
        local y = generator.y + ZombRand(1, SOLDIER_RADIUS + 1)
        local outfit = cfg.soldierOutfits[ZombRand(#cfg.soldierOutfits) + 1]
        addZombiesInOutfit(x, y, generator.z, 1, outfit, 0, false, false, false, false, false, false, 1.0)
    end
end

local function placeGuard(guardId, guard)
    local generatorSquare = square(guard.generator)
    if generatorSquare == nil then return end
    for _, light in ipairs(guard.lights) do
        if square({ x = light.x, y = light.y, z = guard.generator.z }) == nil then return end
    end
    local state = State.withPlaced(Store.load(), guard.group)
    local floodlight = cfg.floodlight
    for index, light in ipairs(guard.lights) do
        local lightSquare = square({ x = light.x, y = light.y, z = guard.generator.z })
        lightSquare:transmitAddObjectToSquare(IsoObject.new(getCell(), lightSquare, floodlight.sprite), -1)
        -- Lampe du client, allumée tant que le groupe du poste tourne (Artemis_WorldLights).
        state = State.withFlagValue(state, "wallLights", guard.group .. "_" .. index, {
            x = light.x, y = light.y, z = guard.generator.z, sprite = floodlight.sprite,
            color = floodlight.color, radius = floodlight.radius, generator = guard.generator })
    end
    Store.save(state)
    local item = instanceItem(cfg.generatorItem)
    item:getModData().fuel = GENERATOR_FUEL
    local generator = IsoGenerator.new(item, getCell(), generatorSquare)
    generator:setConnected(true)
    generator:setActivated(true)
    placeSoldiers(guard)
    Const.log("fleuve : poste " .. guardId .. " pose (groupe en marche, projecteurs)")
end

-- État du groupe : true (tourne), false (arrêté ou disparu), nil (case non chargée).
local function generatorState(guard)
    local generatorSquare = square(guard.generator)
    if generatorSquare == nil then return nil end
    local generator = generatorSquare:getGenerator()
    return generator ~= nil and generator:isActivated()
end

local function riverEntry(data, guardId)
    local entries = data.flags[River.FLAG]
    return type(entries) == "table" and entries[guardId] or nil
end

local function setRiverEntry(guardId, changes, player, sceneId)
    local state = Store.load()
    local entry = State.copy(State.flagValue(state, River.FLAG, guardId) or {})
    for key, value in pairs(changes) do
        entry[key] = value
    end
    Progress.commit(state, State.withFlagValue(state, River.FLAG, guardId, entry), player, sceneId)
end

-- Groupe vu coupé ou rallumé : enregistré (le passeur attend que Kinsella soit coupé).
local function trackGenerator(data, guardId, guard)
    local isOn = generatorState(guard)
    if isOn == nil then return nil end
    local wasCut = River.isCut(riverEntry(data, guardId))
    if wasCut == isOn then
        setRiverEntry(guardId, { cut = not isOn }, nil, nil)
        Const.log("fleuve : groupe du poste " .. guardId .. (isOn and " rallume" or " coupe"))
    end
    return isOn
end

local function sendHorde(guard)
    local horde = cfg.horde
    local banks = guard.banks
    getWorldSoundManager():addSound(nil, banks.x, banks.y, banks.z, horde.noiseRadius, horde.noiseVolume)
    local count = horde.countByIntensity[Config.dramaIntensity()] or horde.countByIntensity[2]
    Waves.new(horde, banks):spawn(count, false)
end

-- Bateau occupé dans la zone d'un poste éclairé : sirène, horde, scène pour le pilote.
local function checkPassage(data, player, x, y, generatorOn)
    local guardId = River.guardAt(cfg, x, y)
    if guardId == nil then return end
    local entry = riverEntry(data, guardId)
    local now = worldMinutes()
    if not River.isLit(entry, generatorOn[guardId]) or River.isAlarmOn(entry, now) then return end
    sendHorde(cfg.guards[guardId])
    setRiverEntry(guardId, { alarmUntil = now + cfg.alarmMinutes }, player, "river_spotted")
    Const.log("fleuve : bateau repere au poste " .. guardId .. " (" .. tostring(player:getUsername()) .. ")")
end

local function checkExit(player, x, y)
    local exit = River.exitAt(cfg, x, y)
    if exit == nil then return end
    -- Pensées (une fois par partie, Progress.onHint).
    if not Boats.isAboard(player) then
        Progress.onHint(player, "river_swim")
        return
    end
    if not player:getInventory():containsTypeRecurse(Const.ITEM.DOSSIER) then
        Progress.onHint(player, "river_nodossier")
        return
    end
    Progress.onExit(player, "A", exit)
end

local function onTick()
    local nowMs = getTimestampMs()
    if nowMs - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = nowMs
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" or data.act ~= Const.ACT.EXFILTRATION or not Config.isEnabled() then return end
    local players = Players.list()
    if #players == 0 then return end
    ensureBoats(data, nowMs)
    local generatorOn = {}
    for guardId, guard in pairs(cfg.guards) do
        if not isPlaced(ModData.get(Const.MODDATA_KEY), guard.group) then
            placeGuard(guardId, guard)
        end
        -- Poste pas encore posé (cases non chargées) : rien à suivre, il « tourne » par défaut.
        if isPlaced(ModData.get(Const.MODDATA_KEY), guard.group) then
            generatorOn[guardId] = trackGenerator(ModData.get(Const.MODDATA_KEY), guardId, guard)
        end
    end
    for _, player in ipairs(players) do
        if not player:isDead() then
            local x, y = math.floor(player:getX()), math.floor(player:getY())
            -- Arrivée au bateau de V : premier engagement sur le fleuve (caisse de ravitaillement).
            if Boats.vBoatScript() ~= nil then
                for basin, spot in pairs(cfg.boats) do
                    if Players.isNear(player, spot, Story.SUPPLY.boatRadius) then
                        Progress.onSupplyCommit(player, basin == "west" and "boatWest" or "boatEast")
                    end
                end
            end
            if Boats.isAboard(player) then
                checkPassage(ModData.get(Const.MODDATA_KEY), player, x, y, generatorOn)
            end
            checkExit(player, x, y)
            data = ModData.get(Const.MODDATA_KEY)
            if data.act ~= Const.ACT.EXFILTRATION then return end
        end
    end
end

Events.OnTick.Add(onTick)
