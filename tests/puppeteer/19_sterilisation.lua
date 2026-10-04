-- Acte III, dossier NON LU, SterilizationDays=1 dès création; pas de fin
-- PZPuppet.runFile("OperationArtemis/19_sterilisation.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="19_sterilisation"; p.reportCase="19_sterilisation"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
