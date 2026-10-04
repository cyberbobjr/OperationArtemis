-- Acte III, dossier, appel B jamais accepté, transport Artemis, hors quai passeur
-- PZPuppet.runFile("OperationArtemis/17_refus_radio_serveur.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="17_refus_radio_serveur"; p.reportCase="17_refus_radio_serveur"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
