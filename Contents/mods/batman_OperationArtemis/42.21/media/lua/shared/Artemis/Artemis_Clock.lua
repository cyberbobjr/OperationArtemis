-- Opération Artemis : heure de jeu, en un seul endroit.
-- getWorldAgeHours compte depuis le début de la partie ; le « jour » change donc à 7 h
-- (heure de départ vanilla), pas à minuit (GameTime.java:830).

local Clock = {}

Clock.HOURS_PER_DAY = 24

-- { worldHours = heures depuis le début, day = jour de jeu à partir de 1 }
function Clock.now()
    local hours = getGameTime():getWorldAgeHours()
    return { worldHours = hours, day = math.floor(hours / Clock.HOURS_PER_DAY) + 1 }
end

return Clock
