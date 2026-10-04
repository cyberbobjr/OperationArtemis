-- Opération Artemis : pilote les sièges automatiques du mod Siege Night (Workshop 3669589584), s'il est actif.
-- Artemis ne modifie jamais les options enregistrées de Siege Night. Il masque temporairement, dans la
-- table Lua SandboxVars.SiegeNight, les interrupteurs que Siege Night relit en direct (SN.getSandbox,
-- SiegeNight_Shared.lua:168). Les options enregistrées sont écrites depuis les valeurs Java
-- (map_sand.bin, écran admin), pas depuis cette table : le masquage n'est pas sauvegardé et il est
-- réappliqué à chaque chargement, puis chaque minute de jeu (un admin MP qui applique des
-- options réécrit SandboxVars, GameServer.java:1637).
-- Phase 6 (décisions du 2026-10-02) : après la lecture du dossier, l'intervalle entre deux sièges est
-- divisé par deux (FrequencyDays et FrequencyDaysMax, relus en direct par SN.getNextFrequency,
-- SiegeNight_Shared.lua:258-265) et un siège est programmé le soir même dans sa ModData
-- (nextSiegeDay ; avertissement de Siege Night puis siège à l'heure de début) ; les sièges sont
-- suspendus pendant les épreuves de l'acte III comme pendant l'évasion. Règles : Artemis_SiegePlan.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Store = require "Artemis/Artemis_Store"
local Story = require "Artemis/Artemis_Story"
local Trial = require "Artemis/Artemis_Trial"
local State = require "Artemis/Artemis_State"
local Clock = require "Artemis/Artemis_Clock"
local SiegePlan = require "Artemis/Artemis_SiegePlan"
local Players = require "Artemis/Artemis_Players"

-- Valeurs de l'option sandbox SiegeNightControl.
local MODE = {
    UNTOUCHED = 1,             -- ne pas toucher à Siege Night
    DURING_INVESTIGATION = 2,  -- suspendre pendant les actes I et II
    UNTIL_FILE = 3,            -- suspendre dès le début de la partie, jusqu'au dossier (acte III)
}

-- Interrupteurs masqués : sièges automatiques et mini-hordes (indépendants dans Siege Night).
local SWITCHES = { "Enabled", "MiniHorde_Enabled" }

-- Le rappel onSiegeStart n'est enregistré qu'une fois (variable locale, pas un champ de fonction).
local isSiegeCallbackRegistered = false

local function shouldSuspend(mode, act)
    if mode == MODE.DURING_INVESTIGATION then
        return act == Const.ACT.SIGNAL or act == Const.ACT.INVESTIGATION
    end
    if mode == MODE.UNTIL_FILE then
        return act < Const.ACT.EXFILTRATION
    end
    return false
end

-- Valeur choisie par le joueur, lue dans les options enregistrées (Java) : jamais masquée par
-- Artemis, et à jour après une modification par un admin.
local function savedValue(key)
    local option = getSandboxOptions():getOptionByName("SiegeNight." .. key)
    return option and option:getValue()
end

-- Valeurs voulues dans SandboxVars.SiegeNight : interrupteurs coupés pendant une suspension,
-- fréquence divisée par deux après le dossier, sinon les valeurs du joueur.
local function wantedValues(isSuspended, isFileRead)
    local values = {}
    for _, key in ipairs(SWITCHES) do
        values[key] = (not isSuspended) and savedValue(key) or false
    end
    -- Fréquence pilotée seulement si les deux options existent (sinon on n'efface rien).
    local days, maxDays = savedValue("FrequencyDays"), savedValue("FrequencyDaysMax")
    if days == nil or maxDays == nil then
        return values
    end
    if isFileRead then
        days, maxDays = SiegePlan.halvedFrequency(days, maxDays)
    end
    values.FrequencyDays, values.FrequencyDaysMax = days, maxDays
    return values
end

local function isApplied(vars, values)
    for key, value in pairs(values) do
        if vars[key] ~= value then
            return false
        end
    end
    return true
end

local function siegeNight()
    return require "SiegeNight_Shared"
end

-- Ne jamais couper Siege Night pendant un siège : son état resterait bloqué. On réessaie plus tard.
-- Pendant une épreuve (quelques heures), l'état d'avertissement (journée d'un siège) peut être coupé :
-- le tick de Siege Night s'arrête et garde l'état, le siège part à la reprise
-- (SiegeNight_Server.lua:2388, 2565-2568).
local function isSiegeIdle(acceptWarning)
    local SN = siegeNight()
    local data = SN and SN.getWorldData and SN.getWorldData()
    return data == nil or data.siegeState == nil or data.siegeState == SN.STATE_IDLE
        or (acceptWarning and data.siegeState == SN.STATE_WARNING)
end

-- Siege Night ne fait plus avancer sa date de siège quand il est coupé. Une date dépassée est
-- repoussée d'un cycle, comme le fait Siege Night lui-même au chargement (SiegeNight_Server.lua:2609) :
-- pas de siège de rattrapage au rétablissement, et pas d'annonce « ce soir » pendant la suspension.
local function postponeOverdueSiege()
    local SN = siegeNight()
    local data = SN and SN.getWorldData and SN.getWorldData()
    if not data or data.siegeState ~= SN.STATE_IDLE or type(data.nextSiegeDay) ~= "number" then return end
    local today = math.floor(SN.getActualDay())
    if not SiegePlan.isOverdue(data.nextSiegeDay, today, SN.isSiegeTime(SN.getCurrentHour())) then return end
    data.nextSiegeDay = today + math.max(1, SN.getNextFrequency())
    if isServer() then
        ModData.transmit("SiegeNight")
    end
end

-- Un siège lancé à la main pendant la suspension (commande, vote, debug : ces chemins ne vérifient pas
-- Enabled) ne progresserait jamais. On rouvre donc Siege Night le temps du siège ; refresh() le
-- suspend de nouveau une fois le siège terminé.
local function onSiegeStart()
    local vars = SandboxVars and SandboxVars.SiegeNight
    if vars and vars.Enabled == false and savedValue("Enabled") == true then
        vars.Enabled = true
        Const.log("Siege Night : siege lance pendant la suspension, sieges rouverts jusqu'a sa fin")
    end
end

local function registerSiegeCallback()
    if isSiegeCallbackRegistered then return end
    local SN = siegeNight()
    if SN and SN.onSiegeStart then
        SN.onSiegeStart(onSiegeStart)
        isSiegeCallbackRegistered = true
    end
end

-- Applique la règle pour l'acte courant. Idempotent : appelé au chargement puis chaque minute (le
-- début de l'évasion suspend les sièges sans attendre).
-- Siège du soir de la lecture du dossier, une seule fois par partie : Siege Night le prépare lui-même
-- (avertissement dans la journée, siège à l'heure de début). Écrit seulement quand il est au repos.
-- Un siège déjà annoncé ou en cours au moment de la lecture tient lieu de siège du dossier (pas deux
-- nuits de suite) : il est enregistré sans annonce.
local function scheduleFileSiege(state)
    if State.flagValue(state, SiegePlan.FLAG, SiegePlan.KEY) ~= nil then return end
    local SN = siegeNight()
    local data = SN and SN.getWorldData and SN.getWorldData()
    if not data then return end
    local Progress = require "Artemis/Artemis_Progress"
    local nowHours = Clock.now().worldHours
    if data.siegeState ~= SN.STATE_IDLE then
        Progress.onFileSiegeScheduled(nil, { day = data.nextSiegeDay, untilHours = nowHours, current = true })
        Const.log("Siege Night : siege deja en cours, compte comme siege du dossier")
        return
    end
    local time = getGameTime()
    local hour = time:getHour() + time:getMinutes() / 60
    local startHour = SN.getSiegeStartHour()
    local today = math.floor(SN.getActualDay())
    local day = SiegePlan.siegeDay(today, hour, startHour, SN.isSiegeTime(time:getHour()))
    data.nextSiegeDay = SiegePlan.closerDate(data.nextSiegeDay, day)
    if isServer() then
        ModData.transmit("SiegeNight")
    end
    -- Heures de monde (sans le décalage « mois depuis l'apocalypse » du jour de Siege Night).
    local untilHours = SiegePlan.warningUntil(nowHours, hour, startHour, data.nextSiegeDay == today,
        SN.getNightDuration())
    local players = Players.list()
    Progress.onFileSiegeScheduled(players[1], { day = data.nextSiegeDay, untilHours = untilHours })
    for index = 2, #players do
        Progress.playScene(players[index], "siege_warning")
    end
    Const.log("Siege Night : siege programme le soir du jour " .. tostring(data.nextSiegeDay) .. " (dossier lu)")
end

-- Applique la règle pour l'acte courant. Idempotent : appelé au chargement puis chaque minute (le
-- début d'une épreuve suspend les sièges sans attendre).
local function refresh()
    -- SandboxVars.SiegeNight n'existe que si Siege Night est actif.
    local vars = SandboxVars and SandboxVars.SiegeNight
    if not vars then return end
    -- Options introuvables (autre version de Siege Night) : ne rien piloter plutôt que d'effacer une valeur.
    for _, key in ipairs(SWITCHES) do
        if savedValue(key) == nil then return end
    end
    registerSiegeCallback()

    local state = Store.load()
    local act = state.act
    local mode = Config.siegeNightMode()
    local isPiloted = Config.isEnabled() and mode ~= MODE.UNTOUCHED
    local isFileRead = isPiloted and act == Const.ACT.EXFILTRATION
        and State.hasFlagEntry(state, "readDocs", Story.EXFIL_REVEAL_DOCUMENT)
    -- Pendant une épreuve du mod (évasion du labo, épreuves de l'acte III), pas de siège par-dessus.
    -- Mod désactivé en cours de partie : une suspension en place est levée (sinon elle durerait
    -- jusqu'au redémarrage).
    local nowMinutes = math.floor(Clock.now().worldHours * 60)
    local isTrial = Trial.isRunning(state.flags, Story.EXIT_CHAPTER)
        or (act == Const.ACT.EXFILTRATION and SiegePlan.isExitTrialRunning(state.flags, nowMinutes))
    local isSuspended = Config.isEnabled() and (shouldSuspend(mode, act) or (isPiloted and isTrial))
    if isSuspended then
        postponeOverdueSiege()
    end
    local values = wantedValues(isSuspended, isFileRead)
    local isTrialOnly = isSuspended and not shouldSuspend(mode, act)
    if not isApplied(vars, values) and not (isSuspended and not isSiegeIdle(isTrialOnly)) then
        for key, value in pairs(values) do
            vars[key] = value
        end
        if not isSuspended then
            postponeOverdueSiege()
        end
        Const.log("Siege Night : sieges automatiques " .. (isSuspended and "suspendus" or "retablis")
            .. (isFileRead and ", frequence divisee par deux" or "") .. " (acte " .. tostring(act) .. ")")
    end
    if isFileRead and not isSuspended and vars.Enabled == true then
        scheduleFileSiege(state)
    end
end

Events.OnInitGlobalModData.Add(refresh)
Events.EveryOneMinute.Add(refresh)
