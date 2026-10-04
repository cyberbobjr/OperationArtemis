-- Opération Artemis : fonctions appelées par les scripts d'objets (media/scripts/Artemis_items.txt).
-- Le moteur résout « OnCreate = OperationArtemisItems.onCreateNote » par son nom : la table doit être globale.

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"

OperationArtemisItems = OperationArtemisItems or {}

-- Rend le carnet lisible par la fenêtre vanilla des documents (ISReadABook -> PZAPI.UI.PrintMedia).
-- La mise en page (info) et le texte contiennent la fréquence, réglable : ils sont traduits ici,
-- avec la fréquence (%1), puis enregistrés sur l'objet. À la lecture, getText reçoit ce texte
-- déjà traduit ; ce n'est pas une clé connue, il le renvoie donc tel quel (Translator.java:363-376).
-- Limite : le carnet garde la langue et la fréquence du moment de sa création.
function OperationArtemisItems.onCreateNote(item)
    local frequency = Config.radioFrequencyLabel()
    item:getModData().printMedia = {
        id = "ArtemisNote",
        title = "Print_Media_ArtemisNote_title",
        info = getText("Print_Media_ArtemisNote_info", frequency),
        text = getText("Print_Text_ArtemisNote_info", frequency),
    }
end

-- Documents de l'enquête (badge, ordres, dossiers, journal du relais) : même fenêtre que le carnet.
-- Leurs textes n'ont pas de paramètre : on enregistre les clés, traduites à la lecture dans la
-- langue du lecteur. Clés attendues pour un objet de type T : Print_Media_T_title,
-- Print_Media_T_info (mise en page, Print_Media.json) et Print_Text_T_info (texte, Print_Text.json).
function OperationArtemisItems.onCreateDocument(item)
    local id = item:getType()
    item:getModData().printMedia = {
        id = id,
        title = "Print_Media_" .. id .. "_title",
        info = "Print_Media_" .. id .. "_info",
        text = "Print_Text_" .. id .. "_info",
    }
end

-- Carte d'accès Artemis : une clé (classe Key) qui ouvre les portes blindées de la base. Une clé naît
-- avec keyId = -1 et aucune propriété de script ne le fixe (Key.java:27 ; Item.java:1502-1511) :
-- on le donne ici. Il est sauvegardé et transmis avec l'objet (Key.java:122-134). Comme toute clé,
-- elle ne compte que dans l'inventaire principal ou un porte-clés, pas dans un sac.
function OperationArtemisItems.onCreateKeycard(item)
    item:setKeyId(Const.KEYCARD_KEY_ID)
end

