-- Opération Artemis : logique serveur (tourne aussi en solo, où isClient() est faux).
-- Charge l'état au démarrage et traite les commandes envoyées par le client.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Clock = require "Artemis/Artemis_Clock"
local Plot = require "Artemis/Artemis_Plot"
local Store = require "Artemis/Artemis_Store"
local Progress = require "Artemis/Artemis_Progress"
local ModMaps = require "Artemis/Artemis_ModMaps"
local Checkpoint = require "Artemis/Artemis_Checkpoint"

local function onInitGlobalModData(_isNewGame)
    local state = Store.save(Plot.normalize(Store.load()))
    Const.log("etat charge : acte " .. tostring(state.act) .. ", revision " .. tostring(state.rev))
end

-- Portée du haut-parleur envoyée par le client : bornée, pour qu'un client ne puisse pas faire
-- venir les zombies de toute la carte (les radios vanilla restent bien en dessous).
local MAX_SPEAKER_RANGE = 60

local function speakerRangeFrom(args)
    local range = type(args) == "table" and tonumber(args.speakerRange) or 0
    return math.max(0, math.min(MAX_SPEAKER_RANGE, math.floor(range or 0)))
end

-- Commandes de jeu : le serveur revalide toujours l'état (voir Artemis_Progress).
local GAMEPLAY_HANDLERS = {
    [Const.COMMAND.HEARD_SIGNAL] = function(player, args) Progress.onSignalHeard(player, speakerRangeFrom(args)) end,
    [Const.COMMAND.HEARD_TAPE] = function(player) Progress.onTapeHeard(player) end,
    [Const.COMMAND.CALL_EXTRACTION] = function(player, args) Progress.onExtractionCall(player, args) end,
    [Const.COMMAND.CONTINUE_AFTER_ENDING] = function(player) Progress.onEndingContinue(player) end,
    [Const.COMMAND.RESTART_AFTER_ENDING] = function(player) Progress.onRestartAfterEnding(player) end,
    [Const.COMMAND.CHECKPOINT_TEST] = function(player) Checkpoint.onModTest(player) end,
    [Const.COMMAND.CHECKPOINT_LEAVE] = function(player) Checkpoint.onLeave(player) end,
    [Const.COMMAND.CALL_FERRY] = function(player, args) Progress.onFerryCall(player, args) end,
}

-- Debug : donne le carnet Artemis au joueur (tester la lecture sans chercher un soldat).
local function giveNoteTo(player)
    local inventory = player:getInventory()
    local item = inventory:AddItem(Const.ITEM_NOTE)
    if isServer() and item then
        sendAddItemToContainer(inventory, item)
    end
end

-- Commandes de debug : chacune reçoit (état, joueur) et renvoie le nouvel état, ou nil si
-- l'état ne change pas ou a déjà été enregistré. Démarrer et avancer jouent aussi la scène de
-- l'acte atteint ; entrer dans l'acte II ouvre le premier chapitre.
local DEBUG_HANDLERS = {
    [Const.COMMAND.DEBUG_START] = function(state) return Plot.start(state, Clock.now().day) end,
    [Const.COMMAND.DEBUG_ADVANCE] = function(state) return Plot.advance(state, Clock.now().day) end,
    [Const.COMMAND.DEBUG_RESET] = function(state) return Plot.reset(state) end,
    [Const.COMMAND.DEBUG_GIVE_NOTE] = function(_state, player)
        giveNoteTo(player)
        return nil
    end,
    -- Termine le chapitre en cours comme si son objectif était atteint (Progress enregistre lui-même).
    [Const.COMMAND.DEBUG_COMPLETE_CHAPTER] = function(_state, player)
        Progress.completeChapter(player)
        return nil
    end,
}

-- En multijoueur, le debug exige l'option DebugMode (ou -debug) ET un rôle autorisé
-- (même contrôle que le menu de debug vanilla, ClientCommands.lua:155).
local function isDebugAuthorized(player)
    if not Config.isDebugAllowed() then
        return false
    end
    if isServer() then
        return checkPermissions(player, Capability.UseDebugContextMenu)
    end
    return true
end

local function runDebugCommand(command, player)
    if not isDebugAuthorized(player) then
        Const.log("commande de debug refusee : " .. command)
        return
    end
    local previousState = Store.load()
    local nextState = DEBUG_HANDLERS[command](previousState, player)
    if nextState == nil then return end
    -- Scène de l'acte atteint seulement si l'acte avance (pas pour un reset).
    local sceneId = Progress.sceneForTransition(previousState, nextState, nil)
    local state = Progress.commit(previousState, nextState, player, sceneId)
    Const.log(command .. " par " .. tostring(player:getUsername())
        .. " : acte " .. tostring(state.act) .. ", revision " .. tostring(state.rev))
end

local function onClientCommand(module, command, player, args)
    if module ~= Const.NET_MODULE or not player then return end
    if not Config.isEnabled() then
        Const.log("mod desactive dans les options sandbox, commande ignoree : " .. tostring(command))
        return
    end
    if GAMEPLAY_HANDLERS[command] then
        GAMEPLAY_HANDLERS[command](player, args)
    elseif DEBUG_HANDLERS[command] then
        runDebugCommand(command, player)
    else
        Const.log("commande inconnue ignoree : " .. tostring(command))
    end
end

-- Partie déjà à l'acte II ou au-delà sans relevé des chapitres optionnels (phase 6) : relevé à la
-- première minute de jeu, la métagrille étant alors construite (ModMaps.freeze).
local isOptionalChecked = false

local function checkOptionalChapters()
    if isOptionalChecked then return end
    isOptionalChecked = true
    Events.EveryOneMinute.Remove(checkOptionalChapters)
    local state = Store.load()
    local frozen = ModMaps.freeze(state)
    if frozen ~= state then
        Store.save(Plot.normalize(frozen))
    end
end

Events.OnInitGlobalModData.Add(onInitGlobalModData)
Events.EveryOneMinute.Add(checkOptionalChapters)
Events.OnClientCommand.Add(onClientCommand)
