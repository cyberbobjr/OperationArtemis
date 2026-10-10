-- Belt Walkie-Talkie (batman_BeltRadio) facultatif. Activé : la copie de secours
-- Artemis/BeltRadioFallback ne fait rien et Artemis s'inscrit auprès du mod commun. Absent : la
-- copie de secours fait le travail. Artemis et Military Drop sans le mod commun : leurs deux copies
-- se remplacent (un seul récepteur). Émission refusée à la ceinture par le prédicat commun.
-- Version trop ancienne : un WARN, une fois.

local T = {}

local function list(items)
    return { size = function() return #items end, get = function(_, i) return items[i + 1] end }
end

-- Ordre du balayage du jeu : shared, puis client.
local FILES = {
    "shared/Artemis/BeltRadioFallback/BatmanRadio_Compat.lua",
    "shared/Artemis/BeltRadioFallback/BatmanRadio_Support.lua",
    "client/Artemis/BeltRadioFallback/BatmanRadio_BeltBattery.lua",
    "client/Artemis/BeltRadioFallback/BatmanRadio_Core.lua",
}
local EVENTS = { "OnTick", "OnGameStart", "OnDeviceText", "OnFillInventoryObjectContextMenu",
    "OnDisconnect", "OnMainMenuEnter" }

function T.setup()
    Events = setmetatable({}, { __index = function(events, name)
        local e = { handlers = {} }
        e.Add = function(fn) e.handlers[#e.handlers + 1] = fn end
        e.Remove = function(fn)
            for i = #e.handlers, 1, -1 do
                if e.handlers[i] == fn then table.remove(e.handlers, i) return end
            end
        end
        rawset(events, name, e)
        return e
    end })
    SandboxVars = {}
    isClient = function() return false end
    isServer = function() return false end
    instanceof = function(object, class) return type(object) == "table" and object.kind == class end
    getText = function(key) return key end
    ACTIVE = {}
    getActivatedMods = function() return list(ACTIVE) end
    ISCollapsableWindow = { update = function() end }
    ORIGINAL_UPDATE = function() end
    ISRadioWindow = { update = ORIGINAL_UPDATE }
    ISRadioAndTvMenu = { openRadioPanel = function() end }
    getNumActivePlayers = function() return 0 end
    getZomboidRadio = function() return { getScriptManager = function() end } end
    PRINTED = {}
    print = function(...) PRINTED[#PRINTED + 1] = table.concat({ ... }, " ") end
    preloadModule("ISUI/ISRadioAndTvMenu", true)
    preloadModule("RadioCom/ISRadioWindow", true)
end

local function count(name)
    return #Events[name].handlers
end

local function counts()
    local result = {}
    for _, name in ipairs(EVENTS) do result[name] = count(name) end
    return result
end

--- Mod commun simulé (globale et modules BatmanRadio/...), version donnée.
local function stubBeltRadio(version)
    local registered = {}
    BatmanRadioSupport = { VERSION = version, register = function(id, provider) registered[id] = provider end }
    preloadModule("BatmanRadio/BatmanRadio_Core", BatmanRadioSupport)
    preloadModule("BatmanRadio/BatmanRadio_Support", BatmanRadioSupport)
    preloadModule("BatmanRadio/BatmanRadio_Compat", { say = function() end, microphoneAvailable = function() return true end })
    return registered
end

function T.belt_radio_active_leaves_the_fallback_inactive()
    ACTIVE = { "\\batman_SignalSmoke", "\\batman_BeltRadio" }
    for _, rel in ipairs(FILES) do
        assertEq(loadMod(rel), nil, rel .. " : rien renvoyé")
    end
    assertEq(BatmanRadioSupport, nil, "aucune globale du récepteur")
    assertEq(BatmanBeltRadioBattery, nil, "aucune globale de pile")
    for name, n in pairs(counts()) do assertEq(n, 0, "aucun gestionnaire " .. name) end
    assertEq(ISRadioWindow.update, ORIGINAL_UPDATE, "fenêtre radio non enveloppée")
    local registered = stubBeltRadio(1)
    require "Artemis_BeltRadio"
    assertTrue(registered.OperationArtemis, "Artemis inscrit auprès du mod commun")
    assertEq(#PRINTED, 0, "version suffisante : aucun avertissement")
end

function T.belt_radio_absent_runs_the_fallback()
    ACTIVE = { "batman_SignalSmoke" }
    require "Artemis_BeltRadio"
    assertTrue(BatmanRadioSupport and BatmanRadioSupport.providers.OperationArtemis, "inscrit dans la copie de secours")
    assertEq(BatmanArtemisBeltRadio, BatmanRadioSupport, "globale historique conservée")
    assertTrue(BatmanBeltRadioBattery and BatmanBeltRadioBattery.onTick, "pile à la ceinture")
    assertEq(count("OnTick"), 1, "pile seulement avant la partie")
    assertEq(count("OnGameStart") + count("OnDeviceText") + count("OnFillInventoryObjectContextMenu"), 3,
        "récepteur inscrit")
    assertEq(BatmanRadioSupport.originalWindowUpdate, ORIGINAL_UPDATE, "fenêtre enveloppée sur l'original")
    assertEq(#PRINTED, 0, "mod commun absent : aucun avertissement")
end

function T.two_fallback_copies_make_one_receiver()
    ACTIVE = {}
    require "Artemis_BeltRadio"
    local before, wrapper = counts(), ISRadioWindow.update
    local support = BatmanRadioSupport
    -- Seconde copie : celle de Military Drop si le dépôt est là, sinon celle d'Artemis rechargée.
    local base = "Contents/mods/batman_MilitaryDrop/42.21/media/lua/"
    local second = "Military Drop"
    for _, rel in ipairs(FILES) do
        local mdRel = rel:gsub("Artemis/", "MilitaryDrop/")
        local source = readSiblingFile("MilitaryDrop", base .. mdRel)
        if not source then
            second = "Artemis (rechargée)"
            source = readModFile(rel)
            mdRel = rel
        end
        local name = mdRel:gsub("^%a+/", ""):gsub("%.lua$", "")
        local result = assert(loadstring(source, "@" .. mdRel))()
        preloadModule(name, result or false)
    end
    local after = counts()
    for _, name in ipairs(EVENTS) do
        assertEq(after[name], before[name], second .. " : gestionnaires " .. name .. " remplacés, pas ajoutés")
    end
    assertEq(BatmanRadioSupport, support, "même table BatmanRadioSupport")
    assertEq(ISRadioWindow.update, wrapper, "fenêtre enveloppée une seule fois")
    assertEq(BatmanRadioSupport.originalWindowUpdate, ORIGINAL_UPDATE, "toujours sur l'original vanilla")
    assertTrue(BatmanRadioSupport.providers.OperationArtemis, "fournisseur Artemis conservé")
    for _, fn in ipairs(Events.OnGameStart.handlers) do fn() end
    assertEq(count("OnTick"), 2, "en partie : une pile et un récepteur")
end

--- Talkie militaire simulé (WalkieTalkie5) allumé sur la fréquence Artemis.
local function militaryRadio()
    local data = {}
    for name, value in pairs({ getIsHighTier = true, getIsTwoWay = true, getIsPortable = true,
        getIsTelevision = false, isNoTransmit = false, getIsTurnedOn = true, getIsBatteryPowered = false,
        getMicIsMuted = false, getChannel = 108000 }) do
        data[name] = function() return value end
    end
    return { kind = "Radio", getDeviceData = function() return data end }
end

function T.belt_radio_never_transmits()
    ACTIVE = {}
    local MilRadio = require "Artemis/Artemis_MilRadio"
    local radio = militaryRadio()
    local where = "belt"
    local player = {
        getPrimaryHandItem = function() return where == "hand" and radio or nil end,
        getSecondaryHandItem = function() end,
        getClothingItem_Back = function() return where == "back" and radio or nil end,
        isAttachedItem = function() return where == "belt" end,
    }
    assertEq(MilRadio.status(player, radio, 108000), "notCarried", "ceinture : même message qu'avant")
    local RadioLib = require "Artemis/Artemis_RadioLib"
    local ok, reason = RadioLib.canTransmitWith(player, radio)
    assertEq(ok, false, "prédicat commun : refus")
    assertEq(reason, "belt", "raison belt")
    where = "bag"
    assertEq(MilRadio.status(player, radio, 108000), "notCarried", "rangée : refus")
    where = "hand"
    assertEq(MilRadio.status(player, radio, 108000), nil, "en main : appel possible")
    where = "back"
    assertEq(MilRadio.status(player, radio, 108000), nil, "sur le dos : appel possible")
end

function T.too_old_belt_radio_warns_once()
    ACTIVE = { "batman_BeltRadio" }
    stubBeltRadio(nil)
    local RadioLib = require "Artemis/Artemis_RadioLib"
    RadioLib.support()
    RadioLib.receiver()
    RadioLib.support()
    assertEq(#PRINTED, 1, "une seule ligne")
    assertTrue(PRINTED[1]:find("WARN", 1, true) and PRINTED[1]:find("batman_BeltRadio", 1, true), PRINTED[1])
    local player = { getPrimaryHandItem = function() end, getSecondaryHandItem = function() end,
        getClothingItem_Back = function() end, isAttachedItem = function() return true end }
    local ok, reason = RadioLib.canTransmitWith(player, { kind = "Radio" })
    assertEq(ok, false, "sans canTransmitWith : refus")
    assertEq(reason, "belt", "règle de position seule")
end

return T
