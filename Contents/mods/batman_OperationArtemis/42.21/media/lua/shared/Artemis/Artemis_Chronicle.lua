-- Opération Artemis : chronique de la partie, affichée par l'écran de fin et écrite dans un fichier
-- (fonctions pures). Construite d'après l'état : fin obtenue (state.flags.ending.result, écrite par
-- le serveur à l'embarquement), jours, heures de survie, zombies tués depuis la lecture du carnet, et
-- le journal daté de l'opération, qui raconte l'enquête.
-- Chaque ligne est { key, params } (clé de traduction et paramètres) ; render la traduit avec la
-- fonction donnée (getText en jeu, une table dans les tests).

local State = require "Artemis/Artemis_State"
local Endings = require "Artemis/Artemis_Endings"

local Chronicle = {}

-- Kahlua (Lua 5.1) a unpack ; les tests hors jeu tournent sous un Lua récent (table.unpack).
local unpackArgs = table.unpack or unpack

-- Lignes de la chronique, ou une liste vide si la partie n'est pas terminée.
-- frequency : fréquence affichée de la chaîne Artemis (certaines entrées du journal la citent).
function Chronicle.lines(state, frequency)
    local ending = State.flagValue(state, "ending", "result")
    if type(ending) ~= "table" then
        return {}
    end
    local startedDay = state.startedDay >= 0 and state.startedDay or ending.day
    local lines = {
        { key = "IGUI_Artemis_Chronicle_Header" },
        { key = "IGUI_Artemis_Chronicle_Days", params = { startedDay, ending.day, ending.day - startedDay + 1 } },
        { key = "IGUI_Artemis_Chronicle_Hours", params = { ending.hours or 0 } },
        { key = "IGUI_Artemis_Chronicle_Kills", params = { ending.kills or 0 } },
        { key = Endings.routeKey(ending) },
    }
    local exitKey = Endings.exitKey(ending)
    if exitKey then
        lines[#lines + 1] = { key = exitKey }
    end
    if ending.hasCure then
        lines[#lines + 1] = { key = "IGUI_Artemis_Chronicle_Cure" }
    end
    lines[#lines + 1] = { key = "IGUI_Artemis_Chronicle_Journal" }
    for _, entry in ipairs(state.journal) do
        lines[#lines + 1] = { key = "IGUI_Artemis_Chronicle_Entry", day = entry.day, entryKey = entry.key,
            params = { frequency } }
    end
    return lines
end

-- Texte de chaque ligne. text(key, ...) traduit une clé avec ses paramètres.
function Chronicle.render(lines, text)
    local out = {}
    for _, line in ipairs(lines) do
        local params = line.params or {}
        if line.entryKey then
            out[#out + 1] = text(line.key, tostring(line.day), text(line.entryKey, unpackArgs(params)))
        else
            local strings = {}
            for index, value in ipairs(params) do
                strings[index] = tostring(value)
            end
            out[#out + 1] = text(line.key, unpackArgs(strings))
        end
    end
    return out
end

-- Nom de fichier sûr pour la chronique (sous Zomboid\Lua) : lettres, chiffres, tiret et soulignés.
function Chronicle.fileName(worldName, day)
    local safe = tostring(worldName or "partie"):gsub("[^%w%-_]", "_")
    return "OperationArtemis/chronique_" .. safe .. "_j" .. tostring(day) .. ".txt"
end

return Chronicle
