-- Opération Artemis : transitions déclenchées par le jeu (carnet lu, signal entendu, chapitre terminé,
-- arrivée sur un lieu, document lu, aide). Seul module, avec les commandes de debug, qui fait avancer
-- l'histoire. Serveur ou solo uniquement.
-- Les règles des transitions sont dans Artemis_Plot (pures) ; ici, on enregistre l'état, on joue
-- la partie serveur de la scène (Artemis_Staging) et on pose les objets d'un chapitre ouvert.
-- La partie client de la scène est jouée par le client du joueur déclencheur (Artemis_SceneTrigger).

local Const = require "Artemis/Artemis_Const"
local Clock = require "Artemis/Artemis_Clock"
local State = require "Artemis/Artemis_State"
local Plot = require "Artemis/Artemis_Plot"
local Scenes = require "Artemis/Artemis_Scenes"
local Store = require "Artemis/Artemis_Store"
local Staging = require "Artemis/Artemis_Staging"
local Placement = require "Artemis/Artemis_Placement"
local Story = require "Artemis/Artemis_Story"
local Goals = require "Artemis/Artemis_Goals"
local Players = require "Artemis/Artemis_Players"
local Trial = require "Artemis/Artemis_Trial"
local Config = require "Artemis/Artemis_Config"
local Extraction = require "Artemis/Artemis_Extraction"
local MilRadio = require "Artemis/Artemis_MilRadio"
local Bridge = require "Artemis/Artemis_Bridge"
local Endings = require "Artemis/Artemis_Endings"
local ModMaps = require "Artemis/Artemis_ModMaps"
local Sterilization = require "Artemis/Artemis_Sterilization"
local Vaccine = require "Artemis/Artemis_Vaccine"
local Boats = require "Artemis/Artemis_Boats"
local River = require "Artemis/Artemis_River"

local Progress = {}

-- Scène d'une transition d'acte ou de chapitre : celle de l'acte atteint, sinon celle du chapitre
-- terminé (« done_<chapitre> »).
function Progress.sceneForTransition(previousState, nextState, completedChapter)
    if nextState.act > previousState.act then
        return Scenes.idForAct(nextState.act)
    end
    if completedChapter then
        return "done_" .. completedChapter
    end
    return nil
end

-- Enregistre le nouvel état. S'il y a une scène, note le joueur déclencheur et joue la partie serveur
-- (sceneParams : valeurs propres à l'événement, par exemple la portée du haut-parleur).
-- Si un nouveau chapitre s'ouvre, tente aussitôt la pose (lieu peut-être déjà chargé : LoadChunk
-- ne se redéclenche pas pour un chunk déjà en mémoire).
function Progress.commit(previousState, nextState, player, sceneId, sceneParams)
    -- Chapitres optionnels : disponibilité relevée une fois, à l'entrée dans l'acte II.
    nextState = ModMaps.freeze(nextState)
    if sceneId and player then
        nextState = State.withScene(nextState, sceneId, player:getUsername())
    end
    local saved = Store.save(nextState)
    if sceneId then
        Staging.play(sceneId, player, sceneParams)
    end
    if saved.chapter and saved.chapter ~= previousState.chapter then
        Placement.ensure(saved.chapter)
    end
    return saved
end

-- Lecture du carnet : démarre l'opération. Renvoie true si la transition a eu lieu.
function Progress.onNoteRead(player)
    local state = Store.load()
    if State.isStarted(state) then
        return false
    end
    -- Zombies tués par ce personnage avant l'opération : la chronique de fin compte ceux d'après.
    local started = State.withFlagValue(Plot.start(state, Clock.now().day), "killsAtStart",
        player:getUsername(), player:getZombieKills())
    Progress.commit(state, started, player, Scenes.idForAct(Const.ACT.SIGNAL))
    Const.log("carnet lu : l'operation commence (acte I)")
    return true
end

-- Signal entendu à la radio : passe de l'acte I à l'acte II (premier chapitre), une seule fois.
-- speakerRange : portée du haut-parleur de la radio (0 avec des écouteurs), pour le bruit du cri.
function Progress.onSignalHeard(player, speakerRange)
    local state = Store.load()
    if state.act ~= Const.ACT.SIGNAL then
        return false
    end
    Progress.commit(state, Plot.enterAct(state, Const.ACT.INVESTIGATION, Clock.now().day), player,
        Scenes.idForAct(Const.ACT.INVESTIGATION), { speakerRange = speakerRange or 0 })
    Const.log("signal entendu : acte II")
    return true
end

-- Objectif du chapitre en cours atteint : chapitre suivant, ou acte III après le dernier.
function Progress.completeChapter(player)
    local state = Store.load()
    local nextState, completed = Plot.completeChapter(state, Clock.now().day)
    if completed == nil then
        return false
    end
    local sceneId = Progress.sceneForTransition(state, nextState, completed)
    -- L'objectif est vérifié à la minute suivante : si l'évasion a déjà commencé (portique franchi
    -- dans la même minute), la pensée « il faut sortir » viendrait après « le portique ! ».
    if Trial.isRunning(state.flags, completed) then
        sceneId = nil
    end
    local saved = Progress.commit(state, nextState, player, sceneId)
    Const.log("chapitre termine : " .. completed .. " -> " .. tostring(saved.chapter or ("acte " .. saved.act)))
    return true
end

-- Enregistre un drapeau (flags[name][key]) une seule fois, avec la scène associée. Renvoie true si
-- le drapeau était nouveau.
local function markOnce(player, name, key, sceneId)
    local state = Store.load()
    if State.hasFlagEntry(state, name, key) then
        return false
    end
    Progress.commit(state, State.withFlagEntry(state, name, key), player, sceneId)
    return true
end

-- Scène jouée pour ce joueur, sans autre changement d'état (refus qui peuvent se répéter).
function Progress.playScene(player, sceneId)
    local state = Store.load()
    Progress.commit(state, State.copy(state), player, sceneId)
end

-- Premier passage d'un joueur à l'entrée du lieu du chapitre : pensée d'arrivée.
function Progress.onArrive(player, chapterId)
    if markOnce(player, "arrived", chapterId, "arrive_" .. chapterId) then
        Const.log("arrivee : " .. chapterId)
    end
end

-- Document de l'enquête lu jusqu'au bout : enregistré (objectifs « hasRead ») et commenté.
function Progress.onDocumentRead(player, fullType)
    local itemType = fullType:match("%.(.+)$") or fullType
    if markOnce(player, "readDocs", fullType, "read_" .. itemType) then
        Const.log("document lu : " .. itemType)
    end
end

-- Distance (cases) au centre de la salle de la bande en deçà de laquelle une écoute est acceptée.
local TAPE_LISTEN_RADIUS = 8

-- Bande de V écoutée jusqu'au bout (commande du client, Artemis_RelayTape). Le serveur revérifie :
-- le chapitre en cours a une bande, le joueur est dans la salle et elle a du courant. L'objectif
-- « heard » termine ensuite le chapitre (Artemis_Director, à la minute suivante).
function Progress.onTapeHeard(player)
    local state = Store.load()
    local chapter = Story.get(state.chapter)
    local tape = chapter and chapter.tape
    if tape == nil then return end
    local room = tape.room
    local center = { x = (room.x1 + room.x2) / 2, y = (room.y1 + room.y2) / 2 }
    local power = tape.powerSquare
    local isPowered = Goals.isMet({ type = "squarePowered", x = power.x, y = power.y, z = power.z }, player, state)
    if not Players.isNear(player, center, TAPE_LISTEN_RADIUS) or not isPowered then
        Const.log("bande " .. tape.key .. " : ecoute refusee (hors de la salle ou sans courant)")
        return
    end
    if markOnce(player, "heard", tape.key, nil) then
        Const.log("bande " .. tape.key .. " entendue par " .. tostring(player:getUsername()))
    end
end

-- Remontée à la surface d'un lieu avec la scène associée (une fois par partie et par lieu).
function Progress.onSurface(player, chapterId, sceneId)
    if markOnce(player, "surfaced", chapterId, sceneId) then
        Const.log("remontee avec le dossier : " .. chapterId)
    end
end

-- Évasion du labo (Artemis_BaseAlarm) ----------------------------------------------------------

local function worldMinutes()
    return math.floor(Clock.now().worldHours * 60)
end

-- Portique franchi avec le dossier : début de l'épreuve et alarme « portique ». Une seule à la fois,
-- jamais après une réussite.
function Progress.onTrialStart(player, chapterId, sceneId)
    local state = Store.load()
    if not Trial.canStart(state.flags, chapterId) then return end
    Progress.commit(state, Plot.startTrial(state, chapterId, worldMinutes(), player:getUsername()), player, sceneId)
    Const.log("evasion " .. chapterId .. " : debut (portique franchi par " .. tostring(player:getUsername()) .. ")")
end

-- Fin de l'épreuve : « success » (un porteur du dossier est sorti de la base : journal, scène de
-- sortie, alarme coupée) ou « abandon » (plus personne dans la base : l'épreuve pourra recommencer).
function Progress.onTrialEnd(player, chapterId, outcome)
    local state = Store.load()
    local escape = Story.get(chapterId).escape
    if outcome == "success" then
        local finished = Plot.finishTrial(state, chapterId, Clock.now().day, escape.journalKey)
        Progress.commit(state, finished, player, escape.scene)
    else
        Progress.commit(state, Plot.abandonTrial(state, chapterId), nil, nil)
    end
    Const.log("evasion " .. chapterId .. " : " .. (outcome == "success" and "reussie" or "abandonnee")
        .. (player and (" (" .. tostring(player:getUsername()) .. ")") or ""))
end

-- Alarme des capteurs de la base : entry = { status, cause, by }, scène jouée pour ce joueur (ou aucune).
function Progress.setBaseAlarm(chapterId, entry, player, sceneId)
    local state = Store.load()
    Progress.commit(state, State.withFlagValue(state, "alarms", chapterId, entry), player, sceneId)
end

-- Extraction par hélicoptère, route B (Artemis_ExtractionDirector) ------------------------------

-- Appel radio (commande du client, Artemis_RadioCall). Le serveur revérifie : acte III, radio
-- militaire à portée, allumée, sur la chaîne Artemis, micro actif. Ouvre le créneau quotidien.
function Progress.onExtractionCall(player, args)
    local state = Store.load()
    local name = tostring(player:getUsername())
    if state.act ~= Const.ACT.EXFILTRATION then
        Const.log("appel d'evacuation refuse (" .. name .. ") : pas a l'acte III")
        return
    end
    if Bridge.hasTransport() then
        Const.log("appel d'evacuation refuse (" .. name .. ") : le transport est assure par un autre mod")
        return
    end
    if Sterilization.closesRoute(state.flags, "B") then
        Const.log("appel d'evacuation refuse (" .. name .. ") : zone sterilisee, l'armee est partie")
        return
    end
    -- Sans le dossier, personne ne vient (décision de la phase 5 : seul le checkpoint reste).
    if not player:getInventory():containsTypeRecurse(Const.ITEM.DOSSIER) then
        Progress.playScene(player, "call_nodossier")
        Const.log("appel d'evacuation refuse (" .. name .. ") : sans le dossier")
        return
    end
    local device = MilRadio.resolve(player, type(args) == "table" and args.radio or nil)
    local reason = "noDevice"
    if device then
        reason = MilRadio.status(player, device, Config.radioFrequency(), true)
    end
    if reason then
        Const.log("appel d'evacuation refuse (" .. name .. ") : " .. reason)
        return
    end
    if Extraction.isCalled(State.flagValue(state, "extraction", Extraction.KEY)) then
        Const.log("appel d'evacuation (" .. name .. ") : creneau deja ouvert")
        Progress.onSupplyCommit(player, "heli")
        return
    end
    Progress.commit(state, Plot.callExtraction(state, Clock.now().day, "IGUI_Artemis_J_Called"), player,
        "extraction_called")
    Progress.onSupplyCommit(player, "heli")
    Const.log("appel d'evacuation accepte (" .. name .. ") : creneau quotidien ouvert")
end

-- Appel du passeur (route A sans mod de bateau, commande CALL_FERRY du client). Le serveur revérifie :
-- acte III, aucun mod de bateau (sinon le bateau de V attend), joueur au quai de Brandenburg avec une
-- radio militaire sur la chaîne Artemis, et groupe du pont Kinsella vu coupé (sinon le passeur refuse
-- de passer devant les projecteurs : pensée et journal).
function Progress.onFerryCall(player, args)
    local state = Store.load()
    local name = tostring(player:getUsername())
    local ferry = Story.FERRY
    if state.act ~= Const.ACT.EXFILTRATION then return end
    if Boats.vBoatScript() ~= nil then
        Const.log("appel du passeur refuse (" .. name .. ") : un mod de bateau est actif")
        return
    end
    -- Même distance que le client (Chebyshev, Artemis_RadioCall), pour ne jamais refuser sans retour.
    if Extraction.distance(player:getX(), player:getY(), ferry.landing.x, ferry.landing.y) > ferry.callRadius then
        Const.log("appel du passeur refuse (" .. name .. ") : loin du quai de Brandenburg")
        return
    end
    local device = MilRadio.resolve(player, type(args) == "table" and args.radio or nil)
    local reason = "noDevice"
    if device then
        reason = MilRadio.status(player, device, Config.radioFrequency(), true)
    end
    if reason then
        Const.log("appel du passeur refuse (" .. name .. ") : " .. reason)
        return
    end
    if Extraction.isCalled(State.flagValue(state, "extraction", ferry.key)) then
        Progress.onSupplyCommit(player, "ferry")
        return
    end
    if not player:getInventory():containsTypeRecurse(Const.ITEM.DOSSIER) then
        Progress.playScene(player, "call_nodossier")
        Const.log("appel du passeur refuse (" .. name .. ") : sans le dossier")
        return
    end
    if not River.isCut(State.flagValue(state, River.FLAG, "kinsella")) then
        Progress.playScene(player, "ferry_refused")
        Const.log("appel du passeur (" .. name .. ") : le pont Kinsella est encore eclaire")
        return
    end
    Progress.commit(state, Plot.callExtraction(state, Clock.now().day, "IGUI_Artemis_J_FerryCalled", ferry.key),
        player, "ferry_called")
    Progress.onSupplyCommit(player, "ferry")
    Const.log("appel du passeur accepte (" .. name .. ") : rendez-vous a l'aube a Brandenburg")
end

-- Nouvelle phase d'un transport (arrivée, pose, départ), avec scène et journal facultatifs.
-- rendezvousKey : Extraction.KEY (hélicoptère, par défaut) ou Story.FERRY.key (passeur).
function Progress.onExtractionPhase(player, phase, changes, sceneId, journalKey, rendezvousKey)
    local state = Store.load()
    local nextState = Plot.setExtractionPhase(state, phase, changes, rendezvousKey)
    if journalKey then
        nextState = State.withJournal(nextState, Clock.now().day, journalKey)
    end
    Progress.commit(state, nextState, player, sceneId)
end

-- Sortie réussie par une route (« A », « B », « C ») et une sortie précise (exit : « west »,
-- « northeast », « ferry », ou nil) : épilogue et fin enregistrée (chronique : jours, zombies tués
-- depuis le carnet, dossier, remède). L'écran de fin (Artemis_Ending, côté client) s'ouvre au passage
-- à l'épilogue : pas de scène.
function Progress.onExit(player, route, exit)
    local state = Store.load()
    if state.act ~= Const.ACT.EXFILTRATION then return end
    local username = player:getUsername()
    local inventory = player:getInventory()
    local killsAtStart = State.flagValue(state, "killsAtStart", username) or 0
    local day = Clock.now().day
    local ending = Endings.build(route, exit, {
        day = day,
        by = username,
        hours = math.floor(player:getHoursSurvived()),
        kills = math.max(0, player:getZombieKills() - killsAtStart),
        hasDossier = inventory:containsTypeRecurse(Const.ITEM.DOSSIER),
        hasCure = Vaccine.carriesCure(inventory),
    })
    Progress.commit(state, Plot.finishExit(state, day, ending), nil, nil)
    Const.log("sortie reussie : " .. tostring(username) .. " (route " .. route .. (exit and (", " .. exit) or "")
        .. (ending.hasDossier and ", avec le dossier" or ", sans le dossier") .. ")")
end

-- Embarquement dans l'hélicoptère (route B, ou hélicoptère d'un autre mod par le pont).
function Progress.onExtractionSuccess(player)
    Progress.onExit(player, "B", nil)
end

-- Checkpoint, route C (Artemis_CheckpointDirector) --------------------------------------------

-- Nouvelle entrée du joueur (Artemis_Quarantine : autorisé, quarantaine, passé, refusé ; nil pour
-- l'effacer), avec scène et journal facultatifs.
function Progress.setCheckpointEntry(player, entry, sceneId, journalKey)
    local state = Store.load()
    local nextState = State.withFlagValue(state, "checkpoint", player:getUsername(), entry)
    if journalKey then
        nextState = State.withJournal(nextState, Clock.now().day, journalKey)
    end
    Progress.commit(state, nextState, player, sceneId)
end

-- Barrage du pont ouvert (commun à tous les joueurs ; le passage reste ouvert).
function Progress.openCheckpointLane()
    local state = Store.load()
    Progress.commit(state, State.withFlagValue(state, "checkpoint", "_lane", true), nil, nil)
end

-- Siege Night après le dossier (Artemis_SiegeNightBridge) -----------------------------------------

-- Siège programmé le soir de la lecture du dossier : V prévient (journal, pensée ; la radio le répète
-- jusqu'à la fin de la nuit, Artemis_Radio). entry = { day, untilHours }.
function Progress.onFileSiegeScheduled(player, entry)
    local state = Store.load()
    if State.flagValue(state, "siegeNight", "fileSiege") ~= nil then return end
    local nextState = State.withFlagValue(state, "siegeNight", "fileSiege", entry)
    -- Siège déjà en cours : enregistré sans annonce (il tient lieu de siège du dossier).
    if entry.current then
        Progress.commit(state, nextState, nil, nil)
        return
    end
    nextState = State.withJournal(nextState, Clock.now().day, "IGUI_Artemis_J_SiegeWarning")
    Progress.commit(state, nextState, player, player and "siege_warning" or nil)
end

-- Caisse de ravitaillement de V (Artemis_SupplyDirector) ------------------------------------------

-- Premier engagement sur une route (pointId : clé de Story.SUPPLY.points) : V fait déposer une caisse
-- près de ce point, une seule fois par partie (journal, pensée).
function Progress.onSupplyCommit(player, pointId)
    local state = Store.load()
    if state.act ~= Const.ACT.EXFILTRATION or State.flagValue(state, "supply", "drop") ~= nil then return end
    local nextState = State.withFlagValue(state, "supply", "drop", { point = pointId, placed = false })
    nextState = State.withJournal(nextState, Clock.now().day, "IGUI_Artemis_J_Supply_" .. pointId)
    Progress.commit(state, nextState, player, player and "supply_drop" or nil)
    Const.log("ravitaillement : caisse annoncee pres de " .. pointId)
end

-- Option « Stérilisation » (Artemis_SterilizationDirector) -------------------------------------

-- Dossier lu, option active : l'armée annonce la stérilisation de la zone dans « days » jours.
function Progress.onSterilizationStart(player, days)
    local state = Store.load()
    if state.act ~= Const.ACT.EXFILTRATION or Sterilization.entry(state.flags) ~= nil then return end
    local now = Clock.now()
    local nextState = State.withFlagValue(state, Sterilization.FLAG, Sterilization.KEY,
        Sterilization.newEntry(now.worldHours, days))
    nextState = State.withJournal(nextState, now.day, "IGUI_Artemis_J_SterilizationStart")
    Progress.commit(state, nextState, player, "sterilization_start")
    Const.log("sterilisation annoncee dans " .. days .. " jour(s)")
end

-- Échéance atteinte avant la sortie : la zone est stérilisée (hélicoptère et checkpoint fermés).
function Progress.onSterilizationStrike(player)
    local state = Store.load()
    local entry = Sterilization.entry(state.flags)
    if state.act ~= Const.ACT.EXFILTRATION or type(entry) ~= "table" or entry.struck == true then return end
    local struck = State.copy(entry)
    struck.struck = true
    local nextState = State.withFlagValue(state, Sterilization.FLAG, Sterilization.KEY, struck)
    nextState = State.withJournal(nextState, Clock.now().day, "IGUI_Artemis_J_Sterilized")
    Progress.commit(state, nextState, player, "sterilization_strike")
    Const.log("sterilisation : la zone est frappee, seul le fleuve reste")
end

-- Écran de fin : le joueur choisit de continuer la partie (épilogue). Retenu par joueur, pour ne plus
-- rouvrir l'écran à chaque chargement.
function Progress.onEndingContinue(player)
    local state = Store.load()
    if state.act ~= Const.ACT.DONE then return end
    local username = player:getUsername()
    if State.flagValue(state, "endingChoice", username) == "continue" then return end
    Progress.commit(state, State.withFlagValue(state, "endingChoice", username, "continue"), nil, nil)
    Const.log("fin : " .. tostring(username) .. " continue la partie (epilogue)")
end

-- Nouveau personnage après une fin : il choisit de relancer l'opération (Artemis_RestartChoice).
-- Solo seulement : en multijoueur, un joueur n'efface pas la partie terminée des autres.
function Progress.onRestartAfterEnding(player)
    local state = Store.load()
    if isServer() or state.act ~= Const.ACT.DONE then return end
    local restarted = Progress.commit(state, Plot.reset(state), nil, nil)
    Const.log("operation relancee apres la fin par " .. tostring(player:getUsername())
        .. " (revision " .. tostring(restarted.rev) .. ")")
end

-- Aide dite par le personnage (une fois par partie).
function Progress.onHint(player, sceneId)
    if markOnce(player, "hinted", sceneId, sceneId) then
        Const.log("aide : " .. sceneId)
    end
end

return Progress
