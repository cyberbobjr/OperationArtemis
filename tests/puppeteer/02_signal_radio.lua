-- Après 01, acte I; personnage non sourd
-- PZDevKit.Scenario.runFile("OperationArtemis/02_signal_radio.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="02_signal_radio"; p.reportCase="02_signal_radio"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
