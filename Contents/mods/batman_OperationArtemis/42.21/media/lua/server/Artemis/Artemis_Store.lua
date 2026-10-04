-- Opération Artemis : seul point d'écriture de l'état dans ModData (serveur ou solo).

local Const = require "Artemis/Artemis_Const"
local State = require "Artemis/Artemis_State"

local Store = {}

function Store.load()
    return State.migrate(ModData.getOrCreate(Const.MODDATA_KEY))
end

-- Remplace le contenu de la table ModData par l'état donné, avec une révision incrémentée.
-- La révision ne redescend jamais, même après une réinitialisation : le journal ouvert se rafraîchit.
-- Renvoie l'état tel qu'il a été enregistré.
function Store.save(state)
    local data = ModData.getOrCreate(Const.MODDATA_KEY)
    local previousRev = type(data.rev) == "number" and data.rev or 0

    local saved = State.copy(state)
    saved.rev = math.max(previousRev, saved.rev or 0) + 1

    local oldKeys = {}
    for key in pairs(data) do
        oldKeys[#oldKeys + 1] = key
    end
    for _, key in ipairs(oldKeys) do
        data[key] = nil
    end
    for key, value in pairs(State.copy(saved)) do
        data[key] = value
    end

    if isServer() then
        ModData.transmit(Const.MODDATA_KEY)
    end
    return saved
end

return Store
