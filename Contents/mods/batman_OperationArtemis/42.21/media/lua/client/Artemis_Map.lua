-- Opération Artemis : révèle sur la carte du monde les lieux des chapitres ouverts (state.revealed)
-- et, une fois le dossier lu, les points d'évacuation de l'acte III (Story.EXFIL_POINTS).
-- Côté client (la carte du monde et ses symboles sont locaux au client, solo comme multijoueur).
-- Détails et références : .claude/pz-knowledge/world-map.md.
-- - Zone : WorldMapVisited:setKnownInSquares (blocs de 32 cases), et en multijoueur la commande
--   vanilla map/setKnownInSquares, qui l'enregistre côté serveur pour ce compte (ClientCommands.lua:1239).
-- - Symbole : ajouté aux notes du joueur (map_symbols.bin) par une carte du monde cachée ; le joueur
--   peut l'effacer, il revient au prochain chargement de la partie.

local Story = require "Artemis/Artemis_Story"
local State = require "Artemis/Artemis_State"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Boats = require "Artemis/Artemis_Boats"
local StateWatcher = require "Artemis/Artemis_StateWatcher"

local TEXT_OFFSET_Y = 12

-- Une seule carte cachée par session : chaque API de symboles ajoute un écouteur permanent
-- (WorldMapSymbolsV2.java:54-59). Même construction que le vanilla (ISWorldMap.lua:643-647).
local hiddenMap = nil

-- État appliqué pendant cette session, par lieu (chapitre ou point d'évacuation) : true (repère
-- posé), false (repère retiré), nil (rien encore).
local appliedThisSession = {}

local function symbolsAPI()
    if hiddenMap == nil then
        local ui = {}
        ui.javaObject = UIWorldMap.new(ui)
        ui.mapAPI = ui.javaObject:getAPIv3()
        ui.mapAPI:setMapItem(MapItem.getSingleton())
        hiddenMap = ui
    end
    return hiddenMap.mapAPI:getSymbolsAPIv2()
end

local function isNear(symbol, x, y)
    return math.abs(symbol:getWorldX() - x) < 1 and math.abs(symbol:getWorldY() - y) < 1
end

local function hasTexture(api, icon, x, y)
    for index = 0, api:getSymbolCount() - 1 do
        local symbol = api:getSymbolByIndex(index)
        if symbol:isTexture() and symbol:getSymbolID() == icon and isNear(symbol, x, y) then
            return true
        end
    end
    return false
end

-- Texte déjà présent à cette position. On compare la position, pas la clé : pour un personnage
-- illettré, getUntranslatedText renvoie le texte masqué par des « ? » (WorldMapTextSymbol.java),
-- la clé ne serait jamais reconnue et le texte serait ajouté à chaque chargement.
local function hasText(api, x, y)
    for index = 0, api:getSymbolCount() - 1 do
        local symbol = api:getSymbolByIndex(index)
        if symbol:isText() and isNear(symbol, x, y) then
            return true
        end
    end
    return false
end

local function addMark(mark, color)
    local api = symbolsAPI()
    if not hasTexture(api, mark.icon, mark.x, mark.y) then
        local symbol = api:addTexture(mark.icon, mark.x, mark.y)
        symbol:setAnchor(0.5, 0.5)
        symbol:setRGBA(color.r, color.g, color.b, 1.0)
    end
    -- Clé de traduction : le texte s'affiche dans la langue du joueur (addUntranslatedText) ;
    -- comme tout texte de la carte, il est masqué par des « ? » pour un personnage illettré.
    local textY = mark.y + TEXT_OFFSET_Y
    if not hasText(api, mark.x, textY) then
        local layer = api:getDefaultTextLayerID()
        local symbol = api:addUntranslatedText(mark.textKey, layer, mark.x, textY)
        symbol:setAnchor(0.5, 0.0)
        symbol:setRGBA(color.r, color.g, color.b, 1.0)
    end
end

-- Retire le repère du mod (symbole et texte) d'un lieu qui n'est pas ou plus révélé : après un
-- redémarrage de l'opération (nouveau personnage), les repères de l'enquête précédente sont encore
-- dans les notes de la carte, sauvegardées avec le monde, et dévoileraient les lieux suivants.
-- Parcours à rebours : retirer un symbole décale les suivants.
local function removeMark(mark)
    local api = symbolsAPI()
    local textY = mark.y + TEXT_OFFSET_Y
    for index = api:getSymbolCount() - 1, 0, -1 do
        local symbol = api:getSymbolByIndex(index)
        local isOurTexture = symbol:isTexture() and symbol:getSymbolID() == mark.icon and isNear(symbol, mark.x, mark.y)
        local isOurText = symbol:isText() and isNear(symbol, mark.x, textY)
        if isOurTexture or isOurText then
            api:removeSymbolByIndex(index)
        end
    end
end

local function revealArea(area)
    WorldMapVisited.getInstance():setKnownInSquares(area.x1, area.y1, area.x2, area.y2)
    if isClient() then
        sendClientCommand(getPlayer(), "map", "setKnownInSquares",
            { x1 = area.x1, y1 = area.y1, x2 = area.x2, y2 = area.y2 })
    end
end

local function isRevealed(state, chapterId)
    for _, id in ipairs(state.revealed) do
        if id == chapterId then
            return true
        end
    end
    return false
end

-- Lieu révélé : zone connue et repère, reposé une fois par session et à chaque changement de couleur
-- (route fermée ou rouverte ; ancien repère gris « à venir » d'une sauvegarde de la phase 4). Lieu
-- non révélé : repère retiré (une fois par session, et de nouveau après un redémarrage de
-- l'opération). La zone déjà connue de la carte reste connue : le moteur n'offre pas de moyen simple
-- de l'oublier.
local function apply(placeId, reveal, isShown, color, colorTag)
    local applied = appliedThisSession[placeId]
    local tag = colorTag or "open"
    if isShown and applied ~= tag then
        appliedThisSession[placeId] = tag
        removeMark(reveal.mark)
        revealArea(reveal.area)
        addMark(reveal.mark, color)
    elseif not isShown and applied ~= false then
        appliedThisSession[placeId] = false
        removeMark(reveal.mark)
    end
end

-- Repères d'anciennes versions dont la position a changé : retirés une fois par session.
local isLegacyCleaned = false

local function removeLegacyMarks()
    if isLegacyCleaned then return end
    isLegacyCleaned = true
    for _, mark in ipairs(Story.EXFIL_LEGACY_MARKS or {}) do
        removeMark(mark)
    end
end

local function onState(state, _isFirst)
    if not getPlayer() then return end
    for chapterId, chapter in pairs(Story.CHAPTERS) do
        apply(chapterId, chapter.reveal, isRevealed(state, chapterId), Story.MARK_COLOR)
    end
    -- Points d'évacuation : le dossier les nomme, sa lecture les révèle. Une route fermée (stérilisation
    -- de la zone) est en gris.
    removeLegacyMarks()
    local isDossierRead = State.hasFlagEntry(state, "readDocs", Story.EXFIL_REVEAL_DOCUMENT)
    local hasBoats = Boats.vBoatScript() ~= nil
    for pointId, point in pairs(Story.EXFIL_POINTS) do
        local isOpen = point.available and not Sterilization.closesRoute(state.flags, point.route)
        local color = isOpen and Story.MARK_COLOR or Story.EXFIL_UNAVAILABLE_COLOR
        local isRelevant = point.boats == nil or (point.boats == "required") == hasBoats
        apply("exfil_" .. pointId, point.reveal, isDossierRead and isRelevant, color, isOpen and "open" or "closed")
    end
end

StateWatcher.subscribe(onState)
