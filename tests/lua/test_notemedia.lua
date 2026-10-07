-- Carnet Artemis : clés et fréquence enregistrées à la création (souvent sur le serveur), texte
-- composé côté client dans la langue du lecteur, à l'ouverture par la fonction vanilla
-- ISReadABook:displayPrintMedia (fichier du jeu chargé tel quel).

local T = {}

T.skip = (not hasVanilla) and "jeu absent : ISReadABook vanilla introuvable" or nil

-- Traductions du lecteur. Translator convertit %1 en %1$s au chargement.
local LAYOUT = "<type:text, x:40, y:40>Listen to %1$s.^At night."
local TEXT = "If it goes bad, listen to %1$s.\\nAt night."

-- getText / getTextOrNull fidèles à Translator.java (42.21) : clé inconnue renvoyée telle quelle
-- (nil pour getTextOrNull) ; texte formaté avec les arguments ; argument manquant journalisé et
-- texte renvoyé sans substitution (reportMissingArgumentsFromPastAbuse, :390-399).
local function format(key, text, ...)
    local args = { ... }
    local missing = false
    local out = text:gsub("%%(%d+)%$s", function(index)
        local value = args[tonumber(index)]
        if value == nil then
            missing = true
            return nil
        end
        return tostring(value)
    end)
    if missing then
        MISSING_ARGS[#MISSING_ARGS + 1] = key
        return text
    end
    return out
end

local function newItem(printMedia)
    local item = { modData = { printMedia = printMedia } }
    function item:hasModData() return self.modData ~= nil end
    function item:getModData() return self.modData end
    return item
end

local function newAction(item)
    return setmetatable({ item = item, playerNum = 0 }, { __index = ISReadABook })
end

function T.setup()
    MISSING_ARGS = {}
    WINDOWS = {}
    TRANSLATIONS = {
        Print_Media_ArtemisNote_title = "Liaison Notebook",
        Print_Media_ArtemisNote_info = LAYOUT,
        Print_Text_ArtemisNote_info = TEXT,
        Print_Media_Flier_title = "Flier",
        Print_Media_Flier_info = "<type:texture, texture:media/ui/flier.png>",
        Print_Text_Flier_info = "Sale",
    }
    getText = function(key, ...)
        local text = TRANSLATIONS[key]
        if text == nil then return key end
        return format(key, text, ...)
    end
    getTextOrNull = function(key, ...)
        local text = TRANSLATIONS[key]
        if text == nil then return nil end
        return format(key, text, ...)
    end
    SandboxVars = { OperationArtemis = { RadioFrequency = 103.4 } }
    -- Fenêtre PZAPI.UI.PrintMedia : on garde ce que displayPrintMedia lui donne.
    PZAPI = { UI = { PrintMedia = function(_args)
        local win = { children = { bar = { children = { name = {} } } } }
        win.javaObj = { setAlwaysOnTop = function() end }
        function win:instantiate()
            if WINDOW_ERROR then error(WINDOW_ERROR) end
            WINDOWS[#WINDOWS + 1] = self
        end
        function win:centerOnScreen() end
        return win
    end } }
    getCore = function()
        return { getOptionAutoRevealPrintMediaMapLocations = function() return false end }
    end
    getJoypadData = function() return nil end
    getTexture = function(name) return { texture = name } end
    -- string.split / string.trim du jeu (séparateur littéral ici, suffisant pour ces données).
    string.split = function(text, sep)
        local parts, start = {}, 1
        while true do
            local i = text:find(sep, start, true)
            if not i then
                parts[#parts + 1] = text:sub(start)
                return parts
            end
            parts[#parts + 1] = text:sub(start, i - 1)
            start = i + #sep
        end
    end
    string.trim = function(text) return (text:gsub("^%s+", ""):gsub("%s+$", "")) end
    ISBaseTimedAction = {}
    function ISBaseTimedAction:derive(kind)
        local o = { Type = kind }
        setmetatable(o, self)
        self.__index = self
        return o
    end
    preloadModule("TimedActions/ISBaseTimedAction", true)
    require "TimedActions/ISReadABook"
end

local function createNote()
    loadMod("shared/Artemis/Artemis_Items.lua")
    local item = newItem(nil)
    item.modData = {}
    OperationArtemisItems.onCreateNote(item)
    return item
end

function T.vanilla_reader_loses_the_frequency_without_the_mod_reader()
    -- Défaut corrigé : clé enregistrée, retraduite sans argument par la fonction vanilla.
    local item = createNote()
    newAction(item):displayPrintMedia()
    assertEq(WINDOWS[1].data, LAYOUT, "vanilla : %1$s affiché à la place de la fréquence")
end

function T.new_note_stores_keys_and_frequency()
    local item = createNote()
    local printMedia = item.modData.printMedia
    assertEq(printMedia.id, "ArtemisNote", "id")
    assertEq(printMedia.title, "Print_Media_ArtemisNote_title", "titre : clé")
    assertEq(printMedia.info, "Print_Media_ArtemisNote_info", "mise en page : clé")
    assertEq(printMedia.text, "Print_Text_ArtemisNote_info", "texte : clé")
    assertEq(printMedia.frequency, "103.4", "fréquence en donnée")
end

function T.note_is_shown_in_reader_language_with_frequency()
    local item = createNote()
    loadMod("client/Artemis_NoteReader.lua")
    newAction(item):displayPrintMedia()
    local win = WINDOWS[1]
    assertEq(win.data, "<type:text, x:40, y:40>Listen to 103.4.^At night.", "mise en page avec fréquence")
    assertEq(win.textData, "If it goes bad, listen to 103.4.\nAt night.", "texte avec fréquence")
    assertEq(win.textTitle, "Liaison Notebook", "titre traduit")
    assertEq(#MISSING_ARGS, 0, "aucun argument manquant")
    local printMedia = item.modData.printMedia
    assertEq(printMedia.info, "Print_Media_ArtemisNote_info", "clés remises après l'ouverture")
    assertEq(printMedia.text, "Print_Text_ArtemisNote_info", "clés remises après l'ouverture")
end

function T.stored_frequency_wins_over_current_option()
    local item = createNote()
    SandboxVars.OperationArtemis.RadioFrequency = 99.0
    loadMod("client/Artemis_NoteReader.lua")
    newAction(item):displayPrintMedia()
    assertEq(WINDOWS[1].textData, "If it goes bad, listen to 103.4.\nAt night.", "fréquence du carnet")
end

function T.legacy_translated_note_is_shown_in_reader_language()
    -- Carnet 0.3.0 : texte traduit à la création (ici en français), sans fréquence enregistrée.
    local item = newItem({ id = "ArtemisNote", title = "Print_Media_ArtemisNote_title",
        info = "<type:text>Écoute le 108.0.", text = "Si ça tourne mal, écoute le 108.0." })
    loadMod("client/Artemis_NoteReader.lua")
    newAction(item):displayPrintMedia()
    assertEq(WINDOWS[1].textData, "If it goes bad, listen to 103.4.\nAt night.",
        "langue du lecteur, fréquence des options")
    assertEq(item.modData.printMedia.info, "Print_Media_ArtemisNote_info", "carnet converti en clés")
end

function T.legacy_raw_key_note_keeps_the_frequency()
    -- Carnet 0.3.0 créé sur un serveur MP sans les traductions du mod : clés brutes.
    local item = newItem({ id = "ArtemisNote", title = "Print_Media_ArtemisNote_title",
        info = "Print_Media_ArtemisNote_info", text = "Print_Text_ArtemisNote_info" })
    loadMod("client/Artemis_NoteReader.lua")
    newAction(item):displayPrintMedia()
    assertEq(WINDOWS[1].data, "<type:text, x:40, y:40>Listen to 103.4.^At night.", "fréquence présente")
    assertEq(#MISSING_ARGS, 0, "aucun argument manquant")
end

function T.other_documents_are_untouched()
    local printMedia = { id = "Flier", title = "Print_Media_Flier_title",
        info = "Print_Media_Flier_info", text = "Print_Text_Flier_info" }
    local item = newItem(printMedia)
    loadMod("client/Artemis_NoteReader.lua")
    local action = newAction(item)
    assertEq(action:startLoadingPrintMediaTextures().texture, "media/ui/flier.png", "préchargement vanilla")
    action:displayPrintMedia()
    assertEq(WINDOWS[1].data, "<type:texture, texture:media/ui/flier.png>", "document vanilla")
    assertEq(printMedia.info, "Print_Media_Flier_info", "données intactes")
end

function T.note_textures_are_not_preloaded_from_the_bare_key()
    local item = createNote()
    loadMod("client/Artemis_NoteReader.lua")
    newAction(item):startLoadingPrintMediaTextures()
    assertEq(#MISSING_ARGS, 0, "pas de traduction sans fréquence (argument manquant journalisé)")
end

function T.window_error_is_raised_and_keys_are_restored()
    local item = createNote()
    loadMod("client/Artemis_NoteReader.lua")
    WINDOW_ERROR = "window failed"
    local ok, err = pcall(function() newAction(item):displayPrintMedia() end)
    assertEq(ok, false, "erreur relancée")
    assertTrue(tostring(err):find("window failed", 1, true), "erreur d'origine : " .. tostring(err))
    assertEq(item.modData.printMedia.info, "Print_Media_ArtemisNote_info", "clé remise malgré l'erreur")
end

function T.reloading_the_reader_does_not_stack_wrappers()
    local item = createNote()
    loadMod("client/Artemis_NoteReader.lua")
    loadMod("client/Artemis_NoteReader.lua")
    newAction(item):displayPrintMedia()
    assertEq(#WINDOWS, 1, "une seule fenêtre")
    assertEq(WINDOWS[1].textData, "If it goes bad, listen to 103.4.\nAt night.", "texte composé une fois")
end

return T
