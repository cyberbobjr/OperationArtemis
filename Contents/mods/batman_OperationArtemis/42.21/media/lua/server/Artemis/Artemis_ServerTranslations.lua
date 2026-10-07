-- Opération Artemis : traductions du mod sur un serveur multijoueur (dédié ou hébergé).
--
-- Un serveur MP lit les traductions avant de charger les mods (GameServer.java:639, loadMods à
-- :1355) et ne les relit jamais : getText y renvoie les clés du mod brutes. Or plusieurs textes sont
-- composés sur le serveur : lignes de la chaîne ARTEMIS (Artemis_Radio), nom de la carte-cachette
-- de V (Artemis_Placement), carte d'identité de Miller (Artemis_Tracked), CD et portable de Computer
-- Mod (Artemis_ComputerMod). Quand ce fichier s'exécute, les mods sont chargés (loadMods précède
-- LuaManager.init, :1355-1356) : un rechargement, comme le menu de debug vanilla
-- (ISDebugMenu.lua:283), ajoute leurs traductions.
-- Limite : ces textes sortent dans la langue du serveur, pas dans celle de chaque joueur. Le carnet,
-- lui, est traduit à la lecture côté client (Artemis_NoteMedia).
-- Solo : traductions déjà présentes, rien à faire.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"

local ServerTranslations = {}

-- Clé sans paramètre, présente dans toutes les langues livrées : getTextOrNull ne signale aucun
-- argument manquant.
ServerTranslations.PROBE_KEY = "IGUI_Artemis_Radio_Numbers"

--- Recharge les traductions si celles du mod manquent ; vrai si rechargées.
function ServerTranslations.ensure()
    if getTextOrNull(ServerTranslations.PROBE_KEY) ~= nil then
        return false
    end
    if not (Translator and Translator.loadFiles) then
        Const.log("mod translations missing on the server and Translator.loadFiles unavailable")
        return false
    end
    Translator.loadFiles()
    local loaded = getTextOrNull(ServerTranslations.PROBE_KEY) ~= nil
    Const.log(loaded and "mod translations reloaded on the server"
        or "mod translations still missing on the server after reload")
    return loaded
end

ServerTranslations.ensure()

return ServerTranslations
