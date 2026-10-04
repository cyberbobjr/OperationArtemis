-- Save through the game after case31, fully quit, restart and load the SAME save.
-- PZPuppet.runBatchFile("OperationArtemis/campagne_rechargement.lua",{playerIndex=0})
return function(params)
    local p={}
    if params.testSave~=nil then p.testSave=params.testSave end
    return {{path="OperationArtemis/25_sauvegarde_rechargee.lua",params=p}}
end
