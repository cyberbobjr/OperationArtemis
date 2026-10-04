-- Acte III, dossier déposé par vraie action, appel B jamais accepté
-- PZPuppet.runFile("OperationArtemis/27_appel_sans_dossier.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="27_appel_sans_dossier"; p.reportCase="27_appel_sans_dossier"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
