-- Opération Artemis : joue la partie client des scènes que le serveur vient d'enregistrer.
-- L'état porte recentScenes, les dernières scènes { id, by, seq } (Artemis_State.withScene) : chaque
-- nouvelle scène augmente seq. Toutes les scènes plus récentes que la dernière vue sont jouées, dans
-- l'ordre, même si deux ont été enregistrées entre deux lectures de l'état. En multijoueur, seul le
-- joueur qui a déclenché une scène la joue (champ by).

local Config = require "Artemis/Artemis_Config"
local Scenes = require "Artemis/Artemis_Scenes"
local StagingFX = require "Artemis/Artemis_StagingFX"
local StateWatcher = require "Artemis/Artemis_StateWatcher"

-- Dernier compteur de scène observé. nil avant la première observation : au chargement d'une
-- partie, les scènes déjà enregistrées servent de point de départ et ne sont pas rejouées.
local lastSeq = nil

local function sceneSeq(scene)
    return type(scene) == "table" and tonumber(scene.seq) or 0
end

local function playScene(scene, player)
    if scene.by ~= player:getUsername() then return end
    local data = Scenes.get(scene.id)
    if data then
        StagingFX.play(data.client, player)
    end
end

local function onState(state, isFirst)
    local previousSeq = lastSeq
    -- Après une réinitialisation (debug), seq repart de 0 : on le suit aussi vers le bas.
    lastSeq = sceneSeq(state.lastScene)
    if isFirst or previousSeq == nil or not Config.isEnabled() then return end

    local player = getPlayer()
    if not player or player:isDead() then return end
    for _, scene in ipairs(state.recentScenes or {}) do
        if sceneSeq(scene) > previousSeq then
            playScene(scene, player)
        end
    end
end

local function onTick()
    StagingFX.update()
end

StateWatcher.subscribe(onState)
Events.OnTick.Add(onTick)
