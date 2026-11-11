-- Après 31 puis sauvegarde dédiée et redémarrage complet, état stable
-- PZDevKit.Scenario.runFile("OperationArtemis/25_sauvegarde_rechargee.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="25_sauvegarde_rechargee"; p.reportCase="25_sauvegarde_rechargee"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
