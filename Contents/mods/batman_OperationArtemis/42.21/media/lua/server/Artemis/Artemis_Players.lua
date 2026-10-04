-- Opération Artemis : joueurs présents, côté serveur ou solo.
-- En solo, getOnlinePlayers() renvoie une liste vide (LuaManager.java:3834) : on parcourt alors
-- les joueurs locaux (écran partagé compris).

local Players = {}

function Players.list()
    local players = {}
    if isServer() then
        local online = getOnlinePlayers()
        for index = 0, online:size() - 1 do
            players[#players + 1] = online:get(index)
        end
        return players
    end
    for index = 0, getNumActivePlayers() - 1 do
        local player = getSpecificPlayer(index)
        if player then
            players[#players + 1] = player
        end
    end
    return players
end

-- Joueur vivant, à moins de radius cases (à plat) du point donné.
function Players.isNear(player, point, radius)
    if player:isDead() then
        return false
    end
    local dx = player:getX() - point.x
    local dy = player:getY() - point.y
    return dx * dx + dy * dy <= radius * radius
end

return Players
