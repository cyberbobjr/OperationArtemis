-- Après 09; tenue selon la durée de journée réelle; vitesse normale, équipement de survie
-- PZPuppet.runFile("OperationArtemis/10_fin_helicoptere.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="10_fin_helicoptere"; p.reportCase="10_fin_helicoptere"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
