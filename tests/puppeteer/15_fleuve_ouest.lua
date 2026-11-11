-- Acte III avec dossier; BoatCore/WorkingMotorboat ou Aquatsar; commandes manuelles
-- PZDevKit.Scenario.runFile("OperationArtemis/15_fleuve_ouest.lua",{playerIndex=0,manualStop=false})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="15_fleuve_ouest"; p.reportCase="15_fleuve_ouest"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
