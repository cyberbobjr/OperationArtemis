-- Opération Artemis : trajectoire de l'hélicoptère d'extraction, route B (fonctions pures).
-- D'après le vol de Military Drop (même auteur, licence MIT), adapté aux phases de l'extraction :
-- - approche : il tourne autour de la zone d'atterrissage sur un cercle qui se resserre au fil de la
--   tenue (le rotor s'entend de loin, puis de plus en plus fort) ;
-- - posé : il est au centre de la zone ;
-- - départ : il s'éloigne en ligne droite.

local Flight = {}

Flight.SPEED = 12             -- cases par seconde réelle (départ)
Flight.ORBIT_MAX_RADIUS = 300 -- rayon du cercle au début de la tenue
Flight.ORBIT_MIN_RADIUS = 25  -- rayon à la fin de la tenue, juste avant l'atterrissage
Flight.ORBIT_SECONDS = 40     -- durée d'un tour (secondes réelles)
Flight.LEAVE_DISTANCE = 600

-- Position pendant l'approche. fraction : part de la tenue écoulée (0 à 1) ; seconds : horloge réelle
-- locale (fait tourner l'hélicoptère, sans besoin de synchronisation entre clients).
function Flight.orbitPosition(landing, fraction, seconds)
    local k = math.max(0, math.min(1, fraction))
    local radius = Flight.ORBIT_MAX_RADIUS - (Flight.ORBIT_MAX_RADIUS - Flight.ORBIT_MIN_RADIUS) * k
    local angle = 2 * math.pi * (seconds / Flight.ORBIT_SECONDS)
    return landing.x + math.cos(angle) * radius, landing.y + math.sin(angle) * radius
end

-- Position au départ, elapsed secondes après le décollage, selon un cap en radians.
-- Renvoie x, y et true une fois hors de portée.
function Flight.leavePosition(landing, heading, elapsed)
    local distance = math.max(0, elapsed) * Flight.SPEED
    local isGone = distance >= Flight.LEAVE_DISTANCE
    distance = math.min(distance, Flight.LEAVE_DISTANCE)
    return landing.x + math.cos(heading) * distance, landing.y + math.sin(heading) * distance, isGone
end

return Flight
