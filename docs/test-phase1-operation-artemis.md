# Protocole de test — Opération Artemis, phase 1 (acte I)

- Mod : `batman_OperationArtemis` (dossier `C:\Users\cyber\Zomboid\Workshop\OperationArtemis\Contents\mods\batman_OperationArtemis`, variante `42.21`)
- Build visée : **42.21**. Vérifier en tête de `console.txt` la version réellement lancée.
- Date du protocole : 2026-09-27. Conception : [conception-operation-artemis.md](conception-operation-artemis.md).
- Durée estimée : 45 min pour les tests essentiels (T01 à T09), 45 min à 1 h de plus pour les tests complémentaires (T10 à T17).

Ce protocole vérifie en jeu ce qui n'a été contrôlé que dans les fichiers du jeu : chargement du mod, carnet dans le cadavre d'un soldat, lecture, chaîne radio, détection de l'écoute, mise en scène (fondu, pensées, sons, panique, sprinteurs), options et sauvegarde.

## 0. Session de test en cours

| Élément | Valeur |
|---|---|
| Date | 2026-09-27, début vers 16:47 |
| Sauvegarde | `Saves/Sandbox/2026-09-27_16-54-22` (partie neuve, option A) |
| Build | 42.21 |
| Options Artemis relevées dans `map_sand.bin` | `DebugMode` = oui ; `NoteChance` = 4 ; `RadioFrequency` = 108.0 ; `DramaIntensity` = Normale ; `SiegeNightControl` = 2 (suspendre pendant l'enquête) |
| Siege Night | actif, premier siège au jour 5 (`State: IDLE | Next: day 5`) |
| Surveillance | `console.txt` suivi en direct ; copie complète dans le scratchpad de la session Claude |

Résultats cochés au fil de la session à partir de `console.txt` et de tes retours. Une case cochée sans ton retour ne porte que sur ce que le journal peut prouver ; les effets visuels et sonores restent à confirmer par toi.

### Bilan de la session du 2026-09-27

**17 tests sur 17 validés**, avec trois réserves : T02 à reconfirmer sans `DebugMode` ; T11 sans observation du démarrage par la lecture ; T17 étapes 3, 4 et 6 non testées. Aucune erreur Lua liée au mod sur l'ensemble de la session.

Corrections et évolutions faites **pendant** la session, toutes revérifiées en jeu :

| Constat en jeu | Correction |
|---|---|
| T04 : le texte du carnet n'apparaissait qu'après un clic sur le bouton « transcription » | `client/Artemis_NoteReader.lua` ouvre la transcription automatiquement |
| T12 : radio muette avant le carnet, jugée trop « scriptée » | Station de chiffres seule avant la lecture, diffusion complète ensuite |
| T08/T10 : aucun moyen de voir le comptage des soldats | Diagnostic en mode debug (`soldat compte : N sur 30`, tenue militaire non reconnue) |
| T14 : options changées en cours de partie ignorées | Lecture des options enregistrées (`getSandboxOptions():getOptionByName`) |
| T14 : fondu visible avec « Effets à l'écran » décoché | Retour à l'image seulement après un vrai fondu au noir |

Constats hors mod : croix X des fenêtres de debug vanilla (`ISButton … __call`), accents perdus par `print` dans `console.txt`, double `OnZombieDead` à la mort par le feu confirmé en jeu.

## 1. Préparation

### Règles de sécurité
- **Ne jamais tester sur ta partie principale.** Utiliser une partie neuve, ou une **copie** de sauvegarde (copier le dossier `C:\Users\cyber\Zomboid\Saves\Sandbox\<partie>`).
- Redémarrer **complètement** le jeu après toute modification du mod ou des options : un rechargement partiel peut garder un état trompeur.

### Deux façons de tester

| | A. Partie de test neuve (recommandée) | B. Copie d'une sauvegarde existante |
|---|---|---|
| Intérêt | Toutes les options réglables à la création | Teste le mod avec ta liste de mods réelle |
| Options sandbox | Page « Opération Artemis » à la création de la partie | Valeurs par défaut (les options d'une partie existante ne se changent pas facilement) |
| Menu de debug | Option `DebugMode` = oui | Lancer le jeu avec `-debug` (Steam → Propriétés → Options de lancement) |
| Mods optionnels | À activer à la création (liste ci-dessous) | Ceux de ta liste habituelle |
| Tests possibles | T01 à T17 | T01 à T09, T11, T13 |

Idéal : **A** pour valider le mod, puis **B** pour vérifier la cohabitation avec tes autres mods.

### Activer le mod
1. Menu principal → **Mods** : activer « batman_Operation Artemis ». Pour la copie de sauvegarde, l'activer aussi dans la liste des mods de cette sauvegarde.
2. Pour une partie neuve : **Sandbox** → page **Opération Artemis**, réglages de test :

| Option | Valeur de test | Défaut |
|---|---|---|
| Activer l'Opération Artemis | oui | oui |
| Chance de trouver le carnet (sur 100) | **100** (pour T08) | 4 |
| Carnet garanti après N soldats | 30 | 30 |
| Jour minimum du carnet | 0 | 0 |
| Nouveau carnet après N jours | 7 | 7 |
| Fréquence de la radio Artemis (MHz) | 108.0 | 108.0 |
| Intensité dramatique | **Normale** | Normale |
| Effets à l'écran | oui | oui |
| Siege Night pendant l'opération | **Suspendre jusqu'au dossier, dès le début** | Suspendre pendant l'enquête (actes I et II) |
| Mode debug | **oui** | non |

3. Point d'apparition conseillé : **près d'une zone militaire** (par exemple Fallas Lake, ou la route au sud de Louisville), pour croiser des zombies en tenue militaire au test T08.

### Mods optionnels à activer dans la partie de test (option A)

La phase 1 n'utilise encore aucun de ces mods. Les activer dès maintenant dans la partie de test sert à deux choses :
- **préparer le monde des phases suivantes** : les cartes (Crossroads-Checkpoint, Tikitown, AnruisiTown) doivent être présentes **dès la création de la partie**, sinon leurs lieux risquent de manquer dans les zones déjà générées ;
- **vérifier dès maintenant qu'ils cohabitent** avec Opération Artemis (test T16).

Tous sont des versions **Build 42** installées dans ton Workshop ; leurs dépendances aussi. Dans le gestionnaire de mods, activer chaque mod **et** ses dépendances (colonne « À activer aussi »).

| Mod (nom affiché) | `id` à activer | Workshop | Variante B42 | À activer aussi | Sert à (phase prévue) |
|---|---|---|---|---|---|
| Siege Night | `SiegeNight` | 3669589584 | `42` | — | Pression de fond entre les actes, sièges plus fréquents après le dossier (phase 6) |
| BoatCore MP | `BoatCoreMP` | 3781735032 | `42` (min 42.20) | — | Route du Fleuve : bateaux sur l'Ohio (phase 5) |
| BoatCore Boats B42 MP | `WorkingMotorboatB42MP` | 3781923154 | `42` (min 42.20) | `BoatCoreMP` | Bateaux à moteur et quais (phase 5) |
| Aquatsar Yacht Club | `AquatsarYachtClubB42` | 3646414716 | `42.17` | `tsarslib` (3402491515) | Autres bateaux reconnus pour le Fleuve (phase 5) |
| Helicopter Event Expansion Framework | `HelicopterEventExpansionFramework` | 3672792485 | `42.13.0` (**à tester**) | — | Son du rotor qui approche de la zone d'atterrissage (phase 4) |
| Zombie Virus Vaccine | `ZVirusVaccine42BETA` | 3615135168 | `42.20` (**annoncé jusqu'à 42.20**) | — | Test sanguin du checkpoint, échantillons, fin « remède » (phases 2 et 5) |
| Research Lab Intern | `ResearchLabInternProfession` | 3615135168 | `42.20` | `ZVirusVaccine42BETA` | Objets et lore de labo (phase 2, facultatif) |
| Knox Detection Kit | `KnoxDetectionKit` | 3688879406 | `42` | — | Détection d'infection (phase 5, facultatif) |
| Science, Bitch! | `ZScienceSkill` | 3659195975 | `42.13` (**à tester**) | `zdk` (3690770492) | Analyse d'échantillons au microscope (phase 2, facultatif) |
| Computer Mod | `ComputerModkum` | 3725497089 | `42` (min 42.20) | — | Mails et notes d'indices sur les ordinateurs (phase 2) |
| Computer Mod: Laptop Addon | `ComputerModLaptop` | 3798992436 | `42` (min 42.20) | `ComputerModkum` | Portable de chercheur à emporter (phase 2) |
| Dead Man's Dossier | `DeadMansDossier` | 3675740871 | `42` | — | Marqueurs de lieu sur la carte (phase 2) |
| Crossroads-Checkpoint *(carte)* | `Crossroads-Checkpoint` | 3686455777 | `42.0` | `UnofficialMappersCommunityTilePack`, `melos_tiles_for_miles_pack`, `simonMDsTiles`, `PertsPartyTiles` | Variante du chapitre 1 : checkpoint, bunker et labo (phase 2) |
| Tikitown *(carte)* | `tikitown` | 3037854728 | `42` | `tikitown_tiles` (3046728955) | Labo secret souterrain, chapitre 4 bonus (phase 2) |
| AnruisiTown *(carte)* | `AnruisiTown` | 3659676359 | `42` | — | Autre labo possible, chapitre 4 bonus (phase 2) |
| Knox Airdrop | `KnoxAirdrop` | 3799630525 | `42` | — | Ravitaillement largué avant l'extraction (phase 6) |
| Railroader | `Railroader` | 3774360904 | `42` | — | Traverser le comté en train (phase 6, facultatif) |

Précautions pour la partie de test :
- **Siege Night** : rien à régler dans ses options. Opération Artemis suspend lui-même ses sièges automatiques et ses mini-hordes, selon l'option « Siege Night pendant l'opération » (page Opération Artemis). Pour les tests, choisir **« Suspendre jusqu'au dossier, dès le début »** : aucun siège ne viendra perturber la phase 1. Les options de Siege Night ne sont jamais modifiées ; seule la partie en cours est concernée.
- **Cartes** : les activer **avant** de créer la partie, et vérifier qu'elles apparaissent sur la carte du monde (M) aux coordonnées de `.claude/pz-knowledge/knox-geography.md`.
- Les versions marquées « à tester » ou « annoncé jusqu'à 42.20 » ciblent une Build plus ancienne que 42.21. Noter toute erreur qu'elles produisent au chargement, même sans lien avec Artemis.
- Le « Tikitown Power Plant » (`TikitownPower`) n'est pas nécessaire au scénario.

### Lire les résultats
- Journal du jeu : `C:\Users\cyber\Zomboid\console.txt`. Toutes les lignes du mod commencent par **`[OperationArtemis]`**.
- `console.txt` peut contenir des octets nuls qui gênent la recherche. Pour filtrer, en PowerShell :
  ```powershell
  Select-String -Path "$env:USERPROFILE\Zomboid\console.txt" -Pattern "OperationArtemis|Artemis|ERROR" | Select-Object -Last 60
  ```
- Chercher aussi les erreurs Lua qui citent un fichier `Artemis_` (par exemple `Artemis_Radio.lua`).
- Journal de l'opération dans le jeu : touche **K** (modifiable dans Options → Mods), ou clic droit au sol → « Journal : Opération Artemis ».

## 2. Tests essentiels

Pour chaque test : cocher **OK** ou **KO** et noter ce qui diffère.

### T01 — Chargement du mod
- **Étapes** : lancer la partie, attendre la fin du chargement.
- **Attendu dans `console.txt`** :
  - `[OperationArtemis] chaine radio creee sur 108.0 MHz`
  - `[OperationArtemis] etat charge : acte 0, revision 1` (le numéro de révision peut être plus grand sur une sauvegarde déjà testée)
  - aucune erreur mentionnant `Artemis` (chercher aussi les lignes `f:0` au chargement).
- **Résultat** : ☑ OK ☐ KO — session du 2026-09-27 : `chaine radio creee sur 108.0 MHz` et `etat charge : acte 0, revision 1`, aucune erreur liée au mod. Remarque : les accents des messages du mod s'affichaient `�` dans `console.txt` (le jeu les remplace à l'écriture). **Depuis le 2026-09-27, les messages du mod sont écrits sans accents** ; ce protocole cite leur forme exacte.

### T02 — Journal caché avant l'opération
- **Étapes** : partie **sans** mode debug (option `DebugMode` = non, jeu lancé sans `-debug`). Appuyer sur K ; faire un clic droit au sol.
- **Attendu** : rien ne s'ouvre et aucune entrée « Opération Artemis » n'apparaît dans le menu. Le scénario reste une surprise.
- **Résultat** : ☑ OK ☐ KO — déclaré OK par l'utilisateur le 2026-09-27. À reconfirmer dans une partie **sans** debug : la partie de test a `DebugMode` = oui, ce qui rend le journal visible dès l'acte 0.
- Remettre ensuite le mode debug pour les tests suivants.

### T03 — Menu de debug
- **Étapes** : clic droit au sol.
- **Attendu** : les entrées « Journal : Opération Artemis » et « Opération Artemis (debug) », avec le sous-menu « Démarrer l'opération », « Passer à l'acte suivant », « Réinitialiser l'état » et « Recevoir le carnet Artemis ». K ouvre le journal : « En sommeil », « Aucune entrée pour l'instant. ».
- **Résultat** : ☑ OK ☐ KO — déclaré OK par l'utilisateur le 2026-09-27.

### T04 — Le carnet et sa lecture
- **Étapes** :
  1. Debug → « Recevoir le carnet Artemis ».
  2. Examiner l'objet dans l'inventaire.
  3. Clic droit sur le carnet → **Inspecter** (ou double-clic).
  4. La transcription (texte du carnet) s'affiche directement. Le bouton de carnet en bas à gauche permet de revenir à la page, puis au texte.
- **Attendu** :
  - Objet « **Carnet de liaison taché de sang** », icône de note, poids 0,1.
  - Fenêtre de document : page crème avec « CARNET DE LIAISON / 2e Bataillon - Cie C » et un trait rouge sombre. Au milieu de la page, **écrit à la main** à l'encre bleue, légèrement penché : « Écoute le 108.0. / La nuit. », puis plus bas à droite la signature « — V. » (en anglais : « Listen to 108.0. / At night. »). Depuis le 2026-09-27, la fréquence n'est plus imprimée en bas de page.
  - **À vérifier après la modification du 2026-09-27** : les accents (É) et le tiret (—) s'affichent, le texte ne déborde pas de la page, l'inclinaison est discrète. Un carnet créé **avant** la modification garde l'ancienne page : en recevoir un nouveau par le menu de debug.
  - Texte défilant : les entrées du 6 au 11 juillet 1993, dont « Si ça tourne mal, écoute le **108.0**. La nuit. D'abord les chiffres, ensuite la voix. Note tout. - V. ».
  - Aucune erreur `RICH TEXT ERROR` à l'écran.
- **Suivi de la session du 2026-09-27** : page affichée conforme (capture de l'utilisateur : « CARNET DE LIAISON / 2e Bataillon - Cie C », trait rouge, « 108.0 » en bas). Le texte long n'apparaît qu'en cliquant sur l'icône de carnet en bas à gauche de la fenêtre (bouton vanilla `readNewspaper`, `PrintMedia.lua:225-250`). L'utilisateur confirme que le texte s'affiche après clic. **Amélioration demandée et écrite** : `client/Artemis_NoteReader.lua` ouvre la transcription automatiquement pour le carnet Artemis. **À revérifier après redémarrage du jeu** : la transcription doit s'afficher sans clic.
- **Résultat** : ☑ OK ☐ KO — après redémarrage, l'utilisateur confirme que la transcription s'affiche directement (`client/Artemis_NoteReader.lua`).

### T05 — Scène de lecture et début de l'opération
- **Étapes** : aller au bout de la lecture du carnet (T04), sans l'interrompre.
- **Attendu** :
  - `console.txt` : `[OperationArtemis] carnet lu : l'operation commence (acte I)`.
  - Fondu au noir d'environ une seconde, puis retour à l'image.
  - Pensée au-dessus du personnage : « Qui écrit ça sur un soldat... ? ».
  - Légère montée de panique (icône d'humeur).
  - Journal (K) : « **Acte I : le Signal** », description citant « le **108.0** MHz » et l'orage, entrée « Jour N : J'ai trouvé un carnet sur un soldat mort… fréquence : 108.0. ».
- **Vérifier aussi** : relire le carnet ne doit **rien** redéclencher (pas de nouveau fondu, pas de nouvelle ligne `carnet lu`).
- **Résultat** : ☑ OK ☐ KO — déclaré OK par l'utilisateur le 2026-09-27 ; `console.txt` : `carnet lu : l'operation commence (acte I)` (deux fois, avant et après un `debugReset`), sans erreur.

### T06 — La radio émet après la lecture
- **Étapes** :
  1. Prendre une radio FM (radio de poche ou de salon) et des piles si besoin.
  2. L'allumer, volume au-dessus de 0, régler sur **108,0 MHz**.
  3. Attendre au plus 10 minutes de jeu (accélérer le temps si besoin).
- **Attendu** : le nom de canal « **ARTEMIS** » s'affiche dans la fenêtre de la radio. Lignes en vert pâle, dans l'ordre : parasites, « Sept. Un. Quatre. Neuf... », « Ici relais Artemis. Secteur Fallas ne répond plus… », parasites, « À quiconque reçoit ce message... le poste avancé, près de Fallas Lake. Le badge… », les chiffres, parasites. La diffusion recommence en boucle.
- **Suivi de la session du 2026-09-27** : réception prouvée par `console.txt` — `signal entendu : acte II` (une ligne clé portant le code a été reçue sur 108,0). Affichage de la chaîne (nom ARTEMIS, lignes vertes) à confirmer par l'utilisateur.
- **Résultat** : ☑ OK ☐ KO — l'utilisateur confirme la réception.

### T07 — Premier signal : passage à l'acte II et mise en scène

> **Remplacé le 2026-09-28** : le sprinteur de la première écoute a été retiré, car il n'avait aucune cause dans le monde du jeu. Le cri de la radio est désormais un vrai bruit, qui attire les zombies selon le volume de la radio. Voir le test A07 de `test-phase2a-operation-artemis.md`. Le résultat ci-dessous reste celui de la version testée.
- **Contexte** : suite directe de T06, radio **tenue en main**, de préférence **la nuit**, **par temps calme** (un orage brouille le signal, c'est voulu).
- **Attendu, dès la ligne « Ici relais Artemis… » ou « À quiconque… »** :
  - `console.txt` : `[OperationArtemis] signal entendu : acte II`.
  - Claquement de parasites, puis un **cri d'homme dans la radio** ; environ 3 s de silence ; un **hurlement au loin, dehors** ; forte panique et **battement de cœur** ; pensée « Ce cri... ça venait de dehors. ».
  - Journal : « **Acte II : l'Enquête** », entrée « Le 108.0 émet encore. Une voix parle d'un poste avancé près de Fallas Lake, et d'un badge. ».
  - Environ **15 s** plus tard : `[OperationArtemis] scene : 1 sprinteur(s) sur 1`, et **un zombie en tenue militaire** qui arrive **en courant** vers le personnage depuis une trentaine de cases.
- **À noter si KO** : le temps écoulé, la radio utilisée, l'heure de jeu, la météo, et si le personnage était dehors ou dans un bâtiment. Si la ligne indique « 0 sprinteur(s) sur 1 », aucune case libre en extérieur n'a été trouvée autour du personnage : réessayer dehors, dans une zone dégagée.
- **Suivi de la session du 2026-09-27** : `signal entendu : acte II`, puis `scene : 1 sprinteur(s) sur 1` environ 900 images plus tard (≈ 15 s, conforme). Sons, panique, pensée et arrivée du sprinteur à confirmer par l'utilisateur.
- **Résultat** : ☑ OK ☐ KO — l'utilisateur confirme les effets (sons, panique, pensée) et l'arrivée du sprinteur (supprimé ensuite par erreur en debug ; nouvel essai possible : Réinitialiser → Démarrer → Passer à l'acte suivant).

### T08 — Le carnet sur un vrai soldat
- **Préparation** : partie neuve avec `Chance de trouver le carnet` = 100. Ou, sur la partie en cours : debug → « Réinitialiser l'état » (le carnet peut alors réapparaître, voir T12).
- **Étapes** : tuer un zombie en **tenue militaire** (camouflage vert ou désert, uniforme de service, instructeur) **à l'arme blanche ou à feu**, puis fouiller son corps.
- **Attendu** :
  - `console.txt` : `[OperationArtemis] carnet Artemis place sur un zombie en tenue ArmyCamoGreen` (ou une autre tenue militaire).
  - Le carnet est **dans l'inventaire du cadavre**.
  - Les zombies non militaires ne portent jamais de carnet.
- **Résultat** : ☑ OK ☐ KO — session du 2026-09-27, `NoteChance` = 4 : les soldats sont bien comptés (révisions de l'état qui augmentent), puis `carnet Artemis place sur un zombie en tenue ArmyCamoGreen` ; le carnet trouvé sur le corps a été lu (`carnet lu : l'operation commence (acte I)`). Ajout d'un diagnostic en mode debug (`soldat compte : N sur 30`, tenue militaire non reconnue) pour les prochains tests.

### T09 — Sauvegarde et rechargement
- **Étapes** : en acte II, sauvegarder, quitter vers le menu, recharger la partie.
- **Attendu** :
  - `console.txt` : `etat charge : acte 2, revision N`.
  - **Aucune scène rejouée** au chargement (ni fondu, ni cri, ni sprinteur).
  - Le journal a gardé l'acte II et ses entrées.
  - La radio 108,0 reprend sa diffusion dans les 10 minutes de jeu.
- **Suivi de la session du 2026-09-27** : rechargement en acte I vérifié dans `console.txt` — `etat charge : acte 1, revision 5`, chaîne radio recréée. Puis rechargement en **acte II** : `etat charge : acte 2, revision 32`, chaîne radio recréée, `Siege Night : sieges automatiques suspendus (acte 2)`, aucune ligne `scene :` au chargement. À confirmer par l'utilisateur : aucun effet à l'écran au chargement, reprise de la radio.
- **Résultat** : ☑ OK ☐ KO — confirmé par l'utilisateur et par `console.txt` : sur les 746 lignes suivant le chargement en acte II, seules `etat charge : acte 2` et `suspendus (acte 2)` concernent le mod ; aucune ligne `scene :`, aucune erreur liée à Artemis. La reprise de la radio n'est pas visible dans le journal (pas de trace à la ré-émission) : constatée par l'utilisateur.

## 3. Tests complémentaires

### T10 — Mort par le feu (pas de carnet, par conception)
- **Préparation** : `Chance` = 100, opération réinitialisée.
- **Étapes** : tuer un zombie militaire **par le feu** (cocktail Molotov, zombie qui brûle).
- **Attendu** : **aucun** carnet, et aucune ligne `carnet Artemis place`. Le cadavre d'un zombie en feu brûle avec son inventaire : le mod ne choisit donc pas ce zombie. Le soldat suivant tué autrement peut porter le carnet.
- **Suivi de la session du 2026-09-27** : premier essai non concluant (opération en acte II : aucun carnet ne peut apparaître, feu ou non). Procédure fiable avec le diagnostic debug : réinitialiser (acte 0), tuer un soldat normalement → `debug : soldat compte : 1 sur 30` ; tuer un soldat par le feu → aucune ligne `soldat compte` pour lui.
- **Résultat** : ☑ OK ☐ KO — session du 2026-09-27, acte 0 après `debugReset` : 15 soldats `ArmyCamoDesert` tués **par le feu** → aucun carnet et aucune ligne `soldat compte` (écartés avant le comptage) ; Dead Man's Dossier a vu **deux** `OnZombieDead` par soldat brûlé (double déclenchement du feu confirmé en jeu). Puis un soldat tué normalement → `carnet Artemis place sur un zombie en tenue ArmyCamoGreen` : le comptage fonctionne.

### T11 — Personnage illettré
- **Étapes** : créer un personnage avec le trait **Illettré**, recevoir le carnet (debug), l'inspecter.
- **Attendu** : l'action « Inspecter » est disponible et la lecture démarre l'opération comme en T05.
- **Résultat** : ☑ OK ☐ KO — l'utilisateur confirme que le personnage illettré peut inspecter et lire le carnet (tag `base:picture`). Opération déjà en acte II pendant le test : le démarrage par cette lecture n'a pas été observé (même chemin de code que T05, validé).

### T12 — Radio avant la lecture : station de chiffres
- **Étapes** : debug → « Réinitialiser l'état » (acte 0), puis radio sur 108,0 MHz pendant 20 minutes de jeu.
- **Attendu** (depuis l'évolution du 2026-09-27) : la chaîne ARTEMIS émet une **station de chiffres** seule (parasites, « Sept. Un. Quatre. Neuf… », « Huit. Huit. Trois… Fin de transmission. »), sans « relais Artemis » ni appel au badge. Le journal de l'opération reste à l'acte 0 (aucun `signal entendu`). Après lecture du carnet, la diffusion complète remplace la station de chiffres dans les minutes qui suivent.
- **Résultat** : ☑ OK ☐ KO — conforme à la conception de départ (chaîne muette avant la lecture). **Retour de l'utilisateur** : trop « scripté », un joueur doit pouvoir écouter le 108,0 à tout moment. Évolution décidée le 2026-09-27 : avant la lecture, station de chiffres seule (sans code, sans révélation) ; diffusion complète après. Test à refaire après la modification (voir l'attendu ci-dessous).
- **Retest après évolution** : ☑ OK — l'utilisateur confirme la station de chiffres seule à l'acte 0 (session du 2026-09-27, après redémarrage).

### T13 — Radio posée, autoradio, distance
- **Étapes** :
  1. Réinitialiser, relire le carnet (acte I).
  2. Poser une radio allumée sur 108,0 **à côté** du personnage (moins de 5 cases, même étage) et attendre une ligne clé.
  3. Recommencer (réinitialiser, relire) avec la radio **à plus de 5 cases** ou à un autre étage.
  4. Recommencer avec l'**autoradio** d'un véhicule, personnage à bord.
  5. Recommencer avec un **talkie-walkie** en main, réglé sur 108,0 par un préréglage (fenêtre de la radio → ajouter un préréglage, curseur sur 108.0).
- **Attendu** : passage à l'acte II dans les cas 2, 4 et 5 ; **pas** de passage dans le cas 3 (le personnage n'est pas à portée).
- **Suivi de la session du 2026-09-27** : cas 2 (radio posée à moins de 5 cases) ☑ OK et cas 3 (radio posée à plus de 5 cases) ☑ OK, confirmés par l'utilisateur ; `console.txt` ne montre qu'un seul `signal entendu : acte II` (f:51271), donc aucun déclenchement par la radio éloignée. Cas 4 (autoradio) ☑ OK : après `debugReset` et relecture du carnet, `signal entendu : acte II` (f:58381) puis `scene : 1 sprinteur(s) sur 1`, personnage à bord. Cas 5 (talkie-walkie) ☑ OK, testé plus tôt dans la session selon l'utilisateur.
- **Résultat** : ☑ OK ☐ KO — les cinq cas validés (radio en main, posée près, posée loin sans déclenchement, autoradio, talkie-walkie).

### T14 — Intensité dramatique et effets à l'écran
- **Étapes** : trois parties neuves courtes (ou trois essais), avec « Intensité dramatique » sur Faible, Normale puis Forte ; refaire T05 et T07. Puis un essai avec « Effets à l'écran » = non.
- **Attendu** :
  - Faible : `scene : 0 sprinteur(s) sur 0`, aucun sprinteur ; sons, panique et pensées présents.
  - Normale : 1 sprinteur. Forte : 3 sprinteurs.
  - « Effets à l'écran » = non : ni fondu ni pensée ; les sons, la panique et les sprinteurs restent.
- **Suivi de la session du 2026-09-27** : « Effets à l'écran » décoché **en cours de partie** (éditeur d'options en jeu) : les effets restaient actifs. Cause : le mod lisait `SandboxVars`, que l'éditeur en jeu ne met pas à jour en solo. **Corrigé** : `Artemis_Config` lit d'abord les options enregistrées (`getSandboxOptions():getOptionByName`). À retester après redémarrage du jeu ; les options pourront alors être changées à la volée.
- **Après redémarrage (correction chargée)** : intensité **Faible** réglée à la volée → `scene : 0 sprinteur(s) sur 0` (f:4546) ✓. Intensité **Forte** → `scene : 3 sprinteur(s) sur 3` (f:8760) ✓, les trois ont trouvé une case d'apparition. « Effets à l'écran » = non : **effet encore visible** selon l'utilisateur. Cause trouvée : le retour à l'image (`UIManager.FadeIn`) était toujours lancé, et il part d'un écran noir, donc il produisait lui-même un fondu. **Corrigé** : `fadeIn` seulement après un `fadeOut` joué par le mod (`Artemis_StagingFX`). À retester après redémarrage. Rappel : l'option ne couvre que les fondus et les pensées ; sons, panique et sprinteurs restent.
- **Résultat** : ☑ OK ☐ KO — après la correction du fondu, l'utilisateur confirme qu'avec « Effets à l'écran » décoché il n'y a plus d'effet visuel ; intensités Faible (0 sprinteur) et Forte (3 sprinteurs) validées dans `console.txt`, options changées à la volée.

### T15 — Fréquence réglable et conflit
- **Étapes** :
  1. Partie neuve avec « Fréquence de la radio Artemis » = **107.6** (fréquence déjà prise par la chaîne vanilla « Unknown Frequency »).
  2. Partie neuve avec une fréquence libre, par exemple **131.8** (captable seulement au talkie-walkie ou à la radio amateur).
- **Attendu** :
  1. `console.txt` : `[OperationArtemis] ERREUR : chaine radio non creee sur 107.6 MHz : frequence deja prise par une autre chaine ; en choisir une autre dans les options sandbox`.
  2. `chaine radio creee sur 131.8 MHz`. Un carnet reçu **après** le chargement cite **131.8** (texte et phrase manuscrite de la page) ; le journal cite 131.8 ; le signal est reçu sur 131,8 avec un talkie-walkie.
- **Suivi de la session du 2026-09-27** : cas 1 ☑ OK — fréquence changée à 107.6 puis partie rechargée : `ERREUR : chaine radio non creee sur 107.6 MHz : frequence deja prise par une autre chaine ; en choisir une autre dans les options sandbox`, et le reste du mod se charge normalement (`etat charge : acte 2`, Siege Night suspendu). Cas 2 ☑ OK — fréquence 131.8 : `chaine radio creee sur 131.8 MHz` ; carnet et journal citent 131.8 (confirmé par l'utilisateur) ; signal capté au talkie-walkie sur 131,8 (`signal entendu : acte II`, f:3145) puis `scene : 1 sprinteur(s) sur 1`.
- **Résultat** : ☑ OK ☐ KO — conflit signalé (107.6) et fréquence libre fonctionnelle (131.8). Remettre ensuite 108.0 pour une partie normale.

### T16 — Cohabitation avec les mods optionnels (option A)
- **Préparation** : partie de test A avec les mods optionnels de la section 1 activés.
- **Étapes** : refaire T01, T04, T05, T06 et T07 dans cette partie.
- **Attendu** :
  - `chaine radio creee sur 108.0 MHz` : aucun de ces mods n'occupe la fréquence ;
  - `[OperationArtemis] Siege Night : sieges automatiques suspendus (acte 0)` au chargement, avec l'option « Suspendre jusqu'au dossier, dès le début » ; aucun siège ni mini-horde de Siege Night pendant les tests, même après le jour 5 ;
  - aucune erreur qui cite un fichier `Artemis_` ;
  - le carnet, la lecture, la radio et la scène du premier signal fonctionnent comme sans ces mods.
  - Les erreurs propres aux autres mods sont à relever à part : elles ne concernent pas Artemis, mais serviront pour les phases suivantes.
- **Résultat** : ☑ OK ☐ KO — session du 2026-09-27 : `console.txt` montre le chargement de 19 mods optionnels sur 20 (Siege Night, BoatCore MP et Motorboat, Aquatsar + tsarslib, HEF, Zombie Virus Vaccine + Research Lab Intern, Knox Detection Kit, Science, Bitch! + zdk, Computer Mod + Laptop, Dead Man's Dossier, Crossroads-Checkpoint, Tikitown + tiles, AnruisiTown, Knox Airdrop) ; **Railroader non chargé** (facultatif). `chaine radio creee sur 108.0 MHz`, aucune erreur liée à Artemis, tests T01 à T13 réussis dans cette partie.

### T17 — Pilotage de Siege Night (si Siege Night est actif)
- **Préparation** : partie de test A avec Siege Night actif, sans changer ses options (premier siège au jour 5).
- **Étapes et attendu** :
  1. Option « Siege Night pendant l'opération » = **Suspendre pendant l'enquête** (défaut). Au chargement, acte 0 : **aucune** ligne de suspension ; Siege Night fonctionne normalement. Lire le carnet (acte I) : dans les 10 minutes de jeu, `Siege Night : sieges automatiques suspendus (acte 1)`. Plus aucun siège tant que l'acte vaut 1 ou 2.
  2. Laisser passer plusieurs jours de jeu où un siège était prévu : aucun siège, et le panneau Siege Night (touche H, onglet Siege Night) n'annonce pas « TONIGHT » (la date est repoussée pendant la suspension). Puis debug → « Passer à l'acte suivant » jusqu'à l'acte III : `Siege Night : sieges automatiques retablis (acte 3)`. **Aucun siège de rattrapage le jour même** : le prochain siège est annoncé au plus tôt pour le lendemain.
  3. Option = **Ne pas y toucher** : aucune ligne `Siege Night :` du mod Artemis, et les sièges ont lieu selon les réglages de Siege Night.
  4. Lire le carnet **pendant** un siège (lancé par `!siege start` dans le chat) : la suspension n'a lieu qu'**après** la fin du siège.
  5. Pendant la suspension, taper `!siege start` (en solo, sans chat : touches de debug de Siege Night, Pavé 0 puis Pavé 2 deux fois, Verr. Num activé) : `Siege Night : siege lance pendant la suspension, sieges rouverts jusqu'a sa fin`. Le siège se déroule normalement (vagues, zombies, aube), puis `sieges automatiques suspendus` revient dans les 10 minutes de jeu qui suivent sa fin.
  6. Sauvegarder et recharger : les options de Siege Night (page Siege Night) sont inchangées.
- **Suivi de la session du 2026-09-27** : étape 1 vérifiée dans `console.txt` — `Siege Night : sieges automatiques suspendus (acte 1)` peu après `carnet lu` (mode 2, défaut). Au rechargement suivant (jeu relancé en `-debug`), suspension **réappliquée dès le chargement** : `Siege Night : sieges automatiques suspendus (acte 1)` juste après `etat charge : acte 1`. Cycle complet observé ensuite : `debugReset` → `sieges automatiques retablis (acte 0)` (mode 2 : pas de suspension à l'acte 0), puis `debugStart` et `debugAdvance` → `suspendus (acte 2)`. Étape 2 ☑ : jour 5 passé pendant la suspension sans aucun siège ; passage à l'acte III → `sieges automatiques retablis (acte 3)` (f:16478), aucun siège de rattrapage, panneau Siege Night : prochain siège dans 5 jours (date repoussée d'un cycle). Étape 5 : en solo (pas de chat), siège lancé par les touches de debug de Siege Night (Pavé 0, puis Pavé 2 deux fois) pendant la suspension en acte I → `siege lance pendant la suspension, sieges rouverts jusqu'a sa fin` dans la même image que `ACTIVE`, puis apparition des vagues (`SPAWN DIAG … phase=SURGE`). Retour de la suspension ☑ : fin du siège (`DAWN->IDLE`, f:43249) puis `sieges automatiques suspendus (acte 1)` à f:43286.
- **Résultat** : ☑ OK ☐ KO — étapes 1, 2 et 5 validées (suspension, aucun siège au jour 5, pas de rattrapage à l'acte III, siège manuel pendant la suspension puis retour de la suspension). **Non testés** (faible risque) : étape 3 (« Ne pas y toucher »), étape 4 (carnet lu pendant un siège), étape 6 (options de Siege Night inchangées après rechargement).

## 4. Récapitulatif

| Test | Sujet | Résultat | Remarques |
|---|---|---|---|
| T01 | Chargement | ☑ OK ☐ KO | Accents illisibles dans `console.txt` (cosmétique) |
| T02 | Journal caché | ☑ OK ☐ KO | À reconfirmer sans `DebugMode` |
| T03 | Menu de debug | ☑ OK ☐ KO | |
| T04 | Carnet et lecture | ☑ OK ☐ KO | Ouverture automatique du texte retirée le 2026-09-29 (demande de l'utilisateur) : le carnet s'ouvre comme les autres documents, texte par le bouton « transcription » vanilla |
| T05 | Scène de lecture, acte I | ☑ OK ☐ KO | |
| T06 | Diffusion radio | ☑ OK ☐ KO | |
| T07 | Premier signal, acte II, sprinteur | ☑ OK ☐ KO | Sprinteur arrivé ~15 s après le signal |
| T08 | Carnet sur un soldat | ☑ OK ☐ KO | Obtenu avec la chance par défaut (4 %) |
| T09 | Sauvegarde et rechargement | ☑ OK ☐ KO | Vérifié en acte I puis en acte II |
| T10 | Mort par le feu | ☑ OK ☐ KO | 15 soldats brûlés écartés, double `OnZombieDead` confirmé |
| T11 | Illettré | ☑ OK ☐ KO | Lecture possible ; démarrage non observé (opération déjà en cours) |
| T12 | Radio avant lecture | ☑ OK ☐ KO | Station de chiffres avant la lecture, retestée OK |
| T13 | Radio posée, autoradio, distance | ☑ OK ☐ KO | Radio posée près/loin, autoradio, talkie-walkie |
| T14 | Intensité et effets à l'écran | ☑ OK ☐ KO | Après 2 corrections : options lues à la volée, fondu entrant conditionné |
| T15 | Fréquence réglable, conflit | ☑ OK ☐ KO | 107.6 refusée avec message, 131.8 captée au talkie |
| T16 | Cohabitation avec les mods optionnels | ☑ OK ☐ KO | 19/20 chargés (Railroader absent), 0 erreur Artemis |
| T17 | Pilotage de Siege Night | ☑ OK ☐ KO | Étapes 3, 4 et 6 non testées |

## 5. Ce qu'il faut me renvoyer

- Ce récapitulatif rempli, avec une phrase par test KO (ce qui s'est passé à la place).
- Le fichier `C:\Users\cyber\Zomboid\console.txt` de la session de test, ou au minimum les lignes `[OperationArtemis]` et toute erreur qui cite un fichier `Artemis_`.
- Si possible, une capture de la fenêtre du carnet (T04) et de la radio (T06).
- La liste des mods actifs pendant le test si ce n'est pas ta liste habituelle.

## 6. Hors périmètre de ce test

- Le **multijoueur** : la logique est prévue pour, mais la phase 1 est testée en solo d'abord.
- Les **effets du trait Sourd** : en multijoueur, un personnage sourd ne peut pas recevoir la radio (limite du jeu).
- La suite de l'enquête (acte II au-delà de l'entrée du journal) : phase 2.

## 7. Régression — talkie à la ceinture (2026-10-02)

Le journal de la session `Sandbox/2026-10-01_19-37-45` confirme le jeu
**42.21.0, révision `4a0e9546ec`**, la création de la chaîne sur 108.0 MHz et
la lecture du carnet (acte I). Le patch MilitaryDrop maintenait le talkie
allumé à la ceinture, mais ne livrait en solo que les chaînes MilitaryDrop.
Le vanilla ne distribue ces transmissions qu'à la radio en main ou sur le dos.

`client/Artemis_BeltRadio.lua` ajoute les options de réglage, maintient la
fenêtre et livre la chaîne Artemis aux radios accrochées en solo, même sans
MilitaryDrop. La chaîne est résolue par UUID, avec sa fréquence réelle ; les
codes de progression sont conservés. Si MilitaryDrop est chargé, son wrapper
de fenêtre est utilisé, y compris pour la prise en main des échanges. Chaque
mod suit ses propres chaînes. Sur un client multijoueur, la réception reste
vanilla pour éviter les doublons.

Validation historique hors jeu avec `lupa.lua51` : **12 tests réussis**, dont Artemis seul,
les deux ordres de chargement avec MilitaryDrop, un seul menu, stabilité des
wrappers, absence de messages doublés, passage par le vrai listener `ART1`,
fréquence personnalisée, météo, conditions de réception et rechargement Lua.
Les **21 tests existants de ceinture MilitaryDrop** passent également.

Ces tests unitaires Artemis ont été supprimés lors du nettoyage du dossier `tests`.
La campagne conservée utilise [PZPuppeteer](../tests/puppeteer/README.md) ;
les résultats historiques ci-dessus ne constituent pas sa validation en jeu.
Les **86 fichiers Lua Artemis** compilent en Lua 5.1. API Java et interface
simulées : ces résultats ne constituent pas une reproduction en jeu.

À confirmer après **redémarrage complet**, sur une partie de test en 42.21 :

1. Artemis actif sans MilitaryDrop : lire le carnet, accrocher un talkie avec
   une pile chargée, ouvrir « Options de l'appareil », allumer, régler la
   fréquence Artemis et le volume. Attendre la prochaine diffusion (relance
   toutes les dix minutes de jeu). Vérifier les lignes puis le passage à l'acte II.
2. Refaire avec MilitaryDrop actif : vérifier une seule option de réglage,
   une seule occurrence de chaque ligne et aucune nouvelle erreur Lua.
3. Vérifier aussi une radio en main et une radio posée à portée, puis une radio
   éteinte ou sans volume. Elles doivent garder leurs comportements habituels.

Limite constatée avant le correctif du 2026-10-03 : en solo, `DeviceData.update` ne
tourne pas pour une radio à la ceinture. La charge n'est donc pas mise à jour
en continu ; la consommation est rattrapée à la reprise en main. Ce correctif
ne généralise pas la réception à toutes les chaînes vanilla et ne modifie pas
les règles des appels d'extraction de l'acte III.

### Batterie à la ceinture — correctif du 2026-10-03

Cette limite de batterie est corrigée dans les projets Artemis et MilitaryDrop.
Depuis 0.4.0, le module vient de Belt Walkie-Talkie (`batman_BeltRadio`) s'il
est activé, sinon de la copie de secours de chaque mod
(`client/Artemis/BeltRadioFallback/`, `client/MilitaryDrop/BeltRadioFallback/`) ;
deux copies se remplacent : un seul handler `OnTick`. Le lanceur Artemis
vérifie l'égalité de la copie avec Belt Walkie-Talkie.

Sans Better Walkie Talkies actif, le gestionnaire appelle `DeviceData.update(false, true)` pour les radios
portatives à pile accrochées dans l'inventaire principal, hors main/dos.
La mise à jour s'effectue à l'allumage puis chaque minute de jeu. Elle utilise
le compteur, le débit, l'extinction et les paquets de synchronisation vanilla
(sources 42.21.0, révision `4a0e9546ec`), sans soustraction manuelle de charge.
Le compteur avance : reprendre la radio en main ne recompte pas cette période.
Les radios éteintes, rangées dans un sac, posées, les joueurs distants et le
serveur dédié ne sont pas pris en charge par ce gestionnaire.

Après simplification le même jour, si BetterWalkieTalkies ou BetterWalkieTalkiesDev
est actif, notre gestionnaire lui laisse **toujours** la batterie. Son option
`BatteryDrain` conserve son effet, activé ou désactivé. Il n'est plus nécessaire
de la désactiver pour éviter un conflit avec Artemis/MilitaryDrop. Cela ne
corrige pas le risque de double décompte interne à BWT, identifié statiquement.

Validation : **25 tests Artemis/radio/batterie réussis**, **34 tests ciblés
MilitaryDrop réussis**, suite complète MilitaryDrop et luacheck sans échec.
Les **134 fichiers Lua des deux mods** compilent en Lua 5.1. Ces tests simulent
les API Java ; aucune reproduction interactive ou client/serveur n'est annoncée.

Après redémarrage complet, avec Artemis seul puis avec MilitaryDrop seul et
les deux ensemble : relever la pile, laisser le talkie allumé à la ceinture
dix minutes de jeu, puis le reprendre en main. Vérifier une baisse régulière,
sans seconde chute à la reprise ; refaire éteint, et vérifier l'extinction
avec une pile presque vide. En MP, vérifier aussi la charge après reconnexion.

### Code commun et PTT Better Walkie Talkies — simplification du 2026-10-03

La source unique est désormais le mod Belt Walkie-Talkie (dépôt `BeltRadio`) ;
`BeltRadio/tools/sync_fallback.py` génère les copies de secours des deux
projets (contrôle avec `--check`, depuis 0.4.0 ; avant :
`MilitaryDrop/source/radio/sync_radio.py`, supprimé). Artemis et MilitaryDrop inscrivent leurs chaînes dans le même
gestionnaire : un seul menu, wrapper et récepteur solo. En MP, la réception et
la VOIP restent au vanilla/BWT. Aucune dépendance chargeable supplémentaire.

Les appels Artemis utilisent le bridge texte de BWT : le silence automatique
de `RadioPTT` (touche maintenue pour émettre la voix en MP) n'est plus confondu
avec un micro volontairement coupé. Ce dernier reste refusé. Les phrases du
scénario préservent le mode vocal et les micros avant/après leur transmission.

**53 tests locaux passent**, dont 7 avec le vrai code PTT/batterie installé de
BWT (variante 42.20) ; le réseau et l'audio restent simulés. La suite complète
MilitaryDrop passe également. Les essais en jeu 42.21 (deux clients, VOIP à
distance et reconnexion) restent à effectuer selon
[le protocole commun](../../MilitaryDrop/dev/TEST-PROTOCOL.md#compatibilité-better-walkie-talkies-et-code-commun--2026-10-03).

### Stations vanilla à la ceinture — extension du 2026-10-03

Le gestionnaire commun reçoit désormais toutes les stations radio du registre
de la partie en solo, y compris l'AEBS à fréquence variable, sur la fréquence
réglée du talkie. Il déclare l'écoute au moteur afin de démarrer les émissions
scriptées, exclut la TV et conserve un seul récepteur avec MilitaryDrop.
Le texte passe par la surcharge native avec joueur de `AddDeviceText`.
L'activation de BWT conserve son effet sur la batterie et le bridge PTT ;
la réception ajoutée reste désactivée en multijoueur.

**La fidélité n'est pas garantie à 100 %** : les publicités annexes sont reçues
en gris sans leurs codes et leurs répétitions identiques ne sont pas détectables ;
le brouillage scénarisé de Louisville n'est pas reproduit. Ces données privées
ne sont pas accessibles par l'API Lua publique en mode normal. Les transmissions
directes hors du registre ne sont pas interceptées. Sources 42.21.0 vérifiées
par empreinte du JAR installé ; 53 tests simulés réussis, aucun essai audio réel.
Voir [les limites et essais vanilla du protocole commun](../../MilitaryDrop/dev/TEST-PROTOCOL.md#stations-vanilla-à-la-ceinture-en-solo--2026-10-03).

### Belt Walkie-Talkie facultatif — 0.4.0 (2026-10-10)

Redémarrage complet entre deux listes de mods ; dans `console.txt`, vérifier
les mods chargés et l'absence de ligne `overrides media/lua/client/BatmanRadio`.

| Cas | Attendu |
|---|---|
| Solo, Artemis seul : talkie militaire allumé à la ceinture sur 108,0 MHz, la nuit | Lignes ARTEMIS au-dessus du personnage ; « Options de l'appareil » ; appel d'extraction grisé (« prenez la radio en main ou portez-la sur le dos ») |
| Solo, Artemis + Belt Walkie-Talkie | Même comportement ; page d'options sandbox **Belt Walkie-Talkie** ; aucune ligne `WARN` d'Artemis |
| Solo, Artemis + Military Drop sans Belt Walkie-Talkie | Une seule ligne par message à la ceinture, pas de doublon |
| MP en fin : talkie à la ceinture puis rangé | Ceinture : bulle radio ; rangé : chat radio seulement ; appel refusé à la ceinture |
