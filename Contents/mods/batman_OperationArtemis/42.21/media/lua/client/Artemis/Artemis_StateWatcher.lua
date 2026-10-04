-- Opération Artemis : prévient les modules client quand l'état de l'opération change.
-- Le client observe la révision de l'état (ModData) au lieu d'attendre un message du serveur :
-- en solo, sendServerCommand ne fait rien (LuaManager.java:7253-7256).
-- Chaque abonné reçoit (état, isFirst) : isFirst est vrai à la première observation après le
-- chargement de la partie (état déjà existant, rien de nouveau ne s'est produit).

local Const = require "Artemis/Artemis_Const"
local ClientState = require "Artemis/Artemis_ClientState"

local StateWatcher = {}

local listeners = {}
local lastRevision = 0

function StateWatcher.subscribe(listener)
    listeners[#listeners + 1] = listener
end

local function onTick()
    local revision = ClientState.revision()
    if revision <= 0 or revision == lastRevision then return end
    local isFirst = lastRevision == 0
    lastRevision = revision
    local state = ClientState.get()
    -- Chaque abonné est isolé : une erreur dans l'un (carte, par exemple) n'empêche pas les autres
    -- (scène) de recevoir cette révision, qui ne sera pas renvoyée.
    for _, listener in ipairs(listeners) do
        local ok, err = pcall(listener, state, isFirst)
        if not ok then
            Const.log("ERREUR dans un abonne a l'etat : " .. tostring(err))
        end
    end
end

Events.OnTick.Add(onTick)

return StateWatcher
