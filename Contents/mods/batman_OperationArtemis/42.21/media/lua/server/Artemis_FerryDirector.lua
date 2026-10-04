-- Opération Artemis : le passeur de V, route A sans mod de bateau (décisions de la phase 5). Serveur ou
-- solo. Après l'appel au talkie depuis le quai de Brandenburg (Progress.onFerryCall : groupe du pont
-- Kinsella coupé, sinon le passeur refuse de passer devant les projecteurs), chaque jour à l'aube : le
-- passeur approche, il faut tenir le quai ; il accoste, fumée verte sur le ponton ; rester au bout du
-- ponton avec le dossier pour embarquer (fondu, fin de l'opération). Rendez-vous manqué : il revient le
-- lendemain. Déroulé commun avec l'hélicoptère : Artemis_Rendezvous.
-- Aucun son vanilla de bateau (relevé du 2026-10-01) : le moteur est un son du mod, joué par chaque
-- client d'après la phase (Artemis_FerryFX).
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local Players = require "Artemis/Artemis_Players"
local Progress = require "Artemis/Artemis_Progress"
local Rendezvous = require "Artemis/Artemis_Rendezvous"

local CHECK_INTERVAL_MS = 1000

local lastCheckMs = 0

local ferry = Rendezvous.new({
    key = Story.FERRY.key,
    cfg = Story.FERRY,
    label = "passeur",
    holdMinutes = Config.extractionHoldMinutes,
    scenes = { inbound = "ferry_inbound", landed = "ferry_landed", missed = "ferry_missed" },
    missedJournalKey = "IGUI_Artemis_J_FerryMissed",
    clearsFog = false,
    onBoard = function(player) Progress.onExit(player, "A", "ferry") end,
})

local function minuteOfDay()
    local time = getGameTime()
    return time:getHour() * 60 + time:getMinutes()
end

local function onTick()
    local now = getTimestampMs()
    if now - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = now
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" or data.act ~= Const.ACT.EXFILTRATION or not Config.isEnabled() then
        ferry:idle()
        return
    end
    local players = Players.list()
    if #players == 0 then return end
    ferry:tick(data, players, minuteOfDay(), now)
end

Events.OnTick.Add(onTick)
