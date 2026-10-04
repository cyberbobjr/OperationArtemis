-- Après 04, ch3_relay; réseau actif ou générateur connecté alimentant la salle
-- PZPuppet.runFile("OperationArtemis/05_relais.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="05_relais"; p.reportCase="05_relais"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
