-- Opération Artemis : règles de l'extraction par hélicoptère, route B (fonctions pures).
-- Après l'appel radio, chaque jour : à l'heure du créneau, le rotor approche (« inbound ») pendant
-- la durée de tenue ; puis l'hélicoptère est posé (« landed ») et attend ; sinon il n'est pas là
-- (« waiting »). Embarquer = rester dans la zone marquée avec le dossier pendant qu'il est posé.
-- S'il repart sans personne, il reviendra au créneau du lendemain, sans nouvel appel.
-- Enregistré dans state.flags.extraction.routeB = { called, calledDay, phase, slotDay, seen }.

local Extraction = {}

Extraction.KEY = "routeB"

-- Appel accepté, premier créneau pas encore commencé : on attend d'abord une période sans
-- hélicoptère, pour qu'un appel passé pendant le créneau ne le fasse pas arriver (ou se poser) aussitôt.
Extraction.CALLED = "called"
Extraction.WAITING = "waiting"
Extraction.INBOUND = "inbound"
Extraction.LANDED = "landed"

local MINUTES_PER_DAY = 24 * 60

-- Phase de l'hélicoptère à cette minute du jour (0 à 1439). timing = { slotHour, holdMinutes,
-- landedMinutes }. Le créneau peut passer minuit : les minutes sont comptées depuis son début.
function Extraction.phaseAt(minuteOfDay, timing)
    local start = timing.slotHour * 60
    -- Dividende rendu positif : en Kahlua, % d'un nombre négatif est tronqué vers zéro.
    local sinceStart = (minuteOfDay - start + MINUTES_PER_DAY) % MINUTES_PER_DAY
    if sinceStart < timing.holdMinutes then
        return Extraction.INBOUND
    end
    if sinceStart < timing.holdMinutes + timing.landedMinutes then
        return Extraction.LANDED
    end
    return Extraction.WAITING
end

-- Fraction de la tenue écoulée (0 à 1), pendant « inbound » ; 1 ensuite.
function Extraction.holdFraction(minuteOfDay, timing)
    local sinceStart = (minuteOfDay - timing.slotHour * 60 + MINUTES_PER_DAY) % MINUTES_PER_DAY
    return math.min(1, sinceStart / math.max(1, timing.holdMinutes))
end

-- L'extraction a-t-elle été demandée (appel radio accepté) ?
function Extraction.isCalled(entry)
    return type(entry) == "table" and entry.called == true
end

-- Prochaine transition, d'après l'entrée enregistrée et la phase du moment :
--   nil         : rien à enregistrer ;
--   "ready"     : après l'appel, première période sans hélicoptère (le prochain créneau comptera) ;
--   "arrive"    : le rotor approche (début du créneau) ;
--   "land"      : l'hélicoptère se pose ;
--   "leave"     : il repart sans personne (rendez-vous manqué si un joueur est venu, « seen ») ;
-- Une phase sautée (sommeil, vitesse accélérée) donne quand même sa transition : on compare la phase
-- voulue à celle enregistrée, pas les minutes exactes.
function Extraction.transition(entry, phase)
    if not Extraction.isCalled(entry) then
        return nil
    end
    local current = entry.phase or Extraction.WAITING
    if current == Extraction.CALLED then
        return phase == Extraction.WAITING and "ready" or nil
    end
    if phase == current then
        return nil
    end
    if phase == Extraction.INBOUND then
        return "arrive"
    end
    if phase == Extraction.LANDED then
        return "land"
    end
    return "leave"
end

-- Distance de Chebyshev (cases) entre deux points au sol.
function Extraction.distance(ax, ay, bx, by)
    return math.max(math.abs(ax - bx), math.abs(ay - by))
end

-- Le joueur à cette case est-il dans la zone marquée où l'on embarque ?
function Extraction.isInBoardZone(extraction, x, y, z)
    local landing = extraction.landing
    return z == landing.z and Extraction.distance(x, y, landing.x, landing.y) <= extraction.boardRadius
end

-- Le joueur à cette case est-il au rendez-vous (assez près de la zone pour l'entendre et la tenir) ?
function Extraction.isNearLanding(extraction, x, y)
    local landing = extraction.landing
    return Extraction.distance(x, y, landing.x, landing.y) <= extraction.holdRadius
end

-- Embarquement : secondes réelles passées dans la zone marquée, avec le dossier, pendant que
-- l'hélicoptère est posé. since = horodatage (ms) d'entrée dans la zone, ou nil.
function Extraction.boardingDone(since, nowMs, seconds)
    return since ~= nil and nowMs - since >= seconds * 1000
end

return Extraction
