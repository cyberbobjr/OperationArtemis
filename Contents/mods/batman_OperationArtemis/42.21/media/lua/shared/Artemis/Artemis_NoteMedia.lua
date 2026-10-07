-- Opération Artemis : texte du carnet Artemis (document printMedia), traduit à la lecture.
--
-- La mise en page (info) et le texte du carnet contiennent la fréquence de la chaîne (%1). Composés
-- à la création de l'objet, souvent sur le serveur, ils seraient figés dans sa langue ; et sur un
-- serveur MP qui ignore les traductions du mod, la clé brute serait enregistrée, puis retraduite par
-- ISReadABook:displayPrintMedia sans argument (ISReadABook.lua:252-259) : la fréquence, indice de
-- l'intrigue, disparaîtrait. L'objet garde donc les clés et la fréquence ; le client compose le texte
-- dans la langue du lecteur juste avant l'ouverture du document (Artemis_NoteReader).

local Config = require "Artemis/Artemis_Config"

local NoteMedia = {}

NoteMedia.ID = "ArtemisNote"
NoteMedia.TITLE_KEY = "Print_Media_ArtemisNote_title"
NoteMedia.INFO_KEY = "Print_Media_ArtemisNote_info"
NoteMedia.TEXT_KEY = "Print_Text_ArtemisNote_info"

--- Données printMedia d'un carnet neuf : clés et fréquence, sans texte traduit.
function NoteMedia.newData()
    return {
        id = NoteMedia.ID,
        title = NoteMedia.TITLE_KEY,
        info = NoteMedia.INFO_KEY,
        text = NoteMedia.TEXT_KEY,
        frequency = Config.radioFrequencyLabel(),
    }
end

function NoteMedia.isNote(printMedia)
    return type(printMedia) == "table" and printMedia.id == NoteMedia.ID
end

-- Fréquence à citer : celle enregistrée sur le carnet, sinon (carnet créé avant la 0.3.1, qui ne
-- l'enregistrait pas) celle des options sandbox, qui est aussi celle de la chaîne.
local function frequencyOf(printMedia)
    local frequency = printMedia.frequency
    if type(frequency) == "string" and frequency ~= "" then
        return frequency
    end
    return Config.radioFrequencyLabel()
end

--- Mise en page et texte traduits dans la langue courante, fréquence comprise. Toujours composés
--- depuis les clés : un carnet ancien, qui gardait un texte déjà traduit ou une clé brute, s'affiche
--- ainsi correctement lui aussi.
function NoteMedia.compose(printMedia)
    local frequency = frequencyOf(printMedia)
    return getText(NoteMedia.INFO_KEY, frequency), getText(NoteMedia.TEXT_KEY, frequency)
end

return NoteMedia
