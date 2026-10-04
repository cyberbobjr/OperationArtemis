-- Opération Artemis : caisse de ravitaillement de V à l'acte III (décision de la phase 6). Serveur ou
-- solo, à la minute de jeu. Annoncée par Progress.onSupplyCommit au premier engagement sur une route,
-- elle est posée dès que sa case est chargée (caisse militaire vanilla, soins, vivres, munitions),
-- puis suivie : vidée, sa fumée verte s'éteint (Artemis_BeaconDirector).
if isClient() then return end

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local State = require "Artemis/Artemis_State"
local Story = require "Artemis/Artemis_Story"
local Store = require "Artemis/Artemis_Store"
local Placement = require "Artemis/Artemis_Placement"

local function dropOf(data)
    local entries = type(data.flags) == "table" and data.flags.supply
    return type(entries) == "table" and entries.drop or nil
end

local function setDrop(changes)
    local state = Store.load()
    local drop = State.copy(State.flagValue(state, "supply", "drop") or {})
    for key, value in pairs(changes) do
        drop[key] = value
    end
    Store.save(State.withFlagValue(state, "supply", "drop", drop))
end

-- Marque posée dans la ModData de l'objet de la caisse (une caisse vanilla du même sprite peut exister).
local MARK = "batman_ArtemisSupply"

local function findCrate(square)
    local objects = square:getObjects()
    for index = 0, objects:size() - 1 do
        local object = objects:get(index)
        if object:getContainer() and object:getModData()[MARK] then
            return object:getContainer()
        end
    end
    return nil
end

local function place(point)
    local square = getCell():getGridSquare(point.x, point.y, point.z)
    if square == nil then return false end
    -- Registre écrit avant la pose : une erreur ne doit pas doubler la caisse.
    setDrop({ placed = true })
    local container, object = Placement.createContainer(square, Story.SUPPLY.sprite)
    if object then
        object:getModData()[MARK] = true
    end
    if container == nil then
        Const.log("ERREUR : caisse de ravitaillement non posee en " .. point.x .. "," .. point.y)
        return true
    end
    for _, fullType in ipairs(Story.SUPPLY.items) do
        if getScriptManager():FindItem(fullType) ~= nil then
            Placement.addToContainer(container, instanceItem(fullType))
        end
    end
    Const.log("ravitaillement : caisse posee en " .. point.x .. "," .. point.y)
    return true
end

local function onEveryOneMinute()
    local data = ModData.get(Const.MODDATA_KEY)
    if type(data) ~= "table" or data.act ~= Const.ACT.EXFILTRATION or not Config.isEnabled() then return end
    local drop = dropOf(data)
    if type(drop) ~= "table" or drop.collected == true then return end
    local point = Story.SUPPLY.points[drop.point]
    if point == nil then return end
    if drop.placed ~= true then
        place(point)
        return
    end
    local square = getCell():getGridSquare(point.x, point.y, point.z)
    if square == nil then return end
    local crate = findCrate(square)
    if crate == nil or crate:getItems():isEmpty() then
        setDrop({ collected = true })
        Const.log("ravitaillement : caisse videe")
    end
end

Events.EveryOneMinute.Add(onEveryOneMinute)
