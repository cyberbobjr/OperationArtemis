-- Opération Artemis : points répartis sur un anneau autour d'un lieu (fonction pure).
-- Sert à poser des zombies autour d'un lieu, hors de la vue du joueur (Artemis_Placement).

local Ring = {}

-- n points entiers autour de (cx, cy), à une distance comprise entre minRadius et maxRadius.
-- Les angles sont répartis régulièrement, avec un écart aléatoire d'au plus un demi-secteur, pour
-- éviter un cercle trop régulier. random() renvoie un nombre dans [0, 1[ (injecté pour les tests).
function Ring.points(cx, cy, n, minRadius, maxRadius, random)
    local points = {}
    if n <= 0 then
        return points
    end
    local sector = 2 * math.pi / n
    for index = 0, n - 1 do
        local angle = index * sector + (random() - 0.5) * sector
        local radius = minRadius + random() * (maxRadius - minRadius)
        points[#points + 1] = {
            x = math.floor(cx + math.cos(angle) * radius + 0.5),
            y = math.floor(cy + math.sin(angle) * radius + 0.5),
        }
    end
    return points
end

return Ring
