-- Opération Artemis : lecture de l'état côté client.
-- En solo, la table ModData est la même que celle du « serveur ».
-- En multijoueur, elle est demandée au serveur puis reçue par OnReceiveGlobalModData.
-- Note 42.21 : sendServerCommand ne fait rien en solo, d'où la lecture directe de ModData.

local Const = require "Artemis/Artemis_Const"
local State = require "Artemis/Artemis_State"

local ClientState = {}

local receivedFromServer = nil

local function rawState()
    if isClient() then
        return receivedFromServer
    end
    return ModData.get(Const.MODDATA_KEY)
end

function ClientState.get()
    return State.migrate(rawState())
end

-- Lecture légère, appelée à chaque mise à jour du journal ouvert.
function ClientState.revision()
    local raw = rawState()
    if type(raw) ~= "table" or type(raw.rev) ~= "number" then
        return 0
    end
    return raw.rev
end

local function onReceiveGlobalModData(key, data)
    if key ~= Const.MODDATA_KEY or type(data) ~= "table" then return end
    receivedFromServer = State.copy(data)
end

local function onGameStart()
    if isClient() then
        ModData.request(Const.MODDATA_KEY)
    end
end

Events.OnReceiveGlobalModData.Add(onReceiveGlobalModData)
Events.OnGameStart.Add(onGameStart)

return ClientState
