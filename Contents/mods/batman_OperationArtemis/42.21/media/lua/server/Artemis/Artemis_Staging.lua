-- Opération Artemis : partie serveur des scènes (panique, bruit, brouillard, zombies). Serveur ou solo.
-- Les sprinteurs ne sont pas persistants : au rechargement de la zone, le moteur leur rend la
-- vitesse de la partie (IsoZombie.load -> DoZombieStats). Ils servent aux scènes courtes.

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Scenes = require "Artemis/Artemis_Scenes"
local Timeline = require "Artemis/Artemis_Timeline"
local Weather = require "Artemis/Artemis_Weather"

local Staging = {}

local SPAWN_ATTEMPTS = 12
local GROUND_LEVEL = 0
local NORMAL_HEALTH = 1.0
local FEMALE_CHANCE = 0

-- Le joueur ciblé est-il encore là ? (mort ou déconnecté pendant la scène)
local function isPresent(player)
    return player ~= nil and not player:isDead() and player:isExistInTheWorld()
end

-- Case d'apparition acceptable : chargée, dehors, libre, hors de l'eau.
local function isSpawnable(square)
    return square ~= nil and square:isOutside() and square:isFree(false) and not square:isWaterSquare()
end

-- Fait apparaître un zombie au sol, à la distance voulue du joueur ; nil si aucune case ne convient.
local function spawnAround(player, distance, outfit)
    for _ = 1, SPAWN_ATTEMPTS do
        local angle = ZombRandFloat(0, 2 * math.pi)
        local x = math.floor(player:getX() + math.cos(angle) * distance)
        local y = math.floor(player:getY() + math.sin(angle) * distance)
        if isSpawnable(getCell():getGridSquare(x, y, GROUND_LEVEL)) then
            local zombies = addZombiesInOutfit(x, y, GROUND_LEVEL, 1, outfit, FEMALE_CHANCE,
                false, false, false, false, false, false, NORMAL_HEALTH)
            if zombies and zombies:size() > 0 then
                return zombies:get(0)
            end
        end
    end
    return nil
end

-- Portée du bruit du cri selon l'intensité dramatique (1 faible, 2 normale, 3 forte), et plafond.
local NOISE_SCALE_BY_INTENSITY = { 0.5, 1.0, 1.5 }
local MAX_NOISE_RANGE = 120
-- Volume du bruit (échelle vanilla : 100 * volume de l'appareil, DeviceData.java:835).
local NOISE_VOLUME = 100

local HANDLERS = {
    -- Panique (0-100), jamais baissée par une scène ; le battement de cœur vanilla la suit.
    -- Côté serveur : en multijoueur, il fait autorité et synchronise les stats vers le client.
    panic = function(cue, player)
        local stats = player:getStats()
        stats:set(CharacterStat.PANIC, math.max(stats:get(CharacterStat.PANIC), cue.value))
    end,

    -- Bruit réel dans le monde (attire les zombies ordinaires, comme tout bruit vanilla) : ici le cri
    -- sorti du haut-parleur. Portée = portée du haut-parleur de la radio x cue.factor x intensité.
    -- Avec des écouteurs (portée 0), aucun bruit.
    noise = function(cue, player, params)
        local scale = NOISE_SCALE_BY_INTENSITY[Config.dramaIntensity()] or 1
        local range = math.min(MAX_NOISE_RANGE, math.floor((params.speakerRange or 0) * cue.factor * scale))
        if range <= 0 then
            Const.log("scene : cri sans bruit dans le monde (ecouteurs ou volume nul)")
            return
        end
        getWorldSoundManager():addSound(player, math.floor(player:getX()), math.floor(player:getY()),
            math.floor(player:getZ()), range, NOISE_VOLUME)
        Const.log("scene : cri entendu dans un rayon de " .. tostring(range) .. " cases")
    end,

    -- Brouillard imposé (Artemis_Weather) : force cue.strength, durée selon l'intensité dramatique.
    -- Global : en multijoueur, tous les joueurs le voient.
    fog = function(cue)
        local minutes = cue.minutesByIntensity[Config.dramaIntensity()] or cue.minutesByIntensity[1]
        Weather.startFog(cue.strength, minutes)
    end,

    -- Sprinteurs individuels (IsoZombie.doSprinter, sans toucher ZombieLore), lancés directement
    -- vers le joueur (pathToCharacter). Plus utilisé par les scènes actuelles (retour de l'utilisateur :
    -- un sprinteur surgi de nulle part n'a pas de cause dans le monde) ; gardé pour les épreuves.
    sprinters = function(cue, player)
        local count = cue.countByIntensity[Config.dramaIntensity()] or 0
        local spawned = 0
        for _ = 1, count do
            local zombie = spawnAround(player, cue.distance, cue.outfit)
            if zombie then
                zombie:doSprinter()
                zombie:pathToCharacter(player)
                spawned = spawned + 1
            end
        end
        Const.log("scene : " .. tostring(spawned) .. " sprinteur(s) sur " .. tostring(count))
    end,
}

-- Chaque repère serveur vise le joueur déclencheur, s'il est toujours présent.
-- Contexte de la minuterie : { player = joueur, params = paramètres de la scène }.
local function guarded(handler)
    return function(cue, context)
        if isPresent(context.player) then
            handler(cue, context.player, context.params)
        end
    end
end

local guardedHandlers = {}
for name, handler in pairs(HANDLERS) do
    guardedHandlers[name] = guarded(handler)
end

local timeline = Timeline.new(guardedHandlers)

-- Joue la partie serveur de la scène donnée (identifiant, voir Artemis_Scenes), s'il y en a une.
function Staging.play(sceneId, player, params)
    local scene = Scenes.get(sceneId)
    if scene and scene.server and player then
        timeline:play(scene.server, { player = player, params = params or {} })
    end
end

local function onTick()
    timeline:update()
end

-- Ce fichier est aussi chargé sur un client multijoueur (dossier server/) : la minuterie n'y sert pas.
if not isClient() then
    Events.OnTick.Add(onTick)
end

return Staging
