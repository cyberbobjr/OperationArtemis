-- Opération Artemis : épreuve « Évasion du labo » (fonctions pures).
-- Elle commence quand un joueur vivant porte le dossier dans la base, hors de la salle des archives
-- (portique franchi ; aussi après une reconnexion, ou un dossier repris sur un cadavre ou posé plus
-- loin), et se termine quand un porteur du dossier sort de la base (réussite), ou quand plus aucun
-- joueur vivant n'y est (abandon : mort, fuite sans le dossier). Une épreuve réussie ne se rejoue
-- pas. Enregistrée dans state.flags.trials.

local Trial = {}

Trial.RUNNING = "on"
Trial.DONE = "done"

local function isInArea(area, x, y)
    return x >= area.x1 and x <= area.x2 and y >= area.y1 and y <= area.y2
end

-- Le joueur est-il encore dans la base, au sens de l'épreuve ? Dans l'emprise de la base (baseArea),
-- et soit sous terre, soit à la surface près du bâtiment (escape.area, marge comprise).
function Trial.isInBase(escape, baseArea, x, y, z)
    return isInArea(baseArea, x, y) and (z < 0 or isInArea(escape.area, x, y))
end

-- Un porteur du dossier à cette case est-il sorti de la base (à la surface, hors du bâtiment) ?
function Trial.isEscaped(escape, x, y, z)
    return z >= 0 and not isInArea(escape.area, x, y)
end

-- Prochaine étape d'une épreuve : nil (pas en cours), « success », « abandon » ou « running ».
-- facts : { isCarrierEscaped = un porteur vivant est sorti, isAnyoneInBase = un joueur vivant est dedans }.
function Trial.step(entry, facts)
    if type(entry) ~= "table" or entry.status ~= Trial.RUNNING then
        return nil
    end
    if facts.isCarrierEscaped then
        return "success"
    end
    if not facts.isAnyoneInBase then
        return "abandon"
    end
    return "running"
end

local function statusOf(flags, chapterId)
    local trials = type(flags) == "table" and flags.trials
    local entry = type(trials) == "table" and trials[chapterId]
    return type(entry) == "table" and entry.status or nil
end

-- L'épreuve peut-elle commencer (ni en cours, ni déjà réussie) ?
function Trial.canStart(flags, chapterId)
    local status = statusOf(flags, chapterId)
    return status ~= Trial.RUNNING and status ~= Trial.DONE
end

-- L'épreuve de ce chapitre est-elle en cours, d'après les drapeaux bruts (ModData ou état) ?
function Trial.isRunning(flags, chapterId)
    return statusOf(flags, chapterId) == Trial.RUNNING
end

return Trial
