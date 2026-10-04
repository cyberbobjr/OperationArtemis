-- Opération Artemis : règles des effets d'ambiance des lieux (fonctions pures).
-- Alerte du bunker (Artemis_Alarm), alarme de la base (Artemis_BaseAlarm) et brume de l'aube
-- (Artemis_Mist).

local Ambience = {}

-- États enregistrés d'une alerte (state.flags.alarms[chapitre]).
Ambience.ALARM_ON = "on"
Ambience.ALARM_DONE = "done"

-- Prochaine étape d'une alerte déclenchée par un groupe électrogène, une seule fois par partie :
--   entry           : valeur enregistrée { status, startMinutes } ou nil (jamais déclenchée)
--   isGeneratorOn   : le groupe tourne-t-il ?
--   nowMinutes      : minutes de jeu depuis le début du monde
--   maxMinutes      : durée d'un cycle de sirène
-- Renvoie « start » (déclencher), « noise » (la sirène continue), « stop » (l'arrêter) ou nil.
function Ambience.alarmStep(entry, isGeneratorOn, nowMinutes, maxMinutes)
    if entry == nil then
        return isGeneratorOn and "start" or nil
    end
    if entry.status ~= Ambience.ALARM_ON then
        return nil
    end
    if not isGeneratorOn or nowMinutes - entry.startMinutes >= maxMinutes then
        return "stop"
    end
    return "noise"
end

-- Rayon du bruit de la sirène selon l'intensité dramatique (1 à 3).
function Ambience.noiseRadius(alarm, intensity)
    return alarm.noiseRadiusByIntensity[intensity] or alarm.noiseRadiusByIntensity[1]
end

-- Alarme de la base (Artemis_BaseAlarm) -------------------------------------------------------

-- Alarme éteinte (elle peut se rallumer, contrairement à l'alerte du bunker, « done »).
Ambience.ALARM_OFF = "off"
-- Causes de l'alarme de la base : portique des archives, ou capteurs actifs hors de la fenêtre de V.
Ambience.CAUSE_GATE = "gate"
Ambience.CAUSE_SENSORS = "sensors"

local MINUTES_PER_DAY = 1440

-- La minute du jour (heure x 60 + minutes) est-elle dans la fenêtre { fromMinutes, durationMinutes } ?
-- La fenêtre peut passer minuit (23 h 15 - 1 h 15). Dividende rendu positif avant le modulo : dans
-- Kahlua, « % » garde le signe du dividende (.claude/pz-knowledge/kahlua-lua.md).
function Ambience.isInSensorWindow(minuteOfDay, window)
    return ((minuteOfDay - window.fromMinutes) + MINUTES_PER_DAY) % MINUTES_PER_DAY < window.durationMinutes
end

-- La case est-elle dans le volume { x1, y1, x2, y2, minZ, maxZ [, indoor] } ? « indoor » : seulement
-- à l'intérieur d'une pièce (le hall de surface, sans savoir de quel côté d'un mur est la case).
local function isInVolume(volume, x, y, z, isIndoor)
    return x >= volume.x1 and x <= volume.x2 and y >= volume.y1 and y <= volume.y2
        and z >= volume.minZ and z <= volume.maxZ and (not volume.indoor or isIndoor)
end

-- Le joueur (case x, y, étage z entier, dans une pièce ou non) est-il dans la base, au sens des
-- capteurs (un des volumes) ?
function Ambience.isInsideBase(volumes, x, y, z, isIndoor)
    for _, volume in ipairs(volumes) do
        if isInVolume(volume, x, y, z, isIndoor) then
            return true
        end
    end
    return false
end

-- La case est-elle dans la salle { x1, y1, x2, y2, z } ?
function Ambience.isInRoom(room, x, y, z)
    return z == room.z and x >= room.x1 and x <= room.x2 and y >= room.y1 and y <= room.y2
end

-- La fenêtre vient-elle de s'ouvrir (moins de graceMinutes minutes) ? Après un saut d'heure (sommeil),
-- la coupure des capteurs par V n'est plus un événement à commenter.
function Ambience.isWindowJustOpened(minuteOfDay, window, graceMinutes)
    return Ambience.isInSensorWindow(minuteOfDay, { fromMinutes = window.fromMinutes, durationMinutes = graceMinutes })
end

-- Cause voulue pour l'alarme de la base, ou nil (éteinte) : l'évasion en cours (portique) prime sur
-- les capteurs ; les capteurs sonnent tant qu'un joueur est dans la base hors de la fenêtre.
function Ambience.baseAlarmCause(isTrialRunning, isAnyoneInsideOutOfWindow)
    if isTrialRunning then
        return Ambience.CAUSE_GATE
    end
    if isAnyoneInsideOutOfWindow then
        return Ambience.CAUSE_SENSORS
    end
    return nil
end

-- L'heure (heures décimales, 0 à 24) est-elle dans la fenêtre de l'aube, de dawn + fromHours à
-- dawn + toHours ? L'aube (5 h à 7 h selon la saison) ne franchit pas minuit.
function Ambience.isInDawnWindow(timeOfDay, dawn, fromHours, toHours)
    return timeOfDay >= dawn + fromHours and timeOfDay <= dawn + toHours
end

return Ambience
