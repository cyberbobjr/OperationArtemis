-- Partie neuve, acte 0; personnage lettré
-- PZPuppet.runFile("OperationArtemis/01_chargement_carnet.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="01_chargement_carnet"; p.reportCase="01_chargement_carnet"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
