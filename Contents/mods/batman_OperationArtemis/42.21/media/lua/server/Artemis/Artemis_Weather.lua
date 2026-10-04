-- Opération Artemis : brouillard imposé par une scène. Serveur ou solo.
-- Calque « modded » du brouillard (ClimateManager, .claude/pz-knowledge/staging-effects.md) :
-- - interpolation à 1 : le moteur recalcule la valeur naturelle à chaque minute de jeu puis la
--   rapproche de la nôtre ; avec une interpolation faible, le brouillard « pulse ». Le rendu reste
--   lissé par IsoWeatherFX, qui applique aussi le plafond de l'option MaxFogIntensity du joueur ;
-- - côté serveur : en multijoueur, le client applique la valeur envoyée par le serveur et écrase un
--   calque posé chez lui. updateEveryTenMins force l'envoi immédiat. Le brouillard est global ;
-- - non sauvegardé : au rechargement, le brouillard et sa minuterie disparaissent ensemble ;
-- - Siege Night utilise le même calque : à la fin, on ne coupe que si la valeur est encore la nôtre.

local Const = require "Artemis/Artemis_Const"

local Weather = {}

local FULL_INTERPOLATION = 1
-- Écart toléré en comparant la valeur du calque à la nôtre (flottants).
local SAME_VALUE_EPSILON = 0.001

-- Brouillard en cours : { strength, untilMinutes } (minutes de jeu depuis le début du monde), ou nil.
local active = nil

local function fogFloat()
    return getClimateManager():getClimateFloat(ClimateManager.FLOAT_FOG_INTENSITY)
end

local function worldMinutes()
    return math.floor(getGameTime():getWorldAgeHours() * 60)
end

local function pushToClients()
    if isServer() then
        getClimateManager():updateEveryTenMins()
    end
end

-- Impose un brouillard de force strength (0 à 1) pendant minutes minutes de jeu.
function Weather.startFog(strength, minutes)
    local fog = fogFloat()
    fog:setEnableModded(true)
    fog:setModdedValue(strength)
    fog:setModdedInterpolate(FULL_INTERPOLATION)
    active = { strength = strength, untilMinutes = worldMinutes() + minutes }
    pushToClients()
    Const.log("brouillard impose : " .. tostring(strength) .. " pendant " .. tostring(minutes) .. " min")
end

local function stopFog()
    local fog = fogFloat()
    if math.abs(fog:getModdedValue() - active.strength) < SAME_VALUE_EPSILON then
        fog:setEnableModded(false)
        pushToClients()
        Const.log("brouillard leve")
    else
        Const.log("brouillard : calque repris par un autre mod, laisse en place")
    end
    active = nil
end

local function onEveryOneMinute()
    if active and worldMinutes() >= active.untilMinutes then
        stopFog()
    end
end

if not isClient() then
    Events.EveryOneMinute.Add(onEveryOneMinute)
end

return Weather
