-- ch5_base, carte en inventaire, aucune évasion antérieure
-- PZPuppet.runFile("OperationArtemis/07_archives_portique.lua",{playerIndex=0})
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="07_archives_portique"; p.reportCase="07_archives_portique"
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
