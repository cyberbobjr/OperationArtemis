-- Opération Artemis : lectures qui comptent pour l'histoire.
-- - Le carnet : le lire démarre l'opération.
-- - Les documents de l'enquête : leur lecture est enregistrée (objectif du relais) et commentée
--   par le personnage (scène « read_<TypeObjet> »).
-- Aucun événement vanilla ne signale une lecture terminée : on enveloppe ISReadABook:complete,
-- qui s'exécute en solo et sur le serveur multijoueur (perform ne tourne que côté client).
if isClient() then return end

require "TimedActions/ISReadABook"

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Progress = require "Artemis/Artemis_Progress"

-- La fonction d'origine est conservée sur la table vanilla : un rechargement du fichier
-- n'empile pas une seconde enveloppe.
ISReadABook.batmanArtemisOriginalComplete = ISReadABook.batmanArtemisOriginalComplete or ISReadABook.complete

function ISReadABook:complete()
    local result = ISReadABook.batmanArtemisOriginalComplete(self)
    -- forceStopped : lecture interrompue côté serveur (ISReadABook.lua:326).
    if not self.item or self.forceStopped or not Config.isEnabled() then
        return result
    end
    local fullType = self.item:getFullType()
    if fullType == Const.ITEM_NOTE then
        Progress.onNoteRead(self.character)
    elseif Const.READABLE_DOCUMENTS[fullType] then
        Progress.onDocumentRead(self.character, fullType)
    end
    return result
end
