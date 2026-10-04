-- Opération Artemis : alarme de la base et évasion du labo (données « baseAlarm » et « escape » du
-- dernier chapitre, Artemis_Story ; décisions de la phase 3). Serveur ou solo.
-- - Portique : le dossier porte une puce ; un joueur qui le porte dans la base, hors des archives,
--   fait sonner l'alarme et commence l'évasion (Artemis_Trial). Elle dure jusqu'à ce qu'un porteur
--   du dossier sorte de la base (réussite) ou que plus personne n'y soit (abandon). Une évasion
--   réussie ne se rejoue pas.
-- - Capteurs : hors de la fenêtre de V (23 h 15 - 1 h 15), l'alarme sonne tant qu'un joueur est dans
--   la base, y compris s'il y est entré pendant la fenêtre ; quand la fenêtre s'ouvre, V la coupe.
-- - Tant que l'alarme sonne, des sirènes d'étage (bruit réémis toutes les 5 s) attirent la garnison.
-- Aucun événement ne signale qu'un joueur change de pièce : sondage limité à une fois par seconde
-- réelle (une minute de jeu peut durer jusqu'à 60 s réelles). L'état n'est enregistré qu'aux
-- changements (chaque enregistrement est retransmis en multijoueur). Sans joueur connecté (serveur
-- vide, reconnexion), rien n'est décidé : l'évasion n'est pas abandonnée pour autant.
-- Si le module cesse d'agir (mod désactivé, histoire finie ou redémarrée), l'évasion en cours est
-- abandonnée et l'alarme coupée, sinon sirène, objectif du journal et suspension de Siege Night
-- resteraient figés.
-- La sirène et les gyrophares sont joués par chaque client d'après l'état (Artemis_AlarmFX,
-- Artemis_Guide).
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local Players = require "Artemis/Artemis_Players"
local Progress = require "Artemis/Artemis_Progress"
local Ambience = require "Artemis/Artemis_Ambience"
local Trial = require "Artemis/Artemis_Trial"
local State = require "Artemis/Artemis_State"

local CHECK_INTERVAL_MS = 1000
local NOISE_INTERVAL_MS = 5000

-- Délai (minutes de jeu) après l'ouverture de la fenêtre pendant lequel la coupure est commentée.
local CUT_THOUGHT_GRACE_MINUTES = 10

local lastCheckMs = 0
local lastNoiseMs = 0

local function rawFlag(data, name, key)
    local flags = type(data) == "table" and data.flags
    local entries = type(flags) == "table" and flags[name]
    return type(entries) == "table" and entries[key] or nil
end

-- L'alarme ne concerne que l'enquête et sa suite, une fois la base révélée (pas une visite de la
-- base à l'acte I, qui n'aurait aucune cause dans l'histoire).
local function isActive(data, chapterId)
    return type(data.act) == "number" and data.act >= Const.ACT.INVESTIGATION and data.act < Const.ACT.DONE
        and type(data.revealed) == "table" and State.isRevealed(data, chapterId)
end

local function minuteOfDay()
    local time = getGameTime()
    return time:getHour() * 60 + time:getMinutes()
end

local function carries(player, itemType)
    return player:getInventory():containsTypeRecurse(itemType)
end

-- Marge (cases) autour de l'emprise de la base où l'on cherche un porteur sorti : au-delà, un joueur
-- ailleurs sur la carte n'a pas à voir son inventaire fouillé chaque seconde.
local ESCAPE_SEARCH_MARGIN = 20

local function isNearBase(x, y)
    local area = Story.BASE_AREA
    return x >= area.x1 - ESCAPE_SEARCH_MARGIN and x <= area.x2 + ESCAPE_SEARCH_MARGIN
        and y >= area.y1 - ESCAPE_SEARCH_MARGIN and y <= area.y2 + ESCAPE_SEARCH_MARGIN
end

-- Ce que font les joueurs, pour ce contrôle. L'inventaire n'est fouillé que si la réponse sert :
-- dans la base (sous-sol ou hall intérieur, pas la marge extérieure) hors des archives quand
-- l'évasion peut commencer, juste dehors quand elle est en cours.
local function observe(chapter, players, canStart, isTrialRunning)
    local alarm, escape = chapter.baseAlarm, chapter.escape
    local facts = { gateCrosser = nil, firstInside = nil, escapedCarrier = nil, isAnyoneInBase = false }
    for _, player in ipairs(players) do
        if not player:isDead() then
            local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
            local isInside = Ambience.isInsideBase(alarm.sensors.volumes, x, y, z, player:getCurrentRoomDef() ~= nil)
            if isInside then
                facts.firstInside = facts.firstInside or player
            end
            if Trial.isInBase(escape, Story.BASE_AREA, x, y, z) then
                facts.isAnyoneInBase = true
                if canStart and isInside and facts.gateCrosser == nil
                    and not Ambience.isInRoom(alarm.gate.room, x, y, z) and carries(player, alarm.gate.item) then
                    facts.gateCrosser = player
                end
            elseif isTrialRunning and facts.escapedCarrier == nil and isNearBase(x, y)
                and Trial.isEscaped(escape, x, y, z) and carries(player, alarm.gate.item) then
                facts.escapedCarrier = player
            end
        end
    end
    return facts
end

-- Sirènes d'étage : un bruit près de chaque groupe de la garnison (Story « escape.horns »).
local function emitHorns(escape)
    for _, horn in ipairs(escape.horns) do
        getWorldSoundManager():addSound(nil, horn.x, horn.y, horn.z, escape.hornRadius, escape.hornVolume)
    end
end

-- Portique franchi, réussite ou abandon de l'évasion. Renvoie true si l'état a changé.
local function updateTrial(chapterId, chapter, data, facts)
    if facts.gateCrosser then
        Progress.onTrialStart(facts.gateCrosser, chapterId, chapter.baseAlarm.scenes.gate)
        return true
    end
    local step = Trial.step(rawFlag(data, "trials", chapterId),
        { isCarrierEscaped = facts.escapedCarrier ~= nil, isAnyoneInBase = facts.isAnyoneInBase })
    if step == "success" then
        Progress.onTrialEnd(facts.escapedCarrier, chapterId, "success")
        return true
    elseif step == "abandon" then
        Progress.onTrialEnd(nil, chapterId, "abandon")
        return true
    end
    return false
end

-- Alarme de la base : suit la cause voulue (évasion en cours, sinon capteurs tant qu'un joueur est
-- dans la base hors de la fenêtre). L'entrée est réécrite dès qu'elle diffère de la cause voulue.
-- Coupure par V quand la fenêtre s'ouvre (pensée, seulement à l'ouverture), ou plus personne dedans.
local function updateSensors(chapterId, chapter, data, facts)
    local alarm = chapter.baseAlarm
    local minute = minuteOfDay()
    local isWindowOpen = Ambience.isInSensorWindow(minute, alarm.sensors.window)
    local insideOutOfWindow = not isWindowOpen and facts.firstInside or nil
    local wanted = Ambience.baseAlarmCause(Trial.isRunning(data.flags, chapterId), insideOutOfWindow ~= nil)
    local entry = rawFlag(data, "alarms", chapterId)
    local current = type(entry) == "table" and entry.status == Ambience.ALARM_ON and entry.cause or nil
    if wanted == current then
        return wanted ~= nil
    end
    if wanted == Ambience.CAUSE_SENSORS then
        local name = insideOutOfWindow:getUsername()
        Progress.setBaseAlarm(chapterId, { status = Ambience.ALARM_ON, cause = Ambience.CAUSE_SENSORS, by = name },
            insideOutOfWindow, alarm.scenes.sensors)
        Const.log("alerte " .. chapterId .. " : capteurs actifs, " .. tostring(name) .. " est dans la base")
    elseif wanted == Ambience.CAUSE_GATE then
        -- Évasion en cours sans alarme enregistrée (état ancien ou incohérent) : l'alarme la suit.
        local trial = rawFlag(data, "trials", chapterId)
        Progress.setBaseAlarm(chapterId, { status = Ambience.ALARM_ON, cause = Ambience.CAUSE_GATE,
            by = type(trial) == "table" and trial.by or nil }, nil, nil)
        Const.log("alerte " .. chapterId .. " : alarme du portique retablie (evasion en cours)")
    else
        local isJustOpened = Ambience.isWindowJustOpened(minute, alarm.sensors.window, CUT_THOUGHT_GRACE_MINUTES)
        local cutBy = isWindowOpen and facts.firstInside or nil
        local sceneId = cutBy and isJustOpened and alarm.scenes.cut or nil
        Progress.setBaseAlarm(chapterId, { status = Ambience.ALARM_OFF }, cutBy, sceneId)
        local reason = cutBy and "fenetre de V, capteurs coupes" or "plus personne dans la base"
        Const.log("alerte " .. chapterId .. " : arretee (" .. reason .. ")")
    end
    return wanted ~= nil
end

-- Le module cesse d'agir : évasion abandonnée (l'abandon coupe aussi l'alarme), ou alarme coupée.
local function shutDown(chapterId, data, reason)
    if Trial.isRunning(data.flags, chapterId) then
        Progress.onTrialEnd(nil, chapterId, "abandon")
        Const.log("evasion " .. chapterId .. " : interrompue (" .. reason .. ")")
        return
    end
    local entry = rawFlag(data, "alarms", chapterId)
    if type(entry) == "table" and entry.status == Ambience.ALARM_ON then
        Progress.setBaseAlarm(chapterId, { status = Ambience.ALARM_OFF }, nil, nil)
        Const.log("alerte " .. chapterId .. " : arretee (" .. reason .. ")")
    end
end

local function onTick()
    local now = getTimestampMs()
    if now - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = now
    local chapterId = Story.EXIT_CHAPTER
    local chapter = Story.get(chapterId)
    local data = ModData.get(Const.MODDATA_KEY)
    if chapter == nil or chapter.baseAlarm == nil or type(data) ~= "table" then return end
    if not Config.isEnabled() then
        shutDown(chapterId, data, "mod desactive")
        return
    end
    if not isActive(data, chapterId) then
        shutDown(chapterId, data, "histoire hors de l'enquete")
        return
    end
    local players = Players.list()
    if #players == 0 then return end
    local facts = observe(chapter, players, Trial.canStart(data.flags, chapterId),
        Trial.isRunning(data.flags, chapterId))
    if updateTrial(chapterId, chapter, data, facts) then return end
    local isRinging = updateSensors(chapterId, chapter, data, facts)
    if isRinging and now - lastNoiseMs >= NOISE_INTERVAL_MS then
        lastNoiseMs = now
        emitHorns(chapter.escape)
    end
end

Events.OnTick.Add(onTick)
