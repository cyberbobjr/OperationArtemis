-- Clinique déjà révélée, ComputerModkum; CD Artemis encore au classeur
-- PZPuppet.runFile("OperationArtemis/21_computer_contenus.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="21_computer_contenus"; p.reportCase="21_computer_contenus"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
