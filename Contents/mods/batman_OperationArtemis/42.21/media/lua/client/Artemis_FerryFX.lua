-- Opération Artemis : moteur du passeur de V (route A sans mod de bateau), côté client.
-- Le serveur décide (Artemis_FerryDirector, Artemis_Rendezvous) et enregistre la phase du passeur
-- (state.flags.extraction.ferry). Chaque client joue le moteur en boucle sur un émetteur libre, en
-- local (comme le rotor de l'hélicoptère, Artemis_Heli) : pendant l'approche, le bateau remonte du
-- large vers le quai au rythme de la tenue ; posé, le moteur tourne au ralenti au bout du ponton.
-- Son : boucle tirée d'un enregistrement Work With Sounds (CC BY 4.0, assets/ferry/CREDITS.md).

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local State = require "Artemis/Artemis_State"
local Extraction = require "Artemis/Artemis_Extraction"
local StateWatcher = require "Artemis/Artemis_StateWatcher"

local SOUND = "ArtemisFerryEngine"
-- Départ de l'approche, sur l'eau, au large du quai (cases).
local APPROACH_DX = 120
local APPROACH_DY = -160

local phase = nil
local emitter, soundId = nil, nil
local isTicking = false

local function minuteOfDay()
    local time = getGameTime()
    return time:getHour() * 60 + time:getMinutes()
end

local function holdFraction()
    local ferry = Story.FERRY
    return Extraction.holdFraction(minuteOfDay(), {
        slotHour = ferry.slotHour,
        holdMinutes = Config.extractionHoldMinutes(),
        landedMinutes = ferry.landedMinutes,
    })
end

-- Position du bateau : il approche en ligne droite pendant la tenue, puis reste au quai.
local function boatPosition()
    local boat = Story.FERRY.boat
    if phase ~= Extraction.INBOUND then
        return boat.x + 0.5, boat.y + 0.5
    end
    local remaining = 1 - holdFraction()
    return boat.x + 0.5 + APPROACH_DX * remaining, boat.y + 0.5 + APPROACH_DY * remaining
end

local function stopSound()
    if emitter and soundId and soundId ~= 0 then
        emitter:stopSoundLocal(soundId)
    end
    emitter, soundId = nil, nil
end

local function onTick()
    local x, y = boatPosition()
    if not emitter then
        emitter = getWorld():getFreeEmitter(x, y, 0)
    end
    emitter:setPos(x, y, 0)
    if not soundId or soundId == 0 or not emitter:isPlaying(soundId) then
        soundId = emitter:playSoundLoopedImpl(SOUND)
    end
end

local function onState(state, _isFirst)
    local entry = State.flagValue(state, "extraction", Story.FERRY.key)
    local isActive = state.act == Const.ACT.EXFILTRATION and Extraction.isCalled(entry)
        and (entry.phase == Extraction.INBOUND or entry.phase == Extraction.LANDED)
    phase = isActive and entry.phase or nil
    if isActive and not isTicking then
        isTicking = true
        Events.OnTick.Add(onTick)
    elseif not isActive and isTicking then
        isTicking = false
        Events.OnTick.Remove(onTick)
        stopSound()
    end
end

StateWatcher.subscribe(onState)
