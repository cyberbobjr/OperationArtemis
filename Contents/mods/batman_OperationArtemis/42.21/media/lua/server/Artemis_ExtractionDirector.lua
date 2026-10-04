-- Opération Artemis : extraction par hélicoptère, route B (décisions de la phase 4). Serveur ou solo.
-- Après l'appel radio (Progress.onExtractionCall), chaque jour au Knox Boundary Camp : rotor vers
-- 5 h, brouillard dissipé (le pilote a besoin de voir), zone à tenir, atterrissage, embarquement ;
-- rendez-vous manqué : retour le lendemain. Déroulé commun avec le passeur : Artemis_Rendezvous.
-- Le rotor, l'ombre, la fumée verte et le compte à rebours sont joués par chaque client d'après
-- l'état (Artemis_Heli, Artemis_ExtractionFX).
-- Après la stérilisation de la zone (option), l'armée est partie : plus de créneau.
-- Si Military Drop assure le transport (Artemis_Bridge), cette route B reste inactive : c'est son
-- hélicoptère qui emmène le joueur, et son départ termine l'opération (batman_OnExtraction).
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"
local Players = require "Artemis/Artemis_Players"
local Progress = require "Artemis/Artemis_Progress"
local Extraction = require "Artemis/Artemis_Extraction"
local Bridge = require "Artemis/Artemis_Bridge"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Rendezvous = require "Artemis/Artemis_Rendezvous"

local CHECK_INTERVAL_MS = 1000

local lastCheckMs = 0

local helicopter = Rendezvous.new({
    key = Extraction.KEY,
    cfg = Story.EXTRACTION,
    label = "extraction",
    holdMinutes = Config.extractionHoldMinutes,
    scenes = { inbound = "extraction_inbound", landed = "extraction_landed", missed = "extraction_missed" },
    missedJournalKey = "IGUI_Artemis_J_Missed",
    clearsFog = true,
    onBoard = Progress.onExtractionSuccess,
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
        helicopter:idle()
        return
    end
    if Bridge.hasTransport() or Sterilization.closesRoute(data.flags, "B") then
        helicopter:abort(data)
        return
    end
    local players = Players.list()
    if #players == 0 then return end
    helicopter:tick(data, players, minuteOfDay(), now)
end

-- Départ avec l'hélicoptère d'un autre mod (pont Military Drop) : l'opération se termine si ce joueur
-- porte le dossier, à l'acte III.
local function onForeignExtraction(username, _info)
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" or data.act ~= Const.ACT.EXFILTRATION then return end
    for _, player in ipairs(Players.list()) do
        if player:getUsername() == username and player:getInventory():containsTypeRecurse(Const.ITEM.DOSSIER) then
            Progress.onExtractionSuccess(player)
            return
        end
    end
end

Events.OnTick.Add(onTick)
Events.batman_OnExtraction.Add(onForeignExtraction)
