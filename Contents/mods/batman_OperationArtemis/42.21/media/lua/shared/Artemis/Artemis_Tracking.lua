-- Opération Artemis : reconnaître un zombie suivi après sa virtualisation (fonctions pures).
-- Un zombie éloigné du joueur est « virtualisé » : à son retour, il ne garde que sa position, ses
-- drapeaux d'état et l'identifiant de sa tenue (persistentOutfitID) ; santé, vitesse, position
-- assise et ModData sont perdues (.claude/pz-knowledge/staging-effects.md). On le reconnaît donc à
-- l'identifiant de sa tenue, dans une zone donnée, pour lui rendre ses traits (Artemis_Tracked).

local Tracking = {}

-- Bit « chapeau tombé » de l'identifiant de tenue (PersistentOutfits.java:290-298) : il change
-- quand le zombie perd son chapeau, il ne fait pas partie de la clé.
local HAT_FALLEN_BIT = 32768
-- L'identifiant est un entier Java 32 bits dont le bit de signe marque une femme (Integer.MIN_VALUE,
-- PersistentOutfits.java:174) : il est négatif pour une femme. On le lit comme un entier non signé.
local UINT32 = 4294967296

-- Clé stable d'un zombie : identifiant de tenue sans le bit du chapeau. Identifiant = bit femme +
-- index de tenue x 65 536 + bit du chapeau + variante (1 à 500). 0 : pas de tenue persistante.
function Tracking.outfitKey(outfitId)
    if type(outfitId) ~= "number" or outfitId == 0 then
        return nil
    end
    local unsigned = outfitId < 0 and outfitId + UINT32 or outfitId
    local hatBit = math.floor(unsigned / HAT_FALLEN_BIT) % 2
    return unsigned - hatBit * HAT_FALLEN_BIT
end

-- Point (x, y) dans la zone { x1, y1, x2, y2 } ? Seulement 500 variantes par tenue : la zone évite
-- de confondre deux zombies de même tenue.
function Tracking.isInArea(area, x, y)
    return x >= area.x1 and x <= area.x2 and y >= area.y1 and y <= area.y2
end

-- Bits de IsoGridSquare:getWallType() (IsoGridSquare.java:8557-8577) et direction du regard d'un
-- zombie assis dos à ce mur.
local FACING_BY_WALL_BIT = {
    { bit = 1, facing = "S" }, -- mur au nord de la case
    { bit = 2, facing = "N" }, -- mur au sud
    { bit = 4, facing = "E" }, -- mur à l'ouest
    { bit = 8, facing = "W" }, -- mur à l'est
}

-- Direction (nom d'IsoDirections) d'un zombie assis contre un mur de cette case, ou nil sans mur.
function Tracking.facingForWall(wallType)
    for _, entry in ipairs(FACING_BY_WALL_BIT) do
        if math.floor(wallType / entry.bit) % 2 == 1 then
            return entry.facing
        end
    end
    return nil
end

return Tracking
