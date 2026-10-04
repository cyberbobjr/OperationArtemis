-- Opération Artemis : intégration facultative de Zombie Virus Vaccine (id ZVirusVaccine42BETA, variante
-- 42.20 ; lu seulement, rien n'en est copié). Ce mod fournit le test sanguin d'entrée du checkpoint
-- (route C) et le remède qui permet de revenir après un test final positif.

local Vaccine = {}

Vaccine.MOD_ID = "ZVirusVaccine42BETA"
-- Seringues de remède (fin bonus, chronique).
Vaccine.CURE_ITEMS = { "LabItems.CmpSyringeWithCure", "LabItems.CmpSyringeReusableWithCure" }

local isActiveCache = nil

-- Le mod est-il actif ? getActivatedMods est une liste Java ; un identifiant peut commencer par « \ ».
-- On vérifie aussi qu'un de ses objets existe (mod présent mais scripts absents).
function Vaccine.isActive()
    if isActiveCache == nil then
        local isListed = false
        local mods = getActivatedMods()
        for index = 0, mods:size() - 1 do
            local id = tostring(mods:get(index)):gsub("^\\", "")
            if id == Vaccine.MOD_ID then
                isListed = true
                break
            end
        end
        isActiveCache = isListed and getScriptManager():FindItem("LabItems.LabTestResultNegative") ~= nil
    end
    return isActiveCache
end

-- L'inventaire contient-il un remède ?
function Vaccine.carriesCure(inventory)
    for _, fullType in ipairs(Vaccine.CURE_ITEMS) do
        if inventory:containsTypeRecurse(fullType) then
            return true
        end
    end
    return false
end

return Vaccine
