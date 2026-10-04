-- Opération Artemis : transitions de l'histoire (actes et chapitres).
-- Fonctions pures : elles combinent l'état (Artemis_State) et les données des chapitres
-- (Artemis_Story) et renvoient un nouvel état. Les effets (sauvegarde, scènes, pose d'objets)
-- sont faits par Artemis_Progress, côté serveur.

local Const = require "Artemis/Artemis_Const"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Trial = require "Artemis/Artemis_Trial"
local Ambience = require "Artemis/Artemis_Ambience"
local Extraction = require "Artemis/Artemis_Extraction"

local Plot = {}

-- Épreuve « Évasion du labo » (Artemis_Trial) -------------------------------------------------
-- state.flags.trials[chapitre] = { status, startMinutes, by } ; l'alarme de la base suit l'épreuve
-- (state.flags.alarms[chapitre] = { status, cause, by }).

-- Début de l'épreuve (portique franchi) : alarme « portique ». Sans effet si elle est déjà en cours
-- ou réussie.
function Plot.startTrial(state, chapterId, startMinutes, by)
    if not Trial.canStart(state.flags, chapterId) then
        return State.copy(state)
    end
    local nextState = State.withFlagValue(state, "trials", chapterId,
        { status = Trial.RUNNING, startMinutes = startMinutes, by = by })
    return State.withFlagValue(nextState, "alarms", chapterId,
        { status = Ambience.ALARM_ON, cause = Ambience.CAUSE_GATE, by = by })
end

-- Réussite : l'épreuve est terminée, l'alarme s'éteint, la remontée est faite (Artemis_Surfacing ne
-- la rejoue pas) et le journal le note.
function Plot.finishTrial(state, chapterId, day, journalKey)
    local nextState = State.withFlagValue(state, "trials", chapterId, { status = Trial.DONE })
    nextState = State.withFlagValue(nextState, "alarms", chapterId, { status = Ambience.ALARM_OFF })
    nextState = State.withFlagEntry(nextState, "surfaced", chapterId)
    return State.withJournal(nextState, day, journalKey)
end

-- Abandon (mort, plus personne dans la base) : l'épreuve peut recommencer, l'alarme s'éteint.
function Plot.abandonTrial(state, chapterId)
    local nextState = State.withFlagValue(state, "trials", chapterId, nil)
    return State.withFlagValue(nextState, "alarms", chapterId, { status = Ambience.ALARM_OFF })
end

-- Extraction par hélicoptère, route B (Artemis_Extraction) -------------------------------------
-- state.flags.extraction.routeB = { called, calledDay, phase, slotDay, seen } ; state.flags.ending
-- .result = fin d'Artemis_Endings une fois la partie gagnée.

-- Rendez-vous par radio : hélicoptère (Extraction.KEY) ou passeur de la route A (« ferry »), même
-- entrée (state.flags.extraction[clé]). rendezvousKey vaut Extraction.KEY par défaut.

-- Appel radio accepté : le créneau quotidien est ouvert (journal). Sans effet s'il l'est déjà.
function Plot.callExtraction(state, day, journalKey, rendezvousKey)
    local key = rendezvousKey or Extraction.KEY
    if Extraction.isCalled(State.flagValue(state, "extraction", key)) then
        return State.copy(state)
    end
    local nextState = State.withFlagValue(state, "extraction", key,
        { called = true, calledDay = day, phase = Extraction.CALLED })
    return State.withJournal(nextState, day, journalKey)
end

-- Nouvelle phase du transport ; « changes » complète l'entrée (slotDay, seen).
function Plot.setExtractionPhase(state, phase, changes, rendezvousKey)
    local key = rendezvousKey or Extraction.KEY
    local entry = State.copy(State.flagValue(state, "extraction", key) or {})
    entry.phase = phase
    for name, value in pairs(changes or {}) do
        entry[name] = value
    end
    return State.withFlagValue(state, "extraction", key, entry)
end

-- Sortie réussie, par n'importe quelle route : l'opération est terminée (épilogue), la fin est
-- enregistrée (Artemis_Endings). Pour l'hélicoptère, le créneau quotidien est aussi refermé.
function Plot.finishExit(state, day, ending)
    local nextState = State.copy(state)
    if ending.route == "B" then
        nextState = Plot.setExtractionPhase(nextState, Extraction.WAITING, { called = false, done = true })
    elseif ending.exit == "ferry" then
        nextState = Plot.setExtractionPhase(nextState, Extraction.WAITING, { called = false, done = true },
            Story.FERRY.key)
    end
    nextState = State.withFlagValue(nextState, "ending", "result", ending)
    return Plot.enterAct(nextState, Const.ACT.DONE, day)
end

-- Chapitres optionnels (phase 6) : un chapitre avec « requires » n'a lieu que si sa carte de mod est
-- chargée, relevé figé à l'entrée dans l'acte II (state.flags.optionalChapters, Artemis_ModMaps).
function Plot.isChapterAvailable(state, chapterId)
    local chapter = Story.get(chapterId)
    if chapter == nil then return false end
    if chapter.requires == nil then return true end
    return State.flagValue(state, "optionalChapters", chapterId) == true
end

-- Premier chapitre disponible à partir de chapterId (lui compris), ou nil (fin de l'enquête).
function Plot.firstAvailable(state, chapterId)
    local current = chapterId
    while current ~= nil and not Plot.isChapterAvailable(state, current) do
        local chapter = Story.get(current)
        current = chapter and chapter.next or nil
    end
    return current
end

-- Numéro affiché d'un chapitre : son rang parmi les chapitres qui ont lieu (1, 2, 3, 4 même si le
-- chapitre 4 bonus est sauté).
function Plot.chapterOrdinal(state, chapterId)
    local rank, current = 0, Story.FIRST_CHAPTER
    while current ~= nil do
        if Plot.isChapterAvailable(state, current) then
            rank = rank + 1
        end
        if current == chapterId then
            return rank
        end
        local chapter = Story.get(current)
        current = chapter and chapter.next or nil
    end
    return rank
end

-- Ouvre un chapitre : il devient le chapitre en cours et son lieu est révélé sur la carte.
function Plot.enterChapter(state, chapterId)
    return State.withReveal(State.withChapter(state, chapterId), chapterId)
end

-- Passe à l'acte donné. L'entrée dans l'acte II ouvre le premier chapitre ; les autres actes
-- n'ont pas de chapitre en cours.
function Plot.enterAct(state, act, day)
    local nextState = State.withAct(state, act, day)
    if act ~= Const.ACT.INVESTIGATION then
        return State.withChapter(nextState, nil)
    end
    if nextState.chapter == nil then
        nextState = Plot.enterChapter(nextState, Story.FIRST_CHAPTER)
    end
    return nextState
end

-- Registres de state.flags liés aux objets posés qui restent dans le monde, gardés au redémarrage.
local KEPT_ON_RESET = { "tracked", "generators", "wallLights" }

-- Redémarrage de l'opération depuis le début : nouveau personnage dans une carte existante
-- (Artemis_NewCharacter) ou réinitialisation de debug. L'histoire repart de l'acte 0 (journal,
-- lectures, révélations, alertes effacés). Les documents et preuves seront reposés (groupes
-- « à ramasser », sans doublon dans un meuble qui les contient encore) ; les autres objets posés
-- restent dans le monde et leur pose n'est pas refaite (elle les doublerait).
function Plot.reset(state)
    local nextState = State.new()
    for group, isPlaced in pairs(state.placed) do
        if not Story.isPickupGroup(group) then
            nextState.placed[group] = isPlaced
        end
    end
    -- Les objets déjà posés restent dans le monde (poses gardées) : on garde aussi ce qui permet de les
    -- retrouver (zombies suivis, groupe électrogène de l'alerte, appliques éclairées).
    for _, name in ipairs(KEPT_ON_RESET) do
        if type(state.flags[name]) == "table" then
            nextState.flags[name] = State.copy(state.flags[name])
        end
    end
    return nextState
end

-- Corrige un état chargé :
-- - une partie arrivée à l'acte II avant la phase 2 (schéma 1) n'a pas de chapitre en cours ; on
--   ouvre alors le premier, sinon l'enquête resterait bloquée ;
-- - un groupe de pose séparé après coup (Story.SPLIT_GROUPS) est posé si son ancien groupe l'est.
function Plot.normalize(state)
    local nextState = State.copy(state)
    for newGroup, oldGroup in pairs(Story.SPLIT_GROUPS) do
        if nextState.placed[oldGroup] and nextState.placed[newGroup] == nil then
            nextState.placed[newGroup] = true
        end
    end
    if nextState.act == Const.ACT.INVESTIGATION and Story.get(nextState.chapter) == nil then
        return Plot.enterChapter(nextState, Story.FIRST_CHAPTER)
    end
    -- Chapitre optionnel en cours devenu indisponible (carte retirée) : on passe au suivant.
    if nextState.act == Const.ACT.INVESTIGATION and not Plot.isChapterAvailable(nextState, nextState.chapter) then
        local nextId = Plot.firstAvailable(nextState, Story.get(nextState.chapter).next)
        if nextId then
            return Plot.enterChapter(nextState, nextId)
        end
        return Plot.enterAct(nextState, Const.ACT.EXFILTRATION, 1)
    end
    return nextState
end

function Plot.start(state, day)
    return State.start(state, day)
end

-- Acte suivant (debug). Sans effet après l'épilogue.
function Plot.advance(state, day)
    if state.act >= Const.ACT.DONE then
        return State.copy(state)
    end
    return Plot.enterAct(state, state.act + 1, day)
end

-- Termine le chapitre en cours : entrée de journal, code d'appel éventuel, puis chapitre suivant
-- ou, pour le dernier, acte III. Renvoie (nouvelÉtat, chapitreTerminé) ; chapitreTerminé vaut nil
-- si aucun chapitre n'est en cours.
function Plot.completeChapter(state, day)
    local chapter = Story.get(state.chapter)
    if state.act ~= Const.ACT.INVESTIGATION or chapter == nil then
        return State.copy(state), nil
    end
    local completedId = state.chapter
    local nextId = Plot.firstAvailable(state, chapter.next)
    -- Entrée de journal propre au chapitre suivant s'il y en a une (chapitre optionnel annoncé).
    local journalKey = chapter.journalKeyByNext and chapter.journalKeyByNext[nextId] or chapter.journalKey
    local nextState = State.withJournal(state, day, journalKey)
    if chapter.callCode then
        nextState = State.withCallCode(nextState, chapter.callCode)
    end
    if nextId then
        return Plot.enterChapter(nextState, nextId), completedId
    end
    return Plot.enterAct(nextState, Const.ACT.EXFILTRATION, day), completedId
end

return Plot
