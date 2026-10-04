-- Opération Artemis : ensemble de lampes du mod (lumières addLamppost), côté client.
-- Utilisé par le guide de la base (Artemis_Guide) et les éclairages de lieu (Artemis_WorldLights).
-- Une lampe est une table { x, y, z [, color = { r, g, b }] [, radius] [, blink = motif] } ; sans
-- couleur ni rayon, ceux de l'ensemble s'appliquent. Les lampes ne sont pas sauvegardées : elles
-- sont recréées quand leur case est chargée.

local Blink = require "Artemis/Artemis_Blink"

local Lamps = {}
Lamps.__index = Lamps

-- Rayon plafonné à 20 cases par le moteur (IsoCell.java:2449).
local MAX_RADIUS = 20

-- defaults : { color = { r, g, b }, radius = cases }.
function Lamps.new(defaults)
    return setmetatable({ defaults = defaults, refs = {}, lit = {}, colorOverride = nil }, Lamps)
end

local function applyColor(light, color)
    light:setR(color.r)
    light:setG(color.g)
    light:setB(color.b)
end

-- Couleur imposée à toutes les lampes de l'ensemble (gyrophares), ou nil pour revenir à leur couleur.
-- setR/G/B sont repris par le moteur sans recréer la lampe (IsoLightSource.java:157-175,
-- LightingJNI.java:291-295).
function Lamps:setColor(color, lamps)
    if self.colorOverride == color then return end
    self.colorOverride = color
    for index, light in pairs(self.refs) do
        local lamp = lamps[index]
        applyColor(light, color or (lamp and lamp.color) or self.defaults.color)
    end
end

-- Kahlua 42.21 n'a pas next() (.claude/pz-knowledge/kahlua-lua.md) : test de table vide par pairs.
function Lamps:hasLamps()
    for _ in pairs(self.refs) do -- luacheck: ignore 512 (un seul tour voulu)
        return true
    end
    return false
end

function Lamps:clear()
    for _, light in pairs(self.refs) do
        getCell():removeLamppost(light)
    end
    self.refs, self.lit = {}, {}
end

-- Une lampe disparaît quand sa case sort de la zone chargée (LightingJNI.java:225-235) : on la recrée
-- quand sa case est de nouveau chargée et que NOTRE lampe n'est plus dans la liste de la cellule
-- (getLamppostPositions). getLightSourceAt renverrait la première lumière de la case, peut-être une
-- autre : on recréerait alors une lampe à chaque passage.
function Lamps:maintain(lamps)
    local cell = getCell()
    local lights = cell:getLamppostPositions()
    for index, lamp in ipairs(lamps) do
        if cell:getGridSquare(lamp.x, lamp.y, lamp.z) ~= nil
            and (self.refs[index] == nil or not lights:contains(self.refs[index])) then
            local color = self.colorOverride or lamp.color or self.defaults.color
            local radius = math.min(MAX_RADIUS, lamp.radius or self.defaults.radius)
            self.refs[index] = cell:addLamppost(lamp.x, lamp.y, lamp.z, color.r, color.g, color.b, radius)
            -- Une lampe neuve est allumée.
            self.lit[index] = true
        end
    end
end

-- Fait clignoter les lampes qui ont un motif (lamp.blink, sinon patternName), seulement à l'étage
-- du joueur (floorZ) : les autres restent allumées. setActive n'est appelé que si l'état change :
-- le moteur reprend alors la lumière à la mise à jour suivante (LightingJNI.java:285-298). Ne jamais
-- retirer puis rajouter la lampe pour clignoter : chaque ajout crée une nouvelle lumière native.
function Lamps:blink(lamps, patternName, nowMs, floorZ)
    for index, lamp in ipairs(lamps) do
        local light = self.refs[index]
        if light then
            local pattern = Blink.get(lamp.blink or patternName)
            local isLit = true
            if pattern and lamp.z == floorZ then
                isLit = Blink.isLit(pattern, nowMs, Blink.offset(pattern, lamp.x, lamp.y, lamp.z))
            end
            if self.lit[index] ~= isLit then
                light:setActive(isLit)
                self.lit[index] = isLit
            end
        end
    end
end

return Lamps
