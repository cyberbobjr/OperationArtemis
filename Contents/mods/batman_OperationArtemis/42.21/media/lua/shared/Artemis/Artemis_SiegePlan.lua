-- Opération Artemis : règles du pilotage de Siege Night après le dossier (fonctions pures, phase 6).
-- - « Ils savent » : une fois le dossier lu, l'intervalle entre deux sièges est divisé par deux
--   (1 jour au moins), sans toucher aux options enregistrées ;
-- - le soir de la lecture, un siège est programmé dans Siege Night (V prévient à la radio) ;
-- - pendant une épreuve de l'acte III (transport en approche ou posé, quarantaine, sirène d'un poste
--   gardé), les sièges sont suspendus comme pendant l'évasion du labo.

local Extraction = require "Artemis/Artemis_Extraction"
local Quarantine = require "Artemis/Artemis_Quarantine"
local River = require "Artemis/Artemis_River"

local SiegePlan = {}

SiegePlan.FLAG = "siegeNight"
SiegePlan.KEY = "fileSiege"

-- Intervalle après le dossier : moitié du réglage du joueur, 1 jour au moins. maxDays (0 = sans
-- tirage) : borne haute du tirage de Siege Night, divisée de même si elle est utilisée.
function SiegePlan.halvedFrequency(days, maxDays)
    local low = math.max(1, math.floor((tonumber(days) or 1) / 2))
    local high = tonumber(maxDays) or 0
    if high > 0 then
        high = math.max(low, math.floor(high / 2))
    end
    return low, high
end

-- Préavis minimal (heures de jeu) avant un siège programmé « ce soir ».
SiegePlan.MIN_NOTICE_HOURS = 3

-- Heures de jeu avant le début du siège programmé ce soir (heure de début - heure actuelle).
local function hoursUntilStart(hour, startHour)
    return (startHour - hour + 24) % 24
end

-- Jour du siège programmé à la lecture du dossier : ce soir si l'on est dans la journée avec assez de
-- préavis, sinon le soir suivant (écrire « aujourd'hui » pendant les heures de siège le lancerait sans
-- avertissement). today : jour de Siege Night (entier) ; hour : heure courante (décimale) ;
-- startHour : heure de début des sièges ; isSiegeTime : l'heure courante est dans la fenêtre de siège.
function SiegePlan.siegeDay(today, hour, startHour, isSiegeTime)
    if isSiegeTime or hoursUntilStart(hour, startHour) < SiegePlan.MIN_NOTICE_HOURS then
        return today + 1
    end
    return today
end

-- Heures de monde jusqu'auxquelles V répète l'avertissement : fin de la nuit du siège, une heure de
-- marge. nowHours : heures de monde ; isTonight : siège ce soir (sinon le soir suivant) ;
-- nightHours : durée de la fenêtre de siège.
function SiegePlan.warningUntil(nowHours, hour, startHour, isTonight, nightHours)
    local untilStart = hoursUntilStart(hour, startHour)
    if not isTonight then
        untilStart = untilStart + (untilStart < SiegePlan.MIN_NOTICE_HOURS and 24 or 0)
    end
    return nowHours + untilStart + nightHours + 1
end

-- Faut-il repousser la date d'un siège pendant une suspension ? Seulement si elle est dépassée, ou si
-- c'est aujourd'hui et que les heures de siège ont commencé (il partirait aussitôt). Un siège prévu
-- ce soir, dans la journée, garde sa date : il partira après l'épreuve.
function SiegePlan.isOverdue(nextDay, today, isSiegeTime)
    return nextDay < today or (nextDay == today and isSiegeTime)
end

-- Nouvelle date du prochain siège : jamais repoussée, seulement rapprochée.
function SiegePlan.closerDate(current, wanted)
    if type(current) ~= "number" or current <= 0 then
        return wanted
    end
    return math.min(current, wanted)
end

local function anyEntry(entries, predicate)
    if type(entries) ~= "table" then return false end
    for key, entry in pairs(entries) do
        if predicate(key, entry) then
            return true
        end
    end
    return false
end

-- Une épreuve de l'acte III est-elle en cours ? flags : state.flags ; nowMinutes : minutes de monde.
function SiegePlan.isExitTrialRunning(flags, nowMinutes)
    if type(flags) ~= "table" then return false end
    local inTransport = anyEntry(flags.extraction, function(_, entry)
        return Extraction.isCalled(entry) and (entry.phase == Extraction.INBOUND or entry.phase == Extraction.LANDED)
    end)
    local inQuarantine = anyEntry(flags[Quarantine.FLAG], function(_, entry)
        return type(entry) == "table" and entry.phase == Quarantine.RUNNING
    end)
    local inAlarm = anyEntry(flags[River.FLAG], function(_, entry)
        return River.isAlarmOn(entry, nowMinutes)
    end)
    return inTransport or inQuarantine or inAlarm
end

return SiegePlan
