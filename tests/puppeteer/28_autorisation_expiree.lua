-- Acte III, non infecté, sans Vaccine ni entrée précédente; vrai test puis rester dehors.
-- PZPuppet.runFile("OperationArtemis/28_autorisation_expiree.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="28_autorisation_expiree"; p.reportCase="28_autorisation_expiree"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
