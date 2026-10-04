-- Opération Artemis : entrées client (touche du journal, menu contextuel, commandes de debug).

require "PZAPI/ModOptions"

local Const = require "Artemis/Artemis_Const"
local Config = require "Artemis/Artemis_Config"
local ClientState = require "Artemis/Artemis_ClientState"
local JournalUI = require "Artemis/Artemis_JournalUI"
local Story = require "Artemis/Artemis_Story"

local DEFAULT_JOURNAL_KEY = Keyboard.KEY_K

local modOptions = PZAPI.ModOptions:create(Const.MOD_ID, getText("IGUI_Artemis_Title"))
local journalKeyOption = modOptions:addKeyBind(
    "journalKey",
    getText("IGUI_Artemis_JournalKey"),
    DEFAULT_JOURNAL_KEY,
    getText("IGUI_Artemis_JournalKey_tooltip")
)

-- Le journal reste caché tant que l'opération n'a pas commencé, sauf en debug.
local function canOpenJournal()
    if not Config.isEnabled() then
        return false
    end
    return ClientState.get().act > Const.ACT.DORMANT or Config.isDebugAllowed()
end

local function onKeyPressed(key)
    if key ~= journalKeyOption:getValue() then return end
    local player = getPlayer()
    if not player or player:isDead() then return end
    if canOpenJournal() then
        JournalUI.toggle()
    end
end

local function sendDebugCommand(player, command)
    sendClientCommand(player, Const.NET_MODULE, command, {})
end

-- Téléportation à l'entrée du lieu du chapitre en cours (même méthode que le menu de debug vanilla,
-- DebugContextMenu.lua:1185 ; les coordonnées sont arrondies à la case, IsoGameCharacter.java:15065).
local function teleportToChapter(player, pointName)
    local chapter = Story.get(ClientState.get().chapter)
    local point = chapter and chapter[pointName]
    if point then
        player:teleportTo(point.x, point.y, point.z)
    end
end

local LANDING_TELEPORT_OFFSET = 6

local function teleportToLanding(player)
    local landing = Story.EXTRACTION.landing
    player:teleportTo(landing.x + LANDING_TELEPORT_OFFSET, landing.y, landing.z)
end

-- Acte III, autres sorties (phase 5) : cases à pied près de chaque lieu (jamais sur l'eau).
local EXIT_TELEPORTS = {
    { key = "ContextMenu_Artemis_DebugGoToCheckpoint", x = 12608, y = 1170, z = 0 },
    { key = "ContextMenu_Artemis_DebugGoToKinsella", x = 1497, y = 5410, z = 0 },
    { key = "ContextMenu_Artemis_DebugGoToFerry", x = 1637, y = 5580, z = 0 },
    { key = "ContextMenu_Artemis_DebugGoToBoatWest", x = 6043, y = 5222, z = 0 },
    { key = "ContextMenu_Artemis_DebugGoToBoatEast", x = 12823, y = 1128, z = 0 },
}

local function teleportTo(player, point)
    player:teleportTo(point.x, point.y, point.z)
end

-- La téléportation se fait côté client, sans passer par le contrôle du serveur : en multijoueur,
-- elle est réservée aux rôles autorisés au menu de debug (même droit que Artemis_Server).
local function canTeleport(player)
    return not isClient() or checkPermissions(player, Capability.UseDebugContextMenu)
end

local function addDebugMenu(context, player)
    local root = context:addOption(getText("ContextMenu_Artemis_Debug"))
    local submenu = ISContextMenu:getNew(context)
    context:addSubMenu(root, submenu)
    local entries = {
        { "ContextMenu_Artemis_DebugStart", Const.COMMAND.DEBUG_START },
        { "ContextMenu_Artemis_DebugAdvance", Const.COMMAND.DEBUG_ADVANCE },
        { "ContextMenu_Artemis_DebugReset", Const.COMMAND.DEBUG_RESET },
        { "ContextMenu_Artemis_DebugGiveNote", Const.COMMAND.DEBUG_GIVE_NOTE },
        { "ContextMenu_Artemis_DebugCompleteChapter", Const.COMMAND.DEBUG_COMPLETE_CHAPTER },
    }
    for _, entry in ipairs(entries) do
        submenu:addOption(getText(entry[1]), player, sendDebugCommand, entry[2])
    end
    if ClientState.get().chapter and canTeleport(player) then
        submenu:addOption(getText("ContextMenu_Artemis_DebugGoToChapter"), player, teleportToChapter, "entrance")
        -- Case voisine du dépôt principal (le meuble lui-même occupe sa case).
        submenu:addOption(getText("ContextMenu_Artemis_DebugGoToSite"), player, teleportToChapter, "siteAccess")
    end
    -- Acte III : bord de la zone d'atterrissage (route de l'hélicoptère), à quelques cases du centre.
    if ClientState.get().act == Const.ACT.EXFILTRATION and canTeleport(player) then
        submenu:addOption(getText("ContextMenu_Artemis_DebugGoToLanding"), player, teleportToLanding)
        for _, point in ipairs(EXIT_TELEPORTS) do
            submenu:addOption(getText(point.key), player, teleportTo, point)
        end
    end
end

local function onFillWorldObjectContextMenu(playerNum, context, _worldObjects, test)
    if not canOpenJournal() then return end
    -- Sondage des manettes : signaler qu'il y a des options (ISWorldObjectContextMenu.lua:122-128).
    if test then return ISWorldObjectContextMenu.setTest() end
    context:addOption(getText("ContextMenu_Artemis_Journal"), nil, JournalUI.toggle)
    if Config.isDebugAllowed() then
        addDebugMenu(context, getSpecificPlayer(playerNum))
    end
end

Events.OnKeyPressed.Add(onKeyPressed)
Events.OnFillWorldObjectContextMenu.Add(onFillWorldObjectContextMenu)
