-- Opération Artemis : lecture des options sandbox.
-- Une option absente (sauvegarde créée avant le mod, option ajoutée plus tard) prend sa valeur par défaut.

local Config = {}

local DEFAULTS = {
    Enabled = true,
    DebugMode = false,
    NoteChance = 4,
    NoteGuaranteeKills = 30,
    NoteMinDay = 0,
    NoteRespawnDays = 7,
    DramaIntensity = 2,
    ScreenEffects = true,
    -- 108,0 MHz : hors de la plage tirée par la radio d'urgence (88,0-107,8), absente de
    -- RadioData.xml, atteinte par les radios FM courantes (MaxChannel = 108000).
    RadioFrequency = 108.0,
    -- 1 ne pas toucher à Siege Night, 2 suspendre pendant l'enquête, 3 suspendre jusqu'au dossier.
    SiegeNightControl = 2,
    -- Route de l'hélicoptère : minutes de jeu à tenir la zone d'atterrissage (rotor à 5 h).
    ExtractionHoldMinutes = 30,
    -- Stérilisation de la zone N jours après la lecture du dossier ; 0 : désactivée.
    SterilizationDays = 0,
}

local SIEGE_NIGHT_MODE_MIN = 1
local SIEGE_NIGHT_MODE_MAX = 3

local DRAMA_INTENSITY_MIN = 1
local DRAMA_INTENSITY_MAX = 3
local KHZ_PER_MHZ = 1000
-- Les radios se règlent par pas de 0,2 MHz (RWMChannel.lua:138) : la fréquence doit y tomber juste.
local FREQUENCY_STEP_KHZ = 200

local OPTION_NAMESPACE = "OperationArtemis."

-- Lit une option dans les options enregistrées (Java), toujours à jour : en solo, l'éditeur
-- d'options en jeu écrit seulement ces valeurs (ISServerSandboxOptionsUI.lua:738-740) et ne met
-- pas à jour la table Lua SandboxVars avant le prochain chargement. Repli : SandboxVars, puis défaut.
local function readOption(name)
    local options = getSandboxOptions and getSandboxOptions()
    local option = options and options:getOptionByName(OPTION_NAMESPACE .. name)
    if option then
        local value = option:getValue()
        if value ~= nil then
            return value
        end
    end
    local vars = SandboxVars and SandboxVars.OperationArtemis
    local value = vars and vars[name]
    if value == nil then
        return DEFAULTS[name]
    end
    return value
end

local function readNumber(name)
    local value = tonumber(readOption(name))
    if value == nil then
        return DEFAULTS[name]
    end
    return value
end

function Config.isEnabled()
    return readOption("Enabled") == true
end

-- Commandes de debug : option sandbox DebugMode, ou jeu lancé avec -debug.
function Config.isDebugAllowed()
    return readOption("DebugMode") == true or isDebugEnabled()
end

-- Intensité dramatique : 1 faible, 2 normale, 3 forte (option enum, index à partir de 1).
function Config.dramaIntensity()
    local value = math.floor(readNumber("DramaIntensity"))
    return math.max(DRAMA_INTENSITY_MIN, math.min(DRAMA_INTENSITY_MAX, value))
end

-- Fondus et pensées affichées pendant les scènes.
function Config.screenEffectsEnabled()
    return readOption("ScreenEffects") == true
end

-- Fréquence de la chaîne ARTEMIS en kHz (unité du moteur), arrondie au pas de réglage des radios.
-- Réglable au cas où un autre mod occuperait déjà 108,0 MHz.
function Config.radioFrequency()
    local mhz = readNumber("RadioFrequency")
    local steps = math.floor(mhz * KHZ_PER_MHZ / FREQUENCY_STEP_KHZ + 0.5)
    return steps * FREQUENCY_STEP_KHZ
end

-- Fréquence telle qu'affichée par les radios du jeu (ex. « 108.0 »), pour les textes du mod.
function Config.radioFrequencyLabel()
    return string.format("%.1f", Config.radioFrequency() / KHZ_PER_MHZ)
end

-- Pilotage de Siege Night (voir Artemis_SiegeNightBridge) : option enum, index à partir de 1.
function Config.siegeNightMode()
    local value = math.floor(readNumber("SiegeNightControl"))
    return math.max(SIEGE_NIGHT_MODE_MIN, math.min(SIEGE_NIGHT_MODE_MAX, value))
end

-- Minutes de jeu entre l'arrivée du rotor et l'atterrissage de l'hélicoptère (route B).
function Config.extractionHoldMinutes()
    return math.max(1, math.floor(readNumber("ExtractionHoldMinutes")))
end

-- Jours entre la lecture du dossier et la stérilisation de la zone ; 0 si l'option est désactivée.
function Config.sterilizationDays()
    return math.max(0, math.floor(readNumber("SterilizationDays")))
end

-- Règles d'apparition de la note (voir Artemis_NotePolicy).
function Config.noteRules()
    return {
        chance = readNumber("NoteChance"),
        guaranteeKills = readNumber("NoteGuaranteeKills"),
        minDay = readNumber("NoteMinDay"),
        respawnDays = readNumber("NoteRespawnDays"),
    }
end

return Config
