-- Test en jeu du véritable écran initial avec la fin C déjà enregistrée.
-- Ne rejoue pas une exfiltration et ne change aucune progression.
-- Deux zombies de fixture figés : proche retiré par le mod, témoin hors rayon conservé.
return function(params)
    params=params or {}
    local P,D=PZPuppet,PZPuppet.Debug
    local Ending,Safety
    local function state() return ModData.get("batman_Artemis") end
    local function present(z) return z~=nil and getCell():getZombieList():contains(z) end
    local function nearby(c)
        local n=0
        local zs=getCell():getZombieList()
        for i=0,zs:size()-1 do
            local z=zs:get(i)
            local dx,dy=z:getX()-c.player:getX(),z:getY()-c.player:getY()
            if math.floor(z:getZ())==math.floor(c.player:getZ()) and dx*dx+dy*dy<=400 then n=n+1 end
        end
        return n
    end
    local s=P.scenario("ArtemisDiagnostic/degagement_fin")
    s:check("PRE: solo debug 42.21 and exact dedicated save",function()
        local v=tostring(getCore():getVersionNumber())
        local world=tostring(getWorld():getWorld())
        return not isClient() and not isServer() and isDebugEnabled()
            and (v=="42.21" or v:match("^42%.21%.")~=nil)
            and (world:match("^PZPuppet_Artemis_")~=nil or world==params.testSave)
    end)
    s:call("SETUP: load real ending UI and cleanup observer",function(c)
        Ending=require "Artemis/Artemis_EndingUI"
        Safety=require "Artemis/Artemis_EndingSafety"
        print("[ArtemisPuppet] degagement_fin save="..getWorld():getWorld()
            .." build="..getCore():getVersionNumber().." act="..tostring(state() and state().act))
        c.vars.observer=function()
            if not c.vars.screen or Ending.instance~=c.vars.screen or not c.vars.screen:isReallyVisible() then return end
            c.vars.seen=true
            c.vars.started=c.vars.started or getTimestampMs()
            c.vars.visibleMs=getTimestampMs()-c.vars.started
            if getGameSpeed()~=0 then c.vars.pauseBroken=true end
            if not c.vars.readable and c.vars.visibleMs>=15000 then
                c.vars.readable=true
                c.vars.continueButton:setEnable(true)
                print("[ArtemisEndingSafetyTest] panel still visible after 15s; click Continue when finished")
            end
        end
        Events.OnPreUIDraw.Add(c.vars.observer)
    end)
    s:check("PRE: continued C ending, no panel, original bridge arrival and normal speed",function(c)
        local t=state()
        return t and t.act==4 and t.flags and t.flags.ending and t.flags.ending.result
            and t.flags.ending.result.route=="C" and t.flags.endingChoice
            and t.flags.endingChoice[c.player:getUsername()]=="continue"
            and Ending.instance==nil and Safety.RADIUS==20 and not c.player:getVehicle()
            and P.Game.near(c.player,12599.5,957.5,0,2)
            and getGameSpeed()>=1 and getGameSpeed()<=2
    end)
    s:check("PRE: two loaded clear bridge fixture squares",function()
        for _,y in ipairs({953,934}) do
            local sq=getCell():getGridSquare(12599,y,0)
            if not sq or not sq:isFree(false) or not sq:hasFloor() then return false end
        end
        return true
    end)
    s:call("SETUP: two frozen fixture zombies; record kills and progress",function(c)
        c.vars.near=D.spawnZombie(12599,953,0,{invulnerable=true})
        D.freezeZombie(c.vars.near,true)
        c.vars.far=D.spawnZombie(12599,934,0,{invulnerable=true})
        D.freezeZombie(c.vars.far,true)
        c.vars.kills=c.player:getZombieKills()
        c.vars.rev=state().rev
        c.vars.result=state().flags.ending.result
        c.vars.previousSpeed=getGameSpeed()
    end)
    s:check("Both actual fixtures present, on correct sides of radius",function(c)
        local function distance(z)
            return (z:getX()-c.player:getX())^2+(z:getY()-c.player:getY())^2
        end
        return present(c.vars.near) and present(c.vars.far)
            and distance(c.vars.near)<400 and distance(c.vars.far)>400
    end)
    s:call("Open actual initial presentation of recorded victory; no direct clear call",function(c)
        local before=nearby(c)
        Ending.open(state(),false,false)
        c.vars.screen=Ending.instance
        -- Test-only preparation: prevent an accidental early Continue click.
        c.vars.continueButton=c.vars.screen.buttons[2].button
        c.vars.continueButton:setEnable(false)
        c.vars.nearRemoved=not present(c.vars.near)
        c.vars.farKept=present(c.vars.far)
        c.vars.remaining=nearby(c)
        -- Retire only the fixture's engine bookkeeping before zombie pooling can reuse it.
        -- The MOD has already removed it; do not call removal a second time in finally.
        if c.vars.nearRemoved then D.spawned[c.vars.near]=nil; c.vars.near=nil end
        print("[ArtemisEndingSafetyTest] before="..before.." remaining="..c.vars.remaining
            .." closeFixtureRemoved="..tostring(c.vars.nearRemoved).." farFixtureKept="..tostring(c.vars.farKept))
    end)
    s:await("Player clicked Continue after reading real screen",function(c)
        return c.vars.seen==true and Ending.instance==nil
    end,600)
    s:check("Actual UI cleared nearby zombies and preserved outside witness",function(c)
        return c.vars.nearRemoved==true and c.vars.farKept==true and c.vars.remaining==0
    end)
    s:check("Screen stayed open at least 15s",function(c)
        print("[ArtemisEndingSafetyTest] visibleMs="..tostring(c.vars.visibleMs)
            .." readable="..tostring(c.vars.readable).." pauseBroken="..tostring(c.vars.pauseBroken)
            .." isReplay="..tostring(c.vars.screen.isReplay).." speed="..getGameSpeed()
            .." previousSpeed="..c.vars.previousSpeed)
        return c.vars.readable==true,"Reading ended before 15s: visibleMs="..tostring(c.vars.visibleMs)
    end)
    s:check("Game remained paused while visible",function(c)
        return not c.vars.pauseBroken,"Pause was interrupted while panel visible"
    end)
    s:check("Real initial presentation used, not journal replay",function(c)
        return c.vars.screen.isReplay==false
    end)
    s:check("Continue restored previous game speed",function(c)
        return getGameSpeed()==c.vars.previousSpeed,
            "Current speed="..getGameSpeed()..", previous="..c.vars.previousSpeed
    end)
    s:check("No zombie kill credit, ending or progress change",function(c)
        local t=state()
        local e=t.flags.ending.result
        for _,k in ipairs({"route","exit","by","hasDossier","hasCure","day","hours","kills"}) do
            if e[k]~=c.vars.result[k] then return false end
        end
        return c.player:getZombieKills()==c.vars.kills and t.act==4 and t.rev==c.vars.rev
            and t.flags.endingChoice[c.player:getUsername()]=="continue"
    end)
    s:finally(function(c)
        if c.vars.observer then Events.OnPreUIDraw.Remove(c.vars.observer) end
        if c.vars.screen and Ending.instance==c.vars.screen then c.vars.screen:close() end
        for _,key in ipairs({"near","far"}) do
            local z=c.vars[key]
            if z then
                if present(z) then D.removeSpawned(z) else D.spawned[z]=nil end
            end
        end
        print("[ArtemisPuppet] cleanup degagement_fin; only own remaining fixtures removed")
    end)
    return s
end
