-- Opération Artemis : option « Stérilisation » (décisions de la phase 5). Serveur ou solo.
-- À la minute de jeu :
-- - après la lecture du dossier (acte III), si l'option est active : compte à rebours de N jours
--   (journal, pensée ; la radio et le journal rappellent l'échéance) ;
-- - à l'échéance, si l'opération n'est pas terminée : la frappe (tonnerre et éclairs synchronisés,
--   cendres, panique), puis la zone « brûlée » : brouillard de cendres entretenu, grondements au loin
--   et hordes chassées vers les joueurs par les bombardements (parfois en sprinteurs). L'hélicoptère et
--   le checkpoint sont fermés (Artemis_Sterilization.closesRoute) ; seul le fleuve reste.
-- Aucun feu ni explosion réels : triggerThunderEvent ne fait qu'un son et un éclair
-- (ThunderStorm.java:353-390), relayé aux clients par le serveur (:323-334).
-- Compteurs non sauvegardés : au rechargement, l'après-frappe reprend avec un brouillard neuf.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Clock = require "Artemis/Artemis_Clock"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Players = require "Artemis/Artemis_Players"
local Progress = require "Artemis/Artemis_Progress"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Waves = require "Artemis/Artemis_Waves"
local Weather = require "Artemis/Artemis_Weather"

-- Cendres : brouillard moyen, réimposé avant la fin du précédent.
local ASH_FOG_STRENGTH = 0.45
local ASH_FOG_MINUTES = 45
local ASH_FOG_REFRESH_MINUTES = 30
-- Grondements au loin : intervalle tiré entre ces bornes (minutes de jeu), à cette distance (cases).
local RUMBLE_MIN_MINUTES = 10
local RUMBLE_MAX_MINUTES = 40
local RUMBLE_DISTANCE = 400
-- Coups de tonnerre de la frappe, autour de chaque joueur.
local STRIKE_THUNDERS = 3
local STRIKE_DISTANCE = 250
-- Hordes chassées par les bombardements : une toutes les HORDE_MINUTES près de chaque joueur, une sur
-- HORDE_SPRINT_EVERY en sprinteurs.
local HORDE_MINUTES = 90
local HORDE_SPRINT_EVERY = 3
local HORDE = {
    label = "sterilisation",
    ringMin = 40,
    ringMax = 55,
    outfits = { "Generic01", "Generic02", "Generic03", "Generic04", "Generic05", "Tourist", "Hobbo" },
}
local HORDE_SIZE_BY_INTENSITY = { 3, 5, 7 }
-- Pas de nouvelle horde près d'un joueur déjà entouré de ce nombre de zombies (rayon HORDE_COUNT_RADIUS).
local HORDE_MAX_NEARBY = 25
local HORDE_COUNT_RADIUS = 60

local minutesSinceFog = ASH_FOG_REFRESH_MINUTES
local minutesToRumble = 0
local minutesSinceHorde = 0
local hordes = 0

local function thunderNear(x, y, distance, isStrike)
    local dx, dy = ZombRand(-distance, distance + 1), ZombRand(-distance, distance + 1)
    getClimateManager():getThunderStorm():triggerThunderEvent(math.floor(x + dx), math.floor(y + dy),
        isStrike, isStrike, true)
end

local function strike(players)
    for _, player in ipairs(players) do
        for _ = 1, STRIKE_THUNDERS do
            thunderNear(player:getX(), player:getY(), STRIKE_DISTANCE, true)
        end
    end
    Weather.startFog(ASH_FOG_STRENGTH, ASH_FOG_MINUTES)
    minutesSinceFog = 0
    minutesSinceHorde = 0
    Progress.onSterilizationStrike(players[1])
    for index = 2, #players do
        Progress.playScene(players[index], "sterilization_strike")
    end
end

local function sendHordes(players)
    hordes = hordes + 1
    local isSprint = hordes % HORDE_SPRINT_EVERY == 0
    local count = HORDE_SIZE_BY_INTENSITY[Config.dramaIntensity()] or HORDE_SIZE_BY_INTENSITY[2]
    for _, player in ipairs(players) do
        local center = { x = math.floor(player:getX()), y = math.floor(player:getY()), z = 0 }
        if not player:isDead() and Waves.countNear(center, HORDE_COUNT_RADIUS) < HORDE_MAX_NEARBY then
            Waves.new(HORDE, center):spawn(count, isSprint)
        end
    end
end

-- Zone « brûlée » : cendres, grondements, hordes.
local function aftermath(players)
    minutesSinceFog = minutesSinceFog + 1
    if minutesSinceFog >= ASH_FOG_REFRESH_MINUTES then
        minutesSinceFog = 0
        Weather.startFog(ASH_FOG_STRENGTH, ASH_FOG_MINUTES)
    end
    minutesToRumble = minutesToRumble - 1
    if minutesToRumble <= 0 then
        minutesToRumble = ZombRand(RUMBLE_MIN_MINUTES, RUMBLE_MAX_MINUTES + 1)
        local player = players[ZombRand(#players) + 1]
        thunderNear(player:getX(), player:getY(), RUMBLE_DISTANCE, ZombRand(3) == 0)
    end
    minutesSinceHorde = minutesSinceHorde + 1
    if minutesSinceHorde >= HORDE_MINUTES then
        minutesSinceHorde = 0
        sendHordes(players)
    end
end

local function onEveryOneMinute()
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" or data.act ~= Const.ACT.EXFILTRATION or not Config.isEnabled() then return end
    local players = Players.list()
    if #players == 0 then return end
    local stage = Sterilization.stage(Sterilization.entry(data.flags), Clock.now().worldHours)
    if stage == Sterilization.STRUCK then
        aftermath(players)
        return
    end
    -- Option désactivée en cours de partie : le compte à rebours est suspendu (la frappe faite reste).
    local days = Config.sterilizationDays()
    if days <= 0 then return end
    if stage == nil then
        if State.hasFlagEntry(data, "readDocs", Story.EXFIL_REVEAL_DOCUMENT) then
            Progress.onSterilizationStart(players[1], days)
        end
    elseif stage == Sterilization.DUE then
        strike(players)
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)
