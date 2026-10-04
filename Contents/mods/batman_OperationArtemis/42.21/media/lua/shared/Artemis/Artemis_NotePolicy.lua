-- Opération Artemis : décision d'apparition de la note Artemis.
-- Fonctions pures : aucun accès au moteur ; le hasard (roll) et l'heure (now) sont fournis par l'appelant.

local Const = require "Artemis/Artemis_Const"
local Clock = require "Artemis/Artemis_Clock"
local State = require "Artemis/Artemis_State"

local NotePolicy = {}

-- Une note peut-elle apparaître maintenant ?
-- now = { day = <jour de jeu>, worldHours = <heures depuis le début> }
-- rules = Config.noteRules()
function NotePolicy.isEligible(state, now, rules)
    if state.act ~= Const.ACT.DORMANT then
        return false
    end
    if now.day < rules.minDay then
        return false
    end
    local spawnedHour = state.flags.noteSpawnedHour
    if spawnedHour == nil then
        return true
    end
    -- Une note est déjà apparue sans être lue : réapparition seulement après le délai choisi.
    if rules.respawnDays <= 0 then
        return false
    end
    return now.worldHours - spawnedHour >= rules.respawnDays * Clock.HOURS_PER_DAY
end

-- Enregistre la mort d'un zombie militaire éligible et décide si la note apparaît sur lui.
-- roll : entier tiré dans [0, 100[. Renvoie (apparaît, nouvelÉtat).
function NotePolicy.onMilitaryKill(state, now, rules, roll)
    local nextState = State.copy(state)
    local kills = (nextState.flags.militaryKills or 0) + 1
    local isGuaranteed = rules.guaranteeKills > 0 and kills >= rules.guaranteeKills
    if roll < rules.chance or isGuaranteed then
        nextState.flags.militaryKills = 0
        nextState.flags.noteSpawnedHour = now.worldHours
        return true, nextState
    end
    nextState.flags.militaryKills = kills
    return false, nextState
end

return NotePolicy
