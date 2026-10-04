-- Opération Artemis : éclairages posés dans les lieux (appliques de secours sur batterie, projecteurs
-- des postes gardés du fleuve), côté client.
-- Le serveur pose l'applique (décor) et enregistre sa lampe dans state.flags.wallLights (Artemis_Placement).
-- Ici, pour chaque applique encore présente sur sa case chargée, on entretient une lampe du client
-- (Artemis_Lamps) qui clignote selon son motif. Si l'applique a été retirée, la lampe s'éteint :
-- la lumière vient bien de l'objet. Indépendant du chapitre en cours.

local Config = require "Artemis/Artemis_Config"
local StateWatcher = require "Artemis/Artemis_StateWatcher"
local Lamps = require "Artemis/Artemis_Lamps"

local CHECK_INTERVAL_MS = 1000

-- Une lampe par applique : { [groupe] = Lamps }.
local lampSets = {}
local lastCheckMs = 0
-- Appliques enregistrées, relues à chaque changement de l'état (pas à chaque tick : une lecture de
-- l'état en fait une copie complète).
local cachedLights = {}

local function wallLights()
    return cachedLights
end

StateWatcher.subscribe(function(state)
    local entries = type(state.flags) == "table" and state.flags.wallLights
    cachedLights = type(entries) == "table" and entries or {}
end)

-- L'applique est-elle toujours sur sa case ? nil si la case n'est pas chargée.
local function hasFixture(lamp)
    local square = getCell():getGridSquare(lamp.x, lamp.y, lamp.z)
    if square == nil then
        return nil
    end
    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local sprite = objects:get(index):getSprite()
        if sprite and sprite:getName() == lamp.sprite then
            return true
        end
    end
    return false
end

-- Projecteur d'un poste gardé (route A) : allumé seulement tant que son groupe électrogène tourne
-- (état du groupe synchronisé par le serveur).
local function isGeneratorOn(position)
    local square = getCell():getGridSquare(position.x, position.y, position.z)
    local generator = square and square:getGenerator()
    return generator ~= nil and generator:isActivated()
end

local function maintain()
    -- Applique qui n'est plus enregistrée (réinitialisation de debug) : sa lampe s'éteint. Retrait
    -- après le parcours (ne pas modifier une table Kahlua pendant pairs).
    local stale = {}
    for group in pairs(lampSets) do
        if wallLights()[group] == nil then
            stale[#stale + 1] = group
        end
    end
    for _, group in ipairs(stale) do
        lampSets[group]:clear()
        lampSets[group] = nil
    end
    for group, lamp in pairs(wallLights()) do
        local lampSet = lampSets[group] or Lamps.new({ color = lamp.color, radius = lamp.radius })
        lampSets[group] = lampSet
        local fixture = hasFixture(lamp)
        if fixture and lamp.generator and not isGeneratorOn(lamp.generator) then
            fixture = false
        end
        if fixture then
            lampSet:maintain({ lamp })
        elseif fixture == false and lampSet:hasLamps() then
            lampSet:clear()
        end
    end
end

local function onTick()
    local player = getPlayer()
    if not player then return end
    local now = getTimestampMs()
    local floorZ = math.floor(player:getZ())
    local lights = wallLights()
    for group, lampSet in pairs(lampSets) do
        local lamp = lights[group]
        if lamp then
            lampSet:blink({ lamp }, lamp.blink, now, floorZ)
        end
    end
    if now - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = now
    if Config.isEnabled() then
        maintain()
    end
end

Events.OnTick.Add(onTick)
