-- Opération Artemis : pose les objets d'un chapitre dans le monde, une seule fois par partie.
-- Serveur ou solo. Appelé par Artemis_Director (événement LoadChunk, et chaque minute pour un joueur
-- proche du lieu) et par Artemis_Progress (ouverture d'un chapitre dont le lieu est déjà chargé).
--
-- Risque à éviter : une « histoire » de bâtiment vanilla (RandomizedBuildingBase.ChunkLoaded) peut
-- vider les conteneurs après notre pose. Elle ne s'applique qu'une fois, quand le bâtiment est
-- entièrement chargé, et jamais si l'une de ses pièces est déjà explorée. On pose donc quand :
--   - le bâtiment est entièrement chargé (l'histoire est alors déjà passée), ou
--   - l'une de ses pièces est explorée (l'histoire ne passera plus).
-- La seconde condition couvre les bâtiments plus larges que la zone chargée autour du joueur
-- (grille de 19 chunks au plus en solo, IsoChunkMap.java:139), comme le laboratoire de la base
-- secrète : ils ne sont jamais « entièrement chargés ».

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Players = require "Artemis/Artemis_Players"
local Ring = require "Artemis/Artemis_Ring"
local Tracking = require "Artemis/Artemis_Tracking"
local Tracked = require "Artemis/Artemis_Tracked"
local ComputerMod = require "Artemis/Artemis_ComputerMod"
local Plot = require "Artemis/Artemis_Plot"

local Placement = {}

-- Marque posée dans la ModData des corps du mod (identifiant du chapitre), pour les retrouver (2b).
local CORPSE_MARK = "batman_ArtemisCorpse"
local CORPSE_BLOOD = 2
local CORPSE_CRAWLER_CHANCE = 0
-- Faux morts : soldats (pas de femmes dans les tenues militaires vanilla), santé normale.
local FAKE_DEAD_FEMALE_CHANCE = 0
local FAKE_DEAD_HEALTH = 1.0

local function hasExploredRoom(buildingDef)
    local rooms = buildingDef:getRooms()
    for index = 0, rooms:size() - 1 do
        if rooms:get(index):isExplored() then
            return true
        end
    end
    return false
end

-- Case chargée et à l'abri des histoires de bâtiment (voir l'en-tête), sinon nil.
local function readySquare(x, y, z)
    local square = getCell():getGridSquare(x, y, z)
    if square == nil then
        return nil
    end
    local building = square:getBuilding()
    if building == nil then
        return square
    end
    local def = building:getDef()
    if def:isFullyStreamedIn() or hasExploredRoom(def) then
        return square
    end
    return nil
end


-- Premier conteneur d'un des types voulus sur la case, avec l'objet qui le porte.
local function findContainer(square, types)
    local wanted = {}
    for _, containerType in ipairs(types) do
        wanted[containerType] = true
    end
    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local object = objects:get(index)
        for slot = 0, object:getContainerCount() - 1 do
            local container = object:getContainerByIndex(slot)
            if wanted[container:getType()] then
                return container, object
            end
        end
    end
    return nil, nil
end

-- Meuble attendu absent (déplacé, détruit) : on en crée un. Constructeur (cellule, case, nom de
-- sprite), comme le vanilla pour un meuble posé (ISMoveableSpriteProps.lua:2346) : il reprend le
-- sprite partagé et ses propriétés, dont « container ». Le constructeur (case, nom) crée un sprite
-- vide, sans conteneur (IsoObject.java:378-383). transmitAddObjectToSquare ajoute l'objet et le
-- transmet aux clients (IsoGridSquare.java:5062).
local function createContainer(square, sprite)
    local object = IsoObject.new(getCell(), square, sprite)
    object:createContainersFromSpriteProperties()
    if object:getContainerCount() == 0 then
        return nil, nil
    end
    for slot = 0, object:getContainerCount() - 1 do
        object:getContainerByIndex(slot):setExplored(true)
    end
    square:transmitAddObjectToSquare(object, -1)
    return object:getContainerByIndex(0), object
end

-- Le butin vanilla s'ajoute sans rien effacer (ItemPickerJava.fillContainer) : on le laisse passer
-- d'abord, pour que le conteneur ne soit pas rempli plus tard par-dessus nos objets. En multijoueur,
-- le conteneur marqué exploré ne serait plus envoyé à la demande d'un client
-- (RequestItemsForContainerPacket.java:44) : on transmet son contenu.
local function prepareContainer(container, object)
    if container:isExplored() then return end
    ItemPickerJava.fillContainer(container, nil)
    container:setExplored(true)
    if isServer() then
        sendItemsInContainer(object, container)
    end
end

local function addToContainer(container, item)
    container:AddItem(item)
    if isServer() then
        sendAddItemToContainer(container, item)
    end
end

-- Carte-cachette vanilla (chemin du panneau de debug vanilla, StashDebug.lua:94-99 : la carte garde
-- ses annotations), renommée pour qu'on la distingue d'une carte ordinaire. Le nom est traduit
-- dans la langue du serveur (limite en multijoueur dédié). nil si la cachette est introuvable.
local function createStashMap(stashMap)
    local stash = StashSystem.getStash(stashMap.stash)
    if stash == nil then
        Const.log("carte-cachette introuvable : " .. stashMap.stash)
        return nil
    end
    local map = instanceItem(stash:getItem())
    StashSystem.doStashItem(stash, map)
    if stashMap.nameKey then
        map:setName(getText(stashMap.nameKey))
        map:setCustomName(true)
    end
    return map
end

-- Pose des objets (et cartes-cachettes vanilla) dans un conteneur du lieu. Renvoie true si posé.
-- Radio posée par V (option tuneRadio d'une pose « items ») : réglée sur la chaîne Artemis, éteinte,
-- pile neuve. setChannelRaw : sans le grésillement d'un changement de canal (DeviceData.java:571).
local function prepareRadio(item)
    local data = instanceof(item, "Radio") and item:getDeviceData() or nil
    if data then
        data:setChannelRaw(Config.radioFrequency())
        data:setHasBattery(true)
        data:setPower(1.0)
    end
end

local function placeItems(placement)
    local square = getCell():getGridSquare(placement.x, placement.y, placement.z)
    local container, object = findContainer(square, placement.containerTypes)
    if container == nil then
        container, object = createContainer(square, placement.fallbackSprite)
    end
    if container == nil then
        Const.log("ERREUR : aucun conteneur en " .. placement.x .. "," .. placement.y .. "," .. placement.z)
        return false
    end
    prepareContainer(container, object)
    -- Après un redémarrage de l'opération, le meuble peut contenir encore l'objet (jamais pris) :
    -- on ne le double pas.
    -- Un même objet peut être listé plusieurs fois : le n-ième exemplaire est posé si le meuble en
    -- contient moins de n.
    local placed = {}
    for _, fullType in ipairs(placement.items or {}) do
        local isKnown = not placement.optionalItems or getScriptManager():FindItem(fullType) ~= nil
        placed[fullType] = (placed[fullType] or 0) + 1
        if isKnown and container:getCountType(fullType) < placed[fullType] then
            local item = instanceItem(fullType)
            if placement.tuneRadio then
                prepareRadio(item)
            end
            addToContainer(container, item)
        end
    end
    for _, stashMap in ipairs(placement.stashMaps or {}) do
        local map = createStashMap(stashMap)
        if map and not container:containsType(map:getFullType()) then
            addToContainer(container, map)
        end
    end
    -- Contenu bonus de Computer Mod (CD, portable), seulement si ce mod est actif (phase 6).
    if placement.computer and not ComputerMod.isIn(container) then
        local item = ComputerMod.create(placement.computer)
        if item then
            addToContainer(container, item)
        end
    end
    return true
end

-- Case où poser un corps : sol, libre, sans escalier (isFree est vrai sur un escalier,
-- IsoGridSquare.java:2908-2912) et dans la même pièce que le point (pas derrière un mur ; dehors,
-- la « pièce » vaut nil des deux côtés).
local function isCorpseSquare(square, siteRoom)
    return square ~= nil and square:getRoom() == siteRoom and square:isSolidFloor()
        and square:isFree(false) and not square:HasStairs()
end

-- Cases libres autour du point, hors de la case du point lui-même (meuble du dépôt).
local function freeSquaresAround(placement)
    local site = getCell():getGridSquare(placement.x, placement.y, placement.z)
    local siteRoom = site and site:getRoom()
    local squares = {}
    for dx = -placement.radius, placement.radius do
        for dy = -placement.radius, placement.radius do
            if dx ~= 0 or dy ~= 0 then
                local square = getCell():getGridSquare(placement.x + dx, placement.y + dy, placement.z)
                if isCorpseSquare(square, siteRoom) then
                    squares[#squares + 1] = square
                end
            end
        end
    end
    return squares
end

-- Soldat mort en uniforme sur la case donnée (tenue sauvegardée avec le corps), marqué pour être
-- retrouvé (2b). nil si le moteur n'a pas pu le créer.
local function createSoldierBody(square, outfit, mark)
    local body = RandomizedWorldBase.createRandomDeadBody(square, IsoDirections.getRandom(),
        CORPSE_BLOOD, CORPSE_CRAWLER_CHANCE, outfit)
    if body then
        -- createRandomDeadBody rend un corps « faux mort » une fois sur 20 (RandomizedWorldBase.java:444-507).
        body:setFakeDead(false)
        body:getModData()[CORPSE_MARK] = mark
    end
    return body
end

-- Zombie « faux mort » en tenue sur la case donnée : il reste au sol et agrippe qui passe trop près
-- (mécanique vanilla, argument isFakeDead d'addZombiesInOutfit, LuaManager.java:8361). L'état faux
-- mort est sauvegardé avec le zombie (ZombieStateFlags). Sans effet si l'option DisableFakeDead
-- l'interdit : le zombie est alors un zombie ordinaire.
local function createFakeDeadSoldier(square, outfit)
    local zombies = addZombiesInOutfit(square:getX(), square:getY(), square:getZ(), 1, outfit, FAKE_DEAD_FEMALE_CHANCE,
        false, false, true, false, false, false, FAKE_DEAD_HEALTH)
    return zombies ~= nil and zombies:size() > 0
end

-- Soldats au sol autour du dépôt : faux morts (fakeDead) ou cadavres. Pose au mieux : moins de
-- soldats si la place manque.
local function placeCorpses(placement, group)
    local squares = freeSquaresAround(placement)
    local stepSize = math.max(1, math.floor(#squares / placement.count))
    local placed = 0
    for index = 1, #squares, stepSize do
        if placed >= placement.count then break end
        local isPlaced
        if placement.fakeDead then
            isPlaced = createFakeDeadSoldier(squares[index], placement.outfit)
        else
            isPlaced = createSoldierBody(squares[index], placement.outfit, group) ~= nil
        end
        if isPlaced then
            placed = placed + 1
        end
    end
    local what = placement.fakeDead and " faux morts sur " or " corps sur "
    Const.log("pose " .. group .. " : " .. placed .. what .. placement.count)
    return true
end

-- Garde tombé : un corps en uniforme qui porte des objets (carte d'accès, plan).
local function placeGuard(placement, group)
    local squares = freeSquaresAround(placement)
    local body = squares[1] and createSoldierBody(squares[1], placement.outfit, group)
    if body == nil then
        Const.log("ERREUR : garde non pose (" .. group .. ")")
        return false
    end
    local inventory = body:getContainer()
    for _, fullType in ipairs(placement.items or {}) do
        addToContainer(inventory, instanceItem(fullType))
    end
    return true
end

-- Case libre au point, sinon la première case libre dans le rayon (même pièce), sinon nil.
local function freeSquareAt(placement)
    local square = getCell():getGridSquare(placement.x, placement.y, placement.z)
    if square and isCorpseSquare(square, square:getRoom()) then
        return square
    end
    return freeSquaresAround(placement)[1]
end

-- Groupe électrogène vanilla (même recette que MOGenerator.lua:5-21) : le constructeur l'ajoute à la
-- case et le transmet aux clients (IsoGenerator.java:102-113). Carburant de 0 à 10 (getMaxFuel).
-- Déjà branché : « Allumer » est proposé sans compétence. Sa case est enregistrée
-- (state.flags.generators[groupe]) pour l'alerte (Artemis_Alarm).
local function placeGenerator(placement, group)
    local square = freeSquareAt(placement)
    if square == nil then
        Const.log("ERREUR : aucune case libre pour le groupe electrogene (" .. group .. ")")
        return false
    end
    local item = instanceItem(placement.item)
    item:setCondition(placement.condition)
    item:getModData().fuel = placement.fuel
    local generator = IsoGenerator.new(item, getCell(), square)
    generator:setConnected(true)
    local position = { x = square:getX(), y = square:getY(), z = square:getZ() }
    Store.save(State.withFlagValue(Store.load(), "generators", group, position))
    Const.log("pose " .. group .. " : groupe electrogene en " .. position.x .. "," .. position.y .. "," .. position.z)
    return true
end

-- Objet posé au sol. filter : { type, level } pour un masque à gaz (filtre choisi au lieu du
-- niveau tiré au hasard par ItemCodeOnCreate.onCreateGasMask ; Clothing.hasFilter lit filterType).
local function placeWorldItem(placement, group)
    local square = freeSquareAt(placement)
    if square == nil then
        Const.log("ERREUR : aucune case libre pour " .. placement.item .. " (" .. group .. ")")
        return false
    end
    local item = instanceItem(placement.item)
    if placement.filter then
        local modData = item:getModData()
        modData.filterType = placement.filter.type
        modData.usedDelta = placement.filter.level
        item:setUsedDelta(placement.filter.level)
    end
    square:AddWorldInventoryItem(item, 0.5, 0.5, 0, true)
    return true
end

-- Applique murale de secours : sprite vanilla en simple décor (IsoObject, sans interrupteur), sur
-- le premier mur ouest ou nord libre parmi les cases candidates (ce sont les murs qui appartiennent à
-- la case, IsoGridSquare.getWallType). La lumière qui clignote est une lampe du client
-- (Artemis_WorldLights), décrite par placement.light et enregistrée avec la case
-- (state.flags.wallLights[groupe]). Si l'applique est retirée, la lampe s'éteint.
local function wallLightSpot(placement)
    for _, candidate in ipairs(placement.candidates) do
        local square = getCell():getGridSquare(candidate.x, candidate.y, placement.z)
        if square and square:getIsoDoor() == nil then
            local sprite = placement.spritesByFacing[Tracking.facingForWall(square:getWallType()) or ""]
            if sprite then
                return square, sprite
            end
        end
    end
    return nil, nil
end

local function placeWallLight(placement, group)
    local square, sprite = wallLightSpot(placement)
    if square == nil then
        Const.log("ERREUR : aucun mur libre pour l'applique (" .. group .. ")")
        return false
    end
    square:transmitAddObjectToSquare(IsoObject.new(getCell(), square, sprite), -1)
    local lamp = { x = square:getX(), y = square:getY(), z = square:getZ(), sprite = sprite,
        color = placement.light.color, radius = placement.light.radius, blink = placement.light.blink }
    Store.save(State.withFlagValue(Store.load(), "wallLights", group, lamp))
    Const.log("pose " .. group .. " : applique en " .. lamp.x .. "," .. lamp.y .. "," .. lamp.z)
    return true
end

-- Radio posée, sans pile : elle ne s'allume qu'avec du courant et s'éteint seule quand il disparaît
-- (DeviceData.java:506-530, 789-796). Réglages « Raw » : sans son ni synchronisation. Le constructeur
-- l'allume au hasard 35 fois sur 100 (IsoWaveSignal.java:73-96) : on l'éteint. transmitAddObjectToSquare
-- l'ajoute au monde et l'enregistre comme appareil (IsoWaveSignal.java:321-327).
-- Plage où chercher une fréquence libre (FM, comme la radio d'urgence vanilla).
local RADIO_FREE_MIN, RADIO_FREE_MAX = 88000, 108000

local function placeRadio(placement, group)
    local square = getCell():getGridSquare(placement.x, placement.y, placement.z)
    local radio = IsoRadio.new(getCell(), square, getSprite(placement.sprite))
    local data = radio:getDeviceData()
    data:setIsBatteryPowered(false)
    data:setHasBattery(false)
    data:setTurnedOnRaw(false)
    data:setDeviceVolumeRaw(placement.volume)
    -- Fréquence qu'aucune station n'utilise, tirée par le jeu (ZomboidRadio.java:179-184) : sinon les
    -- lignes d'une émission se mêleraient à la bande (retour du test : une station tirée au hasard
    -- occupait la fréquence fixe choisie d'abord). Artemis_RelayTape revérifie à chaque lecture.
    local zomboidRadio = getZomboidRadio()
    local channel = zomboidRadio and zomboidRadio:getRandomFrequency(RADIO_FREE_MIN, RADIO_FREE_MAX)
        or placement.channel
    data:setChannelRaw(channel)
    radio:setRenderYOffset(placement.renderYOffset)
    square:transmitAddObjectToSquare(radio, -1)
    Const.log("pose " .. group .. " : radio posee en " .. placement.x .. "," .. placement.y .. "," .. placement.z)
    return true
end

-- Zombies posés (pose « zombies ») --------------------------------------------------------------
-- Champs : outfit (nil : tenue au hasard), femaleChance, count ou countByIntensity (intensité
-- dramatique 1 à 3), health, track (profil de Story.TRACKED : traits rendus après virtualisation)
-- retryOnEmpty : pour un groupe isolé de zombies, attend une création réelle avant de le marquer
-- posé. Réessaie après zéro création ; n'applique pas cette reprise aux groupes mixtes.
-- Et l'une des dispositions :
--   - radius  : cases libres de la pièce du point, dans ce rayon ; avec sitting, seulement contre un
--               mur, le zombie assis dos au mur ; minPlayerDistance facultatif : aucun joueur plus
--               près du point (le zombie n'apparaît pas sous ses yeux) ;
--   - ring    : { minRadius, maxRadius, minPlayerDistance } : dehors, sur un anneau autour du point,
--               quand aucun joueur n'est dans l'anneau ; chaque zombie à au moins minPlayerDistance
--               cases de tout joueur (hors de sa vue).
local DEFAULT_FEMALE_CHANCE = 50
local DEFAULT_HEALTH = 1.0
-- Écart maximal (cases) autour d'un point de l'anneau pour trouver une case libre.
local RING_SEARCH = 2

local function random01()
    return ZombRandFloat(0, 1)
end

local function zombieCount(placement)
    if placement.countByIntensity then
        return placement.countByIntensity[Config.dramaIntensity()] or 0
    end
    return placement.count or 1
end

local function spawnZombie(square, placement, isSitting)
    local zombies = addZombiesInOutfit(square:getX(), square:getY(), square:getZ(), 1, placement.outfit,
        placement.femaleChance or DEFAULT_FEMALE_CHANCE, false, false, false, false, false, isSitting,
        placement.health or DEFAULT_HEALTH)
    return zombies ~= nil and zombies:size() > 0 and zombies:get(0) or nil
end

-- Case dehors, libre, hors de l'eau (comme les apparitions de Artemis_Staging).
local function isOutdoorSpawnable(square)
    return square ~= nil and square:isOutside() and square:isFree(false) and not square:isWaterSquare()
end

local function outdoorSquareNear(x, y, z)
    for dx = -RING_SEARCH, RING_SEARCH do
        for dy = -RING_SEARCH, RING_SEARCH do
            local square = getCell():getGridSquare(x + dx, y + dy, z)
            if isOutdoorSpawnable(square) then
                return square
            end
        end
    end
    return nil
end

-- Aucun joueur à moins de distance cases de la case ?
local function isFarFromPlayers(square, distance, players)
    local point = { x = square:getX(), y = square:getY() }
    for _, player in ipairs(players) do
        if Players.isNear(player, point, distance) then
            return false
        end
    end
    return true
end

-- Points de l'anneau tirés par zombie voulu : on en garde count, chargés, dehors et hors de la vue
-- des joueurs (à au moins ring.minPlayerDistance cases de chacun).
local RING_CANDIDATES_PER_ZOMBIE = 3

local function ringSpots(placement, count)
    local ring, players, spots = placement.ring, Players.list(), {}
    local points = Ring.points(placement.x, placement.y, count * RING_CANDIDATES_PER_ZOMBIE,
        ring.minRadius, ring.maxRadius, random01)
    for _, point in ipairs(points) do
        if #spots >= count then break end
        local square = outdoorSquareNear(point.x, point.y, placement.z)
        if square and isFarFromPlayers(square, ring.minPlayerDistance, players) then
            spots[#spots + 1] = { square = square }
        end
    end
    return spots
end

-- Aussi pour les vagues de l'extraction (Artemis_Waves) : placement = { x, y, z, ring = { minRadius,
-- maxRadius, minPlayerDistance } }.
Placement.ringSpots = ringSpots
-- Utilisés par le site du checkpoint (Artemis_CheckpointSite).
Placement.createContainer = createContainer
Placement.addToContainer = addToContainer

-- Cases de pose : { square }.
local function zombieSpots(placement, count)
    if placement.ring then
        return ringSpots(placement, count)
    end
    local spots = {}
    for _, square in ipairs(freeSquaresAround(placement)) do
        -- Un zombie assis s'assoit dos à un mur : seulement les cases qui en ont un.
        if not placement.sitting or Tracking.facingForWall(square:getWallType()) then
            spots[#spots + 1] = { square = square }
        end
    end
    return spots
end

local function placeZombies(placement, group)
    local count = zombieCount(placement)
    local spots = zombieSpots(placement, count)
    local stepSize = math.max(1, math.floor(#spots / math.max(1, count)))
    local placed = 0
    for index = 1, #spots, stepSize do
        if placed >= count then break end
        local spot = spots[index]
        local zombie = spawnZombie(spot.square, placement, placement.sitting == true)
        if zombie then
            placed = placed + 1
            -- Groupe isolé qui attend une première création : réserver immédiatement, AVANT les
            -- traits/enregistrement, pour qu'une erreur ultérieure ne crée pas un second zombie.
            if placement.retryOnEmpty then
                Store.save(State.withPlaced(Store.load(), group))
            end
            if placement.track then
                Tracked.register(zombie, placement.track)
            end
        end
    end
    Const.log("pose " .. group .. " : " .. placed .. " zombies sur " .. count)
    return placed > 0 or count == 0
end

-- Pièce fermée à clé avec un zombie dedans : il frappe la porte quand il entend le joueur
-- (comportement vanilla ; seul, il ne l'abîme pas, IsoDoor.java:992-1001). Verrou à clé comme
-- ISLockDoor.lua:50-56 (le serveur ne synchronise pas seul) ; un joueur d'une des deux pièces
-- l'ouvre sans clé (canBeOpenFromInside, IsoDoor.java:1266-1268).
local function placeLockedRoom(placement, group)
    local doorSquare = getCell():getGridSquare(placement.door.x, placement.door.y, placement.door.z)
    local door = doorSquare and doorSquare:getIsoDoor()
    local square = freeSquareAt(placement)
    if door == nil or square == nil then
        Const.log("ERREUR : porte ou case introuvable (" .. group .. ")")
        return false
    end
    if door:IsOpen() then
        door:ToggleDoorSilent()
    end
    door:setLockedByKey(true)
    door:syncIsoObject(false, 0, nil, nil)
    local zombie = spawnZombie(square, placement, false)
    Const.log("pose " .. group .. " : porte verrouillee, zombie " .. tostring(placement.outfit)
        .. (zombie and " pose" or " NON pose"))
    return zombie ~= nil
end

-- Case du point prête (voir l'en-tête) : condition par défaut d'une pose.
local function isSquareReady(placement)
    return readySquare(placement.x, placement.y, placement.z) ~= nil
end

-- Anneau prêt : aucun joueur à l'intérieur (les zombies apparaîtraient autour de lui), son centre
-- chargé et au moins RING_MIN_LOADED des huit points cardinaux de l'anneau chargés. On n'exige pas tout
-- l'anneau : la zone chargée autour du joueur ne fait que ± 48 cases sur un écran plus petit que
-- 1080p (IsoChunkMap.java:131-139). Chaque zombie va ensuite sur un point chargé, loin des joueurs
-- (ringSpots) ; s'il en manque, la pose est partielle (journal « N zombies sur M »).
local RING_MIN_LOADED = 6
local RING_DIRECTIONS = {
    { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 }, { 0.7, 0.7 }, { -0.7, 0.7 }, { 0.7, -0.7 }, { -0.7, -0.7 },
}

local function isRingReady(placement)
    local ring, cell, players = placement.ring, getCell(), Players.list()
    -- Liste vide : tout début du chargement en solo ; on attend un joueur.
    if #players == 0 or cell:getGridSquare(placement.x, placement.y, placement.z) == nil then
        return false
    end
    for _, player in ipairs(players) do
        -- Le petit anneau de Miller (rayon 3, distance minimale 30) attendait seulement 5 cases :
        -- il était déclaré prêt alors que toutes ses cases étaient trop proches du joueur.
        if Players.isNear(player, placement, math.max(ring.maxRadius + RING_SEARCH, ring.minPlayerDistance)) then
            return false
        end
    end
    local loaded = 0
    for _, direction in ipairs(RING_DIRECTIONS) do
        local x = math.floor(placement.x + direction[1] * ring.maxRadius)
        local y = math.floor(placement.y + direction[2] * ring.maxRadius)
        if cell:getGridSquare(x, y, placement.z) then
            loaded = loaded + 1
        end
    end
    return loaded >= RING_MIN_LOADED
end

-- Pose près d'un point, avec minPlayerDistance facultatif : aucun joueur à moins de cette distance
-- (à plat) du point, pour que le zombie n'apparaisse pas sous ses yeux.
local function isNearPointReady(placement)
    if not isSquareReady(placement) then
        return false
    end
    if placement.minPlayerDistance == nil then
        return true
    end
    local square = getCell():getGridSquare(placement.x, placement.y, placement.z)
    return isFarFromPlayers(square, placement.minPlayerDistance, Players.list())
end

-- Types de pose : place(pose, groupe) renvoie true si la pose est faite ; ready(pose) dit si le
-- lieu est prêt à la recevoir (par défaut : case chargée et à l'abri des histoires de bâtiment).
local KINDS = {
    items = { place = function(placement) return placeItems(placement) end },
    corpses = { place = function(placement, group) return placeCorpses(placement, group) end },
    guard = { place = function(placement, group) return placeGuard(placement, group) end },
    generator = { place = function(placement, group) return placeGenerator(placement, group) end },
    worldItem = { place = function(placement, group) return placeWorldItem(placement, group) end },
    wallLight = { place = function(placement, group) return placeWallLight(placement, group) end },
    radio = { place = function(placement, group) return placeRadio(placement, group) end },
    lockedRoom = { place = function(placement, group) return placeLockedRoom(placement, group) end },
    zombies = {
        place = function(placement, group) return placeZombies(placement, group) end,
        ready = function(placement)
            if placement.ring then return isRingReady(placement) end
            return isNearPointReady(placement)
        end,
    },
}

-- Toutes les poses de ce groupe sont-elles prêtes ?
local function isReady(placements)
    for _, placement in ipairs(placements) do
        local kind = KINDS[placement.kind]
        local ready = kind and kind.ready or isSquareReady
        if not ready(placement) then
            return false
        end
    end
    return true
end

-- Poses du chapitre regroupées par groupe de registre, dans l'ordre des données.
local function placementsByGroup(chapterId, chapter)
    local groups, order = {}, {}
    for _, placement in ipairs(chapter.placements) do
        local group = Story.groupOf(chapterId, placement)
        if groups[group] == nil then
            groups[group] = {}
            order[#order + 1] = group
        end
        table.insert(groups[group], placement)
    end
    return groups, order
end

local function placeGroup(group, placements)
    local isComplete = true
    for _, placement in ipairs(placements) do
        -- Objet qui annonce un chapitre optionnel : posé seulement si ce chapitre a lieu (Lua 5.1 : pas
        -- de goto).
        if placement.ifChapter and not Plot.isChapterAvailable(Store.load(), placement.ifChapter) then
            Const.log("pose " .. group .. " : sautee (chapitre " .. placement.ifChapter .. " indisponible)")
        else
            local kind = KINDS[placement.kind]
            if kind == nil or not kind.place(placement, group) then
                isComplete = false
            end
        end
    end
    Const.log("pose " .. group .. (isComplete and " : objets poses" or " : incomplete"))
    return isComplete
end

-- Pose chaque groupe du chapitre pas encore posé dont les cases sont prêtes. L'état est relu à
-- chaque groupe : une pose peut elle-même l'enregistrer (zombies suivis, groupe électrogène).
-- Le registre (state.placed[groupe]) est écrit AVANT la pose : si une erreur interrompt la pose,
-- elle n'est pas recommencée au chunk suivant, ce qui doublerait les objets déjà posés. Une pose
-- incomplète est signalée dans le journal. Exception : un groupe isolé de zombies « retryOnEmpty »
-- attend une première création réelle ; placeZombies réserve alors le groupe avant les traits.
function Placement.ensure(chapterId)
    local chapter = Story.get(chapterId)
    if chapter == nil then return end
    local groups, order = placementsByGroup(chapterId, chapter)
    for _, group in ipairs(order) do
        -- Registre lu brut (sans copie de l'état) : appelé à chaque chunk chargé tant qu'une pose
        -- attend. L'état n'est copié que pour une pose réelle.
        local data = ModData.get(Const.MODDATA_KEY)
        local placed = type(data) == "table" and type(data.placed) == "table" and data.placed or {}
        if not placed[group] and isReady(groups[group]) then
            local placements = groups[group]
            local first = placements[1]
            local retryOnEmpty = #placements == 1 and first.kind == "zombies" and first.retryOnEmpty == true
            if not retryOnEmpty then
                Store.save(State.withPlaced(Store.load(), group))
            end
            local complete = placeGroup(group, placements)
            if retryOnEmpty and complete and not Store.load().placed[group] then
                Store.save(State.withPlaced(Store.load(), group))
            end
        end
    end
end

-- Un corps marqué pour ce groupe, qui porte encore l'objet, est-il autour du point ?
local function hasMarkedBodyWith(placement, group, fullType)
    for dx = -placement.radius, placement.radius do
        for dy = -placement.radius, placement.radius do
            local square = getCell():getGridSquare(placement.x + dx, placement.y + dy, placement.z)
            local bodies = square and square:getDeadBodys()
            if bodies then
                for index = 0, bodies:size() - 1 do
                    local body = bodies:get(index)
                    if body:getModData()[CORPSE_MARK] == group
                        and body:getContainer():containsTypeRecurse(fullType) then
                        return true
                    end
                end
            end
        end
    end
    return false
end

local function anyPlayerCarries(players, fullType)
    for _, player in ipairs(players) do
        if player:getInventory():containsTypeRecurse(fullType) then
            return true
        end
    end
    return false
end

-- Objet indispensable perdu (« keepAvailable ») : si aucun corps du groupe ne le porte plus (corps
-- disparu avec l'option de suppression des cadavres, IsoDeadBody.java:1464-1507, ou objet pris par un
-- ancien personnage) et qu'aucun joueur ne l'a, le groupe est retiré du registre pour être reposé.
-- Vérifié seulement quand la case du point est chargée.
function Placement.restoreLost(chapterId, players)
    local chapter = Story.get(chapterId)
    if chapter == nil then return end
    for _, placement in ipairs(chapter.placements) do
        local group = Story.groupOf(chapterId, placement)
        if placement.keepAvailable and getCell():getGridSquare(placement.x, placement.y, placement.z)
            and not hasMarkedBodyWith(placement, group, placement.keepAvailable)
            and not anyPlayerCarries(players, placement.keepAvailable) then
            local state = Store.load()
            if state.placed[group] then
                Store.save(State.withoutPlaced(state, group))
                Const.log("pose " .. group .. " : objet indispensable perdu, nouvelle pose")
            end
        end
    end
end

return Placement
