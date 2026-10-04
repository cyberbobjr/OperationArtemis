-- Opération Artemis : ouvre l'écran de victoire (Artemis_EndingUI).
-- - Au passage à l'épilogue pendant la partie : avec le fondu au blanc (l'hélicoptère décolle).
-- - Au chargement d'une partie terminée, tant que ce joueur n'a pas choisi « Continuer » : sans fondu
--   (« Terminer » a ramené au menu ; l'écran revient à la reprise).
-- - Depuis le journal, après « Continuer » : relecture (Artemis_JournalUI).
-- Un personnage créé dans cette session (nouveau personnage après une fin) ne voit pas l'écran : la
-- fenêtre de relance le remplace (Artemis_RestartChoice), et son choix est enregistré par elle (le nom du
-- joueur n'est définitif qu'après OnNewGame : « Bob » avant, IsoPlayer.java:389, IngameState.java:826).

local Const = require "Artemis/Artemis_Const"
local State = require "Artemis/Artemis_State"
local StateWatcher = require "Artemis/Artemis_StateWatcher"
local EndingUI = require "Artemis/Artemis_EndingUI"

local lastAct = nil
local isNewCharacter = false

local function hasContinued(state)
    local player = getPlayer()
    return player ~= nil and State.flagValue(state, "endingChoice", player:getUsername()) == "continue"
end

local function onState(state, isFirst)
    local previousAct = lastAct
    lastAct = state.act
    if state.act ~= Const.ACT.DONE or not getPlayer() then return end
    if isFirst then
        if not hasContinued(state) and not isNewCharacter then
            EndingUI.open(state, false, false)
        end
    elseif previousAct ~= nil and previousAct < Const.ACT.DONE then
        EndingUI.open(state, true, false)
    end
end

-- Joueur local 0 seulement : en écran partagé, l'arrivée d'un autre joueur déclenche aussi OnNewGame.
local function onNewGame(player, _square)
    if player and player:getPlayerNum() == 0 then
        isNewCharacter = true
    end
end

StateWatcher.subscribe(onState)
Events.OnNewGame.Add(onNewGame)
