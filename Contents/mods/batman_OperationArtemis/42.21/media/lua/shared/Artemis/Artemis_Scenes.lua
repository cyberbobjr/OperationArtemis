-- Opération Artemis : scènes dramatiques, décrites en données.
-- Une scène est désignée par un identifiant (« act1 », « act2 »… et, en phase 2b, les chapitres).
-- Elle est jouée pour le joueur qui l'a déclenchée.
-- Partie « client » : sons, pensées, fondus (Artemis_StagingFX).
-- Partie « server » : panique, zombies (Artemis_Staging) ; le serveur fait autorité sur les stats
-- du joueur, une panique fixée côté client serait écrasée en multijoueur (synchro PlayerStats).
-- Ajouter un effet = ajouter un gestionnaire, pas modifier les scènes existantes.

local Scenes = {}

Scenes.BY_ID = {
    -- Lecture du carnet : un voile noir, une pensée, l'inquiétude monte.
    act1 = {
        client = {
            { at = 0, cue = "fadeOut", seconds = 1 },
            { at = 2, cue = "fadeIn", seconds = 1 },
            { at = 2.5, cue = "thought", key = "IGUI_Artemis_Thought_NoteRead" },
        },
        server = {
            { at = 2.5, cue = "panic", value = 25 },
        },
    },

    -- Premier signal : un claquement de parasites, un cri dans la radio, le silence, puis un
    -- hurlement dehors. Le cri sort vraiment du haut-parleur : c'est un bruit qui attire les zombies
    -- des environs selon le volume de la radio (écouter bas, à l'abri ou avec des écouteurs protège).
    act2 = {
        client = {
            -- RadioZap et non RadioStatic : RadioStatic est un son en boucle (DeviceData.java:737).
            { at = 0, cue = "sound", name = "RadioZap", where = "player" },
            { at = 1.5, cue = "sound", name = "VoiceMaleDeathEaten", where = "player" },
            { at = 5, cue = "sound", name = "MetaScream", where = "far", distance = 60 },
            { at = 7, cue = "thought", key = "IGUI_Artemis_Thought_Scream" },
        },
        server = {
            -- Au moment du cri : portée deux fois celle du haut-parleur (un cri, pas une voix).
            { at = 1.5, cue = "noise", factor = 2 },
            { at = 5.5, cue = "panic", value = 70 },
        },
    },

    -- Lecture du dossier Artemis : ce qu'il contient, puis ce que ça veut dire pour le personnage.
    read_ArtemisDossier = {
        client = {
            { at = 0.5, cue = "thought", key = "IGUI_Artemis_Thought_read_ArtemisDossier", always = true },
            { at = 4.5, cue = "thought", key = "IGUI_Artemis_Thought_read_ArtemisDossier2", always = true },
        },
    },

    -- Portique des archives franchi avec le dossier : l'alarme hurle, la peur monte (phase 3).
    alarm_ch5_gate = {
        client = {
            { at = 0.5, cue = "thought", key = "IGUI_Artemis_Thought_alarm_ch5_gate", always = true },
        },
        server = {
            { at = 0.5, cue = "panic", value = 50 },
        },
    },

    -- Sortie de la base réussie pendant l'évasion : le soulagement, puis le brouillard qui tombe.
    escape_ch5_base = {
        client = {
            { at = 0.5, cue = "thought", key = "IGUI_Artemis_Thought_escape_ch5_base", always = true },
            { at = 4.5, cue = "thought", key = "IGUI_Artemis_Thought_surface_ch5_base", always = true },
        },
        server = {
            { at = 3, cue = "fog", strength = 0.8, minutesByIntensity = { 60, 120, 180 } },
        },
    },

    -- Remontée à la surface de la base avec le dossier : le brouillard tombe (force 0,8, durée selon
    -- l'intensité dramatique), le personnage le remarque.
    surface_ch5_base = {
        client = {
            { at = 3, cue = "thought", key = "IGUI_Artemis_Thought_surface_ch5_base", always = true },
        },
        server = {
            { at = 0, cue = "fog", strength = 0.8, minutesByIntensity = { 60, 120, 180 } },
        },
    },

    -- Fleuve (phase 5) : le bateau est pris dans les projecteurs d'un poste, la sirène hurle.
    river_spotted = {
        client = {
            { at = 0.5, cue = "thought", key = "IGUI_Artemis_Thought_river_spotted", always = true },
        },
        server = {
            { at = 0.5, cue = "panic", value = 60 },
        },
    },

    -- Caisse de ravitaillement (phase 6) : pensée dite après celle de l'appel, joué au même moment.
    supply_drop = {
        client = {
            { at = 4.5, cue = "thought", key = "IGUI_Artemis_Thought_supply_drop", always = true },
        },
    },

    -- Checkpoint (phase 5) : le détenu mort se relève dans l'enclos, la peur réveille le joueur.
    quarantine_reanimate = {
        client = {
            { at = 0, cue = "sound", name = "MetaScream", where = "player" },
            { at = 0, cue = "wake" },
            { at = 1.5, cue = "thought", key = "IGUI_Artemis_Thought_quarantine_reanimate", always = true },
        },
        server = {
            { at = 0.5, cue = "panic", value = 70 },
        },
    },

    -- Stérilisation (option, phase 5) : grondement au loin, peur, puis ce que ça veut dire.
    sterilization_strike = {
        client = {
            { at = 0, cue = "sound", name = "RumbleThunder", where = "far", distance = 200 },
            { at = 3, cue = "thought", key = "IGUI_Artemis_Thought_sterilization_strike", always = true },
            { at = 8, cue = "thought", key = "IGUI_Artemis_Thought_sterilization_strike2", always = true },
        },
        server = {
            { at = 1, cue = "panic", value = 60 },
        },
    },
}

-- Pensées du personnage au fil de l'enquête (aide au joueur) : arrivée sur un lieu, preuve prise,
-- document lu, aide quand l'objectif bloque. Une pensée seule, dite peu après l'événement.
-- La clé de traduction est « IGUI_Artemis_Thought_<scène> ».
local THOUGHT_DELAY = 0.5
local THOUGHT_SCENES = {
    "arrive_ch1_bunker", "done_ch1_bunker", "read_ArtemisMissionOrders", "alarm_ch1_bunker",
    "arrive_ch2_clinic", "done_ch2_clinic", "read_ArtemisPatientFile",
    "arrive_ch3_relay", "hint_ch3_read", "hint_ch3_power", "hint_ch3_radio", "hint_ch3_log",
    "read_ArtemisRelayLog", "done_ch3_relay",
    -- Chapitre 4 bonus (Tikitown, phase 6).
    "read_ArtemisWaybill", "arrive_ch4_lab", "read_ArtemisLabNotes", "done_ch4_lab",
    "arrive_ch5_base", "read_ArtemisBasePlan", "alarm_ch5_sensors", "alarm_ch5_cut",
    -- Fin du dernier chapitre : l'entrée dans l'acte III porte aussi la pensée de la prise du dossier.
    "act3",
    -- Route de l'hélicoptère (phase 4) : appel accepté, rotor en approche, hélicoptère posé,
    -- rendez-vous manqué.
    "extraction_called", "extraction_inbound", "extraction_landed", "extraction_missed",
    -- Stérilisation annoncée (option, phase 5).
    "sterilization_start",
    -- Siege Night : siège programmé le soir du dossier ; caisse de ravitaillement (phase 6).
    "siege_warning",
    -- Checkpoint, route C (phase 5) : test d'entrée, quarantaine, test final.
    "checkpoint_cleared", "checkpoint_wait", "checkpoint_positive", "call_nodossier",
    "quarantine_start", "quarantine_broken",
    "quarantine_passed", "quarantine_refused",
    -- Fleuve, route A (phase 5) : nage, pas de dossier, passeur.
    "river_swim", "river_nodossier",
    "ferry_called", "ferry_inbound", "ferry_landed", "ferry_missed", "ferry_refused",
}
for _, sceneId in ipairs(THOUGHT_SCENES) do
    Scenes.BY_ID[sceneId] = Scenes.BY_ID[sceneId] or {
        client = { { at = THOUGHT_DELAY, cue = "thought", key = "IGUI_Artemis_Thought_" .. sceneId, always = true } },
    }
end

-- Identifiant de la scène jouée à l'entrée dans un acte.
function Scenes.idForAct(act)
    return "act" .. tostring(act)
end

-- Scène de cet identifiant, ou nil (aucune scène prévue : rien n'est joué).
function Scenes.get(sceneId)
    return sceneId and Scenes.BY_ID[sceneId] or nil
end

return Scenes
