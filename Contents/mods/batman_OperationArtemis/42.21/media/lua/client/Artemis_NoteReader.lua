-- Opération Artemis : ouverture du carnet Artemis dans la langue du lecteur, fréquence comprise.
-- Le carnet garde des clés et la fréquence (Artemis_NoteMedia). ISReadABook:displayPrintMedia
-- traduit info et text sans argument (ISReadABook.lua:252-259) : on y place, le temps de l'appel,
-- le texte déjà composé ; getText le renvoie alors tel quel (Translator.java:363-376). Les clés sont
-- ensuite remises, ce qui convertit aussi un carnet ancien (texte figé ou clé brute).
-- Client et solo : perform, qui ouvre le document, ne tourne que côté client.

require "TimedActions/ISReadABook"

local NoteMedia = require "Artemis/Artemis_NoteMedia"

-- Les fonctions d'origine sont conservées sur la table vanilla : un rechargement du fichier
-- n'empile pas une seconde enveloppe.
ISReadABook.batmanArtemisOriginalDisplayPrintMedia = ISReadABook.batmanArtemisOriginalDisplayPrintMedia
    or ISReadABook.displayPrintMedia
ISReadABook.batmanArtemisOriginalLoadPrintMediaTextures = ISReadABook.batmanArtemisOriginalLoadPrintMediaTextures
    or ISReadABook.startLoadingPrintMediaTextures

local function notePrintMedia(action)
    local item = action.item
    local printMedia = item and item:hasModData() and item:getModData().printMedia or nil
    return NoteMedia.isNote(printMedia) and printMedia or nil
end

-- La mise en page du carnet n'utilise aucune image : rien à précharger. L'appel vanilla traduirait
-- la clé sans la fréquence et journaliserait un argument manquant (Translator.java:390-399).
function ISReadABook:startLoadingPrintMediaTextures()
    if notePrintMedia(self) then
        return nil
    end
    return ISReadABook.batmanArtemisOriginalLoadPrintMediaTextures(self)
end

function ISReadABook:displayPrintMedia()
    local printMedia = notePrintMedia(self)
    if printMedia == nil then
        return ISReadABook.batmanArtemisOriginalDisplayPrintMedia(self)
    end
    printMedia.info, printMedia.text = NoteMedia.compose(printMedia)
    -- pcall seulement pour remettre les clés : une erreur de la fenêtre est relancée telle quelle.
    local ok, result = pcall(ISReadABook.batmanArtemisOriginalDisplayPrintMedia, self)
    printMedia.info, printMedia.text = NoteMedia.INFO_KEY, NoteMedia.TEXT_KEY
    if not ok then
        error(result)
    end
    return result
end
