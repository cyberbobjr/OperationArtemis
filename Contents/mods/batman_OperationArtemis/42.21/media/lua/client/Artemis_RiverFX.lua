-- Opération Artemis : sirène des postes gardés du fleuve (route A), côté client.
-- Le serveur décide (Artemis_RiverDirector) et enregistre la fin de la sirène
-- (state.flags.river[poste].alarmUntil, minutes de monde). Chaque client joue la sirène en boucle au
-- groupe électrogène du poste tant qu'elle n'est pas finie (même son et même mécanique que les
-- alertes des lieux, Artemis_AlarmFX).

local Const = require "Artemis/Artemis_Const"
local Story = require "Artemis/Artemis_Story"
local River = require "Artemis/Artemis_River"
local StateWatcher = require "Artemis/Artemis_StateWatcher"

local CHECK_INTERVAL_MS = 1000

-- Sirènes en cours : { [poste] = { emitter, soundId } }.
local playing = {}
local entries = {}
local lastCheckMs = 0

StateWatcher.subscribe(function(state)
    local river = type(state.flags) == "table" and state.flags[River.FLAG]
    entries = type(river) == "table" and river or {}
end)

local function update()
    local now = math.floor(getGameTime():getWorldAgeHours() * 60)
    for guardId, guard in pairs(Story.RIVER.guards) do
        local isOn = River.isAlarmOn(entries[guardId], now)
        local siren = playing[guardId]
        if isOn and siren == nil then
            local position = guard.generator
            local emitter = getWorld():getFreeEmitter(position.x + 0.5, position.y + 0.5, position.z)
            playing[guardId] = { emitter = emitter, soundId = emitter:playSoundLoopedImpl(Story.RIVER.alarmSound) }
            Const.log("sirene du poste " .. guardId .. " : son lance")
        elseif not isOn and siren then
            siren.emitter:stopSound(siren.soundId)
            playing[guardId] = nil
            Const.log("sirene du poste " .. guardId .. " : son arrete")
        end
    end
end

Events.OnTick.Add(function()
    local now = getTimestampMs()
    if now - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = now
    update()
end)
