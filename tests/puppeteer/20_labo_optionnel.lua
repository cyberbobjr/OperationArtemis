-- Après 05 si ch4_lab; Tikitown et dépendances présents dès création
-- PZPuppet.runFile("OperationArtemis/20_labo_optionnel.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="20_labo_optionnel"; p.reportCase="20_labo_optionnel"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
