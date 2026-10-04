-- Acte III, dossier NON LU, Siege Night actif et contrôle Artemis
-- PZPuppet.runFile("OperationArtemis/22_siege_optionnel.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="22_siege_optionnel"; p.reportCase="22_siege_optionnel"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
