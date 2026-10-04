-- Acte III obtenu normalement sur une AUTRE partie; sans mods bateau
-- PZPuppet.runFile("OperationArtemis/11_appel_passeur.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="11_appel_passeur"; p.reportCase="11_appel_passeur"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
