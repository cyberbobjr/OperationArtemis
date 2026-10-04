-- Opération Artemis : brume de l'aube en ressortant d'un lieu souterrain (données « mist » d'un
-- chapitre, Artemis_Story). Serveur ou solo.
-- Un joueur qui sort à l'air libre dans la zone de sortie, peu après avoir été sous terre dans le lieu,
-- pendant la fenêtre de l'aube : une brume légère tombe (Artemis_Weather), une fois par partie.
-- Actif après l'arrivée sur le lieu, même une fois le chapitre terminé (le retour vient après).
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Players = require "Artemis/Artemis_Players"
local Ambience = require "Artemis/Artemis_Ambience"
local Tracking = require "Artemis/Artemis_Tracking"
local Weather = require "Artemis/Artemis_Weather"

local REGISTRY = "mist"

-- Dernière minute de jeu où chaque joueur a été vu sous terre dans le lieu : { [chapitre] = { [nom] = minutes } }.
-- Mémoire de session : après un rechargement, il faut redescendre.
local lastUnderground = {}

local function worldMinutes()
    return math.floor(getGameTime():getWorldAgeHours() * 60)
end

local function rawEntry(data, name, key)
    local flags = type(data) == "table" and data.flags
    local entries = type(flags) == "table" and flags[name]
    return type(entries) == "table" and entries[key] == true
end

local function isDawn(mist)
    local dawn = getClimateManager():getSeason():getDawn()
    return Ambience.isInDawnWindow(getGameTime():getTimeOfDay(), dawn, mist.fromHours, mist.toHours)
end

-- Le joueur vient-il de sortir à l'air libre dans la zone de sortie ?
local function hasJustSurfaced(player, mist, seenUnderground, now)
    local square = player:getCurrentSquare()
    return seenUnderground ~= nil and now - seenUnderground <= mist.recentMinutes
        and math.floor(player:getZ()) == 0 and square ~= nil and square:isOutside()
        and Tracking.isInArea(mist.area, player:getX(), player:getY())
end

local function startMist(chapterId, mist, player)
    Store.save(State.withFlagEntry(Store.load(), REGISTRY, chapterId))
    local strength = mist.strengthByIntensity[Config.dramaIntensity()] or mist.strengthByIntensity[1]
    Weather.startFog(strength, mist.minutes)
    Const.log("brume " .. chapterId .. " : a l'aube, sortie de " .. tostring(player:getUsername()))
end

local function updateMist(chapterId, chapter, now)
    local mist = chapter.mist
    local seen = lastUnderground[chapterId] or {}
    lastUnderground[chapterId] = seen
    for _, player in ipairs(Players.list()) do
        local name = player:getUsername()
        if not player:isDead() and math.floor(player:getZ()) < 0
            and Tracking.isInArea(chapter.reveal.area, player:getX(), player:getY()) then
            seen[name] = now
        elseif hasJustSurfaced(player, mist, seen[name], now) then
            seen[name] = nil
            if isDawn(mist) then
                startMist(chapterId, mist, player)
                return
            end
        end
    end
end

local function onEveryOneMinute()
    if not Config.isEnabled() then return end
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" then return end
    local now = worldMinutes()
    for chapterId, chapter in pairs(Story.CHAPTERS) do
        if chapter.mist and rawEntry(data, "arrived", chapterId) and not rawEntry(data, REGISTRY, chapterId) then
            updateMist(chapterId, chapter, now)
        end
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)
