-- Opération Artemis : option « Stérilisation » (fonctions pures, décisions de la phase 5).
-- Option sandbox SterilizationDays (0 = désactivée, par défaut). Après la lecture du dossier, l'armée
-- annonce la stérilisation de la zone dans N jours. À l'échéance, la zone est « brûlée » de façon
-- simulée : le joueur survit, mais l'armée est partie (hélicoptère et checkpoint fermés) ; seul le
-- fleuve reste. Aucun feu ni explosion réels : la carte n'est pas touchée.
-- État : state.flags.sterilization.zone = { deadlineHours, struck } (heures de monde).

local Sterilization = {}

Sterilization.FLAG = "sterilization"
Sterilization.KEY = "zone"

Sterilization.COUNTDOWN = "countdown"
-- Échéance passée, frappe pas encore jouée.
Sterilization.DUE = "due"
Sterilization.STRUCK = "struck"

local HOURS_PER_DAY = 24

-- Routes fermées après la frappe : l'armée est partie.
local CLOSED_ROUTES = { B = true, C = true }

-- Entrée du compte à rebours lancé maintenant (nowHours : heures de monde).
function Sterilization.newEntry(nowHours, days)
    return { deadlineHours = nowHours + days * HOURS_PER_DAY, struck = false }
end

-- Étape : nil (pas de compte à rebours), COUNTDOWN, DUE ou STRUCK.
function Sterilization.stage(entry, nowHours)
    if type(entry) ~= "table" or type(entry.deadlineHours) ~= "number" then
        return nil
    end
    if entry.struck == true then
        return Sterilization.STRUCK
    end
    if nowHours >= entry.deadlineHours then
        return Sterilization.DUE
    end
    return Sterilization.COUNTDOWN
end

-- Jours restants, arrondis au-dessus (1 pendant le dernier jour), jamais négatifs.
function Sterilization.daysLeft(entry, nowHours)
    return math.max(0, math.ceil((entry.deadlineHours - nowHours) / HOURS_PER_DAY))
end

local function entryOf(flags)
    local entries = type(flags) == "table" and flags[Sterilization.FLAG]
    return type(entries) == "table" and entries[Sterilization.KEY] or nil
end

-- Entrée de l'état (state.flags), ou nil.
function Sterilization.entry(flags)
    return entryOf(flags)
end

function Sterilization.isStruck(flags)
    local entry = entryOf(flags)
    return type(entry) == "table" and entry.struck == true
end

-- La route (« A », « B », « C ») est-elle fermée par la stérilisation ?
function Sterilization.closesRoute(flags, route)
    return CLOSED_ROUTES[route] == true and Sterilization.isStruck(flags)
end

return Sterilization
