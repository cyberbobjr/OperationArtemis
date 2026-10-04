-- Opération Artemis : bande enregistrée rejouée par une radio posée (fonctions pures).
-- Données « tape » d'un chapitre (Artemis_Story) ; lecture côté client par Artemis_RelayTape.

local Tape = {}

-- Repères de la minuterie (Artemis_Timeline) : une ligne après l'autre, chacune affichée pendant
-- « seconds » secondes, puis un repère de fin. Une ligne a soit un texte brut (raw, parasite comme
-- « <fzzt> »), soit une clé de traduction (key).
function Tape.cues(lines)
    local cues, at = {}, 0
    for _, line in ipairs(lines) do
        cues[#cues + 1] = { at = at, cue = "line", raw = line.raw, key = line.key }
        at = at + line.seconds
    end
    cues[#cues + 1] = { at = at, cue = "tapeEnd" }
    return cues
end

-- La case (x, y, z) est-elle dans la salle { x1, y1, x2, y2, z } ?
function Tape.isInRoom(room, x, y, z)
    return z == room.z and x >= room.x1 and x <= room.x2 and y >= room.y1 and y <= room.y2
end

return Tape
