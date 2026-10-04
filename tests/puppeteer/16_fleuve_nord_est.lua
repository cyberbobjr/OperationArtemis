-- Acte III avec dossier; bateau du bassin Louisville; commandes manuelles
-- PZPuppet.runFile("OperationArtemis/16_fleuve_nord_est.lua",{playerIndex=0,manualStop=false})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="16_fleuve_nord_est"; p.reportCase="16_fleuve_nord_est"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
