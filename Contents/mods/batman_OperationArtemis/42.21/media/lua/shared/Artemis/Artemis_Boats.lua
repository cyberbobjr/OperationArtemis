-- Opération Artemis : intégration facultative des mods de bateaux Build 42 (lus seulement, rien n'en est
-- copié) : BoatCoreMP + Working Motorboat (variante 42), Aquatsar Yacht Club (variante 42.17). Le
-- vanilla 42.21 n'a ni bateau ni nage : sans ces mods, la route du fleuve passe par le passeur de V.
-- Les deux mods déclarent un véhicule « BoatMotor » : si les deux sont actifs, on pose le Sunseeker de
-- Working Motorboat, jamais BoatMotor.

local Boats = {}

-- Scripts de bateau posés pour V, par ordre de préférence (le premier qui existe).
local V_BOAT_SCRIPTS = { "Base.BoatSunseekerYacht", "Base.BoatMotor" }

-- Un mod de bateau est-il actif (API de détection chargée) ?
function Boats.isActive()
    return (BoatCoreMP ~= nil and BoatCoreMP.isBoat ~= nil) or (AquaConfig ~= nil and AquaConfig.isBoat ~= nil)
end

-- Ce véhicule est-il un bateau d'un de ces mods ?
function Boats.isBoat(vehicle)
    if vehicle == nil then return false end
    if BoatCoreMP and BoatCoreMP.isBoat and BoatCoreMP.isBoat(vehicle) then
        return true
    end
    if AquaConfig and AquaConfig.isBoat and AquaConfig.isBoat(vehicle) then
        return true
    end
    return false
end

-- Le joueur est-il à bord d'un bateau ?
function Boats.isAboard(player)
    return Boats.isBoat(player:getVehicle())
end

-- Script du bateau de V, ou nil si aucun mod de bateau ne le fournit.
function Boats.vBoatScript()
    if not Boats.isActive() then return nil end
    local manager = getScriptManager()
    for _, name in ipairs(V_BOAT_SCRIPTS) do
        if manager:getVehicle(name) ~= nil then
            return name
        end
    end
    return nil
end

return Boats
