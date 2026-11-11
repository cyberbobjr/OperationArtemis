-- Quarantaine running; aucune fin; variante destructive de la partie dédiée
-- PZDevKit.Scenario.runFile("OperationArtemis/24_checkpoint_abandon.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="24_checkpoint_abandon"; p.reportCase="24_checkpoint_abandon"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
