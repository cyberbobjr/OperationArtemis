-- Après 07, dossier porté, évasion active, z=-17
-- PZDevKit.Scenario.runFile("OperationArtemis/08_evasion.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="08_evasion"; p.reportCase="08_evasion"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
