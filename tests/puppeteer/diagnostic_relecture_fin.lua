-- Relecture réelle via le callback du journal; aucune fermeture automatique.
-- Solo debug 42.21, partie dédiée terminée avec choix Continuer, aucun écran déjà ouvert.
-- Fermer manuellement après au moins 15 s; rendu et audio évalués par le joueur.
return function(params)
    params=params or {}
    local P=PZPuppet
    local Ending,Journal
    local function state() return ModData.get("batman_Artemis") end
    local function choice(c) return state().flags.endingChoice[c.player:getUsername()] end
    local s=P.scenario("ArtemisDiagnostic/relecture_fin")
    s:check("PRE: solo debug 42.21 and exact dedicated save",function()
        local version=tostring(getCore():getVersionNumber())
        local world=tostring(getWorld():getWorld())
        return not isClient() and not isServer() and isDebugEnabled()
            and (version=="42.21" or version:match("^42%.21%.")~=nil)
            and (world:match("^PZPuppet_Artemis_")~=nil or world==params.testSave)
    end)
    s:call("SETUP: load real journal callback; observe screen during pause",function(c)
        Ending=require "Artemis/Artemis_EndingUI"
        Journal=require "Artemis/Artemis_JournalUI"
        print("[ArtemisPuppet] relecture_fin save="..getWorld():getWorld()
            .." build="..getCore():getVersionNumber().." act="..tostring(state() and state().act))
        c.vars.observer=function()
            if not c.vars.screen or Ending.instance~=c.vars.screen or not c.vars.screen:isReallyVisible() then return end
            c.vars.seen=true
            c.vars.started=c.vars.started or getTimestampMs()
            if getGameSpeed()~=0 then c.vars.pauseBroken=true end
            if not c.vars.readable and getTimestampMs()-c.vars.started>=15000 then
                c.vars.readable=true
                print("[ArtemisEndingRead] replay still visible after 15s; close manually when finished")
            end
        end
        Events.OnPreUIDraw.Add(c.vars.observer)
    end)
    s:check("PRE: actual completed ending continued, no open screen, normal speed",function(c)
        local t=state()
        return t and t.act==4 and t.flags and t.flags.ending and t.flags.ending.result
            and t.flags.endingChoice and choice(c)=="continue" and Ending.instance==nil
            and getGameSpeed()>=1 and getGameSpeed()<=2
    end)
    s:call("Open replay using actual journal button callback",function(c)
        local e=state().flags.ending.result
        c.vars.result={route=e.route,exit=e.exit,by=e.by,hasDossier=e.hasDossier,hasCure=e.hasCure}
        c.vars.previousSpeed=getGameSpeed()
        Journal:onReplayEnding()
        c.vars.screen=Ending.instance
    end)
    s:await("Player closed actual replay after reading",function(c)
        return c.vars.seen==true and Ending.instance==nil
    end,600)
    s:check("Replay remained visible for 15s with game paused",function(c)
        return c.vars.readable==true and not c.vars.pauseBroken and c.vars.screen.isReplay==true
    end)
    s:check("Manual close restored speed and preserved actual ending",function(c)
        local e=state().flags.ending.result
        for k,v in pairs(c.vars.result) do if e[k]~=v then return false end end
        return e.exit==c.vars.result.exit and state().act==4 and choice(c)=="continue"
            and getGameSpeed()==c.vars.previousSpeed
    end)
    s:finally(function(c)
        if c.vars.observer then Events.OnPreUIDraw.Remove(c.vars.observer) end
        if c.vars.screen and Ending.instance==c.vars.screen then c.vars.screen:close() end
        print("[ArtemisPuppet] cleanup relecture_fin; no progress change")
    end)
    return s
end
