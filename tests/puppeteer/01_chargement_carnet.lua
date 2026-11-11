-- Partie neuve, acte 0; personnage lettré
-- PZDevKit.Scenario.runFile("OperationArtemis/01_chargement_carnet.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="01_chargement_carnet"; p.reportCase="01_chargement_carnet"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
