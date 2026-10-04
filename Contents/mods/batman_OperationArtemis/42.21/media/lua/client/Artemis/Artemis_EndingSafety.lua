-- Dégage l'arrivée en solo avant la pause de l'écran de fin.
-- API vanilla 42.21 : ISSpawnHordeUI:onRemoveZombies (retrait sans cadavre).
-- Le multijoueur exige une suppression synchronisée serveur, pas un retrait client.
local Safety = {}
Safety.RADIUS = 20

function Safety.clearArrival(player)
    if isClient() or isServer() or not player or player:isDead() then return 0 end
    local zombies = getCell():getZombieList()
    local px, py, pz = player:getX(), player:getY(), math.floor(player:getZ())
    local removed = 0
    -- removeFromWorld retire aussi l'entrée de la liste : parcourir à rebours.
    for index = zombies:size() - 1, 0, -1 do
        local zombie = zombies:get(index)
        local dx, dy = zombie:getX() - px, zombie:getY() - py
        if math.floor(zombie:getZ()) == pz and dx * dx + dy * dy <= Safety.RADIUS * Safety.RADIUS then
            zombie:removeFromWorld()
            zombie:removeFromSquare()
            removed = removed + 1
        end
    end
    return removed
end

return Safety
