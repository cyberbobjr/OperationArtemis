-- Acte III, Vaccine actif, personnage non infecté; test manuel au spectromètre
-- PZPuppet.runFile("OperationArtemis/23_vaccine_entree.lua",{playerIndex=0,manualStop=false})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="23_vaccine_entree"; p.reportCase="23_vaccine_entree"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
