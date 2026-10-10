-- Opération Artemis : radios militaires, pour l'appel d'évacuation de l'acte III (route B).
-- Adapté du module radio de Military Drop (même auteur, licence MIT), avec le contrôle du micro.
--
-- Radio militaire = appareil « haut de gamme » vanilla (DeviceData:getIsHighTier : WalkieTalkie5,
-- ManPackRadio, HamRadio2). Deux formes :
--   * objet d'inventaire : en main ou porté sur le dos. En solo, seule la radio équipée reçoit les
--     chaînes et transmet la parole du joueur (ZomboidRadio.java:500-539) ;
--   * appareil posé (IsoWaveSignal), à MAX_WORLD_DISTANCE cases au plus (sa portée de micro est de 5).
-- La parole n'est transmise que si l'appareil est allumé, émetteur et micro actif : un micro coupé
-- ferait un appel que personne n'entend.
-- Le client désigne l'appareil par une référence ; le serveur la résout lui-même et revérifie tout.

local MilRadio = {}
-- Récepteur commun : Belt Walkie-Talkie s'il est activé, sinon la copie de secours embarquée.
local RadioLib = require "Artemis/Artemis_RadioLib"

MilRadio.MAX_WORLD_DISTANCE = 2

function MilRadio.isInventoryRadio(object)
    return object ~= nil and instanceof(object, "Radio")
end

function MilRadio.isWorldRadio(object)
    return object ~= nil and instanceof(object, "IsoWaveSignal")
end

-- Radios d'inventaire équipées : les deux mains et le dos (emplacements vides possibles).
local function equippedItems(player)
    return { player:getPrimaryHandItem(), player:getSecondaryHandItem(), player:getClothingItem_Back() }
end

-- L'objet d'inventaire est en main ou porté sur le dos.
function MilRadio.isCarried(player, item)
    local items = equippedItems(player)
    -- Pas d'ipairs : il s'arrête au premier emplacement vide (nil).
    for i = 1, 3 do
        if items[i] == item then
            return true
        end
    end
    return false
end

-- L'appareil posé est assez proche du joueur, au même étage.
function MilRadio.isNear(player, object)
    local square = object:getSquare()
    if not square then
        return false
    end
    return math.floor(player:getZ()) == square:getZ()
        and math.abs(player:getX() - (square:getX() + 0.5)) <= MilRadio.MAX_WORLD_DISTANCE + 0.5
        and math.abs(player:getY() - (square:getY() + 0.5)) <= MilRadio.MAX_WORLD_DISTANCE + 0.5
end

-- Radio militaire utilisable pour un appel (sans regarder l'allumage ni le canal).
function MilRadio.isMilitary(object)
    local data = object and object:getDeviceData()
    if not data or not data:getIsHighTier() or not data:getIsTwoWay() then
        return false
    end
    if MilRadio.isInventoryRadio(object) then
        -- Une radio fixe (HamRadio2) ne sert que posée.
        return data:getIsPortable()
    end
    return MilRadio.isWorldRadio(object)
end

-- Motif de refus, ou nil si le joueur peut appeler sur ce canal (kHz) avec cet appareil.
-- ignoreMic : sur le serveur, l'état du micro est périmé (DeviceData.setMicIsMuted n'est pas transmis,
-- DeviceData.java:371-378) ; seul le client le vérifie.
function MilRadio.status(player, object, channel, ignoreMic)
    if not MilRadio.isMilitary(object) then
        return "notMilitary"
    end
    if MilRadio.isInventoryRadio(object) then
        -- Jamais depuis la ceinture ni rangée : prédicat commun à tous les mods (raison "belt" ou
        -- "stowed"), même message qu'avant (prendre la radio en main ou la porter sur le dos).
        local _, reason = RadioLib.canTransmitWith(player, object)
        if reason == "belt" or reason == "stowed" or not MilRadio.isCarried(player, object) then
            return "notCarried"
        end
    elseif not MilRadio.isNear(player, object) then
        return "tooFar"
    end
    local data = object:getDeviceData()
    if not data:getIsTurnedOn() then
        return "radioOff"
    end
    if data:getChannel() ~= channel then
        return "wrongFrequency"
    end
    if not ignoreMic and not RadioLib.compat().microphoneAvailable(data) then
        return "micMuted"
    end
    return nil
end

-- Référence transmissible au serveur (client).
function MilRadio.makeRef(object)
    if MilRadio.isInventoryRadio(object) then
        return { kind = "item", id = object:getID() }
    end
    local square = object:getSquare()
    return {
        kind = "world",
        x = square:getX(), y = square:getY(), z = square:getZ(),
        index = square:getObjects():indexOf(object),
    }
end

local function isInteger(value)
    return type(value) == "number" and value == math.floor(value)
end

-- Appareil désigné par une référence du client, s'il est bien à portée du joueur (serveur ou
-- solo). Toute donnée incohérente donne nil.
function MilRadio.resolve(player, ref)
    if type(ref) ~= "table" then
        return nil
    end
    if ref.kind == "item" and isInteger(ref.id) then
        local items = equippedItems(player)
        for i = 1, 3 do
            local item = items[i]
            if item and item:getID() == ref.id and MilRadio.isInventoryRadio(item) then
                return item
            end
        end
        return nil
    end
    if ref.kind == "world" and isInteger(ref.x) and isInteger(ref.y) and isInteger(ref.z) and isInteger(ref.index) then
        local square = getCell():getGridSquare(ref.x, ref.y, ref.z)
        local objects = square and square:getObjects()
        if not objects or ref.index < 0 or ref.index >= objects:size() then
            return nil
        end
        local object = objects:get(ref.index)
        if MilRadio.isWorldRadio(object) and MilRadio.isNear(player, object) then
            return object
        end
    end
    return nil
end

return MilRadio
