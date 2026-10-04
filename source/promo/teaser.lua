-- Teaser Operation Artemis v2 (decoupage : TEASER.md). Actions reelles, menaces causees a l'image.
-- PZPuppet.runFile("OperationArtemisTrailer/teaser.lua",{playerIndex=0},{shot="01_carnet"})
-- Ne recharge jamais PZPuppet_Core ici (voir film.lua) : PZDirector/tools/tournage.py --reload.
require "PZDirector/PZDirector_Core"
require "PZDirector/PZDirector_Staging"
assert(not PZPuppet.status() or PZPuppet.status().status~="running","Arreter la prise precedente")
assert(PZDirector.production and PZPuppet.Scenario.teleport,"Modules de tournage non charges")

return function(params)
    params=params or {}
    local P,D=PZPuppet,PZDirector
    local Story=require "Artemis/Artemis_Story"
    local Const=require "Artemis/Artemis_Const"
    local Smoke=require "SignalSmoke/SignalSmoke"
    local ch=Story.CHAPTERS
    local TAPE={252,237,51}
    local RED={0.9,0.25,0.2}

    local function square(x,y,z) return getCell():getGridSquare(math.floor(x),math.floor(y),z) end
    local function marker(c,event,shot)
        print("[ArtemisFilm] "..event.."|"..c.vars.film.token.."|"..(shot or "film"))
    end
    local function freeSquare(sq)
        return sq and sq:isFree(false) and not sq:isWaterSquare()
    end
    -- First free square around (x,y,z), nearest ring first, skipping excluded squares.
    local function freeNear(x,y,z,radius,exclude)
        for r=1,radius do
            for dx=-r,r do for dy=-r,r do
                if math.max(math.abs(dx),math.abs(dy))==r then
                    local sq=square(x+dx,y+dy,z)
                    if freeSquare(sq) and not (exclude and exclude(sq)) then return sq end
                end
            end end
        end
    end
    local function onPath(c,sq)
        local b=c.vars.production.block
        if not b then return false end
        local steps=math.abs(b.dx)+math.abs(b.dy)
        for i=0,steps do
            local t=steps>0 and i/steps or 0
            if sq:getX()==math.floor(b.x+b.dx*t) and sq:getY()==math.floor(b.y+b.dy*t) then return true end
        end
        return false
    end
    local function containerAt(point,kind)
        local sq=square(point.x,point.y,point.z)
        if not sq then return nil end
        local objects=sq:getObjects()
        for i=0,objects:size()-1 do
            local container=objects:get(i):getContainer()
            if container and (kind==nil or container:getType()==kind) then return container end
        end
    end
    -- A copy of the mod's exact document type, readable by the document window.
    local function document(c,fullType,container)
        local item=P.Debug.spawnItem(fullType,1,c.playerIndex)[1]
        c.vars.production.items[#c.vars.production.items+1]=item
        if not item:getModData().printMedia then
            if fullType==Const.ITEM_NOTE then OperationArtemisItems.onCreateNote(item)
            else OperationArtemisItems.onCreateDocument(item) end
        end
        if container then
            c.player:getInventory():Remove(item)
            assert(container:AddItem(item),"Document non place dans son meuble")
        end
        return item
    end
    local function radioText(c,key,color)
        local radio=assert(c.vars.film.radio,"Radio du plateau absente")
        local rgb=color or TAPE
        radio:AddDeviceText(getText(key),rgb[1],rgb[2],rgb[3],nil,nil,-1)
    end
    local function gun(c,loaded)
        local f=c.vars.film
        if not f.gun then
            f.gun=P.Debug.spawnItem("Base.Revolver_Short",1,c.playerIndex)[1]
            c.vars.production.items[#c.vars.production.items+1]=f.gun
            local ammo=P.Debug.spawnItem(f.gun:getAmmoType():getItemKey(),12,c.playerIndex)
            for _,round in ipairs(ammo) do c.vars.production.items[#c.vars.production.items+1]=round end
        end
        f.gun:setJammed(false)
        f.gun:setCurrentAmmoCount(loaded or f.gun:getMaxAmmo())
        c.player:setPrimaryHandItem(f.gun); c.player:setSecondaryHandItem(nil)
        assert(not c.player:isUnlimitedAmmo(),"Munitions illimitees interdites pour un tir reel")
        return f.gun
    end
    local function stopSounds(c)
        local sounds=c.vars.director.sounds
        for i=#sounds,1,-1 do sounds[i].emitter:stopSoundLocal(sounds[i].id); table.remove(sounds,i) end
    end

    local scene=D.production("Operation Artemis / trailer",{
        -- immortal: the dead attack and grab on screen, but a take never kills the actor.
        duration=1,countdown=8,hideUI=params.hideUI~=false,protect=false,immortal=true,zoom=params.zoom or 0.75,
        preflight=function(c)
            assert(getCore():getVersion():sub(1,5)=="42.21","Build 42.21 requise")
            local world=getWorld():getWorld()
            assert(world:match("^PZDirector_Artemis_") or world:match("^PZPuppet_Artemis_"),
                "Partie de tournage Artemis dediee requise")
            assert(P.Game.queueSize(c.player)==0,"Vider la file d'actions")
            assert(getActivatedMods():contains("batman_OperationArtemis"),"Activer Operation Artemis")
            assert(getActivatedMods():contains("batman_SignalSmoke"),"Activer Signal Smoke")
            assert(OperationArtemisItems and OperationArtemisItems.onCreateDocument,"Objets Artemis absents")
            c.vars.film={token=tostring(getTimestampMs()),signals={},bodies={},generators={}}
        end,
    })
    scene:call("PREPARATION: plateau",function(c) marker(c,"PREP") end)
         :cast({name="Survivant / enqueteur",costume="field",
             primary={type="Base.HandTorch",charge=1},
             secondary={type="Base.WalkieTalkie5",radio={channel=108000,volume=0.65}}})
         :stashInventory()

    -- Common opening of every shot: set, light, settle, roll.
    local function set(id,definition)
        scene:frame(definition.zoom or params.zoom or 0.75)
        scene:location(id,{point=definition.point,hour=definition.hour,radius=definition.radius or 5,
            travelTiles=definition.travel or 6,isolate=60,outside=definition.outside})
        for _,light in ipairs(definition.lights or {}) do scene:light(light) end
        if definition.clearFog then
            -- Natural morning mist hides the set: hold a null modded fog layer for this shot.
            scene:call("METEO: sans brume",function(c)
                local fog=getClimateManager():getClimateFloat(ClimateManager.FLOAT_FOG_INTENSITY)
                fog:setEnableModded(true); fog:setModdedValue(0); fog:setModdedInterpolate(1)
                c.vars.film.fog=true
            end)
        end
    end
    local function roll(id,settle)
        scene:wait(settle or 2):call("ROLL: "..id,function(c)
            c.vars.film.activeShot=id
            -- The prop walkie's radio window ignores the hidden interface: close it for the take.
            for _,list in ipairs({ISRadioWindow and ISRadioWindow.instances or {},
                    ISRadioWindow and ISRadioWindow.instancesIso or {}}) do
                for _,window in pairs(list) do
                    if window and window.isVisible and window:isVisible() then window:setVisible(false) end
                end
            end
            takeScreenshot("ArtemisTeaser_"..c.vars.film.token.."_"..id..".png")
            marker(c,"ROLL",id)
        end)
    end
    local function cut(id)
        scene:call("COUPE: "..id,function(c)
            marker(c,"CUT",id); c.vars.film.activeShot=nil
            if c.vars.film.fog then
                -- Drop the modded fog layer at once: a fog of 0 would fade out over the next sets.
                getClimateManager():getClimateFloat(ClimateManager.FLOAT_FOG_INTENSITY):setEnableModded(false)
                c.vars.film.fog=nil
            end
            stopSounds(c)
            for _,signal in ipairs(c.vars.film.signals) do Smoke.stop(signal) end
            c.vars.film.signals={}
        end):showUI(false):clearExtras()
    end
    local function torch(c,on)
        local lamp=c.vars.production.props.primary
        c.player:setPrimaryHandItem(lamp)
        if lamp:isActivated()~=on then lamp:setActivated(on) end
    end

    local shots={}

    -- 1. Le carnet : fouille d'un soldat mort la nuit ; un rampant approche pendant la lecture.
    shots["01_carnet"]=function()
        local id="01_carnet"
        set(id,{point={x=4846,y=6292,z=0},hour=2,zoom=0.6,outside=true,travel=6,
            lights={{r=0.10,g=0.13,b=0.20,radius=10}}})
        scene:call("DECOR: soldat mort et carnet",function(c)
            local o=c.vars.production.block
            torch(c,true)
            local sq=assert(freeNear(o.x,o.y,o.z,2,function(s) return onPath(c,s) end),"Pas de place pour le corps")
            local body=assert(RandomizedWorldBase.createRandomDeadBody(sq,IsoDirections.S,2,0,"ArmyCamoGreen"),
                "Corps non cree")
            body:setFakeDead(false)
            c.vars.film.bodies[#c.vars.film.bodies+1]=body
            c.vars.film.note=document(c,Const.ITEM_NOTE,body:getContainer())
            c.vars.film.body=body
        end)
             :extra("rampant",{dx=-2,dy=1,outfit="ArmyCamoGreen",crawler=true,speed="fast"})
             :crouch(true)
        roll(id)
        scene:approachContainer(function(c) return c.vars.film.body:getContainer() end,15)
             :releaseExtra("rampant")
             :showUI(true)
             :openLoot(function(c) return c.vars.film.body:getContainer() end)
             :wait(0.8)
             :transfer(function(c) return c.vars.film.note end,nil,15)
             :document(function(c) return c.vars.film.note end,3.5)
             :showUI(false)
             :think("IGUI_Artemis_Thought_NoteRead")
             :stand()
             :moveOnSet("sprint",15)
        cut(id)
    end

    -- 2. La voix : le groupe electrogene redonne vie a la radio de V ; son bruit attire les morts.
    shots["02_voix"]=function()
        local id="02_voix"
        -- Inside V's radio room (4832-4837 x 6277-6280), next to the radio: its lines must be heard
        -- whole. The generator stands in the room; its noise brings the dead through the entrance.
        set(id,{point={x=4835,y=6279,z=0},hour=2.5,radius=2,travel=0,
            lights={{r=0.08,g=0.10,b=0.16,radius=12}}})
        scene:call("DECOR: groupe electrogene et radio de V",function(c)
            local o=c.vars.production.block
            torch(c,true)
            local sq=assert(freeNear(o.x,o.y,o.z,2,function(s) return s:isOutside() or s:getRoom()==nil end),
                "Pas de place pour le groupe electrogene")
            local item=instanceItem("Base.Generator")
            item:getModData().fuel=60
            local generator=IsoGenerator.new(item,getCell(),sq)
            generator:setConnected(true)
            c.vars.film.generators[#c.vars.film.generators+1]=generator
            c.vars.film.generator=generator
            local radioSquare=assert(square(4836,6277,0),"Case de la radio de V non chargee")
            local objects=radioSquare:getObjects()
            for i=0,objects:size()-1 do
                if instanceof(objects:get(i),"IsoRadio") then c.vars.film.radio=objects:get(i) end
            end
            assert(c.vars.film.radio,"Radio de V absente")
            c.vars.film.radioWasOn=c.vars.film.radio:getDeviceData():getIsTurnedOn()
            c.vars.film.radio:getDeviceData():setIsTurnedOn(false)
        end)
             :extra("fenetre1",{at={x=4843,y=6281,z=0},outfit="Generic02",speed="fast"})
             :extra("fenetre2",{at={x=4844,y=6283,z=0},outfit="Generic01",speed="fast"})
        roll(id)
        scene:act("Demarrer le groupe electrogene",function(c)
                return ISActivateGenerator:new(c.player,c.vars.film.generator,true)
            end,function(c) return c.vars.film.generator:isActivated() end,15)
             -- The generator's noise is the cause: the dead start towards it at once.
             :releaseExtras({"fenetre1","fenetre2"})
             :call("La radio de V se reveille",function(c)
                 c.vars.film.radio:getDeviceData():setIsTurnedOn(true)
                 D.sound(c,"RadioStatic",0,0)
                 radioText(c,"IGUI_Artemis_Radio_Numbers")
             end)
             :wait(2.5)
             :call("V: plus de donnees",function(c) radioText(c,"IGUI_Artemis_Tape_5") end)
             :wait(1.5)
             :call("Eteindre la lampe",function(c) torch(c,false) end)
             :crouch(true)
             :wait(4.5)
        cut(id)
    end

    -- 3. Le bunker : les ordres de mission ; un des morts se releve dans le dos.
    shots["03_bunker"]=function()
        local id="03_bunker"
        set(id,{point=ch.ch1_bunker.siteAccess,hour=10,zoom=0.6,radius=5,travel=6,
            lights={{r=0.22,g=0.20,b=0.16,radius=9},{r=0.3,g=0.04,b=0.03,radius=5,dx=-3,dy=-3}}})
        scene:call("DECOR: ordres de mission",function(c)
            torch(c,true)
            local desk=assert(containerAt(ch.ch1_bunker.site,"desk"),"Bureau du bunker absent")
            c.vars.film.orders=document(c,Const.ITEM.MISSION_ORDERS,desk)
        end)
             :extra("mort1",{dx=2,dy=1,outfit="ArmyCamoGreen",fakeDead=true})
             :extra("dormeur",{at={x=9961,y=12625,z=-4},outfit="ArmyCamoGreen",fakeDead=true,speed="fast"})
             :crouch(true)
        roll(id)
        scene:approachContainer(function(c) return c.vars.film.orders:getContainer() end,15)
             :showUI(true)
             :openLoot(function(c) return c.vars.film.orders:getContainer() end)
             :transfer(function(c) return c.vars.film.orders end,nil,15)
             :document(function(c) return c.vars.film.orders end,2.5)
             :showUI(false)
             :releaseExtra("dormeur",{rise=true})
             :wait(1.2)
             :stand()
             :moveOnSet("sprint",15)
        cut(id)
    end

    -- 4. La clinique : on frappe derriere la porte pendant qu'on arrache le dossier.
    shots["04_clinique"]=function()
        local id="04_clinique"
        set(id,{point=ch.ch2_clinic.siteAccess,hour=3,zoom=0.6,radius=4,travel=5,
            lights={{name="applique",r=0.9,g=0.85,b=0.6,radius=5,dx=2,dy=-6,blink=0.7}}})
        scene:call("DECOR: dossier du patient zero",function(c)
            torch(c,true)
            local cabinet=assert(containerAt(ch.ch2_clinic.site,"filingcabinet"),"Classeur de la clinique absent")
            c.vars.film.file=document(c,Const.ITEM.PATIENT_FILE,cabinet)
        end)
             :extra("infirmiere",{at={x=11881,y=6877,z=0},outfit="Nurse",speed="fast"})
        roll(id,1.5)
        scene:releaseExtra("infirmiere")
             :approachContainer(function(c) return c.vars.film.file:getContainer() end,15)
             :showUI(true)
             :openLoot(function(c) return c.vars.film.file:getContainer() end)
             :transfer(function(c) return c.vars.film.file end,nil,15)
             :document(function(c) return c.vars.film.file end,1.8)
             :showUI(false)
             :moveOnSet("sprint",15)
        cut(id)
    end

    -- 5. Le laboratoire : le dossier fait sonner le portique ; les sujets se levent.
    shots["05_labo"]=function()
        local id="05_labo"
        set(id,{point=ch.ch5_base.siteAccess,hour=12,zoom=0.6,radius=5,travel=6,
            lights={{r=0.16,g=0.15,b=0.14,radius=8},
                {name="alarme",r=0.45,g=0.03,b=0.02,radius=12,dx=-2,dy=-2}}})
        scene:call("DECOR: dossier Artemis",function(c)
            torch(c,true)
            local cabinet=assert(containerAt(ch.ch5_base.site,"filingcabinet"),"Classeur des archives absent")
            c.vars.film.dossier=document(c,Const.ITEM.DOSSIER,cabinet)
        end)
             :extra("sujet1",{dx=-2,dy=2,outfit="HospitalPatient",sitting=true,speed="fast"})
             :extra("sujet2",{dx=3,dy=2,outfit="HospitalPatient",sitting=true})
             :extra("sujet3",{behind=3,side=0,outfit="HospitalPatient",sitting=true,speed="sprint"})
             :crouch(true)
        roll(id)
        scene:approachContainer(function(c) return c.vars.film.dossier:getContainer() end,15)
             :showUI(true)
             :openLoot(function(c) return c.vars.film.dossier:getContainer() end)
             :transfer(function(c) return c.vars.film.dossier end,nil,15)
             :showUI(false)
             :blinkLight("alarme",0.6)
             :call("Le portique sonne",function(c)
                 marker(c,"BEAT",id.."_alarm")
                 D.sound(c,"VehicleSirenWall",0,0,true)
             end)
             :think("IGUI_Artemis_Thought_alarm_ch5_gate",RED)
             :releaseExtras({"sujet1","sujet2","sujet3"})
             :stand()
             :wait(0.6)
             :moveOnSet("sprint",15)
        cut(id)
    end

    -- 6. L'evasion : la garnison charge ; un tir, la fuite dans le brouillard.
    shots["06_evasion"]=function()
        local id="06_evasion"
        set(id,{point=ch.ch5_base.entrance,hour=4.8,radius=6,travel=8,outside=true})
        scene:call("DECOR: brouillard et arme",function(c)
            require("Artemis/Artemis_Weather").startFog(0.15,10)
            c.vars.film.fog=true
            gun(c)
        end)
             :extra("soldat1",{behind=4,side=3,outfit="ArmyCamoGreen",speed="fast"})
             :extra("soldat2",{behind=6,side=4,outfit="ArmyCamoGreen",speed="sprint"})
             :extra("soldat3",{behind=6,side=-4,outfit="ArmyCamoGreen",speed="sprint"})
             :extra("soldat4",{behind=8,side=1,outfit="ArmyCamoGreen",speed="sprint"})
        roll(id)
        scene:call("Sirene de la base",function(c) D.sound(c,"VehicleSirenWall",-6,-6,true) end)
             :releaseExtra("soldat1")
             :wait(1.2)
             :shootAt(function(c) return c.vars.production.namedExtras.soldat1 end,{shots=1,aimTime=0.6,timeout=10})
             :releaseExtras({"soldat2","soldat3","soldat4"})
             :think("IGUI_Artemis_Thought_surface_ch5_base")
             :moveOnSet("sprint",15)
        cut(id)
    end

    -- 7. La sterilisation : le grondement, la horde a l'horizon, recharger et courir.
    shots["07_sterilisation"]=function()
        local id="07_sterilisation"
        set(id,{point={x=4870,y=6300,z=0},hour=23,radius=6,travel=8,outside=true,clearFog=true,
            lights={{r=0.12,g=0.16,b=0.26,radius=16},{r=0.10,g=0.13,b=0.22,radius=14,dx=-8,dy=0}}})
        scene:call("DECOR: arme presque vide",function(c) gun(c,1) end)
             :extra("horde1",{dx=-7,dy=-3,outfit="Generic02",speed="sprint"})
             :extra("horde2",{dx=-8,dy=-1,outfit="Generic01",speed="sprint"})
             :extra("horde3",{dx=-7,dy=1,outfit="Generic03",speed="fast"})
             :extra("horde4",{dx=-9,dy=3,outfit="Generic04",speed="sprint"})
             :extra("horde5",{dx=-8,dy=4,outfit="Generic05",speed="sprint"})
        roll(id)
        scene:call("Frappe au loin",function(c)
                marker(c,"BEAT",id.."_strike")
                D.thunder(c,-20,-10)
            end)
             :think("IGUI_Artemis_Thought_sterilization_strike",RED)
             :reload(function(c) return c.vars.film.gun end,20)
             :releaseExtras({"horde1","horde2","horde3","horde4","horde5"})
             :wait(0.8)
             :moveOnSet("sprint",15)
        cut(id)
    end

    -- 8. L'extraction : fumee verte, rotor, la horde sort de la lisiere.
    shots["08_extraction"]=function()
        local id="08_extraction"
        set(id,{point={x=12548,y=4226,z=0},hour=8,radius=6,travel=8,outside=true,clearFog=true})
        scene:call("DECOR: fumee verte",function(c)
            torch(c,false)
            local o=c.vars.production.block
            for _,offset in ipairs({{0,2},{2,-1}}) do
                local signal=Smoke.start{x=o.x+o.dx+offset[1],y=o.y+o.dy+offset[2],z=o.z,color="green",
                    minutes=30,source="ArtemisTeaser"}
                if signal then c.vars.film.signals[#c.vars.film.signals+1]=signal end
            end
        end)
             :extra("traque1",{behind=5,side=3,outfit="ArmyCamoGreen",speed="sprint"})
             :extra("traque2",{behind=6,side=5,outfit="ArmyCamoGreen",speed="sprint"})
             :extra("traque3",{behind=6,side=-4,outfit="ArmyCamoGreen",speed="sprint"})
        roll(id)
        scene:call("Le rotor approche",function(c)
                D.sound(c,"Helicopter",4,4,true)
                local o=c.vars.production.block
                WorldFlares.launchFlare(3600,o.x+o.dx,o.y+o.dy,50,0,0,1,0,0,1,0)
            end)
             :think("IGUI_Artemis_Thought_extraction_landed")
             :emote("comehere",{hold=1,timeout=5})
             :releaseExtras({"traque1","traque2","traque3"})
             :moveOnSet("sprint",15)
             :wait(1.5)
        cut(id)
    end

    local order={"01_carnet","02_voix","03_bunker","04_clinique","05_labo","06_evasion","07_sterilisation","08_extraction"}
    local count=0
    for _,id in ipairs(order) do
        if not params.shot or params.shot==id then shots[id](); count=count+1 end
    end
    assert(count>0,"Plan inconnu : "..tostring(params.shot))
    scene:call("Tous les plans sont termines",function(c) c.vars.film.finished=true end)
    scene:finally(function(c)
        local f=c.vars.film
        if not f then return end
        local errors={}
        local function restore(fn)
            local ok,err=pcall(fn)
            if not ok then errors[#errors+1]=tostring(err) end
        end
        if f.activeShot then marker(c,"ABORT",f.activeShot) end
        for _,signal in ipairs(f.signals) do restore(function() Smoke.stop(signal) end) end
        -- Drop any modded fog layer left by the shots (escape fog, null mist layer).
        if f.fog then restore(function()
            getClimateManager():getClimateFloat(ClimateManager.FLOAT_FOG_INTENSITY):setEnableModded(false)
        end) end
        if f.radio then restore(function() f.radio:getDeviceData():setIsTurnedOn(f.radioWasOn) end) end
        for _,generator in ipairs(f.generators) do
            restore(function() generator:setActivated(false); generator:remove() end)
        end
        for _,body in ipairs(f.bodies) do
            restore(function() if body:getSquare() then body:removeFromWorld(); body:removeFromSquare() end end)
        end
        marker(c,(f.finished and #errors==0) and "FINISHED" or "FAILED")
        assert(#errors==0,"Nettoyage du plateau: "..table.concat(errors," | "))
    end)
    return scene
end
