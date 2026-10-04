-- ch5_base après relais ou labo optionnel
-- PZPuppet.runFile("OperationArtemis/06_base_acces_capteurs.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="06_base_acces_capteurs"; p.reportCase="06_base_acces_capteurs"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
