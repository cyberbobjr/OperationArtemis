-- Opération Artemis : les fins de l'opération (fonctions pures, décisions de la phase 5).
-- Une fin est enregistrée par le serveur à la sortie (state.flags.ending.result) :
--   { route = "A"|"B"|"C", exit = "west"|"northeast"|"ferry"|nil, hasDossier, hasCure,
--     day, by, hours, kills }.
-- L'épilogue a un tronc commun (IGUI_Artemis_Epilogue_1 à PARAGRAPHS, écrit pour l'hélicoptère) ; chaque
-- variante remplace quelques paragraphes (IGUI_Artemis_Epilogue_<variante>_<n>) : ceux qui racontent
-- la sortie et, sans dossier, ceux qui parlent du dossier. Même voix, même musique ; le son et l'image
-- d'une variante retombent sur ceux de l'hélicoptère tant qu'ils n'existent pas.

local Endings = {}

Endings.PARAGRAPHS = 12

-- sound : préfixe du script de son (suffixe FR ou EN) ; image : chemin de l'image plein écran.
local DEFAULT_SOUND = "ArtemisVictory"
local DEFAULT_IMAGE = "media/ui/Artemis/victory.png"

local VARIANTS = {
    B = { paragraphs = {} },
    A = { paragraphs = { 7, 9 }, sound = "ArtemisVictoryA" },
    Aferry = { paragraphs = { 7, 9 }, sound = "ArtemisVictoryAferry" },
    C = { paragraphs = { 7, 9 }, sound = "ArtemisVictoryC" },
    Cnodossier = { paragraphs = { 2, 7, 8, 9, 10, 11 }, sound = "ArtemisVictoryCnodossier" },
}

-- Libellé de la sortie dans la chronique, par variante (la sortie précise du fleuve a sa clé).
local ROUTE_KEYS = {
    B = "IGUI_Artemis_Chronicle_Route_B",
    A = "IGUI_Artemis_Chronicle_Route_A",
    Aferry = "IGUI_Artemis_Chronicle_Route_Aferry",
    C = "IGUI_Artemis_Chronicle_Route_C",
    Cnodossier = "IGUI_Artemis_Chronicle_Route_Cnodossier",
}

-- Fin enregistrée à la sortie. facts = { day, by, hours, kills, hasDossier, hasCure }.
function Endings.build(route, exit, facts)
    return {
        route = route,
        exit = exit,
        hasDossier = facts.hasDossier == true,
        hasCure = facts.hasCure == true,
        day = facts.day,
        by = facts.by,
        hours = facts.hours or 0,
        kills = facts.kills or 0,
    }
end

-- Identifiant de la variante d'une fin (B pour une fin enregistrée avant la phase 5).
function Endings.variantId(ending)
    if type(ending) ~= "table" then return "B" end
    if ending.route == "A" then
        return ending.exit == "ferry" and "Aferry" or "A"
    end
    if ending.route == "C" then
        return ending.hasDossier == false and "Cnodossier" or "C"
    end
    return "B"
end

local function variant(ending)
    return VARIANTS[Endings.variantId(ending)]
end

-- Clés de traduction des paragraphes de l'épilogue, dans l'ordre.
function Endings.paragraphKeys(ending)
    local id = Endings.variantId(ending)
    local replaced = {}
    for _, index in ipairs(variant(ending).paragraphs) do
        replaced[index] = true
    end
    local keys = {}
    for index = 1, Endings.PARAGRAPHS do
        if replaced[index] then
            keys[index] = "IGUI_Artemis_Epilogue_" .. id .. "_" .. index
        else
            keys[index] = "IGUI_Artemis_Epilogue_" .. index
        end
    end
    return keys
end

-- Script de son (voix et musique) de la fin, pour un code de langue du jeu (FR, sinon EN).
function Endings.soundName(ending, languageCode)
    local prefix = variant(ending).sound or DEFAULT_SOUND
    return prefix .. (languageCode == "FR" and "FR" or "EN")
end

function Endings.image(ending)
    return variant(ending).image or DEFAULT_IMAGE
end

-- Sous-titre de l'écran de fin (la sortie), sous le titre de l'opération.
function Endings.subtitleKey(ending)
    local id = Endings.variantId(ending)
    if id == "B" then
        return "IGUI_Artemis_Ending_Subtitle"
    end
    return "IGUI_Artemis_Ending_Subtitle_" .. id
end

-- Ligne de la chronique qui nomme la sortie.
function Endings.routeKey(ending)
    return ROUTE_KEYS[Endings.variantId(ending)]
end

-- Mots de la chronique pour la sortie précise du fleuve (ouest, nord-est), sinon nil.
function Endings.exitKey(ending)
    if type(ending) == "table" and ending.route == "A" and (ending.exit == "west" or ending.exit == "northeast") then
        return "IGUI_Artemis_Chronicle_Exit_" .. ending.exit
    end
    return nil
end

return Endings
