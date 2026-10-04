-- Opération Artemis : minuterie de repères (utilisée par la mise en scène client et serveur).
-- Chaque repère { at = secondes, cue = "type", ... } est confié, à son heure, au gestionnaire
-- de son type. Le temps n'avance pas pendant la pause du jeu.

local Const = require "Artemis/Artemis_Const"

local Timeline = {}
Timeline.__index = Timeline

local MS_PER_SECOND = 1000

-- handlers : table { [type] = function(cue, context) }.
function Timeline.new(handlers)
    return setmetatable({ handlers = handlers, pending = {}, elapsedMs = 0, lastTickMs = nil }, Timeline)
end

-- Programme les repères d'une scène, à partir de maintenant.
function Timeline:play(cues, context)
    for _, cue in ipairs(cues or {}) do
        self.pending[#self.pending + 1] = {
            dueMs = self.elapsedMs + (cue.at or 0) * MS_PER_SECOND,
            cue = cue,
            context = context,
        }
    end
end

function Timeline:isIdle()
    return #self.pending == 0
end

local function runCue(handlers, entry)
    local handler = handlers[entry.cue.cue]
    if not handler then
        Const.log("repere inconnu ignore : " .. tostring(entry.cue.cue))
        return
    end
    handler(entry.cue, entry.context)
end

-- À appeler à chaque tick : exécute les repères arrivés à échéance.
function Timeline:update()
    local nowMs = getTimestampMs()
    local deltaMs = self.lastTickMs and (nowMs - self.lastTickMs) or 0
    self.lastTickMs = nowMs
    if isGamePaused() or self:isIdle() then return end
    self.elapsedMs = self.elapsedMs + deltaMs

    -- Les repères échus sont retirés AVANT d'être exécutés : une erreur dans un gestionnaire
    -- ne les fait pas rejouer au tick suivant, et un play() appelé par un gestionnaire n'est pas perdu.
    local due, remaining = {}, {}
    for _, entry in ipairs(self.pending) do
        if entry.dueMs <= self.elapsedMs then
            due[#due + 1] = entry
        else
            remaining[#remaining + 1] = entry
        end
    end
    self.pending = remaining
    for _, entry in ipairs(due) do
        runCue(self.handlers, entry)
    end
end

return Timeline
