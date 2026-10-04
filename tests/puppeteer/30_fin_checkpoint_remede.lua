-- Quarantaine 1h, dossier et seringue de remède authentique en inventaire
-- PZPuppet.runFile("OperationArtemis/30_fin_checkpoint_remede.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="14_fin_checkpoint"; p.reportCase="30_fin_checkpoint_remede"; p.expectCure=true; p.expectDossier=true
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
