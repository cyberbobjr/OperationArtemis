-- Opération Artemis : remontée à la surface du dernier lieu avec le dossier (données « surfacing » du
-- dernier chapitre, Artemis_Story). Serveur ou solo.
-- À l'acte III, le premier joueur qui revient à la surface de la base (emprise du guide) avec le
-- dossier dans son inventaire joue la scène de remontée (brouillard, pensée), une fois par partie,
-- quelle que soit l'heure. Aucun événement ne signale un changement d'étage : on regarde chaque minute,
-- seulement tant que la scène n'a pas été jouée.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local Players = require "Artemis/Artemis_Players"
local Progress = require "Artemis/Artemis_Progress"
local Tracking = require "Artemis/Artemis_Tracking"
local Trial = require "Artemis/Artemis_Trial"

local REGISTRY = "surfaced"

local function hasSurfaced(data, chapterId)
    local flags = type(data) == "table" and data.flags
    local entries = type(flags) == "table" and flags[REGISTRY]
    return type(entries) == "table" and entries[chapterId] == true
end

local function isSurfacingWithDossier(player, chapter)
    return not player:isDead() and math.floor(player:getZ()) >= chapter.surfacing.minZ
        and Tracking.isInArea(chapter.guide.area, player:getX(), player:getY())
        and player:getInventory():containsTypeRecurse(Const.ITEM.DOSSIER)
end

local function onEveryOneMinute()
    if not Config.isEnabled() then return end
    local data = ModData.get(Const.MODDATA_KEY)
    local chapterId = Story.EXIT_CHAPTER
    if type(data) ~= "table" or data.act ~= Const.ACT.EXFILTRATION or hasSurfaced(data, chapterId) then
        return
    end
    -- Pendant l'évasion, c'est la réussite de l'épreuve qui joue la sortie (Artemis_BaseAlarm).
    if Trial.isRunning(data.flags, chapterId) then return end
    local chapter = Story.get(chapterId)
    for _, player in ipairs(Players.list()) do
        if isSurfacingWithDossier(player, chapter) then
            Progress.onSurface(player, chapterId, chapter.surfacing.scene)
            return
        end
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)
