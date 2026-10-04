-- Opération Artemis : hélicoptère d'extraction vu et entendu par le client (route B).
-- Suit la phase enregistrée par le serveur (Artemis_ExtractionDirector) ; tout est local, sans paquet.
-- Méthode reprise de Military Drop (même auteur, validée en jeu, staging-effects.md) :
-- - son vanilla « Helicopter » en boucle sur un émetteur libre placé SOUND_Z niveaux plus haut (aucune
--   case n'y existe : jamais étouffé par les murs), déplacé à chaque image ;
-- - ombre au sol « circle_shadow » (WorldMarkers) qui pulse comme un rotor ; posé, elle est fixe et
--   plus large ;
-- - flèche de direction vers l'hélicoptère pour chaque joueur local assez proche, hors de vue.
-- À l'atterrissage, le pilote lance une fusée verte au-dessus de la zone (WorldFlares, locale, non
-- sauvegardée : relancée au chargement si l'hélicoptère est posé). On ne s'abonne à OnTick que
-- pendant un passage (approche, posé, départ).

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local State = require "Artemis/Artemis_State"
local Extraction = require "Artemis/Artemis_Extraction"
local Flight = require "Artemis/Artemis_Flight"
local StateWatcher = require "Artemis/Artemis_StateWatcher"

local SOUND = "Helicopter"
local SOUND_Z = 20
local SHADOW_TEXTURE = "circle_shadow"
local SHADOW_FADE_SPEED = 0.08
local FLYING_SHADOW = { size = 3, alphaMin = 0.35, alphaMax = 0.8 }
local LANDED_SHADOW = { size = 6, alphaMin = 0.7, alphaMax = 0.7 }
local ARROW_TEXTURE = "dir_arrow_up"
local ARROW_RANGE = 600
local ARROW_HIDE_DISTANCE = 25
local ARROW_COLOR = { r = 0.45, g = 0.85, b = 0.45, a = 0.9 }
-- Au-delà, le client ne joue rien : le son vanilla porte à 1000 cases, l'hélicoptère tourne à 300.
local ACTIVE_RANGE = 1000
-- Fusée verte du pilote : durée en unités du multiplicateur (≈ 48 par seconde réelle), portée en cases.
local FLARE_DURATION = 3600
local FLARE_RANGE = 50
-- Cap du départ (radians) : vers le nord-ouest, loin de la zone d'exclusion.
local LEAVE_HEADING = -3 * math.pi / 4

-- Passage en cours : nil, ou { mode = "inbound" | "landed" | "leave", leaveStartMs }.
local pass = nil
local emitter, soundId, shadow, shadowStyle = nil, nil, nil, nil
local arrows = {}
local isTicking = false

local function minuteOfDay()
    local time = getGameTime()
    return time:getHour() * 60 + time:getMinutes()
end

local function holdFraction()
    local extraction = Story.EXTRACTION
    return Extraction.holdFraction(minuteOfDay(), {
        slotHour = extraction.slotHour,
        holdMinutes = Config.extractionHoldMinutes(),
        landedMinutes = extraction.landedMinutes,
    })
end

local function updateSound(x, y)
    if not emitter then
        emitter = getWorld():getFreeEmitter(x, y, SOUND_Z)
    end
    emitter:setPos(x, y, SOUND_Z)
    if not soundId or soundId == 0 or not emitter:isPlaying(soundId) then
        soundId = emitter:playSoundLoopedImpl(SOUND)
    end
end

local function stopSound()
    if emitter and soundId and soundId ~= 0 then
        emitter:stopSoundLocal(soundId)
    end
    emitter, soundId = nil, nil
end

local function removeShadow()
    if shadow then
        getWorldMarkers():removeGridSquareMarker(shadow)
    end
    shadow, shadowStyle = nil, nil
end

local function updateShadow(x, y, style)
    local ix, iy = math.floor(x), math.floor(y)
    if shadow and shadowStyle == style then
        shadow:setPos(ix, iy, 0)
        return
    end
    removeShadow()
    -- Le marqueur se crée sur une case chargée ; ensuite setPos suffit.
    local square = getCell():getGridSquare(ix, iy, 0)
    if square then
        shadow = getWorldMarkers():addGridSquareMarker(SHADOW_TEXTURE, nil, square, 1, 1, 1, true,
            style.size, SHADOW_FADE_SPEED, style.alphaMin, style.alphaMax)
        shadowStyle = style
    end
end

local function removeArrow(playerNum)
    if arrows[playerNum] then
        getWorldMarkers():removeDirectionArrow(arrows[playerNum])
        arrows[playerNum] = nil
    end
end

local function updateArrows(x, y)
    local ix, iy = math.floor(x), math.floor(y)
    for playerNum = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(playerNum)
        local isWanted = false
        if player and not player:isDead() then
            local dx, dy = x - player:getX(), y - player:getY()
            local distance = math.sqrt(dx * dx + dy * dy)
            isWanted = distance <= ARROW_RANGE and distance > ARROW_HIDE_DISTANCE
        end
        local arrow = arrows[playerNum]
        if isWanted and not arrow then
            arrows[playerNum] = getWorldMarkers():addDirectionArrow(player, ix, iy, 0, ARROW_TEXTURE,
                ARROW_COLOR.r, ARROW_COLOR.g, ARROW_COLOR.b, ARROW_COLOR.a)
        elseif isWanted then
            arrow:setX(ix)
            arrow:setY(iy)
        elseif arrow then
            removeArrow(playerNum)
        end
    end
end

local function clearVisuals()
    stopSound()
    removeShadow()
    for playerNum = 0, 3 do
        removeArrow(playerNum)
    end
end

local function isLocalPlayerInRange(landing)
    local player = getPlayer()
    if not player then return false end
    local dx, dy = player:getX() - landing.x, player:getY() - landing.y
    return dx * dx + dy * dy <= ACTIVE_RANGE * ACTIVE_RANGE
end

-- Position de l'hélicoptère pour ce passage, ou nil s'il est parti.
local function currentPosition(landing, now)
    if pass.mode == "inbound" then
        return Flight.orbitPosition(landing, holdFraction(), now / 1000)
    end
    if pass.mode == "landed" then
        return landing.x, landing.y
    end
    local x, y, isGone = Flight.leavePosition(landing, LEAVE_HEADING, (now - pass.leaveStartMs) / 1000)
    if isGone then
        return nil
    end
    return x, y
end

local function onTick()
    local landing = Story.EXTRACTION.landing
    local now = getTimestampMs()
    local x, y = nil, nil
    if pass then
        x, y = currentPosition(landing, now)
    end
    if x == nil then
        pass = nil
    end
    if not pass or not isLocalPlayerInRange(landing) then
        clearVisuals()
        if not pass then
            Events.OnTick.Remove(onTick)
            isTicking = false
        end
        return
    end
    updateSound(x, y)
    updateShadow(x, y, pass.mode == "landed" and LANDED_SHADOW or FLYING_SHADOW)
    updateArrows(x, y)
end

local function startPass(mode)
    pass = { mode = mode, leaveStartMs = getTimestampMs() }
    if not isTicking then
        isTicking = true
        Events.OnTick.Add(onTick)
    end
end

local function launchFlare()
    local landing = Story.EXTRACTION.landing
    WorldFlares.launchFlare(FLARE_DURATION, landing.x, landing.y, FLARE_RANGE, 0, 0, 1, 0, 0, 1, 0)
end

local lastPhase = nil

-- Phase enregistrée par le serveur -> passage local. Un embarquement réussi (épilogue) ne fait pas
-- repartir l'hélicoptère à l'écran : l'écran de fin prend le relais.
local function onState(state, _isFirst)
    local entry = State.flagValue(state, "extraction", Extraction.KEY)
    local phase = state.act == Const.ACT.EXFILTRATION and Extraction.isCalled(entry) and entry.phase or nil
    if phase == lastPhase then return end
    local previous = lastPhase
    lastPhase = phase
    if phase == Extraction.INBOUND then
        startPass("inbound")
    elseif phase == Extraction.LANDED then
        startPass("landed")
        launchFlare()
    elseif previous == Extraction.LANDED and phase == Extraction.WAITING then
        startPass("leave")
    elseif pass and state.act == Const.ACT.EXFILTRATION then
        pass = nil
    elseif state.act ~= Const.ACT.EXFILTRATION then
        pass = nil
        clearVisuals()
    end
end

StateWatcher.subscribe(onState)
