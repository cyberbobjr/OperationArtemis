-- Opération Artemis : rendez-vous quotidien après un appel radio (hélicoptère de la route B, passeur de
-- la route A). Serveur ou solo. Règles pures : Artemis_Extraction (phases, transitions, zone).
-- Après l'appel, chaque jour à l'heure du créneau :
-- - le transport approche : tant qu'un joueur est au rendez-vous, bruit et vagues (Artemis_Waves) ;
-- - après la durée de tenue, il se pose et attend : un porteur du dossier qui reste boardSeconds
--   secondes dans la zone marquée embarque (fin de l'opération) ;
-- - sinon il repart ; il reviendra le lendemain, sans nouvel appel (journal si un joueur était venu).
-- La zone marquée est signalée par le mod requis batman_SignalSmoke : une fusée verte au centre et des
-- fumées vertes à côté (jamais dedans : un zombie dans la fumée perd sa cible), vues de tous les
-- joueurs ; retirées au départ ou à l'embarquement.
-- État enregistré seulement aux transitions (state.flags.extraction[def.key]).
--
-- def = { key, cfg (landing, boardRadius, holdRadius, slotHour, boardSeconds, landedMinutes, smoke,
--   waves), label, holdMinutes() , scenes = { inbound, landed, missed }, missedJournalKey,
--   clearsFog, onBoard(player) }

local Const = require "Artemis/Artemis_Const"
local Clock = require "Artemis/Artemis_Clock"
local Progress = require "Artemis/Artemis_Progress"
local Extraction = require "Artemis/Artemis_Extraction"
local Waves = require "Artemis/Artemis_Waves"
local Weather = require "Artemis/Artemis_Weather"
local SignalSmoke = require "SignalSmoke/SignalSmoke"

local Rendezvous = {}
Rendezvous.__index = Rendezvous

local FLARE_ITEM = "SignalSmoke.RoadFlareLit"
local SIGNAL_OWNER = "OperationArtemis"

function Rendezvous.new(def)
    local rendezvous = setmetatable({ def = def, boardingSince = {} }, Rendezvous)
    rendezvous.waves = Waves.new(def.cfg.waves, def.cfg.landing)
    return rendezvous
end

-- Entrée enregistrée, lue brute dans la ModData (sans copie : appel à chaque seconde).
function Rendezvous:entry(data)
    local flags = type(data) == "table" and data.flags
    local entries = type(flags) == "table" and flags.extraction
    return type(entries) == "table" and entries[self.def.key] or nil
end

function Rendezvous:timing()
    local cfg = self.def.cfg
    return { slotHour = cfg.slotHour, holdMinutes = self.def.holdMinutes(), landedMinutes = cfg.landedMinutes }
end

function Rendezvous:smokeId(index)
    return "artemis:" .. self.def.key .. ":smoke" .. index
end

function Rendezvous:flareId()
    return "artemis:" .. self.def.key .. ":flare"
end

-- Joueurs vivants au rendez-vous (le premier), et porteurs du dossier dans la zone marquée.
function Rendezvous:observe(players)
    local cfg = self.def.cfg
    local facts = { nearPlayer = nil, carriers = {} }
    for _, player in ipairs(players) do
        if not player:isDead() then
            local x, y, z = math.floor(player:getX()), math.floor(player:getY()), math.floor(player:getZ())
            if Extraction.isNearLanding(cfg, x, y) then
                facts.nearPlayer = facts.nearPlayer or player
            end
            if Extraction.isInBoardZone(cfg, x, y, z)
                and player:getInventory():containsTypeRecurse(Const.ITEM.DOSSIER) then
                facts.carriers[#facts.carriers + 1] = player
            end
        end
    end
    return facts
end

-- Fusée et fumées vertes de la zone marquée, pour la durée de l'attente.
function Rendezvous:markZone(minutes)
    local cfg = self.def.cfg
    local landing = cfg.landing
    for index, offset in ipairs(cfg.smoke) do
        SignalSmoke.start{ id = self:smokeId(index), owner = SIGNAL_OWNER, color = "green", radius = 0,
            x = landing.x + offset.dx, y = landing.y + offset.dy, z = landing.z, minutes = minutes, light = true }
    end
    local square = getCell():getGridSquare(landing.x, landing.y, landing.z)
    local flare = square and square:AddWorldInventoryItem(FLARE_ITEM, 0.5, 0.5, 0)
    local worldItem = flare and flare:getWorldItem()
    if worldItem then
        worldItem:setIgnoreRemoveSandbox(true)
    end
    SignalSmoke.start{ id = self:flareId(), owner = SIGNAL_OWNER, kind = "flare", color = "green", radius = 0,
        x = landing.x, y = landing.y, z = landing.z, minutes = minutes, light = true, sound = "SmokeBombLoop",
        itemId = flare and flare:getID() or nil }
end

function Rendezvous:clearZone()
    for index = 1, #self.def.cfg.smoke do
        SignalSmoke.stop(self:smokeId(index))
    end
    SignalSmoke.stop(self:flareId())
end

-- Transport posé : le premier porteur resté assez longtemps dans la zone embarque.
function Rendezvous:updateBoarding(carriers, nowMs)
    local stillInside = {}
    for _, player in ipairs(carriers) do
        local name = player:getUsername()
        local since = self.boardingSince[name] or nowMs
        stillInside[name] = since
        if Extraction.boardingDone(since, nowMs, self.def.cfg.boardSeconds) then
            self.boardingSince = {}
            self:clearZone()
            self.def.onBoard(player)
            return
        end
    end
    self.boardingSince = stillInside
end

function Rendezvous:setPhase(player, phase, changes, sceneId, journalKey)
    Progress.onExtractionPhase(player, phase, changes, sceneId, journalKey, self.def.key)
end

-- Transition (arrivée, pose, départ). Renvoie true si l'état a changé.
function Rendezvous:applyTransition(entry, transition, facts, times)
    local def, near = self.def, facts.nearPlayer
    if transition == "ready" then
        self:setPhase(nil, Extraction.WAITING, nil, nil)
    elseif transition == "arrive" then
        self.waves:reset()
        if def.clearsFog then
            Weather.startFog(0, times.holdMinutes + times.landedMinutes)
        end
        self:setPhase(near, Extraction.INBOUND, { slotDay = Clock.now().day, seen = near ~= nil },
            near and def.scenes.inbound or nil)
        Const.log(def.label .. " : en approche" .. (near and "" or " (personne au rendez-vous)"))
    elseif transition == "land" then
        self:markZone(times.landedMinutes)
        self:setPhase(near, Extraction.LANDED, { seen = entry.seen == true or near ~= nil },
            near and def.scenes.landed or nil)
        Const.log(def.label .. " : arrive au rendez-vous")
    elseif transition == "leave" then
        self.boardingSince = {}
        self:clearZone()
        local wasSeen = entry.seen == true
        self:setPhase(near, Extraction.WAITING, { seen = false },
            (wasSeen and near) and def.scenes.missed or nil, wasSeen and def.missedJournalKey or nil)
        Const.log(def.label .. " : reparti sans personne, retour demain")
    else
        return false
    end
    return true
end

-- Un sondage (appelant : une fois par seconde, acte III, joueurs connectés, route ouverte).
function Rendezvous:tick(data, players, minuteOfDay, nowMs)
    local entry = self:entry(data)
    if not Extraction.isCalled(entry) then return end
    local times = self:timing()
    local phase = Extraction.phaseAt(minuteOfDay, times)
    local facts = self:observe(players)
    if self:applyTransition(entry, Extraction.transition(entry, phase), facts, times) then return end
    if phase == Extraction.INBOUND and facts.nearPlayer then
        if entry.seen ~= true then
            self:setPhase(nil, Extraction.INBOUND, { seen = true }, nil)
        end
        self.waves:update(Extraction.holdFraction(minuteOfDay, times), nowMs)
    elseif phase == Extraction.LANDED then
        self:updateBoarding(facts.carriers, nowMs)
    end
end

-- Route fermée ou opération finie : l'embarquement en cours est oublié.
function Rendezvous:idle()
    self.boardingSince = {}
end

-- Route fermée pendant que le transport est appelé (zone stérilisée, transport repris par un autre
-- mod) : le créneau est refermé, la zone marquée retirée. Sans cela, la phase enregistrée garderait
-- rotor, zone et compte à rebours chez les clients, même après un rechargement.
function Rendezvous:abort(data)
    self:idle()
    if not Extraction.isCalled(self:entry(data)) then return end
    self:clearZone()
    self:setPhase(nil, Extraction.WAITING, { called = false, seen = false })
    Const.log(self.def.label .. " : route fermee, rendez-vous annule")
end

return Rendezvous
