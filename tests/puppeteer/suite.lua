-- Reloadable factories only. Never calls Progress/Plot/Store or writes Artemis ModData.
-- Real game execution required; static compilation is not an in-game result.
return function(params)
    local case = assert(params.case, "case required")
    local P, D = PZPuppet, PZPuppet.Debug
    local s = P.scenario((params.diagnostic==true and "ArtemisDiagnostic/" or "OperationArtemis/") .. (params.reportCase or case))
    local A = {}
    local function state() return ModData.get("batman_Artemis") end
    local function flag(group, key)
        local t = state()
        return t and t.flags and t.flags[group] and t.flags[group][key]
    end
    local function has(c, fullType) return c.player:getInventory():containsTypeRecurse(fullType) end
    local function inventory(c, fullType) return c.player:getInventory():getFirstTypeRecurse(fullType) end
    local function square(x,y,z) return getCell():getGridSquare(x,y,z) end
    local function itemIn(container, fullType)
        if not container then return nil end
        local items = container:getItems()
        for i=0,items:size()-1 do
            local item = items:get(i)
            local computer=fullType=="ComputerMod.BlankCD" or fullType=="ComputerModLaptop.Laptop4861993"
            if item:getFullType() == fullType and (not computer or item:getModData().batman_ArtemisComputer~=nil) then return item end
        end
    end
    local function worldItem(x,y,z,fullType,radius)
        for dx=-(radius or 0),radius or 0 do
            for dy=-(radius or 0),radius or 0 do
                local sq = square(x+dx,y+dy,z)
                if sq then
                    local lists = { sq:getObjects(), sq:getStaticMovingObjects() }
                    for _,objects in ipairs(lists) do
                        for i=0,objects:size()-1 do
                            local object = objects:get(i)
                            if object.getContainer then
                                local item = itemIn(object:getContainer(),fullType)
                                if item then return item end
                            end
                        end
                    end
                end
            end
        end
    end
    local function objectAt(x,y,z,class)
        local sq = square(x,y,z)
        if not sq then return nil end
        local objects = sq:getObjects()
        for i=0,objects:size()-1 do
            local obj=objects:get(i)
            if instanceof(obj,class) then return obj end
        end
    end
    local function entry(c) return flag("checkpoint",c.player:getUsername()) end
    local function radioEntry(key) return flag("extraction",key) end
    local function isPhase(key,phase)
        local e=radioEntry(key)
        return type(e)=="table" and e.phase==phase
    end
    local function readFlag(fullType) return flag("readDocs",fullType)==true end
    local NOTE="batman_Artemis.ArtemisNote"
    local I={ badge="batman_Artemis.ArtemisBadge", orders="batman_Artemis.ArtemisMissionOrders",
        patient="batman_Artemis.ArtemisPatientFile", log="batman_Artemis.ArtemisRelayLog",
        dossier="batman_Artemis.ArtemisDossier", card="batman_Artemis.ArtemisKeycard",
        plan="batman_Artemis.ArtemisBasePlan", notes="batman_Artemis.ArtemisLabNotes" }

    -- All lookups/requires and mutations happen after the safety checks, during execution.
    s:check("PRE: solo debug, Build 42.21",function()
        local version=tostring(getCore():getVersionNumber())
        return not isClient() and not isServer() and isDebugEnabled()
            and (version=="42.21" or version:match("^42%.21%.")~=nil),
            "Solo -debug and 42.21 required"
    end)
    s:check("PRE: dedicated test save",function()
        local world=tostring(getWorld():getWorld())
        return world:match("^PZPuppet_Artemis_")~=nil
            or (type(params.testSave)=="string" and params.testSave~="" and world==params.testSave),
            "Dedicated save required; current="..world..". For a NEW test save with an automatic name, pass its exact name as testSave; personal saves rejected"
    end)
    s:check("PRE: real Artemis state loaded",function()
        return type(state())=="table" and type(state().flags)=="table"
    end)
    s:call("SETUP: load observed APIs and record environment",function(c)
        require "TimedActions/ISReadABook"
        require "RadioCom/ISRadioAction"
        require "TimedActions/ISActivateGenerator"
        require "TimedActions/ISOpenCloseDoor"
        require "Util/AdjacentFreeTileFinder"
        A.Const=require "Artemis/Artemis_Const"
        A.Config=require "Artemis/Artemis_Config"
        A.Story=require "Artemis/Artemis_Story"
        A.Boats=require "Artemis/Artemis_Boats"
        A.Vaccine=require "Artemis/Artemis_Vaccine"
        A.Bridge=require "Artemis/Artemis_Bridge"
        A.Journal=require "Artemis/Artemis_JournalUI"
        A.Ending=require "Artemis/Artemis_EndingUI"
        c.vars.created={}
        c.vars.primary=c.player:getPrimaryHandItem()
        c.vars.secondary=c.player:getSecondaryHandItem()
        print("[ArtemisPuppet] "..case.." save="..tostring(getWorld():getWorld())
            .." build="..tostring(getCore():getVersionNumber()).." act="..state().act)
        local mods=getActivatedMods()
        for i=0,mods:size()-1 do print("[ArtemisPuppet] active="..tostring(mods:get(i))) end
        assert(A.Config.isEnabled(),"Artemis disabled")
    end)

    -- Persistent progress, looted documents, generator use, spawned mod scenery and kills remain.
    -- Only our fixtures, temporary listeners, hands and setup clock are cleaned.
    s:finally(function(c)
        if c.vars.quarantineObserver then Events.OnTick.Remove(c.vars.quarantineObserver) end
        if c.vars.deviceObserver then Events.OnDeviceText.Remove(c.vars.deviceObserver) end
        if c.vars.endingObserver then Events.OnPreUIDraw.Remove(c.vars.endingObserver) end
        if c.vars.tape and c.vars.tapeWasOff then c.vars.tape:getDeviceData():setIsTurnedOn(false) end
        if c.vars.menu then c.vars.menu:hideAndChildren() end
        if c.vars.journal and A.Journal.instance==c.vars.journal then c.vars.journal:close() end
        if c.vars.readingTorch then c.vars.readingTorch:setActivated(false) end
        if c.vars.created and #c.vars.created>0 then
            c.player:setPrimaryHandItem(c.vars.primary)
            c.player:setSecondaryHandItem(c.vars.secondary)
            for _,item in ipairs(c.vars.created) do
                if instanceof(item,"Radio") then item:getDeviceData():setIsTurnedOn(false) end
                local container=item:getContainer()
                if container then container:Remove(item) end
            end
        end
        if c.vars.oldTime then D.setTimeOfDay(c.vars.oldTime) end
        print("[ArtemisPuppet] cleanup "..case.." act="..tostring(state() and state().act))
    end)

    -- 42.21 exposes instanceItem to Lua. Avoid the engine helper's unavailable
    -- InventoryItemFactory global; track only this run's own inventory fixtures.
    local function createFixture(c,fullType)
        assert(isDebugEnabled() and not isClient() and not isServer(),"Solo debug fixtures only")
        local script=getScriptManager():getItem(fullType)
        assert(script and script:getFullName()==fullType and not script:getObsolete(),"Unknown fixture: "..fullType)
        local item=assert(instanceItem(fullType),"Cannot instantiate fixture: "..fullType)
        c.vars.created[#c.vars.created+1]=item
        assert(c.player:getInventory():AddItem(item),"Cannot add fixture: "..fullType)
        return item
    end

    local function preAct(act,chapter)
        s:check("PRE: act "..act..(chapter and " / "..chapter or ""),function()
            return state().act==act and (not chapter or state().chapter==chapter)
        end)
    end
    local function clock(hours)
        s:call("SETUP: clock before tested interval",function(c)
            if not c.vars.oldTime then c.vars.oldTime=getGameTime():getTimeOfDay() end
            D.setTimeOfDay(hours)
        end)
    end
    local function tele(x,y,z) s:teleport(x,y,z,60) end
    local function loot(fullType,x,y,z,radius,allowExisting)
        s:await("World contains "..fullType..(allowExisting and " or prior real pickup retained" or ""),function(c)
            c.vars.priorPickup=allowExisting and inventory(c,fullType) or nil
            if c.vars.priorPickup then c.vars.loot=c.vars.priorPickup; return true end
            c.vars.loot=worldItem(x,y,z,fullType,radius)
            return c.vars.loot~=nil
        end,90)
        s:interact("Approach actual loot container: "..fullType,function(c)
            local source=assert(c.vars.loot:getContainer(),"Loot source vanished")
            if c.vars.priorPickup then
                print("[ArtemisPuppet] RESUME: retain prior real pickup "..fullType)
                return
            end
            local parent=source:getParent()
            local target=parent and parent:getSquare() or source:getSourceGrid()
            assert(target,"Loot source has no world square")
            c.vars.lootTarget=target
            assert(c.player:canAccessContainer(source),"Loot source is locked")
            print("[ArtemisPuppet] loot="..fullType.." container="..source:getType()
                .." source="..target:getX()..","..target:getY()..","..target:getZ()
                .." player="..c.player:getX()..","..c.player:getY()..","..c.player:getZ())
            local adjacent=assert(AdjacentFreeTileFinder.Find(target,c.player),"No reachable adjacent loot square")
            local action=ISPathFindAction:pathToLocationF(c.player,adjacent:getX()+0.5,adjacent:getY()+0.5,adjacent:getZ())
            action:setOnFail(function() c.vars.lootPathFailed=true end)
            ISTimedActionQueue.add(action)
        end,function(c)
            assert(not c.vars.lootPathFailed,"Loot approach pathfinding failed")
            local source=c.vars.loot:getContainer()
            if source and source:getOutermostContainer()==c.player:getInventory() then return true end
            local containers=ISInventoryPaneContextMenu.getContainers(c.player)
            local current=c.player:getCurrentSquare()
            return source~=nil and current~=nil and current:canReachTo(c.vars.lootTarget)
                and c.player:canAccessContainer(source) and containers~=nil and containers:contains(source)
        end,45)
        s:call("Observe original loot source",function(c) c.vars.source=c.vars.loot:getContainer() end)
        s:transfer(function(c) return c.vars.loot end,nil,30)
        s:check("Transfer removed exact world item"..(allowExisting and " or retained declared prior pickup" or ""),function(c)
            return c.vars.loot:getContainer()==c.player:getInventory()
                and (c.vars.priorPickup==c.vars.loot or not c.vars.source:contains(c.vars.loot))
        end)
    end
    local function read(fullType,predicate)
        s:check("PRE: readable "..fullType,function(c)
            return inventory(c,fullType)~=nil and not c.player:hasTrait(CharacterTrait.ILLITERATE)
        end)
        s:call("SETUP: reading light only if genuinely dark",function(c)
            c.vars.needsReadingTorch=c.player:tooDarkToRead()
            if c.vars.needsReadingTorch and not c.vars.readingTorch then
                c.vars.readingTorch=createFixture(c,"Base.HandTorch")
                c.vars.readingTorch:setUsedDelta(1)
                c.vars.readingTorch:setActivated(false)
            end
        end)
        s:interact("Equip reading light through vanilla callback",function(c)
            if c.vars.needsReadingTorch then
                ISInventoryPaneContextMenu.equipWeapon(c.vars.readingTorch,false,false,c.playerIndex)
            end
        end,function(c) return not c.vars.needsReadingTorch or c.player:getSecondaryHandItem()==c.vars.readingTorch end,30)
        s:interact("Switch reading light through vanilla callback",function(c)
            if c.vars.needsReadingTorch and not c.vars.readingTorch:isActivated() then
                ISInventoryPaneContextMenu.onActivateItem(c.vars.readingTorch,c.playerIndex)
            end
        end,function(c) return not c.vars.needsReadingTorch or c.vars.readingTorch:isEmittingLight() end,10)
        s:await("PRE: vanilla tooDarkToRead is false",function(c) return not c.player:tooDarkToRead() end,10)
        s:interact("Read through vanilla inventory callback: "..fullType,function(c)
            assert(not c.player:tooDarkToRead(),"Reading light lost before action")
            ISInventoryPaneContextMenu.readItem(inventory(c,fullType),c.playerIndex)
        end,predicate or function() return readFlag(fullType) end,90)
    end
    local function radioFixture()
        s:call("SETUP: charged military radio fixture, switched off",function(c)
            local item=createFixture(c,"Base.WalkieTalkie5")
            c.vars.radio=item
            local data=item:getDeviceData()
            data:setHasBattery(true); data:setPower(1); data:setIsTurnedOn(false)
            data:setDeviceVolume(0.7); data:setMicIsMuted(false)
        end)
        s:equip(function(c) return c.vars.radio end,true,false,30)
    end
    local function radioAction(mode,value,predicate,selector)
        s:act("Vanilla radio "..mode,function(c)
            local device=selector and selector(c) or c.vars.radio
            return ISRadioAction:new(mode,c.player,device,type(value)=="function" and value(c) or value)
        end,predicate,30)
    end
    local function readyRadio()
        radioFixture()
        radioAction("ToggleOnOff",nil,function(c) return c.vars.radio:getDeviceData():getIsTurnedOn() end)
        radioAction("SetChannel",function() return A.Config.radioFrequency() end,
            function(c) return c.vars.radio:getDeviceData():getChannel()==A.Config.radioFrequency() end)
    end
    local function menu(c,kind,objects,key,invoke)
        local context=ISContextMenu.get(c.playerIndex,30,30)
        c.vars.menu=context
        if kind=="inventory" then
            triggerEvent("OnFillInventoryObjectContextMenu",c.playerIndex,context,objects)
        else
            triggerEvent("OnFillWorldObjectContextMenu",c.playerIndex,context,objects,false)
        end
        local option=context:getOptionFromName(getText(key))
        if invoke then
            assert(option and option.onSelect,"Actual menu option missing: "..key)
            assert(not option.notAvailable and not option.isDisabled,"Actual option disabled: "..key)
            option.onSelect(option.target,option.param1,option.param2,option.param3,option.param4,
                option.param5,option.param6,option.param7,option.param8,option.param9,option.param10)
        end
        context:hideAndChildren()
        return option
    end
    local function callRadio(key,rendezvous)
        s:interact("Actual radio menu: "..key,function(c)
            menu(c,"inventory",{c.vars.radio},key,true)
        end,function()
            local e=radioEntry(rendezvous)
            return type(e)=="table" and e.called==true
        end,20)
    end
    local function observeEnding(route,exit)
        s:call(params.autoContinue==true and "Observe paused ending screen; real Continue button after 12s"
            or "Observe paused ending screen; wait for player's Continue click",function(c)
            local function onDraw()
                local ui=A.Ending.instance
                if not ui or not ui:isReallyVisible() or ui.isReplay then return end
                local e=flag("ending","result")
                if not e or e.route~=route or e.exit~=exit then return end
                c.vars.sawEnding=true
                c.vars.endingSeenAt=c.vars.endingSeenAt or getTimestampMs()
                if params.autoContinue~=true then return end
                if getTimestampMs()-c.vars.endingSeenAt<12000 then return end
                local spec=ui.buttons and ui.buttons[2]
                if spec and spec.key=="IGUI_Artemis_Ending_Continue" and spec.button:isReallyVisible()
                    and spec.button:isEnabled() then spec.button:forceClick() end
            end
            c.vars.endingObserver=function()
                local ok,err=pcall(onDraw)
                if not ok then
                    c.vars.endingError=tostring(err)
                    Events.OnPreUIDraw.Remove(c.vars.endingObserver)
                    print("[ArtemisPuppet] ending adapter failure: "..tostring(err))
                end
            end
            Events.OnPreUIDraw.Add(c.vars.endingObserver)
        end)
    end
    local function endingCheck(route,exit)
        s:await("Real exit committed and paused screen continued",function(c)
            assert(not c.vars.endingError,c.vars.endingError)
            return state().act==4 and c.vars.sawEnding==true and A.Ending.instance==nil
                and flag("endingChoice",c.player:getUsername())=="continue"
        end,45)
        s:check("Ending route, carrier, dossier and cure match real inventory",function(c)
            local e=flag("ending","result")
            return e~=nil and e.route==route and e.exit==exit and e.by==c.player:getUsername()
                and e.hasDossier==has(c,I.dossier) and e.hasCure==A.Vaccine.carriesCure(c.player:getInventory())
                and (params.expectCure==nil or e.hasCure==params.expectCure)
        end)
    end
    local function callPrerequisites()
        preAct(3)
        s:check("PRE: dossier retained from real investigation",function(c) return has(c,I.dossier) end)
    end
    local function transportFinish(key,cfg,route,exit)
        callPrerequisites()
        s:check("PRE: accepted call, no sterilization closing route",function()
            local e=radioEntry(key)
            return e and e.called==true and (route~="B" or not (flag("sterilization","zone") or {}).struck)
        end)
        -- Teleport and clock are setup BEFORE the tested approach/hold/boarding. No time skips later.
        tele(cfg.x+6,cfg.y,0); clock(4.95)
        observeEnding(route,exit)
        s:await("Daily slot armed",function() return isPhase(key,"waiting") end,15)
        s:await("Transport genuinely inbound",function() return isPhase(key,"inbound") end,120)
        s:await("Hold completed by elapsed game time",function() return isPhase(key,"landed") end,
            (params.holdTimeout or 1800))
        s:check("Not boarded outside marked circle",function() return state().act==3 end)
        s:walkTo(cfg.x,cfg.y,0,30)
        endingCheck(route,exit)
    end

    if case=="01_chargement_carnet" then
        preAct(0)
        s:check("Radio channel actually registered",function()
            local r=getZomboidRadio()
            return r and r:getScriptManager():getRadioChannel(A.Const.RADIO.UUID)~=nil
        end)
        s:call("SETUP: notebook only, no progress mutation",function(c)
            local item=createFixture(c,NOTE)
            assert(type(item:getModData().printMedia)=="table","Notebook OnCreate missing")
        end)
        read(NOTE,function() return state().act==1 end)
        s:call("Capture notebook transition revision",function(c) c.vars.rev=state().rev; c.vars.journalCount=#state().journal end)
        read(NOTE,function() return state().act==1 end)
        s:check("Notebook reread starts no second operation",function(c)
            return state().act==1 and state().rev==c.vars.rev and #state().journal==c.vars.journalCount
        end)
        s:interact("Open actual Artemis journal",function(c)
            assert(A.Journal.instance==nil,"Close pre-existing journal first")
            A.Journal.toggle(); c.vars.journal=A.Journal.instance
        end,function(c) return c.vars.journal~=nil and c.vars.journal:isReallyVisible() end,10)
        s:check("Journal reflects current state revision",function(c) return c.vars.journal.shownRevision==state().rev end)
    elseif case=="02_signal_radio" then
        preAct(1); radioFixture()
        s:wait(15):check("Switched-off radio did not start investigation",function() return state().act==1 end)
        radioAction("ToggleOnOff",nil,function(c) return c.vars.radio:getDeviceData():getIsTurnedOn() end)
        radioAction("SetChannel",88000,function(c) return c.vars.radio:getDeviceData():getChannel()==88000 end)
        s:wait(20):check("Wrong frequency did not start investigation",function() return state().act==1 end)
        s:call("Observe real coded radio reception",function(c)
            c.vars.deviceObserver=function(_,codes,_,_,_,_,device)
                if type(codes)=="string" and codes:find("ART1",1,true) and device==c.vars.radio then
                    c.vars.received=true
                end
            end
            Events.OnDeviceText.Add(c.vars.deviceObserver)
        end)
        radioAction("SetChannel",function() return A.Config.radioFrequency() end,
            function(c) return c.vars.radio:getDeviceData():getChannel()==A.Config.radioFrequency() end)
        s:await("Broadcast heard naturally; chapter 1 revealed",function(c)
            return c.vars.received==true and state().act==2 and state().chapter=="ch1_bunker"
        end,600)
    elseif case=="03_bunker" or case=="04_clinique" or case=="20_labo_optionnel" then
        local chapter=case=="03_bunker" and "ch1_bunker" or (case=="04_clinique" and "ch2_clinic" or "ch4_lab")
        local item=case=="03_bunker" and I.badge or (case=="04_clinique" and I.patient or I.notes)
        if case=="03_bunker" and params.resume==true then
            s:check("PRE: resume real bunker pickup, chapter bunker or clinic",function(c)
                return state().act==2 and has(c,I.badge)
                    and (state().chapter=="ch1_bunker" or state().chapter=="ch2_clinic")
            end)
        else preAct(2,chapter) end
        local points={ ch1_bunker={9962,12627,-4,9963,12626}, ch2_clinic={11880,6883,0,11879,6882},
            ch4_lab={6864,7573,-4,6863,7572} }
        local p=points[chapter]; tele(p[1],p[2],p[3]); loot(item,p[4],p[5],p[3],nil,case=="03_bunker" and params.resume==true)
        if chapter=="ch1_bunker" then loot(I.orders,p[4],p[5],p[3],nil,params.resume==true); read(I.orders) end
        if chapter~="ch1_bunker" then read(item) end
        s:await("Chapter advanced by actual goal polling",function()
            return state().act==2 and state().chapter~="" and state().chapter~=chapter
        end,120)
        s:check("Expected next chapter",function()
            local nextId=chapter=="ch1_bunker" and "ch2_clinic" or (chapter=="ch2_clinic" and "ch3_relay" or "ch5_base")
            return state().chapter==nextId
        end)
    elseif case=="05_relais" then
        preAct(2,"ch3_relay")
        s:check("PRE: corrected Miller retry policy loaded",function()
            for _,placement in ipairs(A.Story.get("ch3_relay").placements) do
                if placement.group=="ch3_relay_miller" then return placement.retryOnEmpty==true,
                    "Restart the game with the corrected local Artemis sources" end
            end
            return false,"Miller placement definition missing"
        end)
        s:check("PRE: fresh campaign, Miller group not previously placed",function()
            return state().placed and state().placed.ch3_relay_miller~=true,
                "Use a NEW dedicated campaign; an old placed flag cannot distinguish missing Miller from a dead Miller"
        end)
        -- Preparation only: remain 40 cases from the spawn centre so the real
        -- Director can place Miller outside the observed 30-case exclusion.
        -- Never call Placement/Tracked or repair an old placed/tracked flag here.
        tele(4858,6274,0)
        s:await("Natural Miller: living zombie really loaded with its observed profile",function(c)
            local Tracking=require "Artemis/Artemis_Tracking"
            local zombies=getCell():getZombieList()
            for i=0,zombies:size()-1 do
                local zombie=zombies:get(i)
                if zombie:getCurrentSquare() and not zombie:isDead() and math.floor(zombie:getZ())==0
                    and zombie:hasModData() and zombie:getModData().batman_ArtemisTracked=="miller"
                    and Tracking.isInArea(A.Story.TRACKED.miller.area,zombie:getX(),zombie:getY()) then
                    c.vars.miller=zombie
                    c.vars.millerKey=Tracking.outfitKey(zombie:getPersistentOutfitID())
                    return true
                end
            end
            return false
        end,45)
        s:check("Natural Miller: matching persistent registry and completed placement",function(c)
            local zombie,key=c.vars.miller,c.vars.millerKey
            local tracked=key and flag("tracked",tostring(key))
            local valid=zombie and zombie:getCurrentSquare() and not zombie:isDead()
                and zombie:getModData().batman_ArtemisTracked=="miller"
                and type(tracked)=="table" and tracked.profile=="miller"
                and state().placed.ch3_relay_miller==true
            if valid then print("[ArtemisMiller] naturalSpawn=true profile=miller outfitKey="..tostring(key)
                .." x="..tostring(zombie:getX()).." y="..tostring(zombie:getY()).." z="..tostring(zombie:getZ())) end
            return valid==true,"A registry entry alone does not prove a loaded Miller"
        end)
        tele(4835,6284,0); loot(I.log,4836,6285,0); read(I.log)
        s:walkTo(4835,6278,0,45)
        s:check("PRE: control room genuinely powered (grid or connected generator)",function()
            local sq=square(4834,6278,0)
            return sq and (sq:haveElectricity() or (sq:hasGridPower() and sq:getRoom()~=nil))
        end)
        s:await("Actual installed tape radio",function(c) c.vars.tape=objectAt(4836,6277,0,"IsoRadio"); return c.vars.tape~=nil end,30)
        s:check("PRE: tape not already heard; radio off",function(c)
            return flag("heard","ch3_tape")~=true and not c.vars.tape:getDeviceData():getIsTurnedOn()
        end)
        s:call("Record tape fixture cleanup",function(c) c.vars.tapeWasOff=true end)
        radioAction("ToggleOnOff",nil,function(c) return c.vars.tape:getDeviceData():getIsTurnedOn() end,function(c) return c.vars.tape end)
        s:wait(3)
        radioAction("ToggleOnOff",nil,function(c) return not c.vars.tape:getDeviceData():getIsTurnedOn() end,function(c) return c.vars.tape end)
        s:wait(3):check("Interrupted tape grants no objective",function() return flag("heard","ch3_tape")~=true and state().chapter=="ch3_relay" end)
        radioAction("ToggleOnOff",nil,function(c) return c.vars.tape:getDeviceData():getIsTurnedOn() end,function(c) return c.vars.tape end)
        s:await("Full tape naturally completed",function() return flag("heard","ch3_tape")==true end,100)
        s:await("Real relay goal opens available successor",function()
            local bonus=flag("optionalChapters","ch4_lab")==true
            return state().chapter==(bonus and "ch4_lab" or "ch5_base") and state().callCode=="7149"
        end,120)
        radioAction("ToggleOnOff",nil,function(c) return not c.vars.tape:getDeviceData():getIsTurnedOn() end,function(c) return c.vars.tape end)
    elseif case=="06_base_acces_capteurs" then
        preAct(2,"ch5_base"); clock(12); tele(5588,12484,0)
        if params.resume==true then
            s:check("PRE: resume real base pickups retained from previous run",function(c)
                return has(c,I.card) and has(c,I.plan) and readFlag(I.plan)
            end)
        end
        loot(I.card,5588,12485,0,2,params.resume==true); loot(I.plan,5588,12485,0,2,params.resume==true); read(I.plan)
        s:check("Real guard keycard carries persistent door key",function(c) return inventory(c,I.card):getKeyId()==714900149 end)
        -- Ordinary exterior locks are independent of the guard's card. Placement
        -- here prepares the sensor condition; it does NOT validate exterior entry.
        s:call("SETUP: hall condition only; exterior entry remains untested",function()
            print("[ArtemisPuppet] scope: debug hall placement; ordinary exterior entry NOT validated")
        end)
        tele(5582,12483,0)
        s:await("Sensors alarm outside V window",function() local e=flag("alarms","ch5_base"); return e and e.status=="on" and e.cause=="sensors" end,10)
        clock(23.3)
        s:await("V window cuts sensors",function() local e=flag("alarms","ch5_base"); return e and e.status=="off" end,10)
        clock(1.3)
        s:await("Sensors return after window closes",function() local e=flag("alarms","ch5_base"); return e and e.status=="on" and e.cause=="sensors" end,10)
        s:walkTo(5583,12483,0,30)
        s:await("Vanilla exterior door exists for exit from inside",function(c) c.vars.door=objectAt(5584,12483,0,"IsoDoor"); return c.vars.door~=nil end,15)
        s:door(function(c) return c.vars.door end,true,30):walkTo(5588,12483,0,30)
        s:await("Leaving actual hall stops sensors",function() local e=flag("alarms","ch5_base"); return e and e.status=="off" end,10)
        clock(23.3); tele(5541,12468,0)
        s:await("Actual armored sas door loaded",function(c)
            c.vars.door=objectAt(5541,12468,0,"IsoDoor"); return c.vars.door~=nil
        end,15)
        s:check("Armored sas lock matches real guard card",function(c)
            local door=c.vars.door
            print("[ArtemisPuppet] armored door key="..door:getKeyId().." locked="..tostring(door:isLockedByKey()).." open="..tostring(door:IsOpen()))
            return door:getProperties():has("forceLocked") and not door:IsOpen()
                and door:isLockedByKey() and door:getKeyId()==inventory(c,I.card):getKeyId()
                and c.player:getInventory():haveThisKeyId(door:getKeyId())~=nil
                and not door:isBarricaded() and not door:isObstructed()
        end)
        s:door(function(c) return c.vars.door end,true,30):walkTo(5541,12467,0,30)
        s:check("Real vanilla card opening permits crossing armored sas",function(c)
            return c.vars.door:IsOpen() and math.floor(c.player:getX())==5541 and math.floor(c.player:getY())==12467
        end)
    elseif case=="07_archives_portique" then
        preAct(2,"ch5_base"); clock(23.3)
        s:check("PRE: real guard card retained for archive access",function(c)
            local card=inventory(c,I.card); return card and card:getKeyId()==714900149
        end)
        -- Positioning prepares the corridor condition, not the descent route.
        tele(5575,12432,-17)
        s:check("PRE: no existing escape",function() return flag("trials","ch5_base")==nil end)
        s:await("Actual armored archive door loaded",function(c)
            c.vars.door=objectAt(5574,12432,-17,"IsoDoor"); return c.vars.door~=nil
        end,15)
        s:check("Archive door has guard card lock and is closed",function(c)
            local door=c.vars.door
            print("[ArtemisPuppet] archive door key="..door:getKeyId().." locked="..tostring(door:isLockedByKey()).." open="..tostring(door:IsOpen()))
            return door:getProperties():has("forceLocked") and not door:IsOpen()
                and door:isLockedByKey() and door:getKeyId()==inventory(c,I.card):getKeyId()
                and not door:isBarricaded() and not door:isObstructed()
        end)
        s:walkTo(5574,12432,-17,30):door(function(c) return c.vars.door end,true,30):walkTo(5572,12432,-17,30)
        s:check("Real card opening permits archive entry",function(c)
            return c.vars.door:IsOpen() and math.floor(c.player:getX())==5572 and math.floor(c.player:getY())==12432
        end)
        loot(I.dossier,5568,12430,-17)
        if not params.deferDossierRead then read(I.dossier) end
        s:await("Dossier possession opens act III through game goal",function() return state().act==3 end,120)
        s:check("Inside archives does not trigger gate",function() return flag("trials","ch5_base")==nil end)
        s:walkTo(5576,12433,-17,30)
        s:await("Walking past archive gate starts escape",function()
            local t,a=flag("trials","ch5_base"),flag("alarms","ch5_base")
            return t and t.status=="on" and a and a.status=="on" and a.cause=="gate"
        end,10)
    elseif case=="08_evasion" then
        callPrerequisites()
        if params.resume==true then
            s:check("PRE: resume real ascent at exterior door; escape still active",function(c)
                local t=flag("trials","ch5_base")
                return t and t.status=="on" and math.floor(c.player:getZ())==0
                    and c.player:getX()>=5580 and c.player:getX()<5584
                    and c.player:getY()>=12481 and c.player:getY()<12486
            end)
        else
            s:check("PRE: actual escape running from archives",function(c)
                local t=flag("trials","ch5_base")
                return t and t.status=="on" and math.floor(c.player:getZ())==-17
            end)
            -- Real pathfinding and stairs. No teleport after the dossier has triggered the escape.
            local route={{5576,12446,-17},{5574,12446,-16},{5574,12435,-16},{5556,12435,-16},
                {5553,12443,-16},{5553,12466,-16},{5553,12490,-16},{5551,12496,-16}}
            for _,p in ipairs(route) do s:walkTo(p[1],p[2],p[3],90) end
            for z=-15,-13 do s:walkTo(5550,12496,z,90) end
            s:walkTo(5547,12468,-13,90)
            for z=-12,-1 do s:walkTo(5547,12467,z,90) end
            s:walkTo(5543,12467,0,90):walkTo(5562,12475,0,90)
        end
        -- Within the engine's 2-tile door range even with walkTo's 0.8 tolerance.
        s:walkTo(5583.5,12483.5,0,90)
        s:await("Exit door loaded",function(c) c.vars.door=objectAt(5584,12483,0,"IsoDoor"); return c.vars.door~=nil end,15)
        s:door(function(c) return c.vars.door end,true,30):walkTo(5602,12483,0,90)
        s:await("Real ascent and escape committed",function()
            local t=flag("trials","ch5_base")
            return t and t.status=="done" and flag("surfaced","ch5_base")==true
        end,15)
        s:check("Dossier retained; alarm off",function(c) local a=flag("alarms","ch5_base"); return has(c,I.dossier) and a and a.status=="off" end)
    elseif case=="09_appel_helicoptere" then
        callPrerequisites()
        s:check("PRE: Artemis own transport",function() return not A.Bridge.hasTransport() end)
        readyRadio()
        s:call("Observe real radio reference and authority status, no command",function(c)
            local MilRadio=require "Artemis/Artemis_MilRadio"
            local ref=MilRadio.makeRef(c.vars.radio)
            local device=MilRadio.resolve(c.player,ref)
            c.vars.resolvedRadio=device
            c.vars.clientRadioReason=MilRadio.status(c.player,c.vars.radio,A.Config.radioFrequency())
            c.vars.serverRadioReason=device and MilRadio.status(c.player,device,A.Config.radioFrequency(),true)
            print("[ArtemisRadioDiagnostic] itemId="..c.vars.radio:getID().." refKind="..tostring(ref.kind)
                .." refId="..tostring(ref.id).." resolved="..tostring(device==c.vars.radio)
                .." clientStatus="..tostring(c.vars.clientRadioReason).." serverStatus="..tostring(c.vars.serverRadioReason)
                .." channel="..c.vars.radio:getDeviceData():getChannel())
            if params.diagnostic==true then
                c.vars.foldedRadioReason=device and MilRadio.status(c.player,device,A.Config.radioFrequency(),true) or "noDevice"
                print("[ArtemisRadioDiagnostic] legacyExpressionOnly="..tostring(c.vars.foldedRadioReason)
                    .."; not the current server response")
            end
        end)
        s:check("PRE: real radio resolves and both radio validations accept it",function(c)
            return c.vars.resolvedRadio==c.vars.radio and c.vars.clientRadioReason==nil and c.vars.serverRadioReason==nil
        end)
        if params.diagnostic==true then
            s:check("Diagnostic: old expression reproduces noDevice; current server not called",function(c)
                return c.vars.foldedRadioReason=="noDevice"
            end)
        else
            callRadio("ContextMenu_Artemis_CallExtraction","routeB")
            s:check("First commitment schedules one supply crate",function() local drop=flag("supply","drop"); return drop and drop.point=="heli" end)
            s:wait(5) -- let the real delayed radio reply execute before removing our radio fixture
        end
    elseif case=="10_fin_helicoptere" then
        s:check("PRE: no foreign transport",function() return not A.Bridge.hasTransport() end)
        transportFinish("routeB",{x=12560,y=4218},"B",nil)
    elseif case=="11_appel_passeur" then
        callPrerequisites()
        s:check("PRE: no boat provider",function() return A.Boats.vBoatScript()==nil end)
        tele(1497,5405,0)
        s:await("Kinsella generator installed and running",function(c)
            c.vars.generator=square(1497,5404,0) and square(1497,5404,0):getGenerator()
            return c.vars.generator~=nil and c.vars.generator:isActivated()
        end,30)
        tele(1637,5580,0); readyRadio()
        s:interact("Real ferry call rejected while searchlights run",function(c)
            menu(c,"inventory",{c.vars.radio},"ContextMenu_Artemis_CallFerry",true)
        end,function() return not (radioEntry("ferry") or {}).called end,10)
        s:wait(5):check("No ferry slot after refusal",function() return not (radioEntry("ferry") or {}).called end)
        tele(1497,5405,0)
        s:await("Reacquire loaded Kinsella generator after travel",function(c)
            c.vars.generator=square(1497,5404,0) and square(1497,5404,0):getGenerator()
            return c.vars.generator~=nil and c.vars.generator:isActivated()
        end,30)
        s:act("Switch off Kinsella via real generator action",function(c)
            return ISActivateGenerator:new(c.player,c.vars.generator,false)
        end,function(c) return not c.vars.generator:isActivated() end,30)
        s:await("Director observed generator cut",function() local e=flag("river","kinsella"); return e and e.cut==true end,10)
        tele(1637,5580,0); callRadio("ContextMenu_Artemis_CallFerry","ferry")
        s:wait(5) -- let the real delayed radio reply execute before removing our radio fixture
    elseif case=="12_fin_passeur" then
        s:check("PRE: no boat provider",function() return A.Boats.vBoatScript()==nil end)
        transportFinish("ferry",{x=1637,y=5577},"A","ferry")
    elseif case=="13_entree_checkpoint" then
        preAct(3)
        s:check("PRE: restarted mod uses one-hour quarantine and 30-minute incident",function()
            local cfg=A.Story.CHECKPOINT
            return cfg.hoursWithDossier==1 and cfg.hoursWithoutDossier==1 and cfg.reanimateAtHour==0.5,
                "Restart the whole game to load the one-hour quarantine"
        end)
        s:check("PRE: built-in blood test, uninfected",function(c) return not A.Vaccine.isActive() and not c.player:getBodyDamage():isInfected() end)
        tele(12611,1170,0)
        s:await("Checkpoint post and gate built",function(c)
            c.vars.post=objectAt(12610,1170,0,"IsoObject")
            c.vars.gate=objectAt(12613,1170,0,"IsoThumpable")
            return c.vars.post~=nil and c.vars.gate~=nil
        end,30)
        s:interact("Actual army blood test context callback",function(c)
            menu(c,"world",{c.vars.post},"ContextMenu_Artemis_CheckpointTest",true)
        end,function(c) return entry(c)~=nil and entry(c).phase=="cleared" end,15)
        s:await("Gate genuinely unlocked by army",function(c) return not c.vars.gate:isLockedByKey() end,10)
        s:walkTo(12612,1170,0,30)
        s:act("Open real IsoThumpable gate",function(c) return ISOpenCloseDoor:new(c.player,c.vars.gate) end,
            function(c) return c.vars.gate:IsOpen() end,10)
        s:walkTo(12614,1170,0,30)
        s:await("Walking into pen starts quarantine",function(c) return entry(c)~=nil and entry(c).phase=="running" end,10)
        s:check("Quarantine is one game hour with or without dossier",function(c) return entry(c).hours==1 end)
        s:await("Running quarantine closes and locks gate",function(c) return not c.vars.gate:IsOpen() and c.vars.gate:isLockedByKey() end,10)
    elseif case=="14_fin_checkpoint" then
        preAct(3)
        if params.resume then
            s:check("PRE: resume real passed quarantine, opened lane and surface approach",function(c)
                local e=entry(c)
                return e~=nil and e.phase=="passed" and flag("checkpoint","_lane")==true
                    and not c.player:getBodyDamage():isInfected() and not c.player:getVehicle()
                    and c.player:getZ()==0 and c.player:getX()>=12590 and c.player:getX()<=12612
                    and c.player:getY()>=965 and c.player:getY()<=1171
            end)
            s:check("PRE: resumed ending variant matches retained real inventory",function(c)
                return (params.expectDossier==nil or has(c,I.dossier)==params.expectDossier)
                    and (params.expectCure==nil or A.Vaccine.carriesCure(c.player:getInventory())==params.expectCure)
            end)
        elseif params.completedQuarantine==true then
            s:check("PRE: quarantine already naturally passed before scenario, still inside pen",function(c)
                local e=entry(c)
                local Q=require "Artemis/Artemis_Quarantine"
                return e~=nil and e.phase==Q.PASSED and flag("checkpoint","_lane")==true
                    and not c.player:getBodyDamage():isInfected() and not c.player:getVehicle()
                    and Q.isInPen(A.Story.CHECKPOINT,math.floor(c.player:getX()),math.floor(c.player:getY()),math.floor(c.player:getZ()))
            end)
            s:check("PRE: ending variant matches real retained inventory",function(c)
                return (params.expectDossier==nil or has(c,I.dossier)==params.expectDossier)
                    and (params.expectCure==nil or A.Vaccine.carriesCure(c.player:getInventory())==params.expectCure)
            end)
            s:call("Record scope: interval completed before this scenario; crossing and ending only",function()
                print("[ArtemisQuarantine] completedBeforeStart=true; no timer/progression changes; see prior real console for interval")
            end)
        else
        s:check("PRE: quarantine running, uninfected",function(c) return entry(c)~=nil and entry(c).phase=="running" and not c.player:getBodyDamage():isInfected() end)
        s:check("PRE: requested ending variant has real prerequisites",function(c)
            return (params.expectDossier==nil or has(c,I.dossier)==params.expectDossier)
                and (params.expectCure==nil or A.Vaccine.carriesCure(c.player:getInventory())==params.expectCure)
                and entry(c).hours==1
        end)
        s:call("Record one-hour interval and observe natural clock; no time changes",function(c)
            local Clock=require "Artemis/Artemis_Clock"
            c.vars.quarantineStart=entry(c).startHours
            local function observe()
                local now=getTimestampMs()
                if c.vars.quarantineLastLog and now-c.vars.quarantineLastLog<30000 then return end
                c.vars.quarantineLastLog=now
                local e=entry(c)
                local elapsed=e and type(e.startHours)=="number" and math.max(0,Clock.now().worldHours-e.startHours)
                local remaining=elapsed and e.hours and math.max(0,e.hours-elapsed)
                print("[ArtemisQuarantine] phase="..tostring(e and e.phase)
                    .." elapsedHours="..tostring(elapsed).." remainingHours="..tostring(remaining)
                    .." reanimatedFlag="..tostring(e and e.reanimated)
                    .." minutesPerDay="..getGameTime():getMinutesPerDay()
                    .." player="..c.player:getX()..","..c.player:getY()..","..c.player:getZ())
            end
            c.vars.quarantineObserver=observe
            observe(); Events.OnTick.Add(observe)
        end)
        s:await("Authority records detainee reanimation stage before final test",function(c)
            local e=entry(c)
            assert(e,"Quarantine abandoned: checkpoint entry removed")
            assert(e.phase~="refused","Army final blood test refused")
            return e.reanimated==true
        end,params.quarantineTimeout or 15000)
        s:await("Natural quarantine elapsed; final test negative",function(c)
            local e=entry(c)
            assert(e,"Quarantine abandoned: checkpoint entry removed")
            assert(e.phase~="refused","Army final blood test refused")
            return e.phase=="passed" and flag("checkpoint","_lane")==true
        end,params.quarantineTimeout or 15000)
        s:check("Army did not grant passage before the real one-hour interval",function(c)
            return getGameTime():getWorldAgeHours()>=c.vars.quarantineStart+1
        end)
        end
        observeEnding("C",nil)
        s:await("PRE: idle player action queue and normal speed before automatic exit",function(c)
            return P.Game.queueSize(c.player)==0 and (not getGameSpeed or getGameSpeed()<=2)
        end,300)
        if not params.resume then
        s:walkTo(12614,1170,0,30)
        s:act("Open released quarantine gate",function(c) return ISOpenCloseDoor:new(c.player,objectAt(12613,1170,0,"IsoThumpable")) end,
            function() return objectAt(12613,1170,0,"IsoThumpable"):IsOpen() end,10)
        s:walkTo(12611,1170,0,30)
        end
        -- Use fixed loaded endpoints on the east side of the vanilla traffic jam.
        -- ISPathFindAction still computes the real path around dynamic obstacles.
        -- Resume skips only waypoints already north of the character; it never moves it.
        for y=1165,965,-20 do
            local targetY=y+0.5
            s:interact(string.format("Bridge east approach 12607.5 %.1f 0",targetY),function(c,data)
                data.skip=c.player:getY()<=targetY
                if data.skip then return end
                assert(not c.player:getVehicle() and c.player:getZ()==0,"Walk on the bridge surface")
                assert(not getGameSpeed or getGameSpeed()<=2,"Use normal speed for bridge walking")
                assert(square(12607,math.floor(targetY),0),"Bridge waypoint not loaded")
                local action=ISPathFindAction:pathToLocationF(c.player,12607.5,targetY,0)
                action:setOnFail(function() data.failure="Bridge pathfinding failed at 12607.5,"..targetY end)
                ISTimedActionQueue.add(action)
            end,function(c,data)
                return data.skip==true or P.Game.near(c.player,12607.5,targetY,0,0.8)
            end,45)
        end
        s:walkTo(12599.5,965.5,0,45):walkTo(12599.5,957.5,0,45)
        endingCheck("C",nil)
    elseif case=="15_fleuve_ouest" or case=="16_fleuve_nord_est" then
        callPrerequisites()
        local west=case=="15_fleuve_ouest"
        s:check("PRE: real optional boat API and script",function() return A.Boats.vBoatScript()~=nil end)
        -- Human drives with normal controls (run with manualStop=false). Never move the vehicle in Lua.
        s:await("Board a real boat using game controls",function(c) return A.Boats.isAboard(c.player) end,600)
        observeEnding("A",west and "west" or "northeast")
        s:await("Actually navigate past lit military river guard",function()
            local e=flag("river",west and "kinsella" or "northeast")
            return e and type(e.alarmUntil)=="number"
        end,18000)
        s:await("Real occupied boat crossed exit line",function() return state().act==4 end,18000)
        endingCheck("A",west and "west" or "northeast")
    elseif case=="17_refus_radio_serveur" then
        callPrerequisites(); readyRadio()
        s:check("PRE: extraction not called",function() return not (radioEntry("routeB") or {}).called end)
        local function negative(label,change,reason,clientOnly)
            s:call("SETUP negative condition: "..label,change)
            s:check("Actual radio option disabled: "..label,function(c)
                local o=menu(c,"inventory",{c.vars.radio},"ContextMenu_Artemis_CallExtraction",false)
                return o~=nil and o.notAvailable==true and o.toolTip~=nil
            end)
            if not clientOnly then
                s:call("Exercise server rejection: "..reason,function(c)
                    local Mil=require "Artemis/Artemis_MilRadio"
                    sendClientCommand(c.player,"batman_Artemis","callExtraction",{radio=Mil.makeRef(c.vars.radio)})
                end)
            end
            s:wait(3):check("Invalid request opens no extraction: "..label,function() return not (radioEntry("routeB") or {}).called end)
        end
        negative("wrongFrequency",function(c) c.vars.radio:getDeviceData():setChannelRaw(88000) end,"wrongFrequency")
        -- MilRadio.status(...,true) deliberately ignores microphone state on the authority:
        -- vanilla does not transmit it. Check the actual disabled CLIENT menu only.
        negative("micMuted",function(c) local d=c.vars.radio:getDeviceData(); d:setChannelRaw(A.Config.radioFrequency()); d:setMicIsMuted(true) end,"micMuted",true)
        negative("radioOff",function(c) local d=c.vars.radio:getDeviceData(); d:setMicIsMuted(false); d:setIsTurnedOn(false) end,"radioOff")
    elseif case=="18_rendez_vous_manque" then
        callPrerequisites()
        s:check("PRE: own helicopter called",function() return not A.Bridge.hasTransport() and (radioEntry("routeB") or {}).called==true end)
        tele(12566,4218,0); clock(4.95)
        s:await("Slot armed",function() return isPhase("routeB","waiting") end,15)
        s:await("Inbound while present",function() return isPhase("routeB","inbound") end,120)
        s:await("Landed",function() return isPhase("routeB","landed") end,1800)
        s:await("Waited outside boarding zone until departure",function() return isPhase("routeB","waiting") end,1800)
        s:check("Missed slot keeps daily call, no ending",function() return state().act==3 and (radioEntry("routeB") or {}).called==true and flag("ending","result")==nil end)
    elseif case=="19_sterilisation" then
        callPrerequisites()
        if params.prepareSterilization==true then
            s:check("PRE: no earlier dossier reading or sterilization countdown",function()
                return not readFlag(I.dossier) and flag("sterilization","zone")==nil
            end)
            s:call("SETUP: one-day sterilization option before real dossier reading",function(c)
                local option=assert(getSandboxOptions():getOptionByName("OperationArtemis.SterilizationDays"),"Sandbox option missing")
                c.vars.sterilizationOption=option
                c.vars.sterilizationOriginal=option:getValue()
                option:setValue(1)
            end)
            s:finally(function(c)
                if c.vars.sterilizationOption then c.vars.sterilizationOption:setValue(c.vars.sterilizationOriginal) end
            end)
        end
        s:check("PRE: one-day sterilization, dossier not read yet",function() return A.Config.sterilizationDays()==1 and not readFlag(I.dossier) end)
        read(I.dossier)
        s:await("Real dossier reading started sterilization countdown",function() local e=flag("sterilization","zone"); return e and e.struck==false and e.deadlineHours>getGameTime():getWorldAgeHours() end,120)
        s:call("Record original deadline, never change it",function(c) c.vars.deadline=flag("sterilization","zone").deadlineHours end)
        s:await("Natural world time reached sterilization strike",function() return (flag("sterilization","zone") or {}).struck==true end,params.strikeTimeout or 15000)
        s:check("Deadline unchanged; only B and C closed",function(c)
            local St=require "Artemis/Artemis_Sterilization"
            return flag("sterilization","zone").deadlineHours==c.vars.deadline
                and St.closesRoute(state().flags,"B") and St.closesRoute(state().flags,"C") and not St.closesRoute(state().flags,"A")
        end)
        readyRadio()
        s:call("Actual closed helicopter request",function(c) menu(c,"inventory",{c.vars.radio},"ContextMenu_Artemis_CallExtraction",true) end)
        s:wait(5):check("Army gone: request does not reopen slot",function() return not (radioEntry("routeB") or {}).called end)
    elseif case=="21_computer_contenus" then
        s:check("PRE: Computer Mod installed",function() return getScriptManager():FindItem("ComputerMod.BlankCD")~=nil end)
        tele(11880,6883,0); loot("ComputerMod.BlankCD",11879,6882,0)
        s:check("Actual clinic CD contains three readable note entries",function(c)
            local md=c.vars.loot:getModData(); local notes=md.ComputerModDiscContents
            if md.batman_ArtemisComputer~="disc" or type(notes)~="table" or #notes~=3 then return false end
            for _,n in ipairs(notes) do if n.type~="note" or type(n.text)~="string" or n.text=="" then return false end end
            return true
        end)
        if params.laptop then
            tele(5568,12432,-17); loot("ComputerModLaptop.Laptop4861993",5568,12430,-17)
            s:check("V laptop has three notes and no password",function(c)
                local md=c.vars.loot:getModData()
                return md.batman_ArtemisComputer=="laptop" and md.ComputerModPasswordEnabled==false
                    and type(md.ComputerModDesktopNotes)=="table" and #md.ComputerModDesktopNotes==3
            end)
        end
    elseif case=="22_siege_optionnel" then
        callPrerequisites()
        s:check("PRE: Siege Night APIs loaded, dossier not yet read",function() return SandboxVars.SiegeNight~=nil and not readFlag(I.dossier) end)
        s:call("Snapshot all Siege Night sandbox values",function(c) c.vars.siegeOptions={}; for k,v in pairs(SandboxVars.SiegeNight) do c.vars.siegeOptions[k]=v end end)
        read(I.dossier)
        s:await("Real dossier reading schedules file siege",function() return type(flag("siegeNight","fileSiege"))=="table" end,120)
        s:check("Siege sandbox options unchanged",function(c)
            for k,v in pairs(c.vars.siegeOptions) do if SandboxVars.SiegeNight[k]~=v then return false end end
            for k,v in pairs(SandboxVars.SiegeNight) do if c.vars.siegeOptions[k]~=v then return false end end
            return true
        end)
    elseif case=="23_vaccine_entree" then
        preAct(3)
        s:check("PRE: actual vaccine integration loaded",function() return A.Vaccine.isActive() end)
        tele(12611,1170,0)
        s:await("Perform real syringe/spectrometer test at post using game UI",function(c)
            local e=entry(c); return e~=nil and e.phase=="cleared"
        end,600)
        s:check("Blood result agrees with real body infection",function(c) return not c.player:getBodyDamage():isInfected() end)
    elseif case=="24_checkpoint_abandon" then
        preAct(3)
        s:check("PRE: running quarantine",function(c) return entry(c)~=nil and entry(c).phase=="running" end)
        s:interact("Actual leave-quarantine context callback",function(c)
            menu(c,"world",{c.player:getCurrentSquare():getFloor()},"ContextMenu_Artemis_CheckpointLeave",true)
        end,function(c) return entry(c)==nil end,15)
        s:await("Abandoned quarantine releases gate",function()
            local gate=objectAt(12613,1170,0,"IsoThumpable")
            return gate~=nil and not gate:isLockedByKey()
        end,10)
        s:walkTo(12614,1170,0,30)
        s:act("Open gate after abandonment",function(c) return ISOpenCloseDoor:new(c.player,objectAt(12613,1170,0,"IsoThumpable")) end,
            function() return objectAt(12613,1170,0,"IsoThumpable"):IsOpen() end,10)
        s:walkTo(12611,1170,0,30)
        s:check("No false victory after abandonment",function() return state().act==3 and flag("ending","result")==nil end)
    elseif case=="25_sauvegarde_rechargee" then
        s:call("Read real reference captured before restart",function(c)
            local reader=getFileReader("PZPuppet/OperationArtemis-reload-reference.txt",false)
            assert(reader,"Run 31_reference_rechargement before saving and restarting")
            local values={}
            local ok,err=pcall(function()
                for _=1,32 do
                    local line=reader:readLine()
                    if line==nil then break end
                    local k,v=line:match("^([^=]+)=(.*)$")
                    if k then values[k]=v end
                end
            end)
            reader:close(); assert(ok,err); c.vars.reference=values
        end)
        s:check("Reload preserved progress, with legitimate initialization revision increment",function(c)
            local r=c.vars.reference
            return r.world==tostring(getWorld():getWorld()) and tonumber(r.act)==state().act
                and tonumber(r.rev)~=nil and state().rev>=tonumber(r.rev)+1
                and r.chapter==tostring(state().chapter)
                and r.trial==tostring((flag("trials","ch5_base") or {}).status)
                and r.readDossier==tostring(readFlag(I.dossier))
        end)
        s:check("Reload preserved actual ending and Continue choice",function(c)
            local r=c.vars.reference; local e=flag("ending","result") or {}
            return r.endingRoute==tostring(e.route) and r.endingExit==tostring(e.exit)
                and r.choice==tostring(flag("endingChoice",c.player:getUsername()))
                and (state().act~=4 or A.Ending.instance==nil)
        end)
    elseif case=="26_checkpoint_positif" then
        preAct(3)
        if params.infectionFixture==true then
            s:check("PRE: safe temporary infection fixture, no previous checkpoint entry",function(c)
                local mortality=getSandboxOptions():getOptionByName("ZombieLore.Mortality")
                return mortality~=nil and mortality:getValue()~=1 and not A.Vaccine.isActive()
                    and not c.player:getBodyDamage():isInfected() and entry(c)==nil
                    and flag("checkpoint","_lane")~=true
            end)
            s:call("SETUP: temporary real body infection only; no progression changes",function(c)
                local body=c.player:getBodyDamage()
                c.vars.infectionOriginal={time=body:getInfectionTime(),duration=body:getInfectionMortalityDuration(),
                    fever=c.player:getStats():get(CharacterStat.ZOMBIE_FEVER),
                    level=c.player:getStats():get(CharacterStat.ZOMBIE_INFECTION)}
                c.vars.infectionBody=body
                -- God mode clears infection on each tick; prepare a living test subject safely.
                c.vars.infectionFlags=D.setFlags({god=false,ghost=true,invisible=true},c.playerIndex)
                body:setInfectionTime(c.player:getHoursSurvived())
                body:setInfectionMortalityDuration(1000000)
                body:setInfected(true)
            end)
            s:finally(function(c)
                if c.vars.infectionBody then
                    local b,r=c.vars.infectionBody,c.vars.infectionOriginal
                    b:setInfected(false); b:setInfectionTime(r.time); b:setInfectionMortalityDuration(r.duration)
                    c.player:getStats():set(CharacterStat.ZOMBIE_FEVER,r.fever)
                    c.player:getStats():set(CharacterStat.ZOMBIE_INFECTION,r.level)
                end
                if c.vars.infectionFlags then D.setFlags(c.vars.infectionFlags,c.playerIndex) end
            end)
        end
        s:check("PRE: built-in protocol; actually infected test character",function(c)
            return not A.Vaccine.isActive() and c.player:getBodyDamage():isInfected()
        end)
        tele(12611,1170,0)
        s:await("Post loaded",function(c) c.vars.post=objectAt(12610,1170,0,"IsoObject"); return c.vars.post~=nil end,30)
        s:interact("Actual positive blood test",function(c)
            menu(c,"world",{c.vars.post},"ContextMenu_Artemis_CheckpointTest",true)
        end,function(c) return entry(c)~=nil and entry(c).phase=="refused" end,15)
        s:check("Positive test grants no lane or ending",function() return flag("checkpoint","_lane")~=true and flag("ending","result")==nil end)
        s:await("Positive blood test keeps checkpoint gate locked",function()
            local gate=objectAt(12613,1170,0,"IsoThumpable")
            return gate~=nil and gate:isLockedByKey()
        end,10)
    elseif case=="27_appel_sans_dossier" then
        preAct(3)
        if params.depositDossier==true then
            s:check("PRE: real dossier available for vanilla drop, outside vehicle",function(c)
                local dossier=inventory(c,I.dossier)
                return dossier~=nil and not dossier:isFavorite() and not c.player:isHandItem(dossier) and not c.player:getVehicle()
                    and not (radioEntry("routeB") or {}).called
            end)
            s:call("Record actual dossier identity before drop",function(c) c.vars.depositedDossier=inventory(c,I.dossier) end)
            s:interact("Drop actual dossier through vanilla inventory callback",function(c)
                ISInventoryPaneContextMenu.onDropItems({c.vars.depositedDossier},c.playerIndex)
            end,function(c)
                return not has(c,I.dossier) and c.vars.depositedDossier:getWorldItem()~=nil
            end,30)
        end
        s:check("PRE: dossier absent, slot never called, own transport",function(c)
            return not has(c,I.dossier) and not (radioEntry("routeB") or {}).called and not A.Bridge.hasTransport()
        end)
        readyRadio()
        s:call("Actual radio callback without dossier",function(c)
            menu(c,"inventory",{c.vars.radio},"ContextMenu_Artemis_CallExtraction",true)
        end)
        s:wait(6):check("Without dossier: no helicopter, no supply, no ending",function()
            return not (radioEntry("routeB") or {}).called and flag("ending","result")==nil
        end)
        if params.depositDossier==true then
            s:interact("Recover same real dossier through vanilla pickup callback",function(c)
                require "TimedActions/ISGrabItemAction"
                local world=assert(c.vars.depositedDossier:getWorldItem(),"Dropped dossier vanished")
                ISWorldObjectContextMenu.onGrabWItem({world},world,c.playerIndex)
            end,function(c)
                return has(c,I.dossier) and c.player:getInventory():contains(c.vars.depositedDossier)
                    and c.vars.depositedDossier:getWorldItem()==nil
            end,30)
            s:finally(function(c)
                if c.vars.depositedDossier and not c.player:getInventory():contains(c.vars.depositedDossier) then
                    local world=c.vars.depositedDossier:getWorldItem()
                    local sq=world and world:getSquare()
                    print("[ArtemisPuppet] interrupted drop test: actual dossier remains at "
                        ..tostring(sq and sq:getX())..","..tostring(sq and sq:getY())..","..tostring(sq and sq:getZ())
                        .."; recover through game UI; no direct inventory restoration")
                end
            end)
        end
    elseif case=="28_autorisation_expiree" then
        preAct(3)
        if params.prepareEntry~=false then
            s:check("PRE: built-in test, no previous entry, uninfected and unopened lane",function(c)
                return not A.Vaccine.isActive() and not c.player:getBodyDamage():isInfected()
                    and entry(c)==nil and flag("checkpoint","_lane")~=true
            end)
            tele(12611,1170,0)
            s:await("Actual checkpoint test post and gate loaded",function(c)
                c.vars.post=objectAt(12610,1170,0,"IsoObject")
                c.vars.gate=objectAt(12613,1170,0,"IsoThumpable")
                return c.vars.post~=nil and c.vars.gate~=nil
            end,30)
            s:interact("Actual army test gives timed entry authorization",function(c)
                menu(c,"world",{c.vars.post},"ContextMenu_Artemis_CheckpointTest",true)
            end,function(c) return entry(c)~=nil and entry(c).phase=="cleared" end,15)
        end
        s:check("PRE: genuine cleared entry, outside pen",function(c)
            return entry(c)~=nil and entry(c).phase=="cleared" and c.player:getX()<12613
        end)
        s:call("Record actual authorization deadline, no clock changes",function(c)
            c.vars.entryDeadline=entry(c).clearedUntil
            print("[ArtemisEntryExpiry] deadline="..tostring(c.vars.entryDeadline)
                .." worldHours="..getGameTime():getWorldAgeHours()
                .." minutesPerDay="..getGameTime():getMinutesPerDay())
        end)
        s:await("Entry authorization naturally expired without entering",function(c)
            local e=entry(c)
            if e then
                assert(e.phase=="cleared" and e.clearedUntil==c.vars.entryDeadline,"Authorization unexpectedly changed")
            end
            return e==nil and getGameTime():getWorldAgeHours()>c.vars.entryDeadline
        end,params.expiryTimeout or 1200)
        s:check("Expired entry did not become quarantine or victory",function() return state().act==3 and flag("ending","result")==nil end)
        s:await("Expired authorization relocked army gate",function()
            local gate=objectAt(12613,1170,0,"IsoThumpable")
            return gate~=nil and gate:isLockedByKey()
        end,10)
    elseif case=="31_reference_rechargement" then
        s:call("Record actual progress reference without editing save",function(c)
            local writer=getFileWriter("PZPuppet/OperationArtemis-reload-reference.txt",true,false)
            assert(writer,"Cannot write reload reference")
            c.vars.referenceWriter=writer
            local t=state(); local e=flag("ending","result") or {}
            writer:write("world="..tostring(getWorld():getWorld()).."\nact="..t.act.."\nrev="..t.rev
                .."\nchapter="..tostring(t.chapter).."\ntrial="..tostring((flag("trials","ch5_base") or {}).status)
                .."\nreadDossier="..tostring(readFlag(I.dossier)).."\nendingRoute="..tostring(e.route)
                .."\nendingExit="..tostring(e.exit).."\nchoice="..tostring(flag("endingChoice",c.player:getUsername())).."\n")
            writer:close(); c.vars.referenceWriter=nil
        end)
        s:finally(function(c) if c.vars.referenceWriter then c.vars.referenceWriter:close() end end)
    else
        error("Unknown OperationArtemis case: "..tostring(case))
    end
    return s
end
