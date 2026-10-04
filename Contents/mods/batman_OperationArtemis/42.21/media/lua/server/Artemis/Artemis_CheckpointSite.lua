-- Opération Artemis : objets du checkpoint de la route C (Story.CHECKPOINT), serveur ou solo.
-- - Enclos : grillage vanilla posé en simple IsoObject (comme les cages du Knox Boundary Camp) ; un
--   grillage n'est plié que par FenceThumpersRequired zombies (50 par défaut). Murs nord et ouest :
--   chacun appartient à sa propre case.
-- - Portail : IsoThumpable porte, verrouillé par une clé que personne n'a ; un joueur sans clé est
--   bloqué des deux côtés (IsoThumpable.java:1137-1153). Sur le serveur, setLockedByKey ne transmet
--   rien (:2101-2111) : sync() envoie ouverture, verrou et keyId (:1671-1686). Une IsoDoor « grillage »
--   n'aurait que 100 PV (IsoDoor.java:635-637).
-- - Poste de test : caisse militaire (kit de prélèvement de ZVirusVaccine s'il est actif) et
--   spectromètre de ce mod à côté (son test n'est permis qu'à une case d'un spectromètre).
-- - Haut-parleur : radio de campagne posée dans l'enclos, à pile, que le client fait parler.
-- - Détenu mort, relevé à la 20e heure (createRandomDeadBody puis reanimateNow ; sans effet si
--   HoursForCorpseRemoval <= 0, staging-effects.md).
-- - Barrage vanilla du pont : un passage s'ouvre (objets retirés) après le test final négatif.

local Const = require "Artemis/Artemis_Const"
local Placement = require "Artemis/Artemis_Placement"

local Site = {}

local DETAINEE_BLOOD = 3
local CRAWLER_CHANCE = 0
local SPEAKER_VOLUME = 0.8
local SPEAKER_FREE_MIN, SPEAKER_FREE_MAX = 88000, 108000

local function square(x, y, z)
    return getCell():getGridSquare(x, y, z)
end

-- Toutes les cases du site sont chargées : les quatre coins de l'enclos avec ses murs est et sud (il
-- peut toucher quatre chunks), le portail, le poste, le spectromètre et le haut-parleur.
function Site.isLoaded(cfg)
    local pen = cfg.pen
    local points = {
        { x = pen.x1, y = pen.y1, z = pen.z }, { x = pen.x2 + 1, y = pen.y1, z = pen.z },
        { x = pen.x1, y = pen.y2 + 1, z = pen.z }, { x = pen.x2 + 1, y = pen.y2 + 1, z = pen.z },
        cfg.gate, cfg.post, cfg.spectrometer, cfg.speaker, cfg.detainee,
    }
    for _, point in ipairs(points) do
        if square(point.x, point.y, point.z) == nil then
            return false
        end
    end
    return true
end

local function addObject(sq, sprite)
    local object = IsoObject.new(getCell(), sq, sprite)
    sq:transmitAddObjectToSquare(object, -1)
    return object
end

local function buildFence(cfg)
    local pen, fence, gate = cfg.pen, cfg.fence, cfg.gate
    local z = pen.z
    -- Murs nord : bord nord de l'enclos et bord sud (mur nord de la rangée suivante).
    for x = pen.x1, pen.x2 do
        local sprite = fence.north[(x - pen.x1) % 2 + 1]
        if x ~= pen.x1 then
            addObject(square(x, pen.y1, z), sprite)
        end
        addObject(square(x, pen.y2 + 1, z), sprite)
    end
    -- Murs ouest : bord ouest (sauf le portail) et bord est (mur ouest de la colonne suivante).
    for y = pen.y1, pen.y2 do
        local sprite = fence.west[(y - pen.y1) % 2 + 1]
        if y ~= pen.y1 and y ~= gate.y then
            addObject(square(pen.x1, y, z), sprite)
        end
        addObject(square(pen.x2 + 1, y, z), sprite)
    end
    -- Angle nord-ouest : un seul objet porte les deux murs.
    addObject(square(pen.x1, pen.y1, z), fence.corner)
end

local function buildGate(cfg)
    local gate = cfg.gate
    local sq = square(gate.x, gate.y, gate.z)
    local door = IsoThumpable.new(getCell(), sq, gate.closed, gate.open, false, {})
    door:setIsDoor(true)
    door:setIsDismantable(false)
    door:setIsThumpable(false)
    door:setKeyId(gate.keyId)
    door:setLockedByKey(true)
    sq:AddSpecialObject(door)
    door:transmitCompleteItemToClients()
    return door
end

local function buildPost(cfg, withVaccine)
    local post = cfg.post
    local container = Placement.createContainer(square(post.x, post.y, post.z), post.sprite)
    if container and withVaccine then
        for _, fullType in ipairs(cfg.testKit) do
            Placement.addToContainer(container, instanceItem(fullType))
        end
    end
    if withVaccine then
        local spectrometer = cfg.spectrometer
        addObject(square(spectrometer.x, spectrometer.y, spectrometer.z), spectrometer.sprite)
    end
end

local function buildSpeaker(cfg)
    local speaker = cfg.speaker
    local sq = square(speaker.x, speaker.y, speaker.z)
    local radio = IsoRadio.new(getCell(), sq, getSprite(speaker.sprite))
    local data = radio:getDeviceData()
    data:setIsBatteryPowered(true)
    data:setHasBattery(true)
    data:setPower(1.0)
    data:setDeviceVolumeRaw(SPEAKER_VOLUME)
    data:setTurnedOnRaw(true)
    -- Fréquence qu'aucune station n'utilise (ZomboidRadio.java:179-184) : sinon le haut-parleur
    -- diffuserait une station vanilla tirée au hasard par le constructeur (IsoWaveSignal.java:79-83).
    local zomboidRadio = getZomboidRadio()
    if zomboidRadio then
        data:setChannelRaw(zomboidRadio:getRandomFrequency(SPEAKER_FREE_MIN, SPEAKER_FREE_MAX))
    end
    sq:transmitAddObjectToSquare(radio, -1)
end

-- Pose tout le site (une fois par partie ; l'appelant tient le registre). withVaccine : ZVirusVaccine
-- est actif (kit et spectromètre).
function Site.build(cfg, withVaccine)
    buildFence(cfg)
    buildGate(cfg)
    buildPost(cfg, withVaccine)
    buildSpeaker(cfg)
    Const.log("checkpoint : enclos, portail, poste de test et haut-parleur poses"
        .. (withVaccine and " (protocole ZVirusVaccine)" or ""))
end

-- Portail du site, ou nil (case non chargée, portail détruit).
function Site.findGate(cfg)
    local gate = cfg.gate
    local sq = square(gate.x, gate.y, gate.z)
    if sq == nil then return nil end
    local objects = sq:getSpecialObjects()
    for index = 0, objects:size() - 1 do
        local object = objects:get(index)
        if instanceof(object, "IsoThumpable") and object:isDoor() and object:getKeyId() == gate.keyId then
            return object
        end
    end
    return nil
end

-- Verrouille (fermé) ou déverrouille le portail. Renvoie true si quelque chose a changé.
function Site.setGateLocked(door, isLocked)
    if door:isLockedByKey() == isLocked then
        return false
    end
    if isLocked and door:IsOpen() then
        door:ToggleDoorSilent()
    end
    door:setLockedByKey(isLocked)
    if isServer() then
        door:sync()
    end
    return true
end

-- Case du poste de test (caisse), ou nil si elle n'est pas chargée.
function Site.postSquare(cfg)
    local post = cfg.post
    return square(post.x, post.y, post.z)
end

-- Détenu mort dans l'enclos (s'il n'y a pas déjà un corps sur sa case).
function Site.placeDetainee(cfg)
    local detainee = cfg.detainee
    local sq = square(detainee.x, detainee.y, detainee.z)
    if sq == nil or sq:getDeadBody() ~= nil then return end
    local body = RandomizedWorldBase.createRandomDeadBody(sq, IsoDirections.getRandom(), DETAINEE_BLOOD,
        CRAWLER_CHANCE, detainee.outfit)
    if body then
        body:setFakeDead(false)
    end
end

-- Le détenu se relève. Renvoie true s'il y avait un corps.
function Site.reanimateDetainee(cfg)
    local detainee = cfg.detainee
    local sq = square(detainee.x, detainee.y, detainee.z)
    local body = sq and sq:getDeadBody()
    if body == nil then return false end
    body:reanimateNow()
    return true
end

-- Ouvre le passage dans le barrage vanilla : retire les objets de barrage des cases du passage
-- chargées. Renvoie le nombre d'objets retirés (0 si déjà ouvert ou non chargé).
function Site.openLane(cfg)
    local lane = cfg.lane
    local wanted = {}
    for _, sprite in ipairs(lane.sprites) do
        wanted[sprite] = true
    end
    local removed = 0
    for x = lane.x1, lane.x2 do
        for y = lane.y1, lane.y2 do
            local sq = square(x, y, lane.z)
            if sq then
                local objects = sq:getObjects()
                for index = objects:size() - 1, 0, -1 do
                    local object = objects:get(index)
                    local sprite = object:getSprite()
                    if sprite and wanted[sprite:getName()] then
                        sq:transmitRemoveItemFromSquare(object)
                        removed = removed + 1
                    end
                end
            end
        end
    end
    return removed
end

return Site
