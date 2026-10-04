-- Plateau promotionnel : actions reelles, pas un test du parcours nominal.
-- PZPuppet.runFile("OperationArtemisTrailer/film.lua",{playerIndex=0})
require "PZDirector/PZDirector_Core"

return function(params)
    params=params or {}
    local P,D,S=PZPuppet,PZDirector,PZPuppet.Debug
    local Story=require "Artemis/Artemis_Story"
    local Smoke=require "SignalSmoke/SignalSmoke"
    local chapters=Story.CHAPTERS
    local seconds=params.seconds or 10
    assert(type(seconds)=="number" and seconds>=6 and seconds<=30,"seconds: 6 a 30")
    local plans={
        {id="01_notebook",point=chapters.ch1_bunker.entrance,hour=10,mode="sneak"},
        {id="02_clinic",point=chapters.ch2_clinic.siteAccess,hour=11,mode="walk"},
        {id="03_relay",point=chapters.ch3_relay.entrance,hour=12,mode="radio"},
        {id="04_archives",point=chapters.ch5_base.siteAccess,hour=12,mode="sneak"},
        {id="05_escape",point=chapters.ch5_base.entrance,hour=12,mode="alarm"},
        {id="06_pursuit",point={x=5680,y=12510,z=0},hour=16,mode="chase"},
        {id="07_ferry",point={x=1637,y=5577,z=0},hour=7,mode="observe"},
        {id="08_checkpoint",point={x=12608,y=1168,z=0},hour=10,mode="walk"},
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
    local function free(x,y,z)
        local sq=square(x,y,z)
        return sq and sq:isFree(false) and not sq:isWaterSquare()
    end
    local function route(c)
        local p=c.vars.director.origin
        for _,v in ipairs({{3,0},{-3,0},{0,3},{0,-3},{2,0},{-2,0},{0,2},{0,-2}}) do
            local valid=true
            local length=math.max(math.abs(v[1]),math.abs(v[2]))
            for n=1,length do
                if not free(p.x+v[1]*n/length,p.y+v[2]*n/length,p.z) then valid=false end
            end
            if valid then return {x=p.x+v[1],y=p.y+v[2],z=p.z} end
        end
        error("Aucun petit trajet libre sur ce plateau ; ajuster le point")
    end
    local function fixture(c,fullType)
        local item=S.spawnItem(fullType,1,c.playerIndex)[1]
        c.vars.film.items[#c.vars.film.items+1]=item
        return item
    end
    local scene=D.scene("Operation Artemis / trailer",{
        duration=1,countdown=8,hideUI=params.hideUI~=false,protect=true,
        preflight=function(c)
            assert(getCore():getVersion():sub(1,5)=="42.21","Build 42.21 requise")
            local world=getWorld():getWorld()
            assert(world:match("^PZDirector_Artemis_") or world:match("^PZPuppet_Artemis_"),
                "Partie de test ou de tournage Artemis dediee requise")
            assert(P.Game.queueSize(c.player)==0,"Vider la file d'actions")
            assert(getActivatedMods():contains("batman_OperationArtemis"),"Activer Operation Artemis")
            assert(getActivatedMods():contains("batman_SignalSmoke"),"Activer Signal Smoke")
            c.vars.film={token=tostring(getTimestampMs()),items={},signals={},
                origin=S.position(c.playerIndex),hour=getGameTime():getTimeOfDay(),
                primary=c.player:getPrimaryHandItem(),secondary=c.player:getSecondaryHandItem()}
        end,
    })
    scene:call("PREPARATION: accessoires de tournage uniquement",function(c)
        marker(c,"PREP")
        c.vars.film.radio=fixture(c,"Base.WalkieTalkie5")
        local data=c.vars.film.radio:getDeviceData()
        data:setHasBattery(true); data:setPower(1); data:setIsTurnedOn(false)
        data:setChannel(108000); data:setDeviceVolume(0.65)
        c.vars.film.torch=fixture(c,"Base.HandTorch")
        c.vars.film.torch:setUsedDelta(1); c.vars.film.torch:setActivated(false)
    end)
    scene:equip(function(c) return c.vars.film.radio end,true,false,30)
         :equip(function(c) return c.vars.film.torch end,false,false,30)
         :interact("Allumer la lampe par le callback vanilla",function(c)
             ISInventoryPaneContextMenu.onActivateItem(c.vars.film.torch,c.playerIndex)
         end,function(c) return c.vars.film.torch:isEmittingLight() end,10)
    for _,definition in ipairs(selected) do
        local plan=definition
        scene:teleport(plan.point.x,plan.point.y,plan.point.z,60)
             :await("Plateau charge: "..plan.id,function(c)
                 local p=c.player
                 return p:getCurrentSquare()~=nil and square(p:getX()+6,p:getY()+6,p:getZ())~=nil
                     and square(p:getX()-6,p:getY()-6,p:getZ())~=nil
             end,60)
             :call("Preparer le cadre: "..plan.id,function(c)
                 S.setTimeOfDay(plan.hour)
                 local p=c.player
                 c.vars.director.origin={x=p:getX(),y=p:getY(),z=p:getZ()}
                 c.vars.film.route=route(c)
                 if plan.mode=="extraction" then
                     local o=c.vars.director.origin
                     local id=Smoke.start{x=math.floor(o.x)+2,y=math.floor(o.y)+2,z=o.z,
                         color="green",minutes=30,source="ArtemisTrailer"}
                     assert(id,"Signal de plateau non cree")
                     c.vars.film.signals[#c.vars.film.signals+1]=id
                 end
                 if plan.mode=="chase" then
                     local count=0
                     local o=c.vars.director.origin
                     for _,offset in ipairs({{-5,-3},{-5,3},{3,5},{5,-3},{-3,-5}}) do
                         local sq=square(o.x+offset[1],o.y+offset[2],o.z)
                         if count<3 and sq and sq:isOutside() and free(o.x+offset[1],o.y+offset[2],o.z) then
                             D.zombie(c,offset[1],offset[2],{outfit="Generic02",invulnerable=true})
                             count=count+1
                         end
                     end
                     assert(count>0,"Aucune case libre pour les figurants exterieurs")
                 end
             end)
             :wait(2)
             :call("MOTEUR: "..plan.id,function(c)
                 c.vars.film.activeShot=plan.id
                 marker(c,"ROLL",plan.id)
             end)
             :wait(3)
             :call("ACTION: "..plan.id,function(c)
                 marker(c,"ACTION",plan.id)
                 if plan.mode=="alarm" then D.sound(c,"VehicleSirenWall",0,0) end
                 if plan.mode=="extraction" then D.sound(c,"Helicopter",0,0) end
             end)
        if plan.mode=="radio" then
            scene:emote("stop",10):wait(seconds)
        elseif plan.mode=="observe" or plan.mode=="extraction" then
            scene:stand():wait(seconds)
        else
            scene:crouch(plan.mode=="sneak")
            local running=plan.mode=="alarm" or plan.mode=="chase"
            scene:call("Allure de prise",function(c)
                c.vars.director.motion=running and "run" or "walk"
                D.updateActor(c)
            end)
            scene:travelTo(function(c)
                local r=c.vars.film.route
                return r.x,r.y,r.z
            end,nil,nil,30):wait(seconds)
            scene:call("Relacher la course",function(c)
                c.vars.director.motion=nil
                c.player:setForceRun(false); c.player:setRunning(false)
            end)
        end
        scene:call("COUPE: "..plan.id,function(c)
            marker(c,"CUT",plan.id); c.vars.film.activeShot=nil
            -- Les seuls figurants crees par ce tournage sont retires entre les plateaux.
            local spawned=c.vars.director.spawned
            for i=#spawned,1,-1 do S.removeSpawned(spawned[i]); table.remove(spawned,i) end
            local sounds=c.vars.director.sounds
            for i=#sounds,1,-1 do
                sounds[i].emitter:stopSoundLocal(sounds[i].id); table.remove(sounds,i)
            end
        end)
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
        for _,id in ipairs(f.signals) do restore(function() Smoke.stop(id) end) end
        restore(function() c.player:setPrimaryHandItem(f.primary); c.player:setSecondaryHandItem(f.secondary) end)
        for i=#f.items,1,-1 do
            local item=f.items[i]
            restore(function() S.removeSpawned(item) end)
        end
        restore(function() S.setTimeOfDay(f.hour) end)
        restore(function() S.teleport(f.origin.x,f.origin.y,f.origin.z,c.playerIndex) end)
        marker(c,(f.finished and #errors==0) and "FINISHED" or "FAILED")
        assert(#errors==0,"Nettoyage du plateau: "..table.concat(errors," | "))
    end)
    return scene
end
