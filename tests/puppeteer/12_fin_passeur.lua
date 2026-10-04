-- Après 11; jour de 60 minutes; équipement de survie
-- PZPuppet.runFile("OperationArtemis/12_fin_passeur.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="12_fin_passeur"; p.reportCase="12_fin_passeur"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
