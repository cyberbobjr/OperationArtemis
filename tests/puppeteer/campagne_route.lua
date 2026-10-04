-- Fresh dedicated solo 42.21 save, updated engine/mod loaded after full restart.
-- External collect_results.py --watch required before this command.
-- PZPuppet.runBatchFile("OperationArtemis/campagne_route.lua",{playerIndex=0},{route="passeur"})
-- Loading constructs a plan only. Every child uses its own actions/assertions/finally.
return function(params)
    local route=params.route or "passeur"
    assert(route=="passeur" or route=="helicoptere" or route=="checkpoint","Unknown route")
    assert(params.negatives==nil or type(params.negatives)=="boolean","negatives must be boolean")
    assert(params.missedRendezvous==nil or type(params.missedRendezvous)=="boolean","missedRendezvous must be boolean")
    assert(not params.missedRendezvous or route=="helicoptere","Missed rendezvous requires helicopter route")
    local entries={}
    local function add(case,extra,options)
        local p={}
        if params.testSave~=nil then p.testSave=params.testSave end
        for key,value in pairs(extra or {}) do p[key]=value end
        local e={path="OperationArtemis/"..case..".lua",params=p}
        if options then e.options=options end
        entries[#entries+1]=e
        return e
    end
    for _,case in ipairs({"01_chargement_carnet","02_signal_radio","03_bunker","04_clinique","05_relais"}) do add(case) end
    local lab=add("20_labo_optionnel")
    lab.when=function()
        local state=ModData.get("batman_Artemis")
        assert(type(state)=="table","Artemis state missing before optional chapter")
        return state.chapter=="ch4_lab"
    end
    lab.skipReason="Optional satellite chapter not selected by the actual mod"
    for _,case in ipairs({"06_base_acces_capteurs","07_archives_portique","08_evasion"}) do add(case) end
    if params.negatives~=false then
        add("17_refus_radio_serveur")
        add("27_appel_sans_dossier",{depositDossier=true})
        if route=="checkpoint" then add("26_checkpoint_positif",{infectionFixture=true}) end
    end
    if route=="passeur" then
        add("11_appel_passeur")
        add("12_fin_passeur",nil,{manualStop=false})
    elseif route=="helicoptere" then
        add("09_appel_helicoptere")
        if params.missedRendezvous then add("18_rendez_vous_manque",nil,{manualStop=false}) end
        add("10_fin_helicoptere",nil,{manualStop=false})
    else
        add("13_entree_checkpoint")
        add("14_fin_checkpoint",nil,{manualStop=false})
    end
    -- Captures actual state; saving and restarting through the game remain manual.
    add("31_reference_rechargement")
    return entries
end
