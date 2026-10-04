-- Opération Artemis : nouveau personnage dans une carte où l'opération est terminée (solo).
-- Le serveur a gardé la partie terminée (Artemis_NewCharacter) ; une fenêtre propose de relancer
-- l'opération depuis le début (nouveau carnet à trouver) ou de garder la fin obtenue. « Non » est
-- enregistré comme le choix « Continuer » de l'écran de fin : à ce moment, le nom du joueur est à jour.
-- Joueur local 0 seulement (l'arrivée d'un joueur en écran partagé déclenche aussi OnNewGame).
if isClient() then return end

require "ISUI/ISModalDialog"

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local ClientState = require "Artemis/Artemis_ClientState"

local DIALOG_WIDTH = 380
local DIALOG_HEIGHT = 170

local function onAnswer(_target, button, player)
    local command = button.internal == "YES" and Const.COMMAND.RESTART_AFTER_ENDING
        or Const.COMMAND.CONTINUE_AFTER_ENDING
    sendClientCommand(player, Const.NET_MODULE, command, {})
end

-- La fenêtre s'ouvre au premier tick de jeu : pendant OnNewGame, l'interface n'est pas encore prête.
local function showChoice()
    Events.OnTick.Remove(showChoice)
    local player = getPlayer()
    if not player then return end
    local x = math.floor((getCore():getScreenWidth() - DIALOG_WIDTH) / 2)
    local y = math.floor((getCore():getScreenHeight() - DIALOG_HEIGHT) / 2)
    local dialog = ISModalDialog:new(x, y, DIALOG_WIDTH, DIALOG_HEIGHT, getText("IGUI_Artemis_RestartChoice"), true,
        nil, onAnswer, player:getPlayerNum(), player)
    dialog:initialise()
    dialog:addToUIManager()
end

local function onNewGame(player, _square)
    if not player or player:getPlayerNum() ~= 0 then return end
    if Config.isEnabled() and ClientState.get().act == Const.ACT.DONE then
        Events.OnTick.Add(showChoice)
    end
end

Events.OnNewGame.Add(onNewGame)
