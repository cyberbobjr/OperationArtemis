-- Opération Artemis : détecte que le joueur local entend le signal Artemis à la radio,
-- puis prévient le serveur, qui revalide et fait passer l'opération à l'acte II.

local Const = require "Artemis/Artemis_Const"
local ClientState = require "Artemis/Artemis_ClientState"

-- Même règle que le vanilla pour une radio posée : ±5 cases et même étage (ISRadioInteractions.lua:167-174).
local HEARING_RADIUS = 5
local RESEND_DELAY_MS = 10000
local HELD_DEVICE = -1

local lastSentMs = 0

-- Radio en main ou portée : coordonnées -1. Radio posée ou autoradio : coordonnées de l'appareil,
-- transmises même quand le joueur est loin (en solo), d'où le contrôle de distance.
local function isWithinEarshot(player, x, y, z)
    if x == HELD_DEVICE then
        return true
    end
    return math.abs(player:getX() - x) <= HEARING_RADIUS
        and math.abs(player:getY() - y) <= HEARING_RADIUS
        and math.floor(player:getZ()) == math.floor(z)
end

-- Portée du bruit du haut-parleur de l'appareil, calculée comme le vanilla (DeviceData
-- .getDeviceSoundVolumeRange : volume, intérieur ou extérieur, type d'appareil). Avec des écouteurs,
-- la radio ne fait aucun bruit (DeviceData.java:908, headphoneType < 0 exigé) : portée 0.
local function speakerRange(device)
    local data = device and device:getDeviceData()
    if data == nil or data:getHeadphoneType() >= 0 then
        return 0
    end
    return data:getDeviceSoundVolumeRange()
end

local function onDeviceText(_guid, codes, x, y, z, _line, device)
    if type(codes) ~= "string" or not codes:find(Const.RADIO.SIGNAL_CODE, 1, true) then return end

    local player = getPlayer()
    if not player or player:isDead() or player:isAsleep() then return end
    if not isWithinEarshot(player, x, y, z) then return end
    if ClientState.get().act ~= Const.ACT.SIGNAL then return end

    local now = getTimestampMs()
    if now - lastSentMs < RESEND_DELAY_MS then return end
    lastSentMs = now
    sendClientCommand(player, Const.NET_MODULE, Const.COMMAND.HEARD_SIGNAL, { speakerRange = speakerRange(device) })
end

Events.OnDeviceText.Add(onDeviceText)
