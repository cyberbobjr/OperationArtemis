-- Opération Artemis : contenu bonus pour Computer Mod (ComputerModkum 3725497089, ComputerModLaptop
-- 3798992436, variante 42 ; lus seulement, rien n'en est copié). Décisions de la phase 6 :
-- - un CD gravé dans le classeur de la clinique (mails internes, notes de l'infirmière), lisible dans
--   n'importe quel ordinateur du mod ;
-- - le portable de V dans les archives de la base secrète (son journal), sur batterie.
-- Contenu bonus, jamais nécessaire pour avancer. Le mod n'a pas d'API publique : on remplit avant la
-- première utilisation les champs qu'il lit, au format observé :
-- - CD : ModData ComputerModDiscLabel et ComputerModDiscContents = { { type = "note", key, label, text } }
--   (server/ComputerMod_CD_Server.lua:169-180, 79-104) ; ouvrir la note la copie sur le bureau ;
-- - portable : même initialisation que ses apparitions (ComputerModLaptop_Spawns.lua:23-31), pièces à
--   100 % (ComputerModComponents.ensure, 3e argument), puis ComputerModDesktopNotes = { { key, name,
--   text } }, gardées au premier démarrage (client/ComputerMod_UI_State.lua:2746).
-- Textes écrits au moment de la pose, donc dans la langue du serveur et non dans celle de chaque
-- joueur ; en multijoueur, ils supposent les traductions du mod rechargées
-- (Artemis_ServerTranslations), sinon les clés brutes seraient enregistrées.
-- Serveur ou solo.

local Const = require "Artemis/Artemis_Const"

local ComputerMod = {}

local DISC_ITEM = "ComputerMod.BlankCD"
local LAPTOP_ITEM = "ComputerModLaptop.Laptop4861993"
local LAPTOP_TYPE_ID = "laptop486"
local LAPTOP_CHARGE = 80

-- Marque posée dans la ModData du CD ou du portable d'Artemis (un CD vierge du butin peut être dans le
-- même meuble).
local MARK = "batman_ArtemisComputer"

-- Le meuble contient-il déjà un contenu d'Artemis ?
function ComputerMod.isIn(container)
    local items = container:getItems()
    for index = 0, items:size() - 1 do
        if items:get(index):getModData()[MARK] then
            return true
        end
    end
    return false
end

local function hasItem(fullType)
    return getScriptManager():FindItem(fullType) ~= nil
end

local function noteEntries(notes, prefix)
    local entries = {}
    for _, note in ipairs(notes) do
        entries[#entries + 1] = { key = prefix .. note.key, label = getText(note.labelKey),
            text = getText(note.textKey) }
    end
    return entries
end

-- CD gravé, ou nil si Computer Mod n'est pas actif.
local function createDisc(def)
    if not hasItem(DISC_ITEM) then return nil end
    local item = instanceItem(DISC_ITEM)
    if item == nil then return nil end
    local data = item:getModData()
    data[MARK] = "disc"
    data.ComputerModDiscLabel = getText(def.labelKey)
    -- Comme un disque gravé par le mod (nom = étiquette), sinon il s'afficherait « Blank CD ».
    item:setName(data.ComputerModDiscLabel)
    item:setCustomName(true)
    local contents = {}
    for _, entry in ipairs(noteEntries(def.notes, "artemis_")) do
        contents[#contents + 1] = { type = "note", key = entry.key, label = entry.label, text = entry.text }
    end
    data.ComputerModDiscContents = contents
    return item
end

-- Portable de V, ou nil si le mod du portable n'est pas actif (ou si son API a changé).
local function createLaptop(def)
    local Types, Components, Laptop = ComputerModComputerTypes, ComputerModComponents, ComputerModLaptop
    if not hasItem(LAPTOP_ITEM) or type(Types) ~= "table" or type(Components) ~= "table" or type(Laptop) ~= "table"
        or type(Types.ensureIdentity) ~= "function" or type(Components.ensure) ~= "function"
        or type(Laptop.initializeData) ~= "function" or type(Types.types) ~= "table" then
        return nil
    end
    local item = instanceItem(LAPTOP_ITEM)
    if item == nil then return nil end
    local data = item:getModData()
    data[MARK] = "laptop"
    data.ComputerModComputerType = LAPTOP_TYPE_ID
    Types.ensureIdentity(item, data, Types.types[LAPTOP_TYPE_ID])
    Components.ensure(data, "artemis:" .. tostring(item:getID()), true, Components.getWorldAgeHours())
    data.ComputerModLaptopCharge = LAPTOP_CHARGE
    Laptop.initializeData(data)
    local notes = {}
    for _, entry in ipairs(noteEntries(def.notes, "artemis_")) do
        notes[#notes + 1] = { key = entry.key, name = entry.label, text = entry.text }
    end
    data.ComputerModDesktopNotes = notes
    data.ComputerModPasswordEnabled = false
    return item
end

-- Objet du contenu décrit (def.kind = "disc" ou "laptop"), ou nil si le mod concerné n'est pas actif.
function ComputerMod.create(def)
    local item = def.kind == "laptop" and createLaptop(def) or (def.kind == "disc" and createDisc(def) or nil)
    if item == nil then
        Const.log("Computer Mod missing (or API changed): bonus content " .. tostring(def.kind) .. " not placed")
    end
    return item
end

return ComputerMod
