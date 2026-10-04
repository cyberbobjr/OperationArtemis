-- État stable d’une partie dédiée; avant sauvegarde et redémarrage complets
-- PZPuppet.runFile("OperationArtemis/31_reference_rechargement.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="31_reference_rechargement"; p.reportCase="31_reference_rechargement"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
