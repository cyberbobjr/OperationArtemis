-- Belt Walkie-Talkie (batman_BeltRadio) est un prérequis : Artemis charge ses modules
-- BatmanRadio/... et s'inscrit auprès de lui. Version trop ancienne : un WARN, une fois.

local T = {}

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
    getActivatedMods = function() return { size = function() return 0 end } end
    getZomboidRadio = function() return { getScriptManager = function() end } end
    PRINTED = {}
    print = function(...) PRINTED[#PRINTED + 1] = table.concat({ ... }, " ") end
end

--- Belt Walkie-Talkie simulé (globale et modules BatmanRadio/...), version donnée.
local function stubBeltRadio(version)
    local registered = {}
    BatmanRadioSupport = { VERSION = version, register = function(id, provider) registered[id] = provider end }
    preloadModule("BatmanRadio/BatmanRadio_Core", BatmanRadioSupport)
    preloadModule("BatmanRadio/BatmanRadio_Support", BatmanRadioSupport)
    preloadModule("BatmanRadio/BatmanRadio_Compat", { say = function() end, microphoneAvailable = function() return true end })
    return registered
end

function T.artemis_registers_with_belt_radio()
    local registered = stubBeltRadio(1)
    require "Artemis_BeltRadio"
    assertTrue(registered.OperationArtemis, "Artemis inscrit auprès de Belt Walkie-Talkie")
    assertEq(BatmanArtemisBeltRadio, BatmanRadioSupport, "globale historique conservée")
    assertEq(#PRINTED, 0, "version suffisante : aucun avertissement")
end

function T.too_old_belt_radio_warns_once()
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
