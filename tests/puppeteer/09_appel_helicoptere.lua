-- Après 08; sans transport Military Drop; stérilisation désactivée
-- PZPuppet.runFile("OperationArtemis/09_appel_helicoptere.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="09_appel_helicoptere"; p.reportCase="09_appel_helicoptere"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
