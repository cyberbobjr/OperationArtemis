-- Après 03, ch2_clinic
-- PZDevKit.Scenario.runFile("OperationArtemis/04_clinique.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="04_clinique"; p.reportCase="04_clinique"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
