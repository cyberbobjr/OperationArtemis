-- Opération Artemis : conduit l'acte II (l'enquête). Serveur ou solo.
-- - Pose des objets : à l'événement vanilla LoadChunk (une fois par chunk de 8x8 cases, à la fin de
--   son chargement, après les histoires de bâtiment et le butin, IsoChunk.java:3612).
-- - Chaque minute de jeu, seulement pour le chapitre en cours et les joueurs proches de son lieu
--   (test de distance d'abord) :
--   - pensée d'arrivée, la première fois qu'un joueur approche de l'entrée ;
--   - nouvelle tentative des poses en attente de TOUS les lieux révélés (pas seulement le chapitre en
--     cours), pour un joueur à moins de 80 cases (voir Artemis_Placement) ;
--   - objectif du chapitre : aucun événement ne signale qu'un objet a été pris, qu'un document a été
--     lu ou que le courant est revenu ;
--   - aide dite par le personnage si l'objectif n'est pas atteint (une fois par partie).
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Players = require "Artemis/Artemis_Players"
local Goals = require "Artemis/Artemis_Goals"
local Placement = require "Artemis/Artemis_Placement"
local Progress = require "Artemis/Artemis_Progress"

-- Chapitre en cours, lu directement dans la ModData (sans copie de l'état) : ces appels sont fréquents.
local function currentChapterData()
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" or data.act ~= Const.ACT.INVESTIGATION or data.chapter == nil then
        return nil, nil
    end
    return data.chapter, data
end

-- Distance (cases) au site en deçà de laquelle une pose en attente est retentée chaque minute. Plus
-- large que le rayon de l'objectif : une pose hors de la vue du joueur (anneau de zombies, patient
-- zéro) attend qu'il s'éloigne un peu, par exemple après une téléportation de debug sur le lieu.
local PENDING_RETRY_RADIUS = 80

-- Chapitres dont le lieu est révélé mais dont des poses attendent encore : chapitre en cours, et
-- chapitres terminés dont une pose n'a pas pu se faire à temps (par exemple la mise en scène d'un
-- lieu quitté avant qu'elle soit prête). Leurs effets restent actifs après la fin du chapitre.
local function pendingChapters(data)
    local pending = {}
    if type(data) ~= "table" or type(data.revealed) ~= "table" or data.act < Const.ACT.INVESTIGATION then
        return pending
    end
    for _, chapterId in ipairs(data.revealed) do
        if Story.get(chapterId) and not Story.isFullyPlaced(chapterId, data.placed) then
            pending[#pending + 1] = chapterId
        end
    end
    return pending
end

local function onLoadChunk(_chunk)
    if not Config.isEnabled() then return end
    for _, chapterId in ipairs(pendingChapters(ModData.get(Const.MODDATA_KEY))) do
        Placement.ensure(chapterId)
    end
end

-- Chaque minute : poses en attente des lieux révélés, pour un joueur à moins de PENDING_RETRY_RADIUS
-- cases (LoadChunk ne se redéclenche pas pour un lieu déjà chargé).
local function retryPendingPlacements(players)
    for _, chapterId in ipairs(pendingChapters(ModData.get(Const.MODDATA_KEY))) do
        local site = Story.get(chapterId).site
        for _, player in ipairs(players) do
            if Players.isNear(player, site, PENDING_RETRY_RADIUS) then
                Placement.ensure(chapterId)
                break
            end
        end
    end
end

-- Première aide qui s'applique : condition « when » (facultative) remplie et « unless » non remplie.
-- Les aides restent dans l'ordre : tant que la première qui s'applique a déjà été dite, les suivantes
-- attendent (retour du test : sinon l'aide « radio » suivait l'aide « registre » une minute après,
-- alors que le registre n'était pas encore lu). Une aide soumise à « when » placée en tête ne
-- s'applique qu'à son moment (par exemple après la bande).
local function pendingHint(chapter, player, state)
    for _, hint in ipairs(chapter.hints or {}) do
        if (hint.when == nil or Goals.isMet(hint.when, player, state))
            and not Goals.isMet(hint.unless, player, state) then
            return hint
        end
    end
    return nil
end

-- Minutes de jeu passées près du site du chapitre en cours (mémoire de session) : une aide n'est
-- dite qu'après HINT_DELAY_MINUTES, pour laisser au joueur le temps de chercher (et ne pas couvrir
-- la pensée d'arrivée).
local HINT_DELAY_MINUTES = 3
local nearSite = { chapterId = nil, minutes = 0 }

local function countNearMinute(chapterId)
    if nearSite.chapterId ~= chapterId then
        nearSite.chapterId, nearSite.minutes = chapterId, 0
    end
    nearSite.minutes = nearSite.minutes + 1
    return nearSite.minutes
end

-- Traite un joueur proche du site. Renvoie true si l'état a changé (on s'arrête pour cette minute).
local function handleNearSite(chapter, player, minutesNear)
    local state = Store.load()
    if Goals.isMet(chapter.goal, player, state) then
        Progress.completeChapter(player)
        return true
    end
    local hint = minutesNear >= HINT_DELAY_MINUTES and pendingHint(chapter, player, state)
    if hint and not State.hasFlagEntry(state, "hinted", hint.scene) then
        Progress.onHint(player, hint.scene)
        return true
    end
    return false
end

local function onEveryOneMinute()
    if not Config.isEnabled() then return end
    local players = Players.list()
    retryPendingPlacements(players)
    local chapterId, data = currentChapterData()
    local chapter = Story.get(chapterId)
    if chapter == nil then return end
    local hasArrived = type(data.flags) == "table" and type(data.flags.arrived) == "table"
        and data.flags.arrived[chapterId] == true

    local isRestoreDone = false
    local retryRadius = math.max(chapter.goalRadius, PENDING_RETRY_RADIUS)
    for _, player in ipairs(players) do
        if not hasArrived and Players.isNear(player, chapter.entrance, Story.ARRIVAL_RADIUS) then
            Progress.onArrive(player, chapterId)
            return
        end
        -- Une fois par minute : objet indispensable perdu (reposé à la minute suivante).
        if not isRestoreDone and Players.isNear(player, chapter.site, retryRadius) then
            isRestoreDone = true
            Placement.restoreLost(chapterId, players)
        end
        if Players.isNear(player, chapter.site, chapter.goalRadius) then
            if handleNearSite(chapter, player, countNearMinute(chapterId)) then
                return
            end
        end
    end
end

Events.LoadChunk.Add(onLoadChunk)
Events.EveryOneMinute.Add(onEveryOneMinute)
