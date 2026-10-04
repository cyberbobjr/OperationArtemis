-- Opération Artemis : test d'entrée du checkpoint (route C, premier protocole), serveur ou solo.
-- Deux sources : le test de ZVirusVaccine fait au poste (Artemis_CheckpointVaccine), ou, sans ce mod,
-- le test du mod sur la caisse du poste (commande CHECKPOINT_TEST, Artemis_CheckpointClient). Le
-- serveur revérifie : acte III, route ouverte, joueur au poste, pas déjà en quarantaine.

local Const = require "Artemis/Artemis_Const"
local Clock = require "Artemis/Artemis_Clock"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Progress = require "Artemis/Artemis_Progress"
local Quarantine = require "Artemis/Artemis_Quarantine"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Vaccine = require "Artemis/Artemis_Vaccine"
local Players = require "Artemis/Artemis_Players"

local Checkpoint = {}

local function position(player)
    return math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
end

-- Résultat d'un test d'entrée (isNegative), d'une source (« vaccine » ou « mod »).
function Checkpoint.onEntryTest(player, isNegative, source)
    local state = Store.load()
    local name = tostring(player:getUsername())
    local cfg = Story.CHECKPOINT
    if state.act ~= Const.ACT.EXFILTRATION or Sterilization.closesRoute(state.flags, "C") then return end
    local x, y, z = position(player)
    if not Quarantine.isAtPost(cfg, x, y, z) then
        Const.log("checkpoint : test " .. source .. " de " .. name .. " hors du poste, ignore")
        return
    end
    local entry = State.flagValue(state, Quarantine.FLAG, name)
    if type(entry) == "table" and (entry.phase == Quarantine.RUNNING or entry.phase == Quarantine.PASSED) then
        return
    end
    if isNegative then
        -- Enclos occupé par la quarantaine d'un autre joueur : autorisé, mais il faudra attendre.
        local online = {}
        for _, other in ipairs(Players.list()) do
            online[other:getUsername()] = true
        end
        local entries = type(state.flags[Quarantine.FLAG]) == "table" and state.flags[Quarantine.FLAG] or {}
        local sceneId = Quarantine.isOccupied(entries, online, name) and "checkpoint_wait" or "checkpoint_cleared"
        Progress.setCheckpointEntry(player, Quarantine.cleared(cfg, Clock.now().worldHours), sceneId)
        Progress.onSupplyCommit(player, "checkpoint")
        Const.log("checkpoint : test d'entree negatif (" .. source .. ", " .. name .. ") : portail ouvert")
    else
        Progress.setCheckpointEntry(player, { phase = Quarantine.REFUSED }, "checkpoint_positive",
            "IGUI_Artemis_J_CheckpointPositive")
        Const.log("checkpoint : test d'entree positif (" .. source .. ", " .. name .. ") : refus")
    end
end

-- Test du mod (sans ZVirusVaccine) : le résultat est l'état réel du personnage.
function Checkpoint.onModTest(player)
    if Vaccine.isActive() then
        Const.log("checkpoint : test du mod refuse, le protocole ZVirusVaccine s'applique")
        return
    end
    Checkpoint.onEntryTest(player, not player:getBodyDamage():isInfected(), "mod")
end

-- Joueur en quarantaine qui demande à sortir (commande CHECKPOINT_LEAVE) : la quarantaine est
-- abandonnée, le portail s'ouvre pour lui (Quarantine.isGateOpen).
function Checkpoint.onLeave(player)
    local state = Store.load()
    local entry = State.flagValue(state, Quarantine.FLAG, player:getUsername())
    if type(entry) ~= "table" or entry.phase ~= Quarantine.RUNNING then return end
    Progress.setCheckpointEntry(player, nil, "quarantine_broken", "IGUI_Artemis_J_QuarantineBroken")
    Const.log("checkpoint : quarantaine abandonnee a la demande (" .. tostring(player:getUsername()) .. ")")
end

return Checkpoint
