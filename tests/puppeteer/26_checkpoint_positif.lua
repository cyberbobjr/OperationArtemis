-- Acte III; sans Vaccine; personnage de test réellement infecté, voie non ouverte
-- PZPuppet.runFile("OperationArtemis/26_checkpoint_positif.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="26_checkpoint_positif"; p.reportCase="26_checkpoint_positif"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
