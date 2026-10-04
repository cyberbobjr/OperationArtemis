-- Opération Artemis : place le carnet Artemis dans le cadavre d'un zombie militaire.
-- Serveur ou solo : sur un client multijoueur, un ajout à l'inventaire n'a pas d'autorité.
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local Clock = require "Artemis/Artemis_Clock"
local NotePolicy = require "Artemis/Artemis_NotePolicy"
local Store = require "Artemis/Artemis_Store"

-- Marque posée sur le zombie : « seen » (déjà traité) ou « note » (porte le carnet).
-- Nécessaire car OnZombieDead peut se déclencher deux fois pour une mort par le feu,
-- et le second passage vide l'inventaire (IsoZombie.onKilled -> DoZombieInventory).
local MARK_KEY = "batman_ArtemisMark"
local ROLL_RANGE = 100

local function isMilitary(zombie)
    local outfit = zombie:getOutfitName()
    return outfit ~= nil and Const.MILITARY_OUTFITS[outfit] == true
end

-- Diagnostic (mode debug uniquement) : signale une tenue d'allure militaire absente de la liste,
-- pour repérer un nom de tenue d'un autre mod ou d'une autre version du jeu.
local function reportUnknownMilitaryOutfit(zombie)
    if not Config.isDebugAllowed() then return end
    local outfit = zombie:getOutfitName()
    if outfit and (outfit:find("Army", 1, true) or outfit:find("Military", 1, true)) then
        Const.log("debug : tenue militaire non reconnue : " .. outfit)
    end
end

-- Ajoute le carnet s'il est absent. Appelé pendant OnZombieDead : le cadavre reprend
-- ensuite l'inventaire du zombie (IsoDeadBody.java:327).
local function giveNote(zombie)
    local inventory = zombie:getInventory()
    if not inventory:containsType(Const.ITEM_NOTE) then
        inventory:AddItem(Const.ITEM_NOTE)
    end
end

local function readMark(zombie)
    return zombie:hasModData() and zombie:getModData()[MARK_KEY] or nil
end

local function onZombieDead(zombie)
    if not Config.isEnabled() then return end

    local mark = readMark(zombie)
    if mark == "note" then
        giveNote(zombie)
        return
    end
    if mark ~= nil then return end
    if not isMilitary(zombie) then
        reportUnknownMilitaryOutfit(zombie)
        return
    end
    zombie:getModData()[MARK_KEY] = "seen"
    -- Un cadavre en feu disparaît avec son inventaire (IsoDeadBody.Burn) : le carnet serait perdu.
    if zombie:isOnFire() then return end

    local state = Store.load()
    local now = Clock.now()
    local rules = Config.noteRules()
    if not NotePolicy.isEligible(state, now, rules) then return end

    local shouldSpawn, nextState = NotePolicy.onMilitaryKill(state, now, rules, ZombRand(ROLL_RANGE))
    Store.save(nextState)
    if shouldSpawn then
        zombie:getModData()[MARK_KEY] = "note"
        giveNote(zombie)
        Const.log("carnet Artemis place sur un zombie en tenue " .. tostring(zombie:getOutfitName()))
    elseif Config.isDebugAllowed() then
        Const.log("debug : soldat compte : " .. tostring(nextState.flags.militaryKills)
            .. " sur " .. tostring(rules.guaranteeKills) .. " (tenue " .. tostring(zombie:getOutfitName()) .. ")")
    end
end

Events.OnZombieDead.Add(onZombieDead)
