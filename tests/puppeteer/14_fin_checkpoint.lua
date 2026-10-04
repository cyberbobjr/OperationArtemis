-- Après 13; quarantaine running, dossier, non infecté; nourriture/eau, rester éveillé
-- PZPuppet.runFile("OperationArtemis/14_fin_checkpoint.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="14_fin_checkpoint"; p.reportCase="14_fin_checkpoint"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
