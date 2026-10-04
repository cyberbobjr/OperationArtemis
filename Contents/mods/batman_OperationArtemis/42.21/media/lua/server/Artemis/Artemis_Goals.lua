-- Opération Artemis : objectifs des chapitres (vocabulaire fermé, une fonction par type).
-- Serveur ou solo. Ajouter un type d'objectif = ajouter une fonction ici, sans toucher au moteur.

local Players = require "Artemis/Artemis_Players"

local Goals = {}

-- Un lieu est-il alimenté ? haveElectricity ne teste que les générateurs (IsoGridSquare.java:8223) ;
-- le réseau public passe par hasGridPower (:10150). Le mod ne compte le réseau que dans une pièce
-- (un relais en plein air n'a pas d'installation électrique raccordée).
local function isPowered(square)
    return square:haveElectricity() or (square:hasGridPower() and square:getRoom() ~= nil)
end

local CHECKS = {}

-- Le joueur porte l'objet (sacs compris ; type complet « module.Type » accepté).
function CHECKS.hasItem(goal, player)
    return player:getInventory():containsTypeRecurse(goal.item)
end

-- Le document a été lu jusqu'au bout (par n'importe quel joueur : registre commun flags.readDocs).
function CHECKS.hasRead(goal, _player, state)
    local readDocs = state.flags.readDocs
    return type(readDocs) == "table" and readDocs[goal.item] == true
end

-- La bande enregistrée a été entendue jusqu'au bout (registre commun flags.heard, Artemis_RelayTape).
function CHECKS.heard(goal, _player, state)
    local heard = state.flags.heard
    return type(heard) == "table" and heard[goal.key] == true
end

-- La case (chargée) est alimentée (générateur ou réseau), où que soit le joueur.
function CHECKS.squarePowered(goal)
    local square = getCell():getGridSquare(goal.x, goal.y, goal.z)
    return square ~= nil and isPowered(square)
end

-- Le joueur est près d'une case chargée et alimentée (générateur ou réseau).
function CHECKS.powered(goal, player)
    return Players.isNear(player, goal, goal.radius) and CHECKS.squarePowered(goal)
end

-- Toutes les conditions de goal.goals sont remplies.
function CHECKS.all(goal, player, state)
    for _, subGoal in ipairs(goal.goals) do
        if not Goals.isMet(subGoal, player, state) then
            return false
        end
    end
    return true
end

-- L'objectif est-il atteint par ce joueur, dans cet état ? Un type inconnu n'est jamais atteint.
function Goals.isMet(goal, player, state)
    local check = goal and CHECKS[goal.type]
    return check ~= nil and check(goal, player, state) == true
end

return Goals
