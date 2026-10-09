-- Opération Artemis : constantes partagées (client, serveur et solo).

local Const = {
    MOD_ID = "batman_OperationArtemis",
    MODDATA_KEY = "batman_Artemis",
    NET_MODULE = "batman_Artemis",
    SCHEMA_VERSION = 2,
    LOG_PREFIX = "[OperationArtemis] ",
}

-- Actes du scénario, dans l'ordre de progression.
Const.ACT = {
    DORMANT = 0,       -- la note Artemis n'a pas encore été lue
    SIGNAL = 1,        -- acte I : trouver la fréquence
    INVESTIGATION = 2, -- acte II : l'enquête
    EXFILTRATION = 3,  -- acte III : quitter la zone
    DONE = 4,          -- exfiltration réussie
}

-- Commandes client -> serveur.
Const.COMMAND = {
    HEARD_SIGNAL = "heardSignal",
    HEARD_TAPE = "heardTape",
    CALL_EXTRACTION = "callExtraction",
    CONTINUE_AFTER_ENDING = "continueAfterEnding",
    RESTART_AFTER_ENDING = "restartAfterEnding",
    CHECKPOINT_TEST = "checkpointTest",
    CHECKPOINT_LEAVE = "checkpointLeave",
    CALL_FERRY = "callFerry",
    DEBUG_START = "debugStart",
    DEBUG_ADVANCE = "debugAdvance",
    DEBUG_RESET = "debugReset",
    DEBUG_GIVE_NOTE = "debugGiveNote",
    DEBUG_COMPLETE_CHAPTER = "debugCompleteChapter",
}

-- Objets du mod (script media/scripts/Artemis_items.txt).
Const.ITEM_NOTE = "batman_Artemis.ArtemisNote"
Const.ITEM = {
    BADGE = "batman_Artemis.ArtemisBadge",
    MISSION_ORDERS = "batman_Artemis.ArtemisMissionOrders",
    PATIENT_FILE = "batman_Artemis.ArtemisPatientFile",
    RELAY_LOG = "batman_Artemis.ArtemisRelayLog",
    DOSSIER = "batman_Artemis.ArtemisDossier",
    KEYCARD = "batman_Artemis.ArtemisKeycard",
    BASE_PLAN = "batman_Artemis.ArtemisBasePlan",
    -- Chapitre 4 bonus (Tikitown, phase 6) : bordereau trouvé au relais, notes de V au labo.
    WAYBILL = "batman_Artemis.ArtemisWaybill",
    LAB_NOTES = "batman_Artemis.ArtemisLabNotes",
}

-- keyId de la carte d'accès, donné aussi aux portes blindées de la base (Artemis_BaseDoors). Au-delà
-- des plages vanilla (bâtiments et véhicules : 0 à 99 999 999 ; clés : 0 à 9 999 999) : aucune collision.
Const.KEYCARD_KEY_ID = 714900149

-- Documents dont la lecture est enregistrée (flags.readDocs) et commentée par le personnage.
Const.READABLE_DOCUMENTS = {
    [Const.ITEM.MISSION_ORDERS] = true,
    [Const.ITEM.PATIENT_FILE] = true,
    [Const.ITEM.RELAY_LOG] = true,
    [Const.ITEM.DOSSIER] = true,
    [Const.ITEM.BASE_PLAN] = true,
    [Const.ITEM.WAYBILL] = true,
    [Const.ITEM.LAB_NOTES] = true,
}

-- Tenues vanilla des zombies militaires (media/clothing/clothing.xml), lues par zombie:getOutfitName().
Const.MILITARY_OUTFITS = {
    ArmyCamoGreen = true,
    ArmyCamoDesert = true,
    ArmyServiceUniform = true,
    ArmyInstructor = true,
}

-- Chaîne radio de l'opération. La fréquence est une option sandbox (Config.radioFrequency).
Const.RADIO = {
    NAME = "ARTEMIS",
    UUID = "batman-artemis-relay-0001",
    -- Code porté par les lignes clés ; 4 caractères, donc ignoré par le vanilla (ISRadioInteractions.lua:216).
    SIGNAL_CODE = "ART1",
    -- Couleur des lignes, proche du vert pâle des transmissions militaires (aussi celle
    -- de la bulle MP d'une radio non tenue, BatmanRadio_Core.onDeviceTextMP).
    LINE_COLOR = { r = 0.70, g = 0.85, b = 0.55 },
}

-- Messages écrits sans accents : le jeu remplace les caractères non ASCII par « ? » dans console.txt.
function Const.log(message)
    print(Const.LOG_PREFIX .. tostring(message))
end

return Const
