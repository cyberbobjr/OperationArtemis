-- Diagnosis only: real equipped radio, read-only authority lookups, no call command.
-- A passing diagnosis does not validate the helicopter or ferry route.
return function(params)
    local p={}
    for k,v in pairs(params or {}) do p[k]=v end
    p.case="09_appel_helicoptere"; p.reportCase="radio_appel"; p.diagnostic=true
    return PZPuppet.loadScenario("OperationArtemis/suite.lua",p)
end
