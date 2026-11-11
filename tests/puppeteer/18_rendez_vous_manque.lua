-- Appel B accepté, transport Artemis; aucune fin
-- PZDevKit.Scenario.runFile("OperationArtemis/18_rendez_vous_manque.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="18_rendez_vous_manque"; p.reportCase="18_rendez_vous_manque"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
