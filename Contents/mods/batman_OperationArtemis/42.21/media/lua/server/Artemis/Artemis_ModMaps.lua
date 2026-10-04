-- Opération Artemis : chapitres optionnels qui dépendent d'une carte de mod (phase 6, chapitre 4 à
-- Tikitown). Serveur ou solo.
-- La liste des cartes d'une partie est figée à sa création (solo : map_ver.bin ; MP : Map= du
-- serveur) : un mod de carte activé plus tard n'y est jamais ajouté. Une carte compte donc si :
-- 1. son mod est actif (getActivatedMods, « \ » initial retiré) ;
-- 2. son dossier est dans la liste des cartes de la partie (getWorld():getMap(), noms séparés par « ; ») ;
-- 3. la métagrille connaît la pièce sondée (getRoomAt répond sans charger de case).
-- Décision de la phase 6 : la disponibilité est relevée une fois, à l'entrée dans l'acte II, et
-- enregistrée (state.flags.optionalChapters) ; elle ne change plus ensuite.

local Const = require "Artemis/Artemis_Const"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"

local ModMaps = {}

local FLAG = "optionalChapters"

local function isModActive(modId)
    local mods = getActivatedMods()
    for index = 0, mods:size() - 1 do
        if tostring(mods:get(index)):gsub("^\\", "") == modId then
            return true
        end
    end
    return false
end

local function isMapLoaded(folder)
    local maps = getWorld() and getWorld():getMap() or ""
    return (";" .. tostring(maps) .. ";"):find(";" .. folder .. ";", 1, true) ~= nil
end

local function hasProbeRoom(probe)
    local metaGrid = getWorld() and getWorld():getMetaGrid()
    local room = metaGrid and metaGrid:getRoomAt(probe.x, probe.y, probe.z)
    return room ~= nil
end

-- Disponibilité d'un chapitre optionnel, avec la raison d'un refus (journal de debug).
function ModMaps.check(requires)
    if not isModActive(requires.mod) then
        return false, "mod " .. requires.mod .. " inactif"
    end
    if not isMapLoaded(requires.map) then
        return false, "mod " .. requires.mod .. " actif mais carte " .. requires.map .. " absente de la partie"
    end
    if not hasProbeRoom(requires.probe) then
        return false, "carte " .. requires.map .. " presente mais lieu introuvable"
    end
    return true, nil
end

-- Le chapitre est-il encore à venir ? (chapitre en cours avant lui dans la chaîne « next », ou lui-même)
local function isAhead(state, chapterId)
    if state.act ~= Const.ACT.INVESTIGATION then
        return false
    end
    local current = state.chapter
    while current ~= nil do
        if current == chapterId then
            return true
        end
        local chapter = Story.get(current)
        current = chapter and chapter.next or nil
    end
    return false
end

-- État avec la disponibilité de chaque chapitre optionnel relevée (une fois, à partir de l'acte II).
-- Un chapitre déjà dépassé (partie plus avancée lors de la mise à jour) est marqué indisponible.
-- À n'appeler qu'une fois la métagrille construite : pendant OnInitGlobalModData, getRoomAt renvoie
-- nil (IsoWorld.java:1908, avant IsoMetaGrid.CreateStep2 :1940).
function ModMaps.freeze(state)
    if state.act < Const.ACT.INVESTIGATION then
        return state
    end
    local nextState = state
    for chapterId, chapter in pairs(Story.CHAPTERS) do
        if chapter.requires and State.flagValue(nextState, FLAG, chapterId) == nil then
            local isAvailable, reason = false, "chapitre deja depasse"
            if isAhead(nextState, chapterId) then
                isAvailable, reason = ModMaps.check(chapter.requires)
            end
            nextState = State.withFlagValue(nextState, FLAG, chapterId, isAvailable)
            local outcome = isAvailable and "disponible" or ("saute (" .. reason .. ")")
            Const.log("chapitre optionnel " .. chapterId .. " : " .. outcome)
        end
    end
    return nextState
end

return ModMaps
