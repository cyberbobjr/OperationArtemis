-- Opération Artemis : état du scénario.
-- Fonctions pures : chacune renvoie un nouvel état sans modifier celui reçu.
-- Seul Artemis_Store (serveur) écrit l'état dans ModData.

local Const = require "Artemis/Artemis_Const"

local State = {}

local function deepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = deepCopy(item)
    end
    return copy
end

State.copy = deepCopy

-- chapter  : identifiant du chapitre en cours de l'acte II (Artemis_Story), nil sinon
-- placed   : { [groupe de pose] = true } quand les objets du groupe ont été posés dans le monde
--            (groupe par défaut : l'identifiant du chapitre, voir Artemis_Story)
-- revealed : liste des chapitres dont le lieu est révélé sur la carte, dans l'ordre
-- callCode : code d'appel appris au relais (acte III, route de l'hélicoptère)
-- lastScene: { id = scène, by = joueur déclencheur, seq = compteur } : dernière scène enregistrée
-- recentScenes : les SCENE_QUEUE_SIZE dernières scènes, de la plus ancienne à la plus récente
--            (Artemis_SceneTrigger les joue toutes, même si deux arrivent dans la même minute)
function State.new()
    return {
        schema = Const.SCHEMA_VERSION,
        rev = 0,
        act = Const.ACT.DORMANT,
        startedDay = -1,
        journal = {},
        flags = {},
        placed = {},
        revealed = {},
    }
end

local function isValidAct(act)
    return type(act) == "number" and act >= Const.ACT.DORMANT and act <= Const.ACT.DONE
end

-- Normalise une table lue dans ModData : champs manquants ou invalides remplacés par les valeurs neuves.
-- Le schéma 1 (phase 1) n'avait ni chapitre, ni révélations, ni code d'appel : ils prennent leur
-- valeur neuve. Son lastScene { act, by } sans seq compte comme seq = 0 et n'est jamais rejoué.
function State.migrate(raw)
    local state = State.new()
    if type(raw) ~= "table" then
        return state
    end
    if isValidAct(raw.act) then state.act = raw.act end
    if type(raw.rev) == "number" then state.rev = raw.rev end
    if type(raw.startedDay) == "number" then state.startedDay = raw.startedDay end
    if type(raw.journal) == "table" then state.journal = deepCopy(raw.journal) end
    if type(raw.flags) == "table" then state.flags = deepCopy(raw.flags) end
    if type(raw.placed) == "table" then state.placed = deepCopy(raw.placed) end
    if type(raw.revealed) == "table" then state.revealed = deepCopy(raw.revealed) end
    if type(raw.chapter) == "string" then state.chapter = raw.chapter end
    if type(raw.callCode) == "string" then state.callCode = raw.callCode end
    if type(raw.lastScene) == "table" then state.lastScene = deepCopy(raw.lastScene) end
    -- Avant la file (2c), seule la dernière scène était gardée : elle devient la file.
    if type(raw.recentScenes) == "table" then
        state.recentScenes = deepCopy(raw.recentScenes)
    elseif state.lastScene then
        state.recentScenes = { deepCopy(state.lastScene) }
    end
    return state
end

-- Nombre de scènes gardées : assez pour deux ou trois scènes enregistrées entre deux lectures
-- de l'état par le client.
State.SCENE_QUEUE_SIZE = 4

-- Mémorise la scène à jouer et qui l'a déclenchée : en multijoueur, seul ce joueur la joue côté
-- client (Artemis_SceneTrigger). Le compteur seq augmente à chaque scène, même identique.
function State.withScene(state, sceneId, username)
    local nextState = deepCopy(state)
    local previousSeq = type(state.lastScene) == "table" and tonumber(state.lastScene.seq) or 0
    local scene = { id = sceneId, by = username, seq = (previousSeq or 0) + 1 }
    nextState.lastScene = scene
    local queue = {}
    for _, entry in ipairs(nextState.recentScenes or {}) do
        queue[#queue + 1] = entry
    end
    queue[#queue + 1] = deepCopy(scene)
    while #queue > State.SCENE_QUEUE_SIZE do
        table.remove(queue, 1)
    end
    nextState.recentScenes = queue
    return nextState
end

function State.isStarted(state)
    return state.act > Const.ACT.DORMANT
end

-- Ajoute une entrée datée au journal (clé de traduction).
function State.withJournal(state, day, key)
    local nextState = deepCopy(state)
    nextState.journal[#nextState.journal + 1] = { day = day, key = key }
    return nextState
end

-- Passe à l'acte donné et ajoute l'entrée de journal de cet acte.
function State.withAct(state, act, day)
    if not isValidAct(act) then
        return deepCopy(state)
    end
    local nextState = State.withJournal(state, day, "IGUI_Artemis_J_Act" .. tostring(act))
    nextState.act = act
    if act > Const.ACT.DORMANT and nextState.startedDay < 0 then
        nextState.startedDay = day
    end
    return nextState
end

function State.start(state, day)
    if State.isStarted(state) then
        return deepCopy(state)
    end
    return State.withAct(state, Const.ACT.SIGNAL, day)
end

function State.withChapter(state, chapterId)
    local nextState = deepCopy(state)
    nextState.chapter = chapterId
    return nextState
end

function State.isRevealed(state, chapterId)
    for _, id in ipairs(state.revealed) do
        if id == chapterId then
            return true
        end
    end
    return false
end

function State.withReveal(state, chapterId)
    local nextState = deepCopy(state)
    if not State.isRevealed(state, chapterId) then
        nextState.revealed[#nextState.revealed + 1] = chapterId
    end
    return nextState
end

function State.withPlaced(state, group)
    local nextState = deepCopy(state)
    nextState.placed[group] = true
    return nextState
end

-- Retire un groupe du registre des poses : il sera reposé (objet indispensable perdu).
function State.withoutPlaced(state, group)
    local nextState = deepCopy(state)
    nextState.placed[group] = nil
    return nextState
end

-- Registres de drapeaux dans state.flags (pas de changement de schéma) :
--   readDocs = { [type complet] = true }  documents lus jusqu'au bout
--   arrived  = { [chapitre] = true }      pensée d'arrivée déjà dite
--   hinted   = { [scène d'aide] = true }  aide déjà donnée
function State.hasFlagEntry(state, name, key)
    local entries = state.flags[name]
    return type(entries) == "table" and entries[key] == true
end

function State.withFlagEntry(state, name, key)
    local nextState = deepCopy(state)
    if type(nextState.flags[name]) ~= "table" then
        nextState.flags[name] = {}
    end
    nextState.flags[name][key] = true
    return nextState
end

-- Registres de valeurs dans state.flags (mêmes règles que les drapeaux ci-dessus) :
--   tracked    = { [clé de tenue] = { profile = profil } }  zombies suivis (Artemis_Tracked)
--   generators = { [groupe] = { x, y, z } }                  groupe électrogène d'une alerte
--   wallLights = { [groupe] = { x, y, z, sprite, ... } }     appliques éclairées (Artemis_WorldLights)
--   alarms     = { [chapitre] = { status, startMinutes } }   alertes (Artemis_Alarm)
function State.flagValue(state, name, key)
    local entries = state.flags[name]
    return type(entries) == "table" and entries[key] or nil
end

function State.withFlagValue(state, name, key, value)
    local nextState = deepCopy(state)
    if type(nextState.flags[name]) ~= "table" then
        nextState.flags[name] = {}
    end
    nextState.flags[name][key] = deepCopy(value)
    return nextState
end

function State.withCallCode(state, code)
    local nextState = deepCopy(state)
    nextState.callCode = code
    return nextState
end

return State
