-- Artemis_ServerTranslations : rechargement des traductions sur un serveur MP qui les a lues
-- avant de charger les mods (getText y renvoie les clés brutes).

local T = {}

function T.setup()
    isClient = function() return false end
    isServer = function() return true end
    LOADED = false
    RELOADS = 0
    LOGS = {}
    -- getTextOrNull (Translator.java:416) : nil pour une clé inconnue.
    getTextOrNull = function(key)
        if LOADED and key == "IGUI_Artemis_Radio_Numbers" then
            return "Seven. One. Four. Nine..."
        end
        return nil
    end
    Translator = { loadFiles = function()
        RELOADS = RELOADS + 1
        LOADED = true
    end }
    local Const = require "Artemis/Artemis_Const"
    Const.log = function(message) LOGS[#LOGS + 1] = message end
end

function T.missing_mod_translations_are_reloaded_at_load()
    local ServerTranslations = loadMod("server/Artemis/Artemis_ServerTranslations.lua")
    assertEq(RELOADS, 1, "un rechargement au chargement du fichier")
    assertEq(LOGS[1], "mod translations reloaded on the server", "journal en anglais")
    assertEq(ServerTranslations.ensure(), false, "déjà présentes : rien à refaire")
    assertEq(RELOADS, 1, "pas de second rechargement")
end

function T.present_translations_are_not_reloaded()
    LOADED = true
    loadMod("server/Artemis/Artemis_ServerTranslations.lua")
    assertEq(RELOADS, 0, "solo ou traductions déjà lues : aucun rechargement")
end

function T.reload_without_effect_is_reported()
    Translator.loadFiles = function() RELOADS = RELOADS + 1 end
    loadMod("server/Artemis/Artemis_ServerTranslations.lua")
    assertEq(RELOADS, 1, "rechargement tenté")
    assertEq(LOGS[1], "mod translations still missing on the server after reload", "échec signalé")
end

function T.client_does_nothing()
    isClient = function() return true end
    local result = loadMod("server/Artemis/Artemis_ServerTranslations.lua")
    assertEq(RELOADS, 0, "client : rien")
    assertEq(result, nil, "module absent côté client")
end

function T.probe_key_has_no_parameter_in_every_language()
    -- Une sonde avec %1 ferait journaliser un argument manquant (Translator.java:390-399).
    for _, lang in ipairs({ "EN", "FR", "DE", "ES", "PT", "PTBR", "RU", "TR", "CN", "JP", "KO" }) do
        local source = readModFile("shared/Translate/" .. lang .. "/IG_UI.json")
        assertTrue(source, "IG_UI.json absent : " .. lang)
        local value = source:match('"IGUI_Artemis_Radio_Numbers"%s*:%s*"([^"]*)"')
        assertTrue(value, "clé sonde absente : " .. lang)
        assertTrue(not value:find("%", 1, true), "clé sonde paramétrée : " .. lang)
    end
end

return T
