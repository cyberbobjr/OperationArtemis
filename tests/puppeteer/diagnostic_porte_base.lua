-- Read-only diagnostic, separate from the nominal campaign and its statuses.
-- PZPuppet.runFile("OperationArtemis/diagnostic_porte_base.lua",{playerIndex=0},{testSave="2026-10-03_18-48-28"})
return function(params)
    local s=PZPuppet.scenario("ArtemisDiagnostic/porte_base")
    s:check("PRE: solo debug Build 42.21",function()
        local version=tostring(getCore():getVersionNumber())
        return isDebugEnabled() and not isClient() and not isServer()
            and (version=="42.21" or version:match("^42%.21%.")~=nil)
    end)
    s:check("PRE: dedicated test save",function()
        local world=tostring(getWorld():getWorld())
        return world:match("^PZPuppet_Artemis_")~=nil
            or (type(params.testSave)=="string" and params.testSave~="" and world==params.testSave)
    end)
    s:call("Observe entrance door and real inventory key, no mutation",function(c)
        local sq=getCell():getGridSquare(5584,12483,0)
        assert(sq,"Entrance square not loaded")
        c.vars.found=0
        local objects=sq:getObjects()
        for i=0,objects:size()-1 do
            local door=objects:get(i)
            if instanceof(door,"IsoDoor") then
                c.vars.found=c.vars.found+1
                local matching=c.player:getInventory():haveThisKeyId(door:getKeyId())
                print("[ArtemisDoor] index="..i.." sprite="..tostring(door:getSprite():getName())
                    .." doorKey="..door:getKeyId().." matchingKey="..tostring(matching~=nil)
                    .." forceLocked="..tostring(door:getProperties():has("forceLocked"))
                    .." lockedByKey="..tostring(door:isLockedByKey()).." open="..tostring(door:IsOpen())
                    .." barricaded="..tostring(door:isBarricaded()).." obstructed="..tostring(door:isObstructed())
                    .." couldOpen="..tostring(door:couldBeOpen(c.player)))
            end
        end
        print("[ArtemisDoor] player="..c.player:getX()..","..c.player:getY()..","..c.player:getZ())
    end)
    s:check("Diagnostic found entrance door (does not assert opening)",function(c) return c.vars.found>0 end)
    s:finally(function() print("[ArtemisDoor] read-only diagnostic finished; no world changes") end)
    return s
end
