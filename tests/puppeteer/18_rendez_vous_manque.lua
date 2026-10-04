-- Appel B accepté, transport Artemis; aucune fin
-- PZPuppet.runFile("OperationArtemis/18_rendez_vous_manque.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="18_rendez_vous_manque"; p.reportCase="18_rendez_vous_manque"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
