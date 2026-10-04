-- Opération Artemis : vagues d'une épreuve à tenir (zone d'atterrissage, quai du passeur, enclos de
-- quarantaine, berges des ponts gardés), serveur ou solo.
-- Hybride (décisions de la phase 4) : un bruit réémis attire les zombies des environs (rayon ≥ 50 :
-- les zombies virtuels l'entendent aussi, staging-effects.md). Le mod n'en fait apparaître, hors de la
-- vue des joueurs sur un anneau autour du point tenu, que s'il y en a trop peu près de lui ; ils
-- marchent vers ce point. Une dernière vague de sprinteurs arrive dans le dernier quart de la tenue,
-- quel que soit le nombre de zombies présents. Plafond de zombies apparus par épreuve. Les restes
-- sont des zombies ordinaires : on ne les retire pas.
-- Une instance par épreuve (Waves.new) : chacune a ses compteurs, deux épreuves peuvent se suivre
-- ou se chevaucher sans se gêner.
-- Les sprinteurs ne restent pas sprinteurs s'ils sont virtualisés (joueur parti) : sans importance,
-- l'épreuve n'a alors plus lieu.
--
-- Configuration (cfg) : { ringMin, ringMax, countRadius, minZombiesByIntensity, batchByIntensity,
-- maxSpawnedByIntensity, sprintFromFraction, outfits, noiseRadius, noiseVolume, label } ;
-- center = { x, y, z }.

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Placement = require "Artemis/Artemis_Placement"

local Waves = {}
Waves.__index = Waves

local NOISE_INTERVAL_MS = 5000
local SPAWN_INTERVAL_MS = 20000
-- Distance minimale (cases) entre une apparition et chaque joueur : hors de la vue.
local MIN_PLAYER_DISTANCE = 30
local NORMAL_HEALTH = 1.0
local FEMALE_CHANCE = 0

-- Nouvelle épreuve. État non sauvegardé : au rechargement, les compteurs repartent, le plafond reste
-- une protection par session.
function Waves.new(cfg, center)
    local waves = setmetatable({ cfg = cfg, center = center }, Waves)
    waves:reset()
    return waves
end

-- Nouvelle tenue (créneau du lendemain, nouvelle quarantaine) : compteurs remis à zéro.
function Waves:reset()
    self.lastNoiseMs = 0
    self.lastSpawnMs = 0
    self.spawned = 0
    self.isFinalWaveDone = false
end

function Waves.countNear(center, radius)
    local zombies = getCell():getZombieList()
    local count = 0
    for index = 0, zombies:size() - 1 do
        local zombie = zombies:get(index)
        if not zombie:isDead() and math.abs(zombie:getX() - center.x) <= radius
            and math.abs(zombie:getY() - center.y) <= radius then
            count = count + 1
        end
    end
    return count
end

function Waves:spawn(count, isSprint)
    local cfg, center = self.cfg, self.center
    local spots = Placement.ringSpots({ x = center.x, y = center.y, z = center.z,
        ring = { minRadius = cfg.ringMin, maxRadius = cfg.ringMax, minPlayerDistance = MIN_PLAYER_DISTANCE } },
        count)
    local placed = 0
    for _, spot in ipairs(spots) do
        local square = spot.square
        local outfit = cfg.outfits[ZombRand(#cfg.outfits) + 1]
        local list = addZombiesInOutfit(square:getX(), square:getY(), square:getZ(), 1, outfit, FEMALE_CHANCE,
            false, false, false, false, false, false, NORMAL_HEALTH)
        local zombie = list ~= nil and list:size() > 0 and list:get(0) or nil
        if zombie then
            if isSprint then
                zombie:doSprinter()
            end
            zombie:pathToLocationF(center.x + 0.5, center.y + 0.5, center.z)
            placed = placed + 1
        end
    end
    self.spawned = self.spawned + placed
    Const.log((cfg.label or "epreuve") .. " : vague de " .. placed .. " zombie(s) sur " .. count
        .. (isSprint and " (sprinteurs)" or "") .. ", " .. self.spawned .. " depuis le debut")
end

-- Pendant la tenue, avec un joueur sur place : bruit et vagues.
-- fraction : part de la tenue écoulée (0 à 1).
function Waves:update(fraction, nowMs)
    local cfg, center = self.cfg, self.center
    if nowMs - self.lastNoiseMs >= NOISE_INTERVAL_MS then
        self.lastNoiseMs = nowMs
        getWorldSoundManager():addSound(nil, center.x, center.y, center.z, cfg.noiseRadius, cfg.noiseVolume)
    end
    local intensity = Config.dramaIntensity()
    local room = (cfg.maxSpawnedByIntensity[intensity] or 0) - self.spawned
    local batch = cfg.batchByIntensity[intensity] or 0
    if room <= 0 or batch <= 0 then return end
    -- Vague finale dès le dernier quart, sans attendre l'intervalle : ce quart peut durer moins de
    -- SPAWN_INTERVAL_MS réelles (journée courte, vitesse accélérée).
    if fraction >= cfg.sprintFromFraction and not self.isFinalWaveDone then
        self.isFinalWaveDone = true
        self.lastSpawnMs = nowMs
        self:spawn(math.min(batch, room), true)
        return
    end
    if nowMs - self.lastSpawnMs < SPAWN_INTERVAL_MS then return end
    self.lastSpawnMs = nowMs
    local missing = (cfg.minZombiesByIntensity[intensity] or 0) - Waves.countNear(center, cfg.countRadius)
    local count = math.min(missing, batch, room)
    if count > 0 then
        self:spawn(count, fraction >= cfg.sprintFromFraction)
    end
end

return Waves
