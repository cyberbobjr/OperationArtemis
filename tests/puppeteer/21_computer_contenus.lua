-- Clinique déjà révélée, ComputerModkum; CD Artemis encore au classeur
-- PZDevKit.Scenario.runFile("OperationArtemis/21_computer_contenus.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="21_computer_contenus"; p.reportCase="21_computer_contenus"
    return PZDevKit.Scenario.loadScenario("OperationArtemis/suite.lua",p)
end
