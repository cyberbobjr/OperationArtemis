-- Opération Artemis : test d'entrée du checkpoint par Zombie Virus Vaccine (s'il est actif).
-- Son test (seringue de sang analysée au spectromètre) est traité sur le serveur par
-- BloodTestLogic.ProcessTest(player, itemType), qui renvoie « Positive », « Negative » ou
-- « InvalidSample » (BloodTestLogic_Server.lua:7-77). Son orchestrateur l'appelle par la table du
-- module au moment de la commande (VaccineOrchestrator_Server.lua:104-109) : require renvoie la même
-- table, on enveloppe donc sa fonction. Le résultat compte pour le checkpoint si le joueur est au poste
-- (Artemis_Checkpoint). Le résultat du mod n'a ni propriétaire ni date : on note le nôtre à part.
-- L'enveloppe est posée au chargement du monde (OnInitGlobalModData, solo et serveur) : les scripts
-- d'objets sont alors chargés (Vaccine.isActive vérifie un objet du mod).
if isClient() then return end

local Vaccine = require "Artemis/Artemis_Vaccine"
local Checkpoint = require "Artemis/Artemis_Checkpoint"

local function wrap()
    if not Vaccine.isActive() then return end
    local BloodTestLogic = require "HealthSystem/BloodTestLogic_Server"
    if type(BloodTestLogic) ~= "table" or type(BloodTestLogic.ProcessTest) ~= "function" then return end
    -- Fonction d'origine conservée sur la table du mod : un rechargement n'empile pas une seconde enveloppe.
    BloodTestLogic.batmanArtemisOriginalProcessTest = BloodTestLogic.batmanArtemisOriginalProcessTest
        or BloodTestLogic.ProcessTest
    function BloodTestLogic.ProcessTest(player, itemType)
        local result = BloodTestLogic.batmanArtemisOriginalProcessTest(player, itemType)
        if player and (result == "Negative" or result == "Positive") then
            Checkpoint.onEntryTest(player, result == "Negative", "vaccine")
        end
        return result
    end
end

Events.OnInitGlobalModData.Add(wrap)
