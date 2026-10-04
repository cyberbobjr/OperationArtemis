-- Opération Artemis : icônes de carte du mod (points d'évacuation de l'acte III, Artemis_Story.EXFIL_POINTS).
-- Déclarées au chargement du Lua, avant tout symbole : sans définition, un symbole garde la texture
-- d'erreur (WorldMapSymbols.java:78-91). PNG blancs 64×64 dont l'alpha est un champ de distance,
-- comme les icônes vanilla (rendu SDF, la couleur vient du symbole) : .claude/tools/artemis_map_icons.py.
-- Onglet « Locations » : elles apparaissent aussi dans la palette de symboles du joueur.

local ICONS = {
    ArtemisHeli = "media/ui/Artemis/map_heli.png",
    ArtemisBoat = "media/ui/Artemis/map_boat.png",
    ArtemisCheckpoint = "media/ui/Artemis/map_checkpoint.png",
}

local definitions = MapSymbolDefinitions and MapSymbolDefinitions.getInstance()
if definitions then
    for id, path in pairs(ICONS) do
        definitions:addTexture(id, path, "Locations")
    end
end
