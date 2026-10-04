-- Opération Artemis : zombies suivis (patient zéro, Miller, sujets du labo). Serveur ou solo.
-- Un zombie posé par le mod avec un profil (Story.TRACKED) est enregistré par la clé de sa tenue
-- (state.flags.tracked, Artemis_Tracking). Ses traits (santé, sprint, position assise) sont perdus
-- à chaque virtualisation : on les lui rend quand il revient dans le monde (OnZombieCreate), s'il est
-- toujours dans la zone de son profil. À sa mort, il peut laisser un objet (carte d'identité).
--
-- Profil (Story.TRACKED[nom]) :
--   area              : zone { x1, y1, x2, y2 } hors de laquelle le zombie redevient ordinaire
--   healthByIntensity : santé selon l'intensité dramatique (zombie normal : 1,5 à 1,8)
--   sprint            : sprinteur (doSprinter, sans toucher ZombieLore)
--   sit               : assis contre un mur (la direction est enregistrée avec la clé)
--   deathItem         : { type = objet, nameKey = nom affiché } glissé dans le corps à sa mort

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Tracking = require "Artemis/Artemis_Tracking"

local Tracked = {}

local REGISTRY = "tracked"
-- Marque de session sur le zombie (profil), pour sa mort ; les ModData sont perdues à la
-- virtualisation, la marque est reposée à chaque retour.
local MARK_KEY = "batman_ArtemisTracked"
-- Marque de mort traitée : OnZombieDead peut se déclencher deux fois (mort par le feu), et le
-- second passage vide l'inventaire (IsoZombie.onKilled -> DoZombieInventory).
local DEATH_KEY = "batman_ArtemisTrackedDeath"

-- Assoit le zombie dos au mur de sa case, comme le vanilla (ZombiePopulationManager.sitAgainstWall,
-- ZombiePopulationManager.java:656-700) : centré sur la case, tourné à l'opposé du mur, animation
-- orientée tout de suite. Sans mur sur sa case (il a pu suivre le joueur), il reste debout.
local function sitAgainstWall(zombie)
    local square = getCell():getGridSquare(math.floor(zombie:getX()), math.floor(zombie:getY()),
        math.floor(zombie:getZ()))
    local facing = square and Tracking.facingForWall(square:getWallType())
    if facing == nil then
        return false
    end
    local direction = IsoDirections[facing]
    zombie:setX(square:getX() + 0.5)
    zombie:setY(square:getY() + 0.5)
    zombie:setSitAgainstWall(true)
    zombie:setDir(direction)
    local vector = direction:ToVector()
    -- Direction du corps et de l'animation (IsoGameCharacter.java:2596-2601).
    zombie:setTargetAndCurrentDirection(vector:getX(), vector:getY())
    return true
end

-- Traits du profil. La santé repart de sa valeur pleine à chaque retour : les dégâts reçus avant la
-- virtualisation ne sont pas connus (limite acceptée).
local function applyTraits(zombie, entry, profile)
    if profile.healthByIntensity then
        zombie:setHealth(profile.healthByIntensity[Config.dramaIntensity()] or profile.healthByIntensity[1])
    end
    if profile.sprint then
        zombie:doSprinter()
    end
    if profile.sit then
        sitAgainstWall(zombie)
    end
    zombie:getModData()[MARK_KEY] = entry.profile
end

-- Enregistre un zombie qui vient d'être posé et lui donne ses traits. Renvoie la clé, ou nil si le
-- zombie n'a pas de tenue persistante (il garde ses traits jusqu'à sa virtualisation seulement).
function Tracked.register(zombie, profileName)
    local profile = Story.TRACKED[profileName]
    local entry = { profile = profileName }
    applyTraits(zombie, entry, profile)
    local key = Tracking.outfitKey(zombie:getPersistentOutfitID())
    if key == nil then
        Const.log("ERREUR : zombie suivi sans tenue persistante (" .. profileName .. ")")
        return nil
    end
    Store.save(State.withFlagValue(Store.load(), REGISTRY, tostring(key), entry))
    return key
end

-- Registre lu directement dans la ModData (sans copie) : l'événement est fréquent.
local function registry()
    local data = ModData.get(Const.MODDATA_KEY)
    local flags = type(data) == "table" and data.flags
    local tracked = type(flags) == "table" and flags[REGISTRY]
    return type(tracked) == "table" and tracked or nil
end

-- Retour d'un zombie dans le monde : position déjà fixée, tenue peut-être pas encore habillée
-- (VirtualZombieManager.java:197-207, 354-362), d'où la clé plutôt que le nom de tenue.
local function onZombieCreate(zombie)
    local tracked = registry()
    if tracked == nil then return end
    local key = Tracking.outfitKey(zombie:getPersistentOutfitID())
    local entry = key and tracked[tostring(key)]
    if type(entry) ~= "table" then return end
    local profile = Story.TRACKED[entry.profile]
    if profile == nil or not Tracking.isInArea(profile.area, zombie:getX(), zombie:getY()) then return end
    applyTraits(zombie, entry, profile)
    Const.log("zombie suivi retrouve : " .. entry.profile .. " en " .. math.floor(zombie:getX())
        .. "," .. math.floor(zombie:getY()))
end

-- Objet de mort : dans l'inventaire du zombie, que le cadavre reprend (IsoDeadBody.java:327) ; au
-- sol si le zombie brûle (un cadavre en feu disparaît avec son inventaire, mais BurnTick ne brûle
-- pas les objets au sol, IsoGridSquare.java:5590-5601).
local function giveDeathItem(zombie, deathItem)
    local item = instanceItem(deathItem.type)
    item:setName(getText(deathItem.nameKey))
    item:setCustomName(true)
    if zombie:isOnFire() then
        local square = zombie:getCurrentSquare()
        if square then
            square:AddWorldInventoryItem(item, 0.5, 0.5, 0)
        end
        return "au sol (feu)"
    end
    zombie:getInventory():AddItem(item)
    return "dans le corps"
end

local function onZombieDead(zombie)
    if not zombie:hasModData() then return end
    local modData = zombie:getModData()
    local profileName = modData[MARK_KEY]
    local profile = profileName and Story.TRACKED[profileName]
    if profile == nil then return end
    local deathItem = profile.deathItem
    -- Second passage (mort par le feu) : l'inventaire a été vidé, on remet l'objet s'il y était.
    if modData[DEATH_KEY] == "dans le corps" and deathItem then
        if not zombie:getInventory():containsType(deathItem.type) then
            giveDeathItem(zombie, deathItem)
        end
        return
    end
    if modData[DEATH_KEY] then return end
    modData[DEATH_KEY] = deathItem and giveDeathItem(zombie, deathItem) or "sans objet"
    -- Le zombie est mort : sa clé ne doit plus désigner un autre zombie de même tenue.
    local key = Tracking.outfitKey(zombie:getPersistentOutfitID())
    if key then
        Store.save(State.withFlagValue(Store.load(), REGISTRY, tostring(key), nil))
    end
    Const.log("zombie suivi abattu : " .. profileName .. (deathItem and (", objet " .. modData[DEATH_KEY]) or ""))
end

if not isClient() then
    Events.OnZombieCreate.Add(onZombieCreate)
    Events.OnZombieDead.Add(onZombieDead)
end

return Tracked
