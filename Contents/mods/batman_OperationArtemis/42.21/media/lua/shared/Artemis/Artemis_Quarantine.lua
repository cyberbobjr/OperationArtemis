-- Opération Artemis : route C, le checkpoint du pont Clark Memorial (fonctions pures, décisions de la
-- phase 5). Deux protocoles militaires :
-- 1. test d'entrée au poste, devant l'enclos (ZVirusVaccine s'il est actif, sinon action du mod) :
--    négatif, le portail s'ouvre pour ce joueur pendant un moment (CLEARED) ;
-- 2. quarantaine dans l'enclos (une heure de jeu maximum, avec ou sans dossier), sous attaque (RUNNING), puis test
--    final sur l'état réel du personnage : négatif, le barrage du pont s'ouvre (PASSED) et traverser
--    vers le nord est la sortie ; positif, refus et enclos rouvert (REFUSED).
-- Sortir de l'enclos pendant la quarantaine l'interrompt (l'entrée est effacée).
-- État par joueur : state.flags.checkpoint[nom] = { phase, clearedUntil, startHours, hours, reanimated }.

local Quarantine = {}

Quarantine.FLAG = "checkpoint"
-- Barrage du pont ouvert (state.flags.checkpoint[LANE_KEY] = true), commun à tous les joueurs.
Quarantine.LANE_KEY = "_lane"

Quarantine.CLEARED = "cleared"
Quarantine.RUNNING = "running"
Quarantine.MAX_HOURS = 1
Quarantine.PASSED = "passed"
Quarantine.REFUSED = "refused"

local HOURS_PER_MINUTE = 1 / 60

local function inRect(rect, x, y)
    return x >= rect.x1 and x <= rect.x2 and y >= rect.y1 and y <= rect.y2
end

-- Cases intérieures de l'enclos.
function Quarantine.isInPen(cfg, x, y, z)
    return z == cfg.pen.z and inRect(cfg.pen, x, y)
end

-- Au poste de test, devant le portail.
function Quarantine.isAtPost(cfg, x, y, z)
    local post = cfg.post
    return z == post.z and math.max(math.abs(x - post.x), math.abs(y - post.y)) <= cfg.testRadius
end

-- Au-delà du barrage, sur le pont (sortie).
function Quarantine.isPastExitLine(cfg, x, y)
    local line = cfg.exitLine
    return x >= line.x1 and x <= line.x2 and y <= line.maxY
end

-- Durée de la quarantaine (heures de jeu) selon que le joueur porte le dossier à l'entrée.
function Quarantine.hoursFor(cfg, hasDossier)
    return math.min(Quarantine.MAX_HOURS, hasDossier and cfg.hoursWithDossier or cfg.hoursWithoutDossier)
end

-- Entrée après un test d'entrée négatif : le portail reste ouvert pour ce joueur un moment.
function Quarantine.cleared(cfg, nowHours)
    return { phase = Quarantine.CLEARED, clearedUntil = nowHours + cfg.entryValidMinutes * HOURS_PER_MINUTE }
end

function Quarantine.isClearValid(entry, nowHours)
    return type(entry) == "table" and entry.phase == Quarantine.CLEARED
        and type(entry.clearedUntil) == "number" and nowHours <= entry.clearedUntil
end

-- Début de la quarantaine.
function Quarantine.started(cfg, nowHours, hasDossier)
    return { phase = Quarantine.RUNNING, startHours = nowHours, hours = Quarantine.hoursFor(cfg, hasDossier),
        reanimated = false }
end

-- Part de la quarantaine écoulée (0 à 1).
function Quarantine.fraction(entry, nowHours)
    if type(entry) ~= "table" or entry.phase ~= Quarantine.RUNNING or (entry.hours or 0) <= 0 then
        return 0
    end
    return math.max(0, math.min(1, (nowHours - entry.startHours) / entry.hours))
end

function Quarantine.isOver(entry, nowHours)
    return type(entry) == "table" and entry.phase == Quarantine.RUNNING and nowHours >= entry.startHours + entry.hours
end

-- Heures de quarantaine écoulées.
function Quarantine.elapsedHours(entry, nowHours)
    if type(entry) ~= "table" or entry.phase ~= Quarantine.RUNNING then
        return 0
    end
    return math.max(0, nowHours - entry.startHours)
end

-- Le détenu mort se relève-t-il maintenant ? (une fois, à l'heure prévue, avant la fin)
function Quarantine.isReanimationDue(cfg, entry, nowHours)
    return type(entry) == "table" and entry.phase == Quarantine.RUNNING and entry.reanimated ~= true
        and Quarantine.elapsedHours(entry, nowHours) >= cfg.reanimateAtHour
end

-- Le portail doit-il être ouvert (déverrouillé) ?
-- - oui si un joueur dans l'enclos n'y est pas en quarantaine (entré avec un autre, quarantaine
--   finie, abandonnée ou refusée) : personne n'y reste enfermé ;
-- - sinon oui si un joueur est autorisé à entrer et qu'aucune quarantaine n'est en cours ;
-- - non pendant une quarantaine.
-- inPen[nom] : joueur connecté dans l'enclos ; online[nom] : joueur connecté (la quarantaine d'un
-- joueur déconnecté ne bloque pas les autres).
function Quarantine.isGateOpen(entries, inPen, online, nowHours)
    for name in pairs(inPen) do
        local entry = entries[name]
        if type(entry) ~= "table" or entry.phase ~= Quarantine.RUNNING then
            return true
        end
    end
    local isCleared = false
    for name, entry in pairs(entries) do
        if type(entry) == "table" and online[name] then
            if entry.phase == Quarantine.RUNNING then
                return false
            end
            if Quarantine.isClearValid(entry, nowHours) then
                isCleared = true
            end
        end
    end
    return isCleared
end

-- Une quarantaine d'un autre joueur connecté est-elle en cours ?
function Quarantine.isOccupied(entries, online, exceptName)
    for name, entry in pairs(entries) do
        if name ~= exceptName and online[name] and type(entry) == "table" and entry.phase == Quarantine.RUNNING then
            return true
        end
    end
    return false
end

return Quarantine
