-- Opération Artemis : alerte déclenchée par un groupe électrogène (données « alarm » d'un chapitre,
-- Artemis_Story). Serveur ou solo.
-- Le joueur qui démarre le groupe remet aussi l'alerte sous tension : une sirène hurle et attire le
-- secteur (vrai bruit). Une seule fois par partie ; elle s'arrête quand le groupe est coupé, après
-- un cycle de « minutes » minutes de jeu, ou si le lieu n'est plus chargé.
-- Aucun événement vanilla ne signale le démarrage d'un groupe (setActivated, IsoGenerator.java:462) :
-- chaque minute, on lit son état sur UNE case, seulement si elle est chargée. Actif même après la
-- fin du chapitre (le badge peut être pris avant que le groupe soit démarré).
-- La sirène elle-même est jouée par chaque client (Artemis_AlarmFX) d'après l'état enregistré.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Players = require "Artemis/Artemis_Players"
local Progress = require "Artemis/Artemis_Progress"
local Ambience = require "Artemis/Artemis_Ambience"

local REGISTRY = "alarms"
-- Distance (cases) au groupe du joueur à qui l'on attribue le démarrage (pensée).
local STARTER_RADIUS = 30

local function worldMinutes()
    return math.floor(getGameTime():getWorldAgeHours() * 60)
end

-- Registres lus directement dans la ModData (sans copie) : appel chaque minute.
local function rawFlag(data, name, key)
    local flags = type(data) == "table" and data.flags
    local entries = type(flags) == "table" and flags[name]
    return type(entries) == "table" and entries[key] or nil
end

-- État du groupe : true (tourne), false (arrêté), nil (case non chargée ou groupe disparu).
local function generatorState(position)
    local square = getCell():getGridSquare(position.x, position.y, position.z)
    if square == nil then
        return nil
    end
    local generator = square:getGenerator()
    return generator ~= nil and generator:isActivated()
end

local function nearestPlayer(position)
    for _, player in ipairs(Players.list()) do
        if Players.isNear(player, position, STARTER_RADIUS) then
            return player
        end
    end
    return nil
end

local function emitNoise(alarm)
    local radius = Ambience.noiseRadius(alarm, Config.dramaIntensity())
    -- Émis en surface, à la cabane : sous terre, l'étage compte triple dans la distance
    -- (WorldSoundManager.java:230) et la sirène n'attirerait presque rien.
    getWorldSoundManager():addSound(nil, alarm.horn.x, alarm.horn.y, alarm.horn.z, radius, alarm.noiseVolume)
    return radius
end

local function startAlarm(chapterId, alarm, position, now)
    local state = Store.load()
    local entry = { status = Ambience.ALARM_ON, startMinutes = now }
    local nextState = State.withFlagValue(state, REGISTRY, chapterId, entry)
    local starter = nearestPlayer(position)
    Progress.commit(state, nextState, starter, starter and alarm.scene or nil)
    Const.log("alerte " .. chapterId .. " : sirene declenchee (rayon " .. tostring(emitNoise(alarm)) .. ")")
end

local function stopAlarm(chapterId, reason)
    local state = Store.load()
    local entry = State.flagValue(state, REGISTRY, chapterId)
    local stopped = { status = Ambience.ALARM_DONE, startMinutes = entry and entry.startMinutes or 0 }
    Store.save(State.withFlagValue(state, REGISTRY, chapterId, stopped))
    Const.log("alerte " .. chapterId .. " : sirene arretee (" .. reason .. ")")
end

local function updateAlarm(chapterId, alarm, data)
    local position = rawFlag(data, "generators", alarm.group)
    local entry = rawFlag(data, REGISTRY, chapterId)
    if position == nil or (entry and entry.status == Ambience.ALARM_DONE) then return end
    -- Après un redémarrage de l'opération, le groupe (gardé dans le monde) peut tourner encore : pas
    -- d'alerte tant que le lieu n'est pas de nouveau révélé.
    if entry == nil and (type(data.revealed) ~= "table" or not State.isRevealed(data, chapterId)) then return end
    local isOn = generatorState(position)
    if isOn == nil then
        if entry then stopAlarm(chapterId, "zone dechargee") end
        return
    end
    local now = worldMinutes()
    local step = Ambience.alarmStep(entry, isOn, now, alarm.minutes)
    if step == "start" then
        startAlarm(chapterId, alarm, position, now)
    elseif step == "noise" then
        emitNoise(alarm)
    elseif step == "stop" then
        stopAlarm(chapterId, isOn and "fin du cycle" or "groupe arrete")
    end
end

local function onEveryOneMinute()
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" then return end
    local isEnabled = Config.isEnabled()
    for chapterId, chapter in pairs(Story.CHAPTERS) do
        if chapter.alarm and isEnabled then
            updateAlarm(chapterId, chapter.alarm, data)
        elseif chapter.alarm then
            -- Mod désactivé en cours de partie : une sirène en marche ne doit pas tourner sans fin.
            local entry = rawFlag(data, REGISTRY, chapterId)
            if entry and entry.status == Ambience.ALARM_ON then
                stopAlarm(chapterId, "mod desactive")
            end
        end
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)
