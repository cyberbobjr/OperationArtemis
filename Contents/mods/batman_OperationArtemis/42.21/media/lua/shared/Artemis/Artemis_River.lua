-- Opération Artemis : route A, le fleuve (fonctions pures, décisions de la phase 5).
-- Sorties par l'Ohio (ouest, nord-est), postes gardés (zone de passage, groupe électrogène) et état
-- des postes : state.flags.river[poste] = { cut, alarmUntil } (groupe coupé vu par le serveur ;
-- fin de la sirène en minutes de monde).

local River = {}

River.FLAG = "river"

local function inRect(rect, x, y)
    return x >= rect.x1 and x <= rect.x2 and y >= rect.y1 and y <= rect.y2
end

-- Sortie franchie à cette position : « west », « northeast » ou nil.
function River.exitAt(cfg, x, y)
    local west, northeast = cfg.exits.west, cfg.exits.northeast
    if x <= west.maxX and y >= west.y1 and y <= west.y2 then
        return "west"
    end
    if x >= northeast.minX and y <= northeast.maxY then
        return "northeast"
    end
    return nil
end

-- Poste dont la zone de passage contient cette position, ou nil.
function River.guardAt(cfg, x, y)
    for guardId, guard in pairs(cfg.guards) do
        if inRect(guard.zone, x, y) then
            return guardId
        end
    end
    return nil
end

-- Le groupe du poste tourne-t-il ? generatorOn : état lu sur la case (true, false, ou nil si la case
-- n'est pas chargée) ; sinon, le dernier état vu (entry.cut). Un poste jamais vu tourne.
function River.isLit(entry, generatorOn)
    if generatorOn ~= nil then
        return generatorOn
    end
    return not (type(entry) == "table" and entry.cut == true)
end

-- La sirène du poste sonne-t-elle encore ?
function River.isAlarmOn(entry, nowMinutes)
    return type(entry) == "table" and type(entry.alarmUntil) == "number" and nowMinutes < entry.alarmUntil
end

-- Le groupe du poste a-t-il été vu coupé ?
function River.isCut(entry)
    return type(entry) == "table" and entry.cut == true
end

return River
