-- Opération Artemis : la carte d'accès Artemis ouvre les portes blindées de la base secrète.
-- Ces portes portent la propriété de sprite « forceLocked » : toujours verrouillées, keyId du
-- bâtiment, aucune clé vanilla (IsoDoor.java:633-664). On leur donne le keyId de la carte d'accès
-- (objet de classe Key, OperationArtemisItems.onCreateKeycard) quand leur chunk se charge. La porte
-- garde ce keyId dans la sauvegarde (IsoDoor.java:753-799).
-- Chargé côté client ET serveur : la touche E vérifie la clé côté client (IsoPlayer.java:4425),
-- le menu contextuel côté serveur (ISOpenCloseDoor:complete).
-- Multijoueur : le client reçoit l'état des portes du serveur APRÈS son propre LoadChunk
-- (IsoChunk.java:3600 puis 3612 ; IsoDoor.loadState), et le serveur l'envoie parfois avant d'avoir
-- appliqué le keyId (IsoChunk.java:3571-3588). Un client multijoueur réapplique donc le keyId aux
-- portes proches du joueur, une fois par seconde, tant qu'il est dans la base.
-- Seules quelques tuiles portent « forceLocked » (dont des portes de postes de police) : on se
-- limite à l'emprise de la base.

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Story = require "Artemis/Artemis_Story"

local CHUNK_SIZE = 8
local BASE_AREA = Story.CHAPTERS.ch5_base.guide.area

-- IsoChunk n'expose pas ses coordonnées à Lua : on les déduit d'une de ses cases.
local function chunkOrigin(chunk)
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for localX = 0, CHUNK_SIZE - 1 do
            for localY = 0, CHUNK_SIZE - 1 do
                local square = chunk:getGridSquare(localX, localY, z)
                if square then
                    return square:getX() - localX, square:getY() - localY
                end
            end
        end
    end
    return nil, nil
end

local function overlapsBase(originX, originY)
    return originX + CHUNK_SIZE - 1 >= BASE_AREA.x1 and originX <= BASE_AREA.x2
        and originY + CHUNK_SIZE - 1 >= BASE_AREA.y1 and originY <= BASE_AREA.y2
end

local function assignKeycard(square)
    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local object = objects:get(index)
        if instanceof(object, "IsoDoor") and object:getProperties():has("forceLocked")
            and object:getKeyId() ~= Const.KEYCARD_KEY_ID then
            object:setKeyId(Const.KEYCARD_KEY_ID)
        end
    end
end

local function onLoadChunk(chunk)
    if not Config.isEnabled() then return end
    local originX, originY = chunkOrigin(chunk)
    if originX == nil or not overlapsBase(originX, originY) then return end
    for z = chunk:getMinLevel(), chunk:getMaxLevel() do
        for localX = 0, CHUNK_SIZE - 1 do
            for localY = 0, CHUNK_SIZE - 1 do
                local square = chunk:getGridSquare(localX, localY, z)
                if square then
                    assignKeycard(square)
                end
            end
        end
    end
end

Events.LoadChunk.Add(onLoadChunk)

-- Client multijoueur : portes à 2 cases ou moins du joueur local, à son étage.
local NEAR_RADIUS = 2
local CHECK_INTERVAL_MS = 1000
local lastCheckMs = 0

local function onTickClient()
    local now = getTimestampMs()
    if now - lastCheckMs < CHECK_INTERVAL_MS then return end
    lastCheckMs = now
    local player = getPlayer()
    if not player or not Config.isEnabled() then return end
    local x, y = math.floor(player:getX()), math.floor(player:getY())
    if x < BASE_AREA.x1 or x > BASE_AREA.x2 or y < BASE_AREA.y1 or y > BASE_AREA.y2 then return end
    -- math.floor : Kahlua tronquerait vers zéro un étage négatif (.claude/pz-knowledge/kahlua-lua.md).
    local z = math.floor(player:getZ())
    for dx = -NEAR_RADIUS, NEAR_RADIUS do
        for dy = -NEAR_RADIUS, NEAR_RADIUS do
            local square = getCell():getGridSquare(x + dx, y + dy, z)
            if square then
                assignKeycard(square)
            end
        end
    end
end

if isClient() then
    Events.OnTick.Add(onTickClient)
end
