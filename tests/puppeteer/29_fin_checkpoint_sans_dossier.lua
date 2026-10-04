-- Quarantaine 1h commencée sans dossier; non infecté; partie distincte
-- PZPuppet.runFile("OperationArtemis/29_fin_checkpoint_sans_dossier.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="14_fin_checkpoint"; p.reportCase="29_fin_checkpoint_sans_dossier"; p.expectDossier=false
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
