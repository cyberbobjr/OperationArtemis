-- Opération Artemis : sirènes des alertes, côté client.
-- Le serveur décide (Artemis_Alarm, Artemis_BaseAlarm) et enregistre l'état de chaque alerte
-- (state.flags.alarms[chapitre]). Chaque client joue la sirène en boucle tant que l'alerte est active :
-- - alerte d'un lieu (« alarm », bunker) : à la case de la sirène, atténuée par la distance ;
-- - alarme de la base (« baseAlarm ») : à la position du joueur local tant qu'il est dans la
--   base (sous-sol ou bâtiment de surface), comme des haut-parleurs partout. Un émetteur posé à
--   un autre étage serait étouffé (ParameterOcclusion.java:39-53).

local Const = require "Artemis/Artemis_Const"
local Story = require "Artemis/Artemis_Story"
local StateWatcher = require "Artemis/Artemis_StateWatcher"
local Ambience = require "Artemis/Artemis_Ambience"
local Trial = require "Artemis/Artemis_Trial"

-- Sirènes en cours : { [chapitre] = { emitter, soundId } }.
local playing = {}
-- Alarmes de base actives d'après l'état : { [chapitre] = true } (relu à chaque changement d'état).
local baseAlarmsOn = {}

local function isAlarmOn(state, chapterId)
    local alarms = type(state.flags) == "table" and state.flags.alarms
    local entry = type(alarms) == "table" and alarms[chapterId]
    return type(entry) == "table" and entry.status == Ambience.ALARM_ON
end

-- Son en boucle : playSoundLoopedImpl, arrêté par stopSound (BaseSoundEmitter.java:19, 71), comme la
-- sirène vanilla (SirenSound.java:23-33). Un émetteur qui joue n'est pas recyclé (IsoWorld.java:2791).
local function startSiren(chapterId, sound, x, y, z)
    local emitter = getWorld():getFreeEmitter(x, y, z)
    playing[chapterId] = { emitter = emitter, soundId = emitter:playSoundLoopedImpl(sound) }
    Const.log("sirene " .. chapterId .. " : son lance")
end

local function stopSiren(chapterId)
    local siren = playing[chapterId]
    siren.emitter:stopSound(siren.soundId)
    playing[chapterId] = nil
    Const.log("sirene " .. chapterId .. " : son arrete")
end

local function onState(state)
    for chapterId, chapter in pairs(Story.CHAPTERS) do
        local isOn = isAlarmOn(state, chapterId)
        if chapter.alarm then
            if isOn and playing[chapterId] == nil then
                local horn = chapter.alarm.horn
                startSiren(chapterId, chapter.alarm.sound, horn.x + 0.5, horn.y + 0.5, horn.z)
            elseif not isOn and playing[chapterId] then
                stopSiren(chapterId)
            end
        elseif chapter.baseAlarm then
            baseAlarmsOn[chapterId] = isOn or nil
        end
    end
end

-- Même règle que l'évasion (Artemis_Trial) : sous terre dans l'emprise, ou dans le bâtiment de
-- surface. Un joueur en forêt dans l'emprise n'entend pas les haut-parleurs.
local function isInBase(player, chapter)
    local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
    return Trial.isInBase(chapter.escape, Story.BASE_AREA, x, y, z)
end

-- Alarme de la base : la sirène suit le joueur local tant qu'il est dans la base.
local function onTick()
    local player = getPlayer()
    for chapterId, chapter in pairs(Story.CHAPTERS) do
        if chapter.baseAlarm then
            local shouldPlay = baseAlarmsOn[chapterId] and player ~= nil and not player:isDead()
                and isInBase(player, chapter)
            local siren = playing[chapterId]
            if shouldPlay and siren == nil then
                startSiren(chapterId, chapter.baseAlarm.sound, player:getX(), player:getY(), player:getZ())
            elseif shouldPlay then
                siren.emitter:setPos(player:getX(), player:getY(), player:getZ())
            elseif siren then
                stopSiren(chapterId)
            end
        end
    end
end

StateWatcher.subscribe(onState)
Events.OnTick.Add(onTick)
