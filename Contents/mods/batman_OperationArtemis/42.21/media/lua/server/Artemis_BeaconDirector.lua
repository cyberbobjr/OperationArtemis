-- Opération Artemis : balises de fumée verte de l'acte III (demande de l'utilisateur du 2026-10-01 :
-- toujours une fumée verte là où le joueur doit aller pour sortir). Serveur ou solo, à la minute de jeu.
-- Une fois le dossier lu, chaque balise de Story.BEACONS dont l'étape est en cours est posée par le mod
-- requis batman_SignalSmoke (fumée et lampe vertes, vues de tous les joueurs, restaurées au
-- chargement), puis prolongée avant la fin de sa durée ; une balise dont l'étape est passée (groupe
-- coupé, barrage ouvert, route fermée) est retirée. Toutes sont retirées hors de l'acte III.
-- Cause dans le monde : V et ses contacts balisent les points de rendez-vous avec la fumée verte du
-- protocole, comme la zone d'atterrissage (le dossier et le journal le disent).
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Bridge = require "Artemis/Artemis_Bridge"
local Boats = require "Artemis/Artemis_Boats"
local River = require "Artemis/Artemis_River"
local Quarantine = require "Artemis/Artemis_Quarantine"
local Sterilization = require "Artemis/Artemis_Sterilization"
local SignalSmoke = require "SignalSmoke/SignalSmoke"

local OWNER = "OperationArtemis"
-- Durée d'une pose (minutes de jeu) et marge sous laquelle on la prolonge.
local BEACON_MINUTES = 180
local REFRESH_BELOW_HOURS = 1

local function beaconId(beacon)
    return "artemis:beacon:" .. beacon.id
end

-- Étapes en cours, d'après l'état (table brute de la ModData).
local function conditions(data)
    local flags = data.flags
    local hasBoats = Boats.vBoatScript() ~= nil
    local checkpoint = type(flags[Quarantine.FLAG]) == "table" and flags[Quarantine.FLAG] or {}
    local isLaneOpen = checkpoint[Quarantine.LANE_KEY] == true
    local isCheckpointOpen = not Sterilization.closesRoute(flags, "C")
    local river = type(flags[River.FLAG]) == "table" and flags[River.FLAG] or {}
    return {
        heli = not Sterilization.closesRoute(flags, "B") and not Bridge.hasTransport(),
        boats = hasBoats,
        kinsellaLit = not hasBoats and not River.isCut(river.kinsella),
        ferry = not hasBoats,
        checkpoint = isCheckpointOpen and not isLaneOpen,
        lane = isCheckpointOpen and isLaneOpen,
    }
end

local function isWanted(data)
    return type(data) == "table" and data.act == Const.ACT.EXFILTRATION and Config.isEnabled()
        and State.hasFlagEntry(data, "readDocs", Story.EXFIL_REVEAL_DOCUMENT)
end

local function ensure(beacon, nowHours)
    local id = beaconId(beacon)
    local entry = SignalSmoke.list()[id]
    if entry and entry.untilH - nowHours > REFRESH_BELOW_HOURS then return end
    SignalSmoke.start{ id = id, owner = OWNER, color = "green", radius = 0, light = true,
        x = beacon.x, y = beacon.y, z = beacon.z, minutes = BEACON_MINUTES }
end

local function remove(beacon)
    local id = beaconId(beacon)
    if SignalSmoke.isActive(id) then
        SignalSmoke.stop(id)
    end
end

-- Balise de la caisse de ravitaillement : tant qu'elle n'a pas été vidée (Artemis_SupplyDirector).
local function supplyBeacon(data)
    local entries = type(data.flags) == "table" and data.flags.supply
    local drop = type(entries) == "table" and entries.drop or nil
    if type(drop) ~= "table" or drop.collected == true then return nil end
    local point = Story.SUPPLY.points[drop.point]
    return point and { id = "supply", x = point.x + 1, y = point.y, z = point.z } or nil
end

local SUPPLY_BEACON = { id = "supply" }

local function onEveryOneMinute()
    local data = ModData.get(Const.MODDATA_KEY)
    -- Caisse de ravitaillement : balisée dès qu'elle est annoncée, à l'acte III, même sans le dossier lu
    -- (engagement au checkpoint ou au bateau).
    local isExfiltration = type(data) == "table" and data.act == Const.ACT.EXFILTRATION and Config.isEnabled()
    local supply = isExfiltration and supplyBeacon(data) or nil
    if supply then
        ensure(supply, getGameTime():getWorldAgeHours())
    else
        remove(SUPPLY_BEACON)
    end
    if not isWanted(data) then
        for _, beacon in ipairs(Story.BEACONS) do
            remove(beacon)
        end
        return
    end
    local active = conditions(data)
    local nowHours = getGameTime():getWorldAgeHours()
    for _, beacon in ipairs(Story.BEACONS) do
        if active[beacon.when] then
            ensure(beacon, nowHours)
        else
            remove(beacon)
        end
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)
