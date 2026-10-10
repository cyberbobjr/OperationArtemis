-- Récepteur radio commun (copie de BatmanRadio_Core) et chaîne Artemis : ligne affichée pour
-- un talkie accroché à la ceinture en solo, bulle MP d'une radio non tenue.

local T = {}

local FREQ = 108000

local function list(items)
    return { size = function() return #items end, get = function(_, i) return items[i + 1] end,
        getItemByIndex = function(_, i) return items[i + 1] end }
end

local function makeRadio(frequency)
    local data = { frequency = frequency or FREQ }
    data.getIsPortable = function() return true end
    data.getIsTurnedOn = function() return true end
    data.getIsTelevision = function() return false end
    data.getChannel = function() return data.frequency end
    data.getDeviceVolume = function() return 0.5 end
    data.getDeviceVolumeRange = function() return 12 end
    data.isPlayingMedia = function() return false end
    data.isNoTransmit = function() return false end
    data.getIsBatteryPowered = function() return false end
    local radio = { kind = "Radio", said = {}, shown = {} }
    radio.getDeviceData = function() return data end
    radio.getContainer = function() return INVENTORY end
    -- Doublure fidèle des deux surcharges Java (volume > 0, sourd exclu). 8 arguments, joueur
    -- en premier (WaveSignalDevice.java:41-62) : bulle seulement si player:isEquipped(radio),
    -- jamais à la ceinture ; le reste au chat radio, absent en solo. 7 arguments, texte en
    -- premier (Radio.java:77-89) : SayRadio, bulle au-dessus du propriétaire (conteneur parent).
    -- Puis OnDeviceText (said) si codes ~= nil.
    radio.AddDeviceText = function(self, first, ...)
        local text, codes, shown, _
        if type(first) == "string" then
            text, _, _, _, _, codes = first, ...
            shown = self:getContainer() == INVENTORY
        else
            text, _, _, _, _, codes = ...
            shown = first:isEquipped(self)
        end
        if PLAYER.deaf then return end
        if shown then self.shown[#self.shown + 1] = text end
        if codes ~= nil then self.said[#self.said + 1] = { text = text, codes = codes } end
    end
    return radio
end

local function broadcast(lines)
    local bc = { count = 0 }
    bc.getCurrentLineNumber = function() return bc.count end
    bc.getLines = function()
        local wrapped = {}
        for i, entry in ipairs(lines) do
            wrapped[i] = { getText = function() return entry[1] end,
                getEffectsString = function() return entry[2] or "" end,
                getR = function() return 0.7 end, getG = function() return 0.85 end, getB = function() return 0.55 end }
        end
        return list(wrapped)
    end
    return bc
end

function T.setup()
    Events = setmetatable({}, { __index = function(events, name)
        local e = { handlers = {} }
        e.Add = function(fn) e.handlers[#e.handlers + 1] = fn end
        e.Remove = function(fn)
            for i = #e.handlers, 1, -1 do
                if e.handlers[i] == fn then table.remove(e.handlers, i) end
            end
        end
        rawset(events, name, e)
        return e
    end })
    triggerEvent = function(name, ...)
        for _, fn in ipairs(Events[name].handlers) do fn(...) end
    end
    CLIENT, ACTIVE = false, {}
    isClient = function() return CLIENT end
    isServer = function() return false end
    getActivatedMods = function() return list(ACTIVE) end
    instanceof = function(object, class) return type(object) == "table" and object.kind == class end
    getClimateManager = function() return { getWeatherInterference = function() return 0 end } end
    UIFont = { Medium = "Medium" }
    NOW = 1000
    getTimestampMs = function() return NOW end
    SandboxVars = {}
    INVENTORY = {}
    PLAYER = { attached = {}, bubbles = {} }
    PLAYER.getInventory = function() return INVENTORY end
    PLAYER.getAttachedItems = function() return list(PLAYER.attached) end
    PLAYER.getEquipedRadio = function() return PLAYER.hand end
    PLAYER.getPrimaryHandItem = function() return PLAYER.hand end
    PLAYER.getSecondaryHandItem = function() end
    PLAYER.getClothingItem_Back = function() end
    PLAYER.isEquipped = function(_, item) return item == PLAYER.hand end
    PLAYER.isDead = function() return false end
    PLAYER.isAttachedItem = function(_, item)
        for _, attached in ipairs(PLAYER.attached) do if attached == item then return true end end
        return false
    end
    -- IsoGameCharacter.addLineChatElement (12 arguments) : bulle ajoutée directement.
    PLAYER.addLineChatElement = function(_, text, r, _g, _b, _font, range, tag)
        PLAYER.bubbles[#PLAYER.bubbles + 1] = { text = text, r = r, range = range, tag = tag }
    end
    getSpecificPlayer = function() return PLAYER end
    getNumActivePlayers = function() return 1 end
    CHANNEL = { airing = nil }
    CHANNEL.GetFrequency = function() return FREQ end
    CHANNEL.IsTv = function() return false end
    CHANNEL.getAiringBroadcast = function() return CHANNEL.airing end
    CHANNEL.getLastAiredLine = function() return "" end
    MANAGER = { getChannelsList = function() return list({ CHANNEL }) end,
        getRadioChannel = function() return CHANNEL end }
    getZomboidRadio = function()
        return { getScriptManager = function() return MANAGER end, getDisableBroadcasting = function() return false end,
            PlayerListensChannel = function() end }
    end
    ISRadioWindow = { update = function() end }
    ISRadioAndTvMenu = { openRadioPanel = function() end }
    preloadModule("ISUI/ISRadioAndTvMenu", true)
    preloadModule("RadioCom/ISRadioWindow", true)
    preloadModule("BatmanRadio/BatmanRadio_BeltBattery", true) -- batterie : hors sujet ici
    SUPPORT = require "Artemis_BeltRadio"
end

function T.solo_belt_radio_shows_the_artemis_line_once()
    local radio = makeRadio()
    PLAYER.attached = { radio }
    SUPPORT.onGameStart()
    CHANNEL.airing = broadcast({ { "Relais Artemis", "ART1" } })
    SUPPORT.onTick()
    CHANNEL.airing.count = 1
    SUPPORT.onTick()
    SUPPORT.onTick()
    assertEq(#radio.shown, 1, "une bulle au-dessus du joueur (surcharge à 7 arguments)")
    assertEq(radio.said[1].codes, "ART1", "OnDeviceText conservé avec ses codes")
end

function T.solo_deaf_player_gets_nothing()
    local radio = makeRadio()
    PLAYER.attached, PLAYER.deaf = { radio }, true
    SUPPORT.onGameStart()
    CHANNEL.airing = broadcast({ { "Relais Artemis", "ART1" } })
    SUPPORT.onTick()
    CHANNEL.airing.count = 1
    SUPPORT.onTick()
    assertEq(#radio.shown + #radio.said, 0, "sourd : ni bulle ni OnDeviceText")
end

--- Client MP : ligne servie par le vanilla à chaque radio de l'inventaire principal
--- (surcharge à 8 arguments), puis OnDeviceText ; gestionnaire de chaînes nil.
local function mpLine(radios, text)
    CLIENT, MANAGER = true, nil
    for _, radio in ipairs(radios) do
        radio:AddDeviceText(PLAYER, text, 0.7, 0.85, 0.55, nil, "", -1)
        triggerEvent("OnDeviceText", nil, "", -1, -1, -1, text, radio)
    end
end

function T.mp_unheld_radio_on_the_sandbox_frequency_gets_one_bubble()
    local belt, pocket = makeRadio(), makeRadio()
    PLAYER.attached = { belt }
    mpLine({ belt, pocket }, "Relais Artemis")
    assertEq(#belt.shown + #pocket.shown, 0, "vanilla : chat radio seulement")
    assertEq(#PLAYER.bubbles, 1, "une bulle pour deux radios non tenues")
    assertEq(PLAYER.bubbles[1].tag, "radio", "bulle radio")
    assertEq(PLAYER.bubbles[1].r, 0.70, "couleur de la chaîne Artemis")
end

function T.mp_held_radio_and_bwt_add_nothing_other_channels_get_a_white_bubble()
    local hand = makeRadio()
    PLAYER.hand = hand
    mpLine({ hand }, "Relais Artemis")
    assertEq(#hand.shown, 1, "bulle vanilla de la radio en main")
    assertEq(#PLAYER.bubbles, 0, "pas de doublon")
    PLAYER.hand = nil
    mpLine({ makeRadio(98000) }, "Météo")
    assertEq(#PLAYER.bubbles, 1, "chaîne vanilla : bulle aussi (toutes les chaînes)")
    assertEq(PLAYER.bubbles[1].r, 1, "couleur par défaut")
    PLAYER.bubbles = {}
    ACTIVE = { "\\BetterWalkieTalkies" }
    mpLine({ makeRadio() }, "Relais Artemis")
    assertEq(#PLAYER.bubbles, 0, "Better Walkie Talkies actif : rien ajouté")
end

return T
