-- Opération Artemis : pont avec Military Drop (même auteur), contrat « Military Drop transporte,
-- Artemis raconte » (MilitaryDrop/docs/analyses/idee-10-extraction.md, décisions de la phase 4).
-- Événements Lua partagés, déclarés par chaque mod (LuaEventManager.AddEvent est idempotent,
-- LuaEventManager.java:615-631) :
--   batman_OnExtractionAvailable(provider)  serveur : un mod annonce qu'il assure le transport
--                                            (hélicoptère) ; Artemis n'ouvre alors pas sa route B ;
--   batman_OnExtraction(username, info)     serveur : un joueur part avec l'hélicoptère de l'autre mod ;
--                                            Artemis termine l'opération s'il porte le dossier ;
--   batman_OnExtractionSummary(lines, player) client : l'autre mod demande des lignes pour son bilan.
-- Sans Military Drop (ou tant qu'il n'annonce rien), Artemis garde sa propre route B.
-- L'annonce doit être faite sur le serveur (ou en solo) après le chargement de tous les mods
-- (OnGameStart, OnServerStarted) : une annonce faite avant l'abonnement d'Artemis serait perdue.

local Bridge = {}

Bridge.EVENTS = { "batman_OnExtractionAvailable", "batman_OnExtraction", "batman_OnExtractionSummary" }

for _, name in ipairs(Bridge.EVENTS) do
    LuaEventManager.AddEvent(name)
end

local transportProvider = nil

-- Un autre mod assure-t-il le transport de l'extraction ?
function Bridge.hasTransport()
    return transportProvider ~= nil
end

local function onExtractionAvailable(provider)
    transportProvider = tostring(provider or "?")
end

Events.batman_OnExtractionAvailable.Add(onExtractionAvailable)

return Bridge
