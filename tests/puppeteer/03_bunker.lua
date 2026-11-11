-- Après 02, ch1_bunker
-- PZDevKit.Scenario.runFile("OperationArtemis/03_bunker.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="03_bunker"; p.reportCase="03_bunker"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
