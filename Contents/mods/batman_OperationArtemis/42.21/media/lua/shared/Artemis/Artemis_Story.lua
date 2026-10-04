-- Opération Artemis : données des chapitres de l'acte II (l'enquête).
-- Ajouter un chapitre = ajouter une entrée ici, sans toucher au moteur (Artemis_Plot, Artemis_Director).
-- Coordonnées relevées dans les fichiers de carte vanilla 42.21 (.claude/tools/lotheader_parser.py),
-- voir .claude/pz-knowledge/knox-geography.md.
--
-- Champs d'un chapitre :
--   number        : numéro affiché (le chapitre 4, bonus, viendra avec les intégrations)
--   site          : case du dépôt principal
--   entrance      : entrée du lieu : pensée d'arrivée, téléportation de debug
--   siteAccess    : case libre à côté du dépôt, pour la téléportation de debug au dépôt
--   placements    : poses du chapitre (Artemis_Placement), par type (« kind ») : items, corpses, guard,
--                   zombies, generator, worldItem, wallLight, lockedRoom, radio. « group » : registre
--                   anti-doublon de la pose (par défaut l'identifiant du chapitre) ; un nouveau groupe
--                   peut être ajouté à un chapitre déjà posé dans une partie en cours, sans reposer
--                   les autres.
--   goal          : objectif qui termine le chapitre (Artemis_Goals)
--   goalRadius    : distance (cases) au site en deçà de laquelle l'objectif est vérifié
--   alarm, mist   : effets d'ambiance du lieu, actifs même après la fin du chapitre (Artemis_Alarm,
--                   Artemis_Mist)
--   tape          : bande rejouée par une radio posée (Artemis_RelayTape, objectif « heard »)
--   surfacing     : scène jouée quand un joueur remonte à la surface du lieu à l'acte III
--                   (Artemis_Surfacing ; seulement le dernier chapitre, Story.EXIT_CHAPTER)
--   baseAlarm     : alarme de la base, portique et capteurs (Artemis_BaseAlarm, dernier chapitre)
--   escape        : épreuve « Évasion du labo » (Artemis_Trial, Artemis_BaseAlarm)
--   hints         : aides dites par le personnage près du site tant que l'objectif n'est pas atteint :
--                   la première aide dont « when » (facultatif) est rempli et « unless » ne l'est pas
--                   joue sa scène, une fois par partie ; tant qu'elle n'est pas résolue, les
--                   suivantes attendent
--   guide         : étapes et balisage dans un grand lieu (Artemis_Guide, côté client)
--   reveal        : zone révélée sur la carte et symbole (Artemis_Map)
--   journalKey    : entrée de journal à la fin du chapitre
--   callCode      : code d'appel appris à la fin du chapitre (facultatif)
--   next          : chapitre suivant ; sans suivant, la fin du chapitre ouvre l'acte III
-- Scènes associées (Artemis_Scenes) : « arrive_<chapitre> », « done_<chapitre> », « read_<TypeObjet> ».

local Const = require "Artemis/Artemis_Const"

local Story = {}

Story.FIRST_CHAPTER = "ch1_bunker"

-- Dernier chapitre : son guide reste actif à l'acte III (sortie de la base) et sa remontée fait
-- tomber le brouillard.
Story.EXIT_CHAPTER = "ch5_base"

-- Distance (cases) à l'entrée d'un lieu pour la pensée d'arrivée.
Story.ARRIVAL_RADIUS = 12

-- Rouge des annotations de « V » sur la carte vanilla WorldStashMap17 (WorldStashDesc.lua:199).
Story.MARK_COLOR = { r = 0.65, g = 0.054, b = 0.054 }

-- Sprites de secours si le meuble attendu a disparu (vérifiés dans newtiledefinitions.tiles.txt).
local SPRITE_MILITARY_CRATE = "location_military_generic_01_0"
local SPRITE_FILING_CABINET = "location_business_office_generic_01_16"

-- Base secrète : puits d'escalier du sas (niveaux 0 à -13), second puits (niveaux -13 à -17).
-- Relevé dans les .lotpack : un escalier est posé au niveau inférieur et mène au niveau supérieur.
-- Emprise de la base (surface, labo et grotte) : guide, zombies suivis, alarme.
local BASE_AREA = { x1 = 5515, y1 = 12400, x2 = 5700, y2 = 12520 }
Story.BASE_AREA = BASE_AREA

local BASE_SHAFT_1 = { x = 5545, y = 12466 }
local BASE_SHAFT_2 = { x = 5550, y = 12498 }

local function shaftLamps(point, fromZ, toZ)
    local lamps = {}
    for z = fromZ, toZ, -1 do
        lamps[#lamps + 1] = { x = point.x, y = point.y, z = z }
    end
    return lamps
end

local function concat(...)
    local all = {}
    for _, list in ipairs({ ... }) do
        for _, item in ipairs(list) do
            all[#all + 1] = item
        end
    end
    return all
end

Story.CHAPTERS = {
    -- Bunker militaire désaffecté de March Ridge : cabane d'entrée en surface, escalier jusqu'à z -4.
    ch1_bunker = {
        number = 1,
        site = { x = 9963, y = 12626, z = -4 },
        siteAccess = { x = 9961, y = 12628, z = -4 },
        entrance = { x = 9923, y = 12625, z = 0 },
        placements = {
            { kind = "items", x = 9963, y = 12626, z = -4, containerTypes = { "desk" },
              fallbackSprite = SPRITE_MILITARY_CRATE,
              items = { Const.ITEM.MISSION_ORDERS, Const.ITEM.BADGE } },
            -- Soldats tombés à leur poste, infectés : des « faux morts » (mécanique vanilla), qui
            -- agrippent qui passe trop près. Ils ne dépendent pas du badge.
            -- Groupe à part (les documents sont reposés au redémarrage de l'opération, pas les soldats).
            { group = "ch1_bunker_soldiers", kind = "corpses", x = 9963, y = 12626, z = -4, count = 3, radius = 3,
              outfit = "ArmyCamoGreen", fakeDead = true },
            -- Groupe électrogène de secours dans la salle des machines (9944-9956, 12615-12623), à
            -- 16 cases du bureau : il l'éclaire, mais il remet aussi l'alerte sous tension (« alarm »).
            -- Réservoir au tiers (carburant de 0 à 10). Déjà branché : « Allumer » ne demande aucune
            -- compétence. Allumé à l'intérieur, il rend le bunker toxique (règle vanilla) : un masque
            -- à gaz avec son filtre traîne à côté. Groupe à part : il se pose aussi dans une partie
            -- où le bunker est déjà posé.
            { group = "ch1_bunker_generator", kind = "generator", x = 9948, y = 12620, z = -4, radius = 2,
              item = "Base.Generator_Old", fuel = 3, condition = 70 },
            { group = "ch1_bunker_generator", kind = "worldItem", x = 9950, y = 12619, z = -4, radius = 2,
              item = "Base.Hat_GasMask", filter = { type = "Base.GasmaskFilter", level = 0.8 } },
        },
        -- Alerte (Artemis_Alarm) : démarrer le groupe fait hurler la sirène de la cabane d'entrée,
        -- un vrai bruit qui attire le secteur, une seule fois par partie, pendant au plus « minutes »
        -- minutes de jeu (couper le groupe l'arrête).
        alarm = {
            group = "ch1_bunker_generator",
            horn = { x = 9923, y = 12625, z = 0 },
            sound = "VehicleSirenWall",
            minutes = 20,
            -- Référence vanilla : sirène de véhicule, rayon 100, volume 60 (BaseVehicle.java:7016-7018).
            noiseRadiusByIntensity = { 60, 100, 150 },
            noiseVolume = 60,
            scene = "alarm_ch1_bunker",
        },
        -- Brume de l'aube (Artemis_Mist) : en ressortant du bunker à l'aube, une fois par partie.
        mist = {
            area = { x1 = 9910, y1 = 12610, x2 = 9940, y2 = 12640 },
            fromHours = -1, toHours = 1.5,
            -- Sortie dans les N minutes de jeu après avoir été sous terre.
            recentMinutes = 10,
            minutes = 60,
            strengthByIntensity = { 0.2, 0.3, 0.4 },
        },
        goal = { type = "hasItem", item = Const.ITEM.BADGE },
        goalRadius = 60,
        reveal = {
            area = { x1 = 9890, y1 = 12580, x2 = 10010, y2 = 12670 },
            mark = { icon = "Target", x = 9923, y = 12625, textKey = "IGUI_Artemis_Map_ch1_bunker" },
        },
        journalKey = "IGUI_Artemis_J_Ch1",
        next = "ch2_clinic",
    },

    -- Clinique de West Point (pièce « clinic », classeur à côté du bureau).
    ch2_clinic = {
        number = 2,
        site = { x = 11879, y = 6882, z = 0 },
        siteAccess = { x = 11881, y = 6883, z = 0 },
        entrance = { x = 11883, y = 6879, z = 0 },
        placements = {
            { kind = "items", x = 11879, y = 6882, z = 0, containerTypes = { "filingcabinet" },
              fallbackSprite = SPRITE_FILING_CABINET,
              items = { Const.ITEM.PATIENT_FILE } },
            -- Mise en scène (groupe à part, posé aussi dans une partie où le dossier est déjà posé) :
            -- - applique de secours sur un mur du couloir, sur batterie : elle clignote ;
            -- - salle d'examen 2 fermée à clé, l'infirmière K. Dunn dedans (le dossier dit qu'elle
            --   s'y est isolée après avoir été mordue) : elle frappe la porte quand elle entend ;
            -- - le patient zéro, plus résistant, erre à l'accueil (le dossier explique pourquoi).
            -- Computer Mod (bonus, phase 6) : CD de sauvegarde de la clinique dans le même classeur,
            -- lisible dans n'importe quel ordinateur du mod (celui du bureau voisin, 11881,6881).
            { group = "ch2_clinic_cd", kind = "items", x = 11879, y = 6882, z = 0, containerTypes = { "filingcabinet" },
              fallbackSprite = SPRITE_FILING_CABINET, items = {},
              computer = { kind = "disc", labelKey = "IGUI_Artemis_CD_Label", notes = {
                  { key = "clinic_mail", labelKey = "IGUI_Artemis_CD_Mail_Title", textKey = "IGUI_Artemis_CD_Mail" },
                  { key = "clinic_shift", labelKey = "IGUI_Artemis_CD_Shift_Title", textKey = "IGUI_Artemis_CD_Shift" },
                  { key = "clinic_lab", labelKey = "IGUI_Artemis_CD_Lab_Title", textKey = "IGUI_Artemis_CD_Lab" },
              } } },
            { group = "ch2_clinic_scene", kind = "wallLight", x = 11883, y = 6877, z = 0,
              candidates = { { x = 11883, y = 6877 }, { x = 11883, y = 6876 }, { x = 11883, y = 6879 },
                             { x = 11883, y = 6880 }, { x = 11883, y = 6873 }, { x = 11883, y = 6874 } },
              -- Sprites vanilla « Wall Light » : 44 contre un mur ouest (regarde à l'est), 45 contre
              -- un mur nord (regarde au sud) (newtiledefinitions.tiles.txt).
              spritesByFacing = { E = "lighting_indoor_02_44", S = "lighting_indoor_02_45" },
              light = { color = { r = 0.9, g = 0.85, b = 0.6 }, radius = 5, blink = "lowBattery" } },
            { group = "ch2_clinic_scene", kind = "lockedRoom", x = 11881, y = 6877, z = 0, radius = 1,
              door = { x = 11883, y = 6878, z = 0 }, outfit = "Nurse", femaleChance = 100 },
            { group = "ch2_clinic_scene", kind = "zombies", x = 11884, y = 6885, z = 0, radius = 2, count = 1,
              outfit = "HospitalPatient", femaleChance = 0, track = "patient_zero", minPlayerDistance = 15 },
        },
        goal = { type = "hasItem", item = Const.ITEM.PATIENT_FILE },
        goalRadius = 60,
        reveal = {
            area = { x1 = 11840, y1 = 6840, x2 = 11920, y2 = 6920 },
            mark = { icon = "Target", x = 11883, y = 6879, textKey = "IGUI_Artemis_Map_ch2_clinic" },
        },
        journalKey = "IGUI_Artemis_J_Ch2",
        next = "ch3_relay",
    },

    -- Station relais avec pylône entre Brandenburg et Riverside. Le joueur lit le registre du relais,
    -- qui explique quoi faire, puis remet le relais sous tension (générateur à portée, ou réseau
    -- public encore actif) depuis la salle de contrôle : la bande de V donne alors le code d'appel.
    ch3_relay = {
        number = 3,
        site = { x = 4836, y = 6285, z = 0 },
        siteAccess = { x = 4835, y = 6283, z = 0 },
        entrance = { x = 4840, y = 6281, z = 0 },
        placements = {
            { kind = "items", x = 4836, y = 6285, z = 0, containerTypes = { "desk" },
              fallbackSprite = SPRITE_FILING_CABINET,
              items = { Const.ITEM.RELAY_LOG },
              -- Carte-cachette vanilla de V (« V will turn off sensors at 23.15 ») : mène à la base.
              -- Renommée pour qu'on ne la prenne pas pour une carte ordinaire.
              stashMaps = { { stash = "WorldStashMap17", nameKey = "IGUI_Artemis_VMap_Name" } } },
            -- Mise en scène (groupes à part, posés aussi dans une partie où le relais est déjà posé) :
            -- - zombies ordinaires sur un anneau autour de la station, posés quand tous les joueurs
            --   sont loin : le groupe électrogène du joueur les attire (bruit vanilla, rayon 20 à 25,
            --   divisé par deux à l'intérieur) ;
            -- - la « machine » du registre : une radio sans pile sur la table de la salle de contrôle,
            --   qui rejoue la bande de V quand on l'allume avec du courant (Artemis_RelayTape). Les
            --   radios vanilla de la station sont dans le bureau et marchent sur pile ;
            -- - Miller, le technicien qui « s'est enfui en courant » (registre), derrière la station.
            { group = "ch3_relay_zombies", kind = "zombies", x = 4834, y = 6278, z = 0,
              ring = { minRadius = 15, maxRadius = 22, minPlayerDistance = 25 }, countByIntensity = { 3, 5, 8 } },
            { group = "ch3_relay_radio", kind = "radio", x = 4836, y = 6277, z = 0,
              sprite = "appliances_com_01_0", volume = 0.7,
              -- Fréquence de repli seulement : à la pose, le jeu tire une fréquence libre (certaines
              -- stations vanilla, comme la radio d'urgence, changent de fréquence à chaque partie).
              channel = 103400,
              -- Posée sur la table : Surface de la table (26) moins celle du sprite (34), comme le
              -- vanilla (ISMoveableSpriteProps.lua:1555-1561).
              renderYOffset = -8 },
            -- Chapitre 4 bonus (phase 6) : bordereau d'expédition d'échantillons vers le labo satellite
            -- de Tikitown, dans le bureau du relais, seulement si ce chapitre a lieu.
            { group = "ch3_relay_waybill", kind = "items", x = 4836, y = 6285, z = 0, containerTypes = { "desk" },
              fallbackSprite = SPRITE_FILING_CABINET, items = { Const.ITEM.WAYBILL }, ifChapter = "ch4_lab" },
            { group = "ch3_relay_miller", kind = "zombies", x = 4818, y = 6274, z = 0,
              ring = { minRadius = 0, maxRadius = 3, minPlayerDistance = 30 }, count = 1,
              outfit = "Mechanic", femaleChance = 0, track = "miller", retryOnEmpty = true },
        },
        -- Bande de V (Artemis_RelayTape) : rejouée par une radio allumée dans la salle de contrôle, qui
        -- n'a du courant que si le relais est sous tension. Chaque allumage la relance du début.
        tape = {
            key = "ch3_tape",
            room = { x1 = 4832, y1 = 6277, x2 = 4837, y2 = 6280, z = 0 },
            -- Case de la salle dont le courant est vérifié par le serveur quand la bande est finie.
            powerSquare = { x = 4834, y = 6278, z = 0 },
            -- Jaune vif, lisible sur tous les fonds (retour du test : l'ambre était difficile à lire).
            -- Couleur normalisée : Artemis_RelayTape la convertit en entiers 0-255 pour la radio
            -- posée (surcharge entière d'AddDeviceText, IsoWaveSignal.java:188-190).
            color = { r = 0.99, g = 0.93, b = 0.2 },
            lines = {
                { raw = "<fzzt>", seconds = 2 },
                { key = "IGUI_Artemis_Tape_1", seconds = 7 },
                { key = "IGUI_Artemis_Tape_2", seconds = 7 },
                { raw = "<bzzt>", seconds = 2 },
                { key = "IGUI_Artemis_Tape_3", seconds = 7 },
                { key = "IGUI_Artemis_Tape_4", seconds = 7 },
                { key = "IGUI_Artemis_Tape_5", seconds = 7 },
                { raw = "<wzzt>", seconds = 2 },
                { key = "IGUI_Artemis_Tape_6", seconds = 7 },
                { key = "IGUI_Artemis_Tape_7", seconds = 7 },
            },
        },
        -- Registre lu et bande de V entendue (la bande exige le courant). Salle de contrôle du relais.
        goal = { type = "all", goals = {
            { type = "hasRead", item = Const.ITEM.RELAY_LOG },
            { type = "heard", key = "ch3_tape" },
        } },
        goalRadius = 12,
        hints = {
            -- Bande écoutée mais registre toujours pas lu (retour du test : on peut l'oublier). En tête,
            -- mais seulement après la bande ; sinon l'aide « registre », déjà dite, la bloquerait.
            { when = { type = "heard", key = "ch3_tape" }, unless = { type = "hasRead", item = Const.ITEM.RELAY_LOG },
              scene = "hint_ch3_log" },
            { unless = { type = "hasRead", item = Const.ITEM.RELAY_LOG }, scene = "hint_ch3_read" },
            { unless = { type = "squarePowered", x = 4834, y = 6278, z = 0 }, scene = "hint_ch3_power" },
            { unless = { type = "heard", key = "ch3_tape" }, scene = "hint_ch3_radio" },
        },
        reveal = {
            area = { x1 = 4790, y1 = 6240, x2 = 4870, y2 = 6320 },
            mark = { icon = "Target", x = 4832, y = 6281, textKey = "IGUI_Artemis_Map_ch3_relay" },
        },
        journalKey = "IGUI_Artemis_J_Ch3",
        -- Chapitre 4 bonus après le relais : le journal parle du bordereau trouvé dans le registre.
        journalKeyByNext = { ch4_lab = "IGUI_Artemis_J_Ch3_Lab" },
        -- Les chiffres de la station (« Sept. Un. Quatre. Neuf ») étaient le code d'appel.
        callCode = "7149",
        next = "ch4_lab",
    },

    -- Chapitre 4 bonus (phase 6) : le labo satellite sous le bureau de Tikitown (carte de mod, relevé du
    -- 2026-10-01 dans ses lotpacks). N'a lieu que si la carte est chargée dans la partie (« requires »,
    -- Artemis_ModMaps) ; sinon le relais mène directement à la base. Escalier unique 6877-6879,7572,
    -- porte de palier 6877,7571 à chaque niveau. Notes de V dans un bureau du -4, échantillons à la
    -- morgue du -5 (objets de Zombie Virus Vaccine, seulement si ce mod est actif), sujets assis.
    ch4_lab = {
        number = 4,
        requires = { mod = "tikitown", map = "Tikitown", probe = { x = 6868, y = 7568, z = -5 } },
        site = { x = 6863, y = 7572, z = -4 },
        siteAccess = { x = 6864, y = 7573, z = -4 },
        entrance = { x = 6862, y = 7584, z = 0 },
        placements = {
            { kind = "items", x = 6863, y = 7572, z = -4, containerTypes = { "desk" },
              fallbackSprite = SPRITE_FILING_CABINET, items = { Const.ITEM.LAB_NOTES } },
            { group = "ch4_lab_samples", kind = "items", x = 6862, y = 7559, z = -5, containerTypes = { "crate" },
              fallbackSprite = SPRITE_MILITARY_CRATE, optionalItems = true,
              items = { "LabItems.MatInfectedBlood", "LabItems.MatInfectedBlood", "LabItems.HumanBrainMid" } },
            { group = "ch4_lab_subjects", kind = "zombies", x = 6866, y = 7562, z = -5, radius = 4,
              sitting = true, outfit = "HospitalPatient", countByIntensity = { 1, 2, 3 }, track = "tikitown_subject" },
        },
        goal = { type = "hasRead", item = Const.ITEM.LAB_NOTES },
        goalRadius = 60,
        reveal = {
            area = { x1 = 6820, y1 = 7520, x2 = 6920, y2 = 7620 },
            mark = { icon = "Target", x = 6862, y = 7584, textKey = "IGUI_Artemis_Map_ch4_lab" },
        },
        journalKey = "IGUI_Artemis_J_Ch4",
        next = "ch5_base",
    },

    -- Base secrète vanilla (SecretBase) : le dossier est dans les archives du niveau le plus bas.
    ch5_base = {
        number = 5,
        site = { x = 5568, y = 12430, z = -17 },
        siteAccess = { x = 5568, y = 12432, z = -17 },
        entrance = { x = 5588, y = 12483, z = 0 },
        placements = {
            { kind = "items", x = 5568, y = 12430, z = -17, containerTypes = { "filingcabinet" },
              fallbackSprite = SPRITE_FILING_CABINET,
              items = { Const.ITEM.DOSSIER } },
            -- Talkie de l'Armée américaine laissé par V à côté du dossier, réglé sur la chaîne Artemis
            -- (phase 4) : le joueur a la radio militaire de l'appel d'évacuation au moment où il en a
            -- besoin. Groupe à part : il se pose aussi dans une partie où le dossier est déjà posé.
            { group = "ch5_base_radio", kind = "items", x = 5568, y = 12430, z = -17,
              containerTypes = { "filingcabinet" }, fallbackSprite = SPRITE_FILING_CABINET,
              items = { "Base.WalkieTalkie5" }, tuneRadio = true },
            -- Computer Mod (bonus, phase 6) : le portable de V, son journal, sur batterie.
            { group = "ch5_base_laptop", kind = "items", x = 5568, y = 12430, z = -17,
              containerTypes = { "filingcabinet" }, fallbackSprite = SPRITE_FILING_CABINET, items = {},
              computer = { kind = "laptop", notes = {
                  { key = "v_journal_1", labelKey = "IGUI_Artemis_Laptop_1_Title", textKey = "IGUI_Artemis_Laptop_1" },
                  { key = "v_journal_2", labelKey = "IGUI_Artemis_Laptop_2_Title", textKey = "IGUI_Artemis_Laptop_2" },
                  { key = "v_journal_3", labelKey = "IGUI_Artemis_Laptop_3_Title", textKey = "IGUI_Artemis_Laptop_3" },
              } } },
            -- Garde tombé devant la porte est : carte d'accès (portes blindées) et plan de la base.
            -- Groupe à part : ajouté après les premiers tests, il se pose aussi dans une partie où le
            -- dossier est déjà posé.
            -- keepAvailable : si le corps a disparu (option de suppression des cadavres) et qu'aucun
            -- joueur n'a la carte, le garde est reposé, sinon la base resterait fermée.
            { group = "ch5_base_guard", kind = "guard", x = 5588, y = 12485, z = 0, radius = 2,
              outfit = "ArmyCamoGreen", items = { Const.ITEM.KEYCARD, Const.ITEM.BASE_PLAN },
              keepAvailable = Const.ITEM.KEYCARD },
            -- « Sujets » du labo : zombies en blouse de patient, assis dos au mur, dans le labo du
            -- niveau -17 et les salles du -16. Ils se lèvent quand ils voient ou entendent le joueur
            -- (vanilla) ; le jeu ne sauvegarde pas la position assise, ils sont rassis à leur retour
            -- (profil suivi « lab_subject »). Nombre selon l'intensité dramatique.
            { group = "ch5_base_subjects", kind = "zombies", x = 5567, y = 12439, z = -17, radius = 6,
              sitting = true, outfit = "HospitalPatient", countByIntensity = { 1, 2, 3 }, track = "lab_subject" },
            { group = "ch5_base_subjects", kind = "zombies", x = 5572, y = 12462, z = -16, radius = 4,
              sitting = true, outfit = "HospitalPatient", countByIntensity = { 1, 1, 2 }, track = "lab_subject" },
            { group = "ch5_base_subjects", kind = "zombies", x = 5558, y = 12439, z = -16, radius = 4,
              sitting = true, outfit = "HospitalPatient", countByIntensity = { 0, 1, 1 }, track = "lab_subject" },
            { group = "ch5_base_subjects", kind = "zombies", x = 5570, y = 12439, z = -16, radius = 4,
              sitting = true, outfit = "HospitalPatient", countByIntensity = { 0, 1, 1 }, track = "lab_subject" },
            -- Garnison (phase 3) : soldats zombies posés d'avance sur les niveaux du retour, dans des
            -- recoins reliés au chemin sans porte (un zombie n'ouvre pas les portes), à 12 pas au moins
            -- du chemin ; l'alarme les attire. Deux groupes : le labo et la surface ne sont pas prêts
            -- au même moment. 4, 6 ou 8 soldats selon l'intensité.
            { group = "ch5_base_garrison_lab", kind = "zombies", x = 5564, y = 12459, z = -16, radius = 1,
              outfit = "ArmyCamoGreen", femaleChance = 0, countByIntensity = { 1, 2, 2 }, minPlayerDistance = 20 },
            { group = "ch5_base_garrison_lab", kind = "zombies", x = 5574, y = 12488, z = -13, radius = 1,
              outfit = "ArmyCamoGreen", femaleChance = 0, countByIntensity = { 1, 2, 3 }, minPlayerDistance = 20 },
            { group = "ch5_base_garrison_surface", kind = "zombies", x = 5579, y = 12472, z = 0, radius = 2,
              outfit = "ArmyCamoGreen", femaleChance = 0, countByIntensity = { 1, 1, 2 }, minPlayerDistance = 20 },
            { group = "ch5_base_garrison_surface", kind = "zombies", x = 5540, y = 12501, z = 0, radius = 2,
              outfit = "ArmyCamoGreen", femaleChance = 0, countByIntensity = { 1, 1, 1 }, minPlayerDistance = 20 },
        },
        -- Remontée avec le dossier (Artemis_Surfacing) : une fois à la surface de la base, à l'acte
        -- III, le brouillard tombe (choix de l'utilisateur, météo imposée non sauvegardée). Pendant
        -- l'évasion, c'est la réussite de l'épreuve qui le fait tomber (scène « escape_ch5_base »).
        surfacing = { minZ = 0, scene = "surface_ch5_base" },
        -- Alarme de la base (Artemis_BaseAlarm, décisions de la phase 3) :
        -- - portique : le dossier porte une puce ; un joueur qui sort des archives avec lui fait sonner
        --   l'alarme et commence l'évasion, jusqu'à sa sortie de la base (plan de V : il le dit) ;
        -- - capteurs : hors de la fenêtre de V (23 h 15 - 1 h 15), l'alarme sonne tant qu'un joueur est
        --   dans la base ; quand la fenêtre s'ouvre, V la coupe.
        -- La sirène suit le joueur local dans la base (haut-parleurs partout) ; la garnison est
        -- attirée par des sirènes d'étage (escape.horns).
        baseAlarm = {
            sound = "VehicleSirenWall",
            gate = { item = Const.ITEM.DOSSIER,
                     room = { x1 = 5564, y1 = 12430, x2 = 5573, y2 = 12434, z = -17 } },
            sensors = {
                window = { fromMinutes = 23 * 60 + 15, durationMinutes = 120 },
                -- Dans la base : le hall de surface (à l'intérieur d'une pièce), ou le sous-sol.
                volumes = {
                    { x1 = 5537, y1 = 12440, x2 = 5584, y2 = 12505, minZ = 0, maxZ = 1, indoor = true },
                    { x1 = BASE_AREA.x1, y1 = BASE_AREA.y1, x2 = BASE_AREA.x2, y2 = BASE_AREA.y2,
                      minZ = -17, maxZ = -1 },
                },
            },
            scenes = { gate = "alarm_ch5_gate", sensors = "alarm_ch5_sensors", cut = "alarm_ch5_cut" },
            -- Gyrophares : lampes du guide en rouge vif, clignotement lent (Artemis_Blink « alarm »).
            lamps = { blink = "alarm", color = { r = 1, g = 0, b = 0 } },
        },
        -- Évasion du labo (Artemis_Trial) : sortir de la base avec le dossier. Sirènes d'étage : un bruit
        -- réémis près de chaque groupe de la garnison, rayon 45 (sous 50, les zombies hors de la base
        -- ne l'entendent pas ; l'étage compte triple dans la distance, pas besoin des escaliers).
        escape = {
            area = { x1 = 5528, y1 = 12428, x2 = 5600, y2 = 12512 },
            horns = { { x = 5554, y = 12467, z = -16 }, { x = 5548, y = 12488, z = -13 },
                      { x = 5544, y = 12486, z = 0 } },
            hornRadius = 45, hornVolume = 60,
            journalKey = "IGUI_Artemis_J_Escape", scene = "escape_ch5_base",
            objectiveKey = "IGUI_Artemis_Trial_ch5_base",
        },
        goal = { type = "hasItem", item = Const.ITEM.DOSSIER },
        goalRadius = 120,
        guide = {
            area = BASE_AREA,
            -- Étape selon l'étage du joueur (et la zone, si « area ») ; la première qui correspond
            -- s'applique. Chemin relevé case par case dans les tuiles (test du 2026-09-29) : le second
            -- escalier descend jusqu'au -17, mais le bloc des archives n'est pas relié au bas de cet
            -- escalier. Il faut en sortir au -16, suivre le couloir vers le nord puis l'est, et
            -- redescendre par un petit escalier (5574,12449) dans le couloir des archives.
            steps = {
                -- Surface : la pensée d'arrivée (« arrive_ch5_base ») est déjà dite, pas de seconde pensée.
                { minZ = 0, maxZ = 1, key = "IGUI_Artemis_Base_Step1", silent = true },
                { minZ = -12, maxZ = -1, key = "IGUI_Artemis_Base_Step2" },
                { minZ = -13, maxZ = -13, key = "IGUI_Artemis_Base_Step3" },
                { minZ = -15, maxZ = -14, key = "IGUI_Artemis_Base_Step4" },
                { minZ = -16, maxZ = -16, key = "IGUI_Artemis_Base_Step16" },
                -- Bas du second escalier, au -17 : mauvais bloc.
                { minZ = -17, maxZ = -17, key = "IGUI_Artemis_Base_StepWrong",
                  area = { x1 = 5540, y1 = 12455, x2 = 5600, y2 = 12510 } },
                { minZ = -17, maxZ = -17, key = "IGUI_Artemis_Base_Step5" },
            },
            -- Lampes rouges de secours laissées par V : sas, puits d'escalier, chemin jusqu'aux archives.
            -- Leurs batteries faiblissent (plan de V) : elles clignotent (Artemis_Blink).
            lampBlink = "failing",
            -- Dans les couloirs du chemin (retour du test : une lampe dans une salle fait croire qu'on
            -- est arrivé), une tous les 12 cases environ ; seule la salle d'arrivée, les archives, est
            -- éclairée. Le second escalier n'est balisé que jusqu'au -16, où il faut en sortir.
            lamps = concat(
                { { x = 5582, y = 12483, z = 0 }, { x = 5562, y = 12475, z = 0 } },
                shaftLamps(BASE_SHAFT_1, 0, -13),
                { { x = 5548, y = 12482, z = -13 } },
                shaftLamps(BASE_SHAFT_2, -13, -16),
                { { x = 5553, y = 12490, z = -16 }, { x = 5553, y = 12478, z = -16 },
                  { x = 5553, y = 12466, z = -16 }, { x = 5553, y = 12454, z = -16 },
                  { x = 5554, y = 12443, z = -16 }, { x = 5558, y = 12435, z = -16 },
                  { x = 5570, y = 12435, z = -16 }, { x = 5574, y = 12443, z = -16 },
                  { x = 5574, y = 12447, z = -16 } },
                { { x = 5576, y = 12448, z = -17 }, { x = 5576, y = 12438, z = -17 },
                  { x = 5568, y = 12432, z = -17 } }
            ),
        },
        reveal = {
            area = { x1 = 5440, y1 = 12370, x2 = 5919, y2 = 12609 },
            mark = { icon = "Target", x = 5584, y = 12483, textKey = "IGUI_Artemis_Map_ch5_base" },
        },
        journalKey = "IGUI_Artemis_J_Ch5",
    },
}

-- Profils des zombies suivis (Artemis_Tracked) : traits rendus après chaque virtualisation, tant que
-- le zombie reste dans la zone du profil. Une pose « zombies » y renvoie par son champ « track ».
Story.TRACKED = {
    -- Patient zéro de la clinique : il résiste aux sédatifs, tissus anormalement durs (dossier).
    -- Un zombie normal est à 1,5-1,8 de santé, un costaud vanilla à 3,5 (VirtualZombieManager.java:339-350).
    patient_zero = {
        area = { x1 = 11840, y1 = 6840, x2 = 11920, y2 = 6920 },
        healthByIntensity = { 4, 6, 9 },
    },
    -- Miller, technicien du relais exposé à l'agent : il court (registre). À sa mort, sa carte
    -- d'identité (objet vanilla renommé) permet de le reconnaître.
    miller = {
        area = { x1 = 4714, y1 = 6158, x2 = 4954, y2 = 6398 },
        sprint = true,
        deathItem = { type = "Base.IDcard", nameKey = "IGUI_Artemis_Miller_IdCard" },
    },
    -- Sujets du labo de la base : rassis quand ils reviennent dans le monde (emprise de la base).
    lab_subject = {
        area = BASE_AREA,
        sit = true,
    },
    -- Sujets de la morgue du labo de Tikitown (chapitre 4 bonus).
    tikitown_subject = {
        area = { x1 = 6850, y1 = 7550, x2 = 6885, y2 = 7590 },
        sit = true,
    },
}

-- Acte III : points d'évacuation, révélés sur la carte à la lecture du dossier (Artemis_Map ; le
-- dossier nomme les lieux du protocole d'évacuation). Gris si « available » est faux ou si la route
-- est fermée (stérilisation de la zone). « boats » : point montré seulement avec un mod de bateau
-- (« required », bateaux de V) ou sans (« absent », passeur).
-- Icônes du mod déclarées dans Artemis_MapSymbols (PNG en champ de distance, outil
-- .claude/tools/artemis_map_icons.py). Lieux relevés dans les données de carte vanilla 42.21.
Story.EXFIL_REVEAL_DOCUMENT = Const.ITEM.DOSSIER
Story.EXFIL_UNAVAILABLE_COLOR = { r = 0.35, g = 0.35, b = 0.35 }
Story.EXFIL_POINTS = {
    -- B. Hélicoptère : champ intérieur du Knox Boundary Camp, camp militaire au sud de Louisville.
    route_b = {
        route = "B",
        available = true,
        reveal = {
            area = { x1 = 12440, y1 = 4190, x2 = 12610, y2 = 4360 },
            mark = { icon = "ArtemisHeli", x = 12560, y = 4214, textKey = "IGUI_Artemis_Map_route_b" },
        },
    },
    -- A. Fleuve, bassin ouest : bateau de V au ponton de Riverside (sortie ouest, pont Kinsella gardé).
    route_a = {
        route = "A",
        available = true,
        boats = "required",
        reveal = {
            area = { x1 = 5980, y1 = 5170, x2 = 6100, y2 = 5260 },
            mark = { icon = "ArtemisBoat", x = 6040, y = 5222, textKey = "IGUI_Artemis_Map_route_a" },
        },
    },
    -- A. Fleuve, bassin est : bateau de V aux quais de Louisville (sortie nord-est, barrage gardé).
    route_a_east = {
        route = "A",
        available = true,
        boats = "required",
        reveal = {
            area = { x1 = 12780, y1 = 1100, x2 = 12900, y2 = 1200 },
            mark = { icon = "ArtemisBoat", x = 12823, y = 1138, textKey = "IGUI_Artemis_Map_route_a_east" },
        },
    },
    -- A. Fleuve, sans mod de bateau : quai du passeur à Brandenburg.
    route_a_ferry = {
        route = "A",
        available = true,
        boats = "absent",
        reveal = {
            area = { x1 = 1590, y1 = 5540, x2 = 1690, y2 = 5620 },
            mark = { icon = "ArtemisBoat", x = 1637, y = 5582, textKey = "IGUI_Artemis_Map_route_a_ferry" },
        },
    },
    -- C. Checkpoint : enclos au pied du pont Clark Memorial ; le barrage du pont est la ligne de l'armée.
    route_c = {
        route = "C",
        available = true,
        reveal = {
            area = { x1 = 12560, y1 = 940, x2 = 12660, y2 = 1200 },
            mark = { icon = "ArtemisCheckpoint", x = 12616, y = 1176, textKey = "IGUI_Artemis_Map_route_c" },
        },
    },
}

-- Repères de la phase 4 (routes A et C « à venir ») dont la position a changé : retirés de la carte.
Story.EXFIL_LEGACY_MARKS = {
    { icon = "ArtemisBoat", x = 1500, y = 5460 },
    { icon = "ArtemisCheckpoint", x = 12472, y = 4240 },
}

-- Acte III, route B : extraction par hélicoptère (décisions de la phase 4). Appel par radio
-- militaire sur la chaîne Artemis (Artemis_RadioCall) ; ensuite, chaque jour à l'aube, le rotor
-- s'entend au camp, il faut tenir la zone (durée : option ExtractionHoldMinutes), puis
-- l'hélicoptère se pose et attend : rester dans la zone marquée avec le dossier pour embarquer
-- (Artemis_Extraction, Artemis_ExtractionDirector). Un rendez-vous manqué revient le lendemain.
Story.EXTRACTION = {
    -- Centre de la zone d'atterrissage (champ intérieur du camp ; dégagé dans les lotpacks, la
    -- végétation procédurale reste à vérifier en jeu).
    landing = { x = 12560, y = 4218, z = 0 },
    -- Zone marquée où se tenir pour embarquer : cases à cette distance (Chebyshev) du centre.
    boardRadius = 2,
    -- Un joueur à cette distance du centre est « au rendez-vous » (vagues, rotor, compte à rebours).
    holdRadius = 30,
    -- Heure du rotor (créneau quotidien).
    slotHour = 5,
    -- Secondes réelles à rester dans la zone marquée avec le dossier pour embarquer.
    boardSeconds = 10,
    -- Minutes de jeu pendant lesquelles l'hélicoptère attend, posé, avant de repartir.
    landedMinutes = 30,
    -- Fumée verte posée à côté de la zone marquée, jamais dedans (un zombie dans la fumée perd sa cible).
    smoke = { { dx = 4, dy = 0 }, { dx = -4, dy = 0 } },
    -- Vagues hybrides (Artemis_Waves) : le bruit du rotor attire les zombies des environs ; le mod n'en
    -- fait apparaître, hors de vue sur un anneau autour de la zone, que s'il y en a trop peu près
    -- d'elle. Dans le dernier quart de la tenue, les nouveaux venus sont des sprinteurs.
    waves = {
        label = "extraction",
        ringMin = 35,
        ringMax = 45,
        countRadius = 40,
        minZombiesByIntensity = { 6, 10, 14 },
        batchByIntensity = { 3, 5, 7 },
        maxSpawnedByIntensity = { 20, 35, 50 },
        sprintFromFraction = 0.75,
        outfits = { "ArmyCamoGreen", "ArmyCamoGreen", "ArmyServiceUniform" },
        noiseRadius = 60,
        noiseVolume = 80,
    },
}

-- Acte III, route A : le fleuve (décisions de la phase 5, relevés du 2026-10-01). Le pont Clark
-- Memorial coupe l'Ohio en deux bassins : V a caché un bateau dans chacun (posé seulement si un mod de
-- bateau est actif, Artemis_Boats), clé posée sur le ponton. Deux sorties, chacune gardée par un poste
-- de l'armée : projecteurs alimentés par un groupe électrogène à terre ; passer pendant que le groupe
-- tourne déclenche la sirène et rabat une horde sur les berges ; le couper permet de passer dans le
-- noir. Les projecteurs n'éclairent pas tout le chenal (environ 200 cases) : « éclairé » est une règle
-- (bateau dans la zone du poste, groupe en marche), pas une mesure de lumière. Sans mod de bateau, le
-- passeur de V vient à Brandenburg, une fois le groupe de Kinsella coupé (Artemis_FerryDirector).
Story.RIVER = {
    boats = {
        -- Bassin ouest : ponton de Riverside (case d'eau, bateau parallèle au ponton).
        west = { group = "river_boat_west", x = 6037, y = 5212, z = 0, key = { x = 6042, y = 5218, z = 0 } },
        -- Bassin est : quais de Louisville, en amont du Clark Memorial.
        east = { group = "river_boat_east", x = 12823, y = 1153, z = 0, key = { x = 12823, y = 1132, z = 0 } },
    },
    -- Part du réservoir remplie à la pose.
    fuelFraction = 0.6,
    -- Lignes de sortie, dans les données vanilla (au-delà, monde généré ; absent avec -no-worldgen).
    exits = {
        west = { maxX = 20, y1 = 4800, y2 = 5118 },
        northeast = { minX = 19780, maxY = 299 },
    },
    guards = {
        -- Pont Esther Kinsella (moignon) : groupe sur la chaussée, au bout du tablier ; soldats zombies
        -- vanilla sur le tablier et au camp de la rive sud.
        kinsella = {
            group = "river_guard_kinsella", exit = "west",
            generator = { x = 1497, y = 5404, z = 0 },
            -- Première rangée de tablier hors de l'eau (y 5401) : voie ferrée (x 1484) et chaussée.
            lights = { { x = 1484, y = 5401 }, { x = 1497, y = 5401 }, { x = 1506, y = 5401 } },
            zone = { x1 = 1480, y1 = 5201, x2 = 1510, y2 = 5399 },
            banks = { x = 1495, y = 5420, z = 0 },
            soldiers = 0,
        },
        -- Barrage flottant de l'armée à l'est des quais de Louisville : groupe sur la rive sud, gardé.
        northeast = {
            group = "river_guard_northeast", exit = "northeast",
            generator = { x = 13100, y = 1193, z = 0 },
            lights = { { x = 13090, y = 1192 }, { x = 13100, y = 1192 }, { x = 13110, y = 1192 } },
            zone = { x1 = 13090, y1 = 900, x2 = 13110, y2 = 1190 },
            banks = { x = 13100, y = 1200, z = 0 },
            soldiers = 5,
        },
    },
    floodlight = { sprite = "lighting_outdoor_01_51", color = { r = 1.0, g = 0.97, b = 0.85 }, radius = 18 },
    generatorItem = "Base.Generator",
    soldierOutfits = { "ArmyCamoGreen", "ArmyCamoGreen", "ArmyServiceUniform" },
    -- Sirène du poste (minutes de jeu) et horde rabattue sur les berges.
    alarmSound = "VehicleSirenWall",
    alarmMinutes = 20,
    horde = {
        label = "berges",
        ringMin = 25,
        ringMax = 40,
        outfits = { "ArmyCamoGreen", "ArmyCamoGreen", "ArmyServiceUniform" },
        countByIntensity = { 6, 10, 14 },
        noiseRadius = 120,
        noiseVolume = 100,
    },
}

-- Passeur de V (route A sans mod de bateau) : appel au talkie depuis le quai de Brandenburg, une
-- fois le groupe du pont Kinsella coupé ; il arrive à l'aube, il faut tenir le quai puis rester sur le
-- bout du ponton avec le dossier pour embarquer. Même déroulé que l'hélicoptère (Artemis_Extraction).
Story.FERRY = {
    key = "ferry",
    -- Bout du ponton en T (terre ferme) où se tenir ; le bateau arrive sur l'eau, au nord.
    landing = { x = 1637, y = 5577, z = 0 },
    boat = { x = 1637, y = 5570, z = 0 },
    boardRadius = 2,
    holdRadius = 30,
    -- Distance au quai depuis laquelle l'appel radio s'adresse au passeur.
    callRadius = 40,
    slotHour = 5,
    boardSeconds = 10,
    landedMinutes = 30,
    -- Sur la tête du ponton (seule rangée hors de l'eau, x 1632-1643), hors de la zone marquée.
    smoke = { { dx = 4, dy = 0 }, { dx = -4, dy = 0 } },
    waves = {
        label = "passeur",
        ringMin = 30,
        ringMax = 40,
        countRadius = 35,
        minZombiesByIntensity = { 5, 8, 12 },
        batchByIntensity = { 3, 4, 6 },
        maxSpawnedByIntensity = { 18, 30, 45 },
        sprintFromFraction = 0.75,
        outfits = { "Generic01", "Generic02", "Generic03", "Generic04", "Generic05" },
        noiseRadius = 60,
        noiseVolume = 80,
    },
}

-- Acte III, route C : checkpoint au pied du pont Clark Memorial, côté Louisville (décisions de la
-- phase 5, relevés du 2026-10-01 dans les données de carte vanilla 42.21). Le pont est barré en plein
-- fleuve par un barrage vanilla (y 961-964) : c'est la ligne de l'armée. Le mod pose l'enclos de
-- quarantaine et le poste de test sur l'esplanade dallée au sud de la salle de sport, puis ouvre un
-- passage dans le barrage après le test final négatif (Artemis_Quarantine, Artemis_CheckpointSite,
-- Artemis_CheckpointDirector).
Story.CHECKPOINT = {
    -- Cases intérieures de l'enclos (6 x 6, sol dallé, dehors).
    pen = { x1 = 12613, y1 = 1167, x2 = 12618, y2 = 1172, z = 0 },
    -- Grillage vanilla des cages du Knox Boundary Camp : murs nord (88/89 en alternance), ouest
    -- (90/91), poteau d'angle nord-ouest (92).
    fence = { north = { "fencing_01_88", "fencing_01_89" }, west = { "fencing_01_90", "fencing_01_91" },
        corner = "fencing_01_92" },
    -- Portail grillagé (IsoThumpable verrouillé, sans clé en jeu) dans le mur ouest de l'enclos.
    gate = { x = 12613, y = 1170, z = 0, closed = "fixtures_doors_fences_01_128",
        open = "fixtures_doors_fences_01_130", keyId = 714900300 },
    -- Poste de test devant le portail : caisse militaire (kit de prélèvement si ZVirusVaccine est
    -- actif, sinon le test du mod se fait sur la caisse) et spectromètre de ZVirusVaccine à côté.
    post = { x = 12610, y = 1170, z = 0, sprite = SPRITE_MILITARY_CRATE },
    spectrometer = { x = 12610, y = 1169, z = 0, sprite = "demonius_vaccine_01_8" },
    testKit = { "LabItems.LabSyringe", "LabItems.LabSyringe", "LabItems.LabSyringe",
        "Base.AlcoholedCottonBalls", "Base.AlcoholedCottonBalls", "Base.AlcoholedCottonBalls" },
    -- Distance (cases, Chebyshev) au poste pour qu'un test compte.
    testRadius = 3,
    -- Haut-parleur : radio de campagne posée dans l'enclos (annonces, Artemis_CheckpointClient).
    speaker = { x = 12618, y = 1167, z = 0, sprite = "appliances_com_01_0" },
    -- Détenu mort posé au début de la quarantaine ; il se relève après 30 minutes de jeu.
    detainee = { x = 12617, y = 1171, z = 0, outfit = "Generic02" },
    reanimateAtHour = 0.5,
    -- Minutes de jeu pendant lesquelles un test d'entrée négatif ouvre le portail.
    entryValidMinutes = 60,
    -- Plafond de gameplay : une heure de jeu, avec ou sans le dossier.
    hoursWithDossier = 1,
    hoursWithoutDossier = 1,
    -- Passage ouvert dans le barrage vanilla après le test final négatif : objets retirés.
    lane = { x1 = 12598, x2 = 12600, y1 = 961, y2 = 964, z = 0,
        sprites = { "fencing_01_96", "fencing_01_88", "fencing_01_89", "street_decoration_01_28" } },
    -- Au nord du barrage (dans les données vanilla : y ≤ 899 n'existe qu'avec le monde généré).
    exitLine = { x1 = 12590, x2 = 12609, maxY = 958 },
    -- Vagues de civils autour de l'enclos pendant la quarantaine (Artemis_Waves).
    waves = {
        label = "quarantaine",
        ringMin = 30,
        ringMax = 40,
        countRadius = 25,
        minZombiesByIntensity = { 4, 6, 8 },
        batchByIntensity = { 2, 3, 4 },
        maxSpawnedByIntensity = { 30, 50, 70 },
        sprintFromFraction = 0.9,
        outfits = { "Generic01", "Generic02", "Generic03", "Generic04", "Generic05" },
        noiseRadius = 50,
        noiseVolume = 60,
    },
}

-- Acte III : balises de fumée verte là où le joueur doit aller pour sortir (demande de l'utilisateur
-- du 2026-10-01), posées une fois le dossier lu (Artemis_BeaconDirector, mod batman_SignalSmoke).
-- « when » : condition de l'étape en cours (Artemis_BeaconDirector.conditions). Cases relevées hors de
-- l'eau dans worldmap.xml, jamais dans une zone d'embarquement.
Story.BEACONS = {
    -- Hélicoptère : bord du champ d'atterrissage (la zone marquée est à 6 cases).
    { id = "heli", x = 12560, y = 4212, z = 0, when = "heli" },
    -- Fleuve avec un mod de bateau : bateaux de V (pied du ponton, quai) et lignes de sortie (rive sud).
    { id = "boatWest", x = 6043, y = 5223, z = 0, when = "boats" },
    { id = "boatEast", x = 12822, y = 1128, z = 0, when = "boats" },
    { id = "exitWest", x = 10, y = 5128, z = 0, when = "boats" },
    { id = "exitNortheast", x = 19785, y = 302, z = 0, when = "boats" },
    -- Fleuve sans mod de bateau : groupe électrogène de Kinsella tant qu'il tourne, puis quai du passeur.
    { id = "kinsella", x = 1500, y = 5406, z = 0, when = "kinsellaLit" },
    { id = "ferry", x = 1638, y = 5590, z = 0, when = "ferry" },
    -- Checkpoint : devant le poste de test, puis, barrage ouvert, au nord du passage.
    { id = "checkpoint", x = 12608, y = 1168, z = 0, when = "checkpoint" },
    { id = "lane", x = 12599, y = 957, z = 0, when = "lane" },
}

-- Acte III : caisse de ravitaillement de V (décision de la phase 6, sans dépendance). Une seule par
-- partie, au premier engagement sur une route (appel de l'hélicoptère ou du passeur accepté, test
-- d'entrée du checkpoint, arrivée au bateau de V) : déposée près de ce point, annoncée (journal,
-- pensée) et marquée d'une fumée verte (Artemis_SupplyDirector, Artemis_BeaconDirector). Cases
-- relevées hors de l'eau, à côté des balises, jamais dans une zone d'embarquement.
Story.SUPPLY = {
    points = {
        heli = { x = 12548, y = 4226, z = 0 },
        ferry = { x = 1638, y = 5594, z = 0 },
        checkpoint = { x = 12606, y = 1173, z = 0 },
        boatWest = { x = 6045, y = 5226, z = 0 },
        boatEast = { x = 12819, y = 1127, z = 0 },
    },
    -- Distance au bateau de V qui vaut engagement sur le fleuve (cases).
    boatRadius = 15,
    sprite = SPRITE_MILITARY_CRATE,
    -- Objets absents (autre version du jeu) ignorés à la pose.
    items = { "Base.FirstAidKit", "Base.Bandage", "Base.Bandage", "Base.Disinfectant", "Base.Pills",
        "Base.TinnedBeans", "Base.CannedChili", "Base.Bullets9mmBox", "Base.ShotgunShellsBox", "Base.556Box" },
}

function Story.get(chapterId)
    return chapterId and Story.CHAPTERS[chapterId] or nil
end

-- Groupe de registre d'une pose (voir « placements » ci-dessus).
function Story.groupOf(chapterId, placement)
    return placement.group or chapterId
end

-- Groupes séparés après coup : { [nouveau groupe] = ancien groupe }. Dans une partie où l'ancien
-- groupe est déjà posé, le nouveau l'est aussi (Artemis_Plot.normalize), sinon il serait reposé en
-- double. Les soldats du bunker étaient dans le groupe du chapitre jusqu'à la phase 2c.
Story.SPLIT_GROUPS = { ch1_bunker_soldiers = "ch1_bunker" }

-- Le groupe ne contient-il que des objets à ramasser (documents, preuves, pose « items ») ? Un
-- redémarrage de l'opération les repose (Artemis_Plot.reset) ; les autres poses (zombies, groupe
-- électrogène, radio, décor) restent dans le monde et ne sont pas refaites.
function Story.isPickupGroup(group)
    local isFound = false
    for chapterId, chapter in pairs(Story.CHAPTERS) do
        for _, placement in ipairs(chapter.placements) do
            if Story.groupOf(chapterId, placement) == group then
                if placement.kind ~= "items" then
                    return false
                end
                isFound = true
            end
        end
    end
    return isFound
end

-- Tous les groupes de pose du chapitre sont-ils enregistrés dans placed ?
function Story.isFullyPlaced(chapterId, placed)
    local chapter = Story.get(chapterId)
    if chapter == nil or type(placed) ~= "table" then
        return false
    end
    for _, placement in ipairs(chapter.placements) do
        if not placed[Story.groupOf(chapterId, placement)] then
            return false
        end
    end
    return true
end

return Story
