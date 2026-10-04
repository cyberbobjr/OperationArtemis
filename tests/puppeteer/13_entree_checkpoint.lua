-- Acte III obtenu normalement; sans Vaccine, non infecté; dossier selon variante
-- PZPuppet.runFile("OperationArtemis/13_entree_checkpoint.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="13_entree_checkpoint"; p.reportCase="13_entree_checkpoint"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
