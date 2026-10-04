-- Opération Artemis : guide du joueur dans un grand lieu (données « guide » d'un chapitre,
-- Artemis_Story). Côté client, pour le joueur local :
-- - étape en cours selon l'étage, affichée par le journal (Artemis_JournalUI) ;
-- - pensée à chaque nouvelle étape (une fois par étape et par session) ;
-- - lampes rouges de secours qui balisent le chemin (lumières locales au client, Artemis_Lamps),
--   qui clignotent si le guide a un motif (« lampBlink », Artemis_Blink).
-- Aucun état sauvegardé : l'étape se déduit de la position du joueur.

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local ClientState = require "Artemis/Artemis_ClientState"
local StagingFX = require "Artemis/Artemis_StagingFX"
local Lamps = require "Artemis/Artemis_Lamps"
local Ambience = require "Artemis/Artemis_Ambience"

local Guide = {}

local CHECK_INTERVAL_MS = 1000
local THOUGHT_SUFFIX = "_Thought"

-- Rouge des lampes de secours, rayon en cases.
local LAMP_COLOR = { r = 0.85, g = 0.1, b = 0.05 }
local LAMP_RADIUS = 6

local lastCheckMs = 0
local announcedSteps = {}
local lamps = Lamps.new({ color = LAMP_COLOR, radius = LAMP_RADIUS })
-- Guide dont les lampes sont en place (pour le clignotement, à chaque tick).
local litGuide = nil

local function isInArea(player, area)
    local x, y = player:getX(), player:getY()
    return x >= area.x1 and x <= area.x2 and y >= area.y1 and y <= area.y2
end

-- Étape du guide du chapitre en cours pour ce joueur, ou nil (pas de guide, ou joueur hors du lieu).
function Guide.currentStep(player)
    local chapter = Story.get(ClientState.get().chapter)
    local guide = chapter and chapter.guide
    if guide == nil or player == nil or not isInArea(player, guide.area) then
        return nil
    end
    local z = math.floor(player:getZ())
    for _, step in ipairs(guide.steps) do
        if z >= step.minZ and z <= step.maxZ and (step.area == nil or isInArea(player, step.area)) then
            return step
        end
    end
    return nil
end

-- Guide dont le balisage est actif : celui du chapitre en cours, ou celui de la base à l'acte III.
local function activeLampGuide(state)
    local chapter = Story.get(state.chapter)
    if chapter and chapter.guide then
        return chapter.guide
    end
    -- Après la prise du dossier (acte III), le balisage de la base reste allumé pour la sortie.
    if state.act == Const.ACT.EXFILTRATION then
        return Story.get(Story.EXIT_CHAPTER).guide
    end
    return nil
end

-- Gyrophares : réglages des lampes pendant l'alarme de la base (Story « baseAlarm.lamps »), ou nil.
local function alarmLampsFor(state)
    local chapter = Story.get(Story.EXIT_CHAPTER)
    local alarms = type(state.flags) == "table" and state.flags.alarms
    local entry = type(alarms) == "table" and alarms[Story.EXIT_CHAPTER]
    if chapter and chapter.baseAlarm and type(entry) == "table" and entry.status == Ambience.ALARM_ON then
        return chapter.baseAlarm.lamps
    end
    return nil
end

-- Réglages des gyrophares en cours (relus chaque seconde), ou nil.
local alarmLamps = nil

local function updateLamps(player)
    local state = ClientState.get()
    local guide = activeLampGuide(state)
    if guide and isInArea(player, guide.area) then
        lamps:maintain(guide.lamps)
        litGuide = guide
        alarmLamps = alarmLampsFor(state)
        lamps:setColor(alarmLamps and alarmLamps.color or nil, guide.lamps)
    elseif guide == nil and lamps:hasLamps() then
        lamps:clear()
        litGuide = nil
        alarmLamps = nil
    end
end

local function onTick()
    local now = getTimestampMs()
    local player = getPlayer()
    if not player or player:isDead() then return end
    -- Clignotement à chaque tick (quelques lampes, setActive seulement quand l'état change) : lent et
    -- rouge vif pendant l'alarme de la base (gyrophares), sinon le motif du guide.
    local pattern = alarmLamps and alarmLamps.blink or (litGuide and litGuide.lampBlink)
    if litGuide and pattern then
        lamps:blink(litGuide.lamps, pattern, now, math.floor(player:getZ()))
    end
    if now - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = now
    if not Config.isEnabled() then return end
    updateLamps(player)
    local step = Guide.currentStep(player)
    if step and not announcedSteps[step.key] then
        announcedSteps[step.key] = true
        -- Étape « silencieuse » : la pensée d'arrivée sur le lieu la couvre déjà.
        if step.silent then return end
        StagingFX.play({ { at = 0, cue = "thought", key = step.key .. THOUGHT_SUFFIX, always = true } }, player)
    end
end

Events.OnTick.Add(onTick)

return Guide
