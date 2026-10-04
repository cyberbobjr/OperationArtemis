-- Opération Artemis : un nouveau personnage dans une carte existante recommence l'opération.
-- Solo uniquement. Le jeu déclenche OnNewGame seulement à la création d'un personnage (nouvelle
-- partie, ou nouveau personnage après une mort dans la même carte : IsoWorld.java:2154, 2245), pas au
-- rechargement d'un personnage existant. Si l'opération avait commencé, l'enquête du personnage
-- précédent ne lui appartient pas : l'état repart de l'acte 0 (Artemis_Plot.reset : documents
-- reposés, objets du monde gardés). Dans une carte neuve, l'opération n'a pas commencé : rien à faire.
-- En multijoueur, un joueur qui arrive ne doit pas effacer l'enquête des autres : aucun effet.
if isClient() or isServer() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Plot = require "Artemis/Artemis_Plot"
local Store = require "Artemis/Artemis_Store"

-- Après une fin (épilogue), l'opération n'est pas effacée d'office : une fenêtre propose au joueur de
-- la relancer (Artemis_RestartChoice, Progress.onRestartAfterEnding ; décision de la phase 4).
-- Joueur local 0 seulement : en écran partagé, l'arrivée d'un autre joueur déclenche aussi OnNewGame
-- (LuaManager.java:5358-5372) et ne doit pas effacer l'enquête en cours.
local function onNewGame(player, _square)
    if not Config.isEnabled() or not player or player:getPlayerNum() ~= 0 then return end
    local state = Store.load()
    if not State.isStarted(state) then return end
    if state.act == Const.ACT.DONE then
        Const.log("nouveau personnage apres la fin : partie terminee gardee, choix propose")
        return
    end
    local restarted = Store.save(Plot.reset(state))
    Const.log("nouveau personnage : operation reprise du debut (acte " .. tostring(restarted.act)
        .. ", revision " .. tostring(restarted.rev) .. ")")
end

Events.OnNewGame.Add(onNewGame)
