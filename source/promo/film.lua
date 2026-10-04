-- Plateau promotionnel : actions reelles, pas un test du parcours nominal.
-- PZPuppet.runFile("OperationArtemisTrailer/film.lua",{playerIndex=0})
require "PZDirector/PZDirector_Core"
require "RadioCom/ISRadioAction"
-- Never reload PZPuppet_Core from here: runFile is executing this file, and a reloaded
-- core makes its own factory check (getmetatable(scenario)==Scenario) fail.
-- Hot reload of the engine and production modules: PZDirector/tools/tournage.py --reload,
-- which reloads them in a separate request before runFile.
assert(not PZPuppet.status() or PZPuppet.status().status~="running","Arreter la prise precedente")
assert(PZDirector.production,"Module de production PZDirector non charge")
assert(PZPuppet.Scenario.teleport,"Etapes de debug PZPuppet non chargees")

return function(params)
    params=params or {}
    local P,D=PZPuppet,PZDirector
    local Story=require "Artemis/Artemis_Story"
    local Const=require "Artemis/Artemis_Const"
    local Smoke=require "SignalSmoke/SignalSmoke"
    local chapters=Story.CHAPTERS
    local seconds=params.seconds or 3
    assert(type(seconds)=="number" and seconds>=2 and seconds<=10,"seconds: 2 a 10")
    local plans={
        {id="01_notebook",point=chapters.ch1_bunker.siteAccess,hour=10,mode="sneak",
            evidence={point=chapters.ch1_bunker.site,type=Const.ITEM.MISSION_ORDERS,container="desk"}},
        {id="02_clinic",point=chapters.ch2_clinic.siteAccess,hour=11,mode="walk",
            evidence={point=chapters.ch2_clinic.site,type=Const.ITEM.PATIENT_FILE,container="filingcabinet"}},
        {id="03_relay",point={x=4835,y=6278,z=0},hour=12,mode="radio"},
        {id="04_archives",point=chapters.ch5_base.siteAccess,hour=12,mode="sneak",
            evidence={point=chapters.ch5_base.site,type=Const.ITEM.DOSSIER,container="filingcabinet"}},
        {id="05_escape",point=chapters.ch5_base.entrance,hour=12,mode="alarm"},
        {id="06_pursuit",point=chapters.ch5_base.entrance,hour=16,mode="chase"},
        {id="07_ferry",point={x=1637,y=5577,z=0},hour=7,mode="observe"},
        {id="08_checkpoint",point={x=12608,y=1168,z=0},hour=10,mode="armed"},
        {id="09_extraction",point={x=12548,y=4226,z=0},hour=8,mode="extraction"},
    }
    local selected={}
    for _,plan in ipairs(plans) do
        if not params.shot or params.shot==plan.id then selected[#selected+1]=plan end
    end
    assert(#selected>0,"Prise inconnue")
    local function marker(c,event,shot)
        print("[ArtemisFilm] "..event.."|"..c.vars.film.token.."|"..(shot or "film"))
    end
    local function square(x,y,z)
        return getCell():getGridSquare(math.floor(x),math.floor(y),z)
    end
    local scene=D.production("Operation Artemis / trailer",{
        duration=1,countdown=8,hideUI=params.hideUI~=false,protect=false,zoom=params.zoom or 0.75,
        preflight=function(c)
            assert(getCore():getVersion():sub(1,5)=="42.21","Build 42.21 requise")
            local world=getWorld():getWorld()
            assert(world:match("^PZDirector_Artemis_") or world:match("^PZPuppet_Artemis_"),
                "Partie de test ou de tournage Artemis dediee requise")
            assert(P.Game.queueSize(c.player)==0,"Vider la file d'actions")
            assert(getActivatedMods():contains("batman_OperationArtemis"),"Activer Operation Artemis")
            assert(getActivatedMods():contains("batman_SignalSmoke"),"Activer Signal Smoke")
            c.vars.film={token=tostring(getTimestampMs()),signals={},radios={}}
        end,
    })
    scene:call("PREPARATION: plateau de tournage",function(c) marker(c,"PREP") end)
         :cast({name="Survivant / enqueteur",costume="field",
             primary={type="Base.HandTorch",charge=1},
             secondary={type="Base.WalkieTalkie5",radio={channel=108000,volume=0.65}}})
         :activate(function(c) return c.vars.production.props.primary end,true)
         :check("LAMPE: chargee, allumee et tenue par l'acteur",function(c)
             local torch=c.vars.production.props.primary
             return c.player:getPrimaryHandItem()==torch and torch:isEmittingLight()
         end)
    for _,definition in ipairs(selected) do
        local plan=definition
        local moving=not plan.evidence and plan.mode~="radio" and plan.mode~="armed"
        scene:location(plan.id,{point=plan.point,hour=plan.hour,
            travelTiles=moving and 6 or 0,radius=5,isolate=60})
        if plan.point.z<0 then
            scene:light({r=0.28,g=0.26,b=0.22,radius=12})
                 :light({r=0.3,g=0.035,b=0.025,radius=5,dx=-3,dy=-3})
        end
        scene:call("Preparer les effets: "..plan.id,function(c)
                 -- Keep unrelated weather broadcasts out of the story take.
                 -- Only loaded set radios are switched off, with their state retained.
                 local origin=c.vars.director.origin
                 for dx=-5,5 do for dy=-5,5 do
                     local sq=square(origin.x+dx,origin.y+dy,origin.z)
                     if sq then
                         local objects=sq:getObjects()
                         for i=0,objects:size()-1 do
                             local radio=objects:get(i)
                             if instanceof(radio,"IsoRadio") then
                                 local data=radio:getDeviceData()
                                 c.vars.film.radios[#c.vars.film.radios+1]={data=data,on=data:getIsTurnedOn()}
                                 data:setIsTurnedOn(false)
                             end
                         end
                     end
                 end end
                 c.player:setPrimaryHandItem(c.vars.production.props.primary)
                 c.player:setSecondaryHandItem(c.vars.production.props.secondary)
                 if plan.mode=="chase" or plan.mode=="armed" then
                     local gun=c.vars.film.gun
                     if not gun then
                         gun=P.Debug.spawnItem("Base.Revolver_Short",1,c.playerIndex)[1]
                         c.vars.production.items[#c.vars.production.items+1]=gun
                         c.vars.film.gun=gun
                     end
                     gun:setCurrentAmmoCount(gun:getMaxAmmo()); gun:setJammed(false)
                     c.player:setPrimaryHandItem(gun); c.player:setSecondaryHandItem(nil)
                     assert(not c.player:isUnlimitedAmmo(),"Desactiver les munitions illimitees pour le tir reel")
                 end
                 if plan.evidence then
                     local point=plan.evidence.point
                     local container
                         local sq=square(point.x,point.y,point.z)
                         if sq then
                             local objects=sq:getObjects()
                             for i=0,objects:size()-1 do
                                 local candidate=objects:get(i):getContainer()
                                 if candidate and candidate:getType()==plan.evidence.container then
                                     container=container or candidate
                                 end
                             end
                         end
                     assert(container,"Le meuble des preuves doit reellement exister")
                     -- Film prop of the mod's exact type, placed in its actual set.
                     -- Pickup follows on camera; existing evidence is not moved.
                     local item=P.Debug.spawnItem(plan.evidence.type,1,c.playerIndex)[1]
                     c.vars.production.items[#c.vars.production.items+1]=item
                     c.player:getInventory():Remove(item)
                     assert(container:AddItem(item),"Accessoire de preuve non place")
                     c.vars.film.evidence=item
                 end
                 if plan.mode=="extraction" then
                     local o=c.vars.director.origin
                     local id=Smoke.start{x=math.floor(o.x)+2,y=math.floor(o.y)+2,z=o.z,
                         color="green",minutes=30,source="ArtemisTrailer"}
                     assert(id,"Signal de plateau non cree")
                     c.vars.film.signals[#c.vars.film.signals+1]=id
                 end
                 if plan.mode=="radio" then
                     local sq=assert(square(4836,6277,0),"Case de la vraie radio non chargee")
                     local objects=sq:getObjects()
                     for i=0,objects:size()-1 do
                         local object=objects:get(i)
                         if instanceof(object,"IsoRadio") then c.vars.film.tape=object; break end
                     end
                     local radio=assert(c.vars.film.tape,"La vraie radio de la bande de V est absente")
                     c.vars.film.tapeWasOn=radio:getDeviceData():getIsTurnedOn()
                     assert(sq:haveElectricity() or (sq:hasGridPower() and sq:getRoom()),
                         "Alimenter reellement le relais avant de filmer la bande de V")
                     -- Reset only this tape's switch so the actual vanilla action can replay it.
                     radio:getDeviceData():setIsTurnedOn(false)
                 end
             end)
        if plan.mode=="chase" then
            scene:extra("assaillant",{behind=3,side=0,outfit="Generic02",speed="fast"})
                 :extra("poursuivant",{behind=4,side=1,outfit="Generic02",speed="sprint"})
        end
        scene:wait(4)
             :check("ACTEUR ET HEURE REELS: "..plan.id,function(c)
                 local p=c.player
                 return not p:isGodMod() and not p:isInvisible() and not p:isGhostMode()
                     and not p:isNoClip() and not p:isZombiesDontAttack()
                     and math.abs(getGameTime():getTimeOfDay()-plan.hour)<0.01
             end)
             :call("MOTEUR: "..plan.id,function(c)
                 c.vars.film.activeShot=plan.id
                 if params.hideUI~=false then ISUIHandler.setVisibleAllUI(false) end
                 local p=c.player
                 print("[ArtemisFilm] SET|"..plan.id.."|hour="..plan.hour.."|x="..p:getX()
                     .."|y="..p:getY().."|z="..p:getZ().."|cheats=false")
                 takeScreenshot("ArtemisFilm_"..c.vars.film.token.."_"..plan.id..".png")
                 marker(c,"ROLL",plan.id)
             end)
             :wait(3)
             :call("ACTION: "..plan.id,function(c)
                 marker(c,"ACTION",plan.id)
                 if plan.mode=="alarm" then D.sound(c,"VehicleSirenWall",0,0) end
                 if plan.mode=="extraction" then D.sound(c,"Helicopter",0,0) end
             end)
        if plan.evidence then
            scene:crouch(false)
                 :approachContainer(function(c) return c.vars.film.evidence:getContainer() end,30)
                 :transfer(function(c) return c.vars.film.evidence end,nil,20)
                 :check("PREUVE: vrai document du mod recupere",function(c)
                     return c.vars.film.evidence:getContainer()==c.player:getInventory()
                 end):wait(0.7)
        elseif plan.mode=="radio" then
            scene:act("Allumer la vraie radio du relais",function(c)
                return ISRadioAction:new("ToggleOnOff",c.player,c.vars.film.tape,nil)
            end,function(c) return c.vars.film.tape:getDeviceData():getIsTurnedOn()==true end,10)
                 :wait(seconds)
        elseif plan.mode=="chase" then
            scene:stand()
                 :releaseExtra("assaillant")
                 :call("INSERT: arme et menace",function(c) marker(c,"BEAT","06_pursuit_fire") end)
                 :shootAt(function(c) return c.vars.production.namedExtras.assaillant end,
                     {shots=1,aimTime=0.7,timeout=12})
                 :releaseExtra("poursuivant")
                 :call("INSERT: fuite",function(c) marker(c,"BEAT","06_pursuit_run") end)
                 :moveOnSet("sprint",15)
        elseif plan.mode=="armed" then
            scene:stand():aimAt(function(c)
                local o=c.vars.director.origin
                return o.x+2,o.y,o.z
            end,1.5)
        elseif plan.mode=="observe" then
            scene:stand():emote("stop",{hold=1,timeout=5}):moveOnSet("run",15)
        elseif plan.mode=="extraction" then
            scene:stand():emote("comehere",{hold=1.5,timeout=5}):moveOnSet("run",15)
        else
            scene:crouch(plan.mode=="sneak")
            scene:moveOnSet(plan.mode=="alarm" and "sprint" or "walk",15)
        end
        scene:call("COUPE: "..plan.id,function(c)
            marker(c,"CUT",plan.id); c.vars.film.activeShot=nil
            -- Les seuls figurants crees par ce tournage sont retires entre les plateaux.
            local sounds=c.vars.director.sounds
            for i=#sounds,1,-1 do
                sounds[i].emitter:stopSoundLocal(sounds[i].id); table.remove(sounds,i)
            end
            if plan.mode=="radio" then
                c.vars.film.tape:getDeviceData():setIsTurnedOn(c.vars.film.tapeWasOn)
                c.vars.film.tape=nil
            end
            for _,radio in ipairs(c.vars.film.radios) do radio.data:setIsTurnedOn(radio.on) end
            c.vars.film.radios={}
            if plan.mode=="extraction" then
                for _,id in ipairs(c.vars.film.signals) do Smoke.stop(id) end
                c.vars.film.signals={}
            end
        end):clearExtras()
        if plan.mode=="extraction" then scene:wait(2) end
    end
    scene:call("Toutes les prises sont terminees",function(c) c.vars.film.finished=true end)
    scene:finally(function(c)
        local f=c.vars.film
        if not f then return end
        local errors={}
        local function restore(fn)
            local ok,err=pcall(fn)
            if not ok then errors[#errors+1]=tostring(err) end
        end
        if f.activeShot then marker(c,"ABORT",f.activeShot) end
        if f.tape then restore(function() f.tape:getDeviceData():setIsTurnedOn(f.tapeWasOn) end) end
        for _,radio in ipairs(f.radios) do restore(function() radio.data:setIsTurnedOn(radio.on) end) end
        for _,id in ipairs(f.signals) do restore(function() Smoke.stop(id) end) end
        marker(c,(f.finished and #errors==0) and "FINISHED" or "FAILED")
        assert(#errors==0,"Nettoyage du plateau: "..table.concat(errors," | "))
    end)
    return scene
end
