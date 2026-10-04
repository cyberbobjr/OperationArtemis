# Protocole de test — Opération Artemis, phase 2a (acte II, mécanique de l'enquête)

- Mod : `batman_OperationArtemis` (dossier `C:\Users\cyber\Zomboid\Workshop\OperationArtemis\Contents\mods\batman_OperationArtemis`, variante `42.21`)
- Build visée : **42.21**. Vérifier en tête de `console.txt` la version réellement lancée.
- Date du protocole : 2026-09-27. Conception : [conception-operation-artemis.md](conception-operation-artemis.md), section « Plan de la phase 2 ».
- Durée estimée : 1 h à 1 h 30 avec la téléportation de debug.

Ce protocole vérifie en jeu ce qui n'a été contrôlé que dans les fichiers : pose des objets dans les quatre lieux (une seule fois), documents lisibles, objectifs, révélations sur la carte, journal, code d'appel, passage à l'acte III, rechargement et migration d'une sauvegarde de la phase 1. **La mise en scène des chapitres (soldats qui se relèvent, sirène, voix de V…) est la phase 2b : elle n'est pas attendue ici.**

## 0. Session de test en cours

| Élément | Valeur |
|---|---|
| Date | 2026-09-27, vers 23 h |
| Sauvegarde | `Saves/Sandbox/2026-09-27_16-54-22` (partie de test de la phase 1, chargée à l'acte I, révision 66) |
| Build | 42.21.0 (`version=42.21.0 4a0e9546ec`) |
| Radio | 131.8 MHz (réglage resté du test T15) |
| Surveillance | `pzwatch.py`, copie complète dans le scratchpad de la session |

### Bilan de la session du 2026-09-27 (test arrêté à la demande de l'utilisateur)

**Validés : V01 à V07.** V08 n'est pas terminé, mais la pose du dossier dans la base fonctionne (`chapitre ch5_base : objets poses`, f:47199). Non joués : V09 à V13. **Aucune erreur Lua liée au mod** sur toute la session (26 700 lignes de `console.txt`).

La mécanique fonctionne de bout en bout jusqu'à la base : pose sur `LoadChunk` dans les quatre lieux, une seule fois, y compris dans le labo trop grand pour être entièrement chargé ; objectifs ; journal ; carte ; code d'appel ; rechargement à l'acte II sans nouvelle pose.

Corrections faites pendant la session :

| Constat en jeu | Correction |
|---|---|
| Texte des repères de carte en `?` (personnage illettré) : comportement vanilla, mais la recherche de doublon par clé échouait aussi | Repère texte retrouvé par sa position |
| Sous-titre des ordres de mission hors de la page, tampon superposé | Nouvelle mise en page ; largeur de chaque ligne vérifiée hors jeu avec les métriques des polices du jeu ; validé en jeu |
| Base : aucun moyen d'atteindre le dépôt pour tester | Entrée de debug « Aller au dépôt du chapitre » |

**Retours de l'utilisateur, qui orientent la suite** (détail dans la conception, section « Plan de la phase 2 ») :
- relais : le chapitre se termine à l'arrivée, sans rien comprendre ; il faut lire quelque chose ;
- le personnage devrait parler au fil de ses découvertes ;
- la carte de V passe pour une carte vanilla quelconque ;
- base : portes blindées (`forceLocked`) impossibles à ouvrir, escaliers introuvables, recherche trop fastidieuse sans indice.

**Suite décidée** : implémenter d'abord les aides au joueur, puis reprendre ce protocole à V08.

## 1. Préparation

- **Ne jamais tester sur la partie principale** : partie neuve (option A de la phase 1) ou copie de sauvegarde. Redémarrer complètement le jeu après toute modification.
- Options de la page « Opération Artemis » : `Mode debug` = oui ; le reste par défaut.
- Surveillance : `.claude/tools/pzwatch.py` (voir `.claude/pz-knowledge/logs-and-tools.md`). Toutes les lignes du mod commencent par `[OperationArtemis]` et sont **sans accents**.
- Carte du monde : touche **M**. Journal de l'opération : **K**.
- Clic droit au sol → « Opération Artemis (debug) » : « Démarrer l'opération », « Passer à l'acte suivant », « Terminer le chapitre en cours », « Aller au lieu du chapitre » (visible seulement pendant un chapitre), « Réinitialiser l'état ».

Lieux (coordonnées relevées dans les fichiers de carte, **à confirmer en jeu**) :

| Chapitre | Lieu | Entrée (téléportation) | Dépôt |
|---|---|---|---|
| 1 | Bunker militaire désaffecté de March Ridge | cabane 9923,12625, z 0 ; escalier 9921,12624-12626 jusqu'à z -4 | bureau 9963,12626, z -4 : ordres de mission + badge ; 3 soldats morts autour |
| 2 | Clinique de West Point | 11883,6879, z 0 | classeur 11879,6882, z 0 : dossier du patient zéro |
| 3 | Station relais (pylône), entre Brandenburg et Riverside | dehors, 4840,6281 ; porte 4838,6281 | bureau 4836,6285, z 0 : registre du relais + carte de V (WorldStashMap17) ; salle de contrôle 4832-4837, 6277-6280 |
| 5 | Base secrète, au sud-ouest de Rosewood | dehors, 5588,12483 ; double porte 5584,12483-12484 | classeur 5568,12430, z -17 (archives) : dossier Artemis ; escaliers 5544-5546,12466-12467 puis 5549-5550,12497-12499 |

## 2. Tests

### V01 — Chargement
- **Attendu** : `[OperationArtemis] etat charge : acte 0, revision N`, `chaine radio creee sur 108.0 MHz` ; aucune erreur citant un fichier `Artemis_`.
- **Résultat** : ☑ OK ☐ KO — `chaine radio creee sur 131.8 MHz`, `etat charge : acte 1, revision 66` (sauvegarde de phase 1 au schéma 1, migrée sans erreur), `Siege Night : sieges automatiques suspendus (acte 1)` ; aucune erreur liée au mod ; messages sans accents.

### V02 — Entrée dans l'acte II : chapitre 1 et carte
- **Étapes** : debug « Démarrer l'opération », puis « Passer à l'acte suivant » (ou lire le carnet puis écouter le 108,0). Ouvrir le journal (K), puis la carte (M).
- **Attendu** :
  - journal : « Acte II : l'Enquête », « **Chapitre 1 : Le poste abandonné** » et son objectif (bunker de March Ridge) ; entrée « … un bunker sous March Ridge, et d'un badge » ;
  - carte : la zone du bunker est révélée, avec un **symbole cible rouge** et le texte « **Bunker (Artemis)** », sans rouvrir la partie ;
  - la radio (108,0) parle désormais de « secteur March Ridge » et du « bunker, sous March Ridge ».
- **Suivi** : `debugAdvance par LilaYoungblood : acte 2, revision 67` (f:8046), puis `scene : 1 sprinteur(s) sur 1` (f:8946, ≈ 15 s) : la scène `act2` se déclenche bien par `lastScene.seq`. Journal : chapitre 1 affiché (confirmé par l'utilisateur). Carte : zone révélée et cible rouge au bon endroit. Le texte s'affiche « ?????? ????????? », car le personnage de test est **illettré** : c'est le masquage vanilla des textes de la carte. Ce test a révélé un défaut, corrigé : le texte était retrouvé par sa clé, masquée elle aussi, et aurait été ajouté de nouveau à chaque chargement. Il est désormais retrouvé par sa position (à revérifier au rechargement, V09). Radio non vérifiée (131.8 MHz).
- **Résultat** : ☑ OK ☐ KO

### V03 — Chapitre 1 : pose des objets au bunker
- **Étapes** : debug « Aller au lieu du chapitre » (cabane d'entrée). Descendre l'escalier jusqu'à z -4 ; aller au bureau vers 9963,12626.
- **Attendu** :
  - `console.txt` : `pose ch1_bunker : 3 corps sur 3` (moins si la place manque) puis `pose ch1_bunker : objets poses`, **une seule fois** ;
  - le bureau contient les **Ordres de mission Artemis** et le **Badge d'accès Artemis** (en plus d'un éventuel butin vanilla) ;
  - trois **soldats morts en uniforme** au sol autour. Depuis le 2026-09-28, dans une partie neuve, ce sont des **faux morts** qui agrippent qui passe trop près (`pose ch1_bunker : 3 faux morts sur 3`). Une sauvegarde où le bunker est déjà posé garde ses cadavres.
- **Suivi** : `chapitre ch1_bunker : 3 corps sur 3` puis `chapitre ch1_bunker : objets poses` (f:14342), une seule fois, à l'arrivée (événement `LoadChunk`). L'utilisateur confirme les ordres, le badge et les trois corps en uniforme.
- **À noter si KO** : la ligne `objets poses` est-elle apparue ? Si le meuble a disparu, une caisse militaire doit avoir été créée à sa place. Si la ligne n'apparaît pas, noter l'heure d'arrivée au bunker et s'il était déjà chargé à l'ouverture du chapitre.
- **Résultat** : ☑ OK ☐ KO

### V04 — Documents lisibles
- **Étapes** : inspecter le badge, puis les ordres de mission.
- **Attendu** : fenêtre de document ; badge (bandeau rouge « ARTEMIS », « ACCÈS NIVEAU 3 », signature manuscrite) ; ordres (en-tête, tampon rouge « SECRET » incliné, note manuscrite « Pourquoi le 4 ? »), puis la transcription. Aucune erreur `RICH TEXT ERROR` dans `console.txt`. Vérifier que les textes ne débordent pas de la page.
- **Suivi** : documents lisibles par le personnage illettré ; badge conforme. **Ordres de mission : le sous-titre débordait de la page** et le tampon « SECRET » le chevauchait (capture de l'utilisateur). **Corrigé** : sous-titre séparé en romain à l'échelle 0,55, tampon placé sous le texte, et largeur de chaque ligne de chaque document vérifiée hors jeu avec les métriques des polices du jeu. La page stocke des clés : le document déjà ramassé sera corrigé **après un redémarrage du jeu**. À revérifier : les cinq documents.
- **Résultat** : ☑ OK ☐ KO — après rechargement (retour au menu, traductions relues : `overrides … print_media.json`), l'utilisateur confirme que les ordres de mission tiennent dans la page. Registre du relais et dossier Artemis à regarder quand ils seront trouvés.

### V05 — Objectif du chapitre 1 : prendre le badge
- **Étapes** : mettre le badge dans l'inventaire (ou dans un sac porté).
- **Suivi** : `chapitre termine : ch1_bunker -> ch2_clinic` (f:27540). Journal et carte confirmés par l'utilisateur.
- **Attendu** : dans la minute de jeu, `chapitre termine : ch1_bunker -> ch2_clinic` ; journal : entrée « Le badge était dans le bunker… 4 juillet… » et « Chapitre 2 : Les dossiers médicaux » ; carte : « Clinique (Artemis) » à West Point.
- **Résultat** : ☑ OK ☐ KO

### V06 — Chapitre 2 : clinique de West Point
- **Suivi** : `chapitre ch2_clinic : objets poses` (f:1332, après rechargement), puis `chapitre termine : ch2_clinic -> ch3_relay` (f:5882). L'utilisateur confirme le dossier médical dans le classeur de la clinique. Journal et carte non commentés.
- **Étapes** : « Aller au lieu du chapitre » ; ouvrir le classeur près du bureau (11879,6882) ; prendre le dossier ; le lire.
- **Attendu** : `pose ch2_clinic : objets poses` ; **Dossier médical du patient zéro** dans le classeur ; après l'avoir pris, `chapitre termine : ch2_clinic -> ch3_relay`, journal chapitre 3, carte « Relais (Artemis) ».
- **Résultat** : ☑ OK ☐ KO

### V07 — Chapitre 3 : relais et code d'appel
- **Suivi** : `chapitre ch3_relay : objets poses` (f:8662), puis `chapitre termine : ch3_relay -> ch5_base` (f:8791, environ 2 s plus tard) : réseau public probablement encore actif, relais déjà alimenté. **Constat de conception** : le chapitre se termine avant que le joueur ait lu le registre ; proposition pour la 2b : terminer le chapitre quand la bande de V a été entendue sur la radio du relais. L'utilisateur confirme le registre (correct) et la carte annotée dans le bureau ; **la carte passe inaperçue** (« je croyais que c'était une carte vanilla ») : en 2b, la renommer (« Carte annotée de V ») et l'annoncer par une pensée. Journal (« Code d'appel : 7149 », chapitre 5) et cible de la base sur la carte confirmés par l'utilisateur.
- **Étapes** : « Aller au lieu du chapitre » (devant la porte). Entrer ; ouvrir le bureau (4836,6285) ; lire le **registre** et la **carte** (carte annotée de V).
- **Attendu** :
  - `chapitre ch3_relay : objets poses` ; le bureau contient le registre et une carte vanilla annotée (« patrol blindspot », « V will turn off sensors at 23.15 ») ;
  - **si le réseau électrique fonctionne encore** (début de partie) : le chapitre se termine dès que le personnage est dans la salle de contrôle (≤ 8 cases de 4834,6278) ;
  - **si le courant est coupé** : rien ne se passe tant qu'aucun générateur allumé n'alimente la salle de contrôle ; avec un générateur allumé à proximité (moins de 20 cases), le chapitre se termine ;
  - à la fin : `chapitre termine : ch3_relay -> ch5_base` ; journal : « **Code d'appel : 7149** » et l'entrée sur la bande de V ; carte : « Base (Artemis) ».
- **Résultat** : ☑ OK ☐ KO — réseau actif (pas de générateur) ; mécanique conforme, compréhension à revoir en 2b

### V08 — Chapitre 5 : la base secrète et l'acte III
- **Suivi** : l'utilisateur signale des **portes verrouillées** (à ouvrir avec une clé qu'on ne trouve pas : frustrant) et **ne trouve pas les escaliers** ; chemin relevé communiqué (porte est, hall vers l'ouest, sas 5540-5543,12466, escalier 5544-5546 jusqu'à z -13, puis 5549-5550,12497-12499 jusqu'à z -17). `chapitre ch5_base : objets poses` (f:47199) : la pose attendue après exploration d'une pièce du labo fonctionne. Propositions pour la 2b dans la conception (badge = clé de la base, plan d'accès, pensées). Ajout d'une entrée de debug « Aller au dépôt du chapitre » (téléportation à côté du dépôt), chargée au prochain retour au menu.
- **Étapes** : « Aller au lieu du chapitre ». Entrer par la double porte est ; descendre jusqu'à z -17 ; archives vers 5564-5573,12430-12434 ; ouvrir le classeur 5568,12430 ; prendre le **Dossier Artemis** ; le lire.
- **Attendu** : `pose ch5_base : objets poses`. Le laboratoire est trop grand pour être entièrement chargé : la pose attend qu'une de ses pièces soit explorée, puis se fait dans la minute de jeu (joueur à moins de 120 cases du classeur). Elle doit donc avoir eu lieu avant d'arriver à z -17. Après la prise : `chapitre termine : ch5_base -> acte 3` ; journal « Acte III : l'Exfiltration », entrées « Tout est dans le dossier… » et « J'ai le dossier Artemis… » ; le code d'appel reste affiché. Avec Siege Night en mode « suspendre jusqu'au dossier » : `Siege Night : sieges automatiques retablis (acte 3)` dans les 10 minutes de jeu.
- **À relever** : les escaliers de la base mènent-ils bien de z 0 à z -17 ? Portes verrouillées ? Temps de descente.
- **Résultat** : ☐ OK ☐ KO

### V09 — Une seule pose, même après rechargement
- **Étapes** : à deux moments différents (après V03 et après V07), sauvegarder, quitter, recharger, retourner au lieu.
- **Attendu** : aucune nouvelle ligne `objets poses` pour un chapitre déjà posé ; pas de second badge, dossier ou corps ; les symboles de la carte ne sont pas doublés ; aucune scène rejouée au chargement.
- **Résultat** : ☐ OK ☐ KO

### V10 — Lieu déjà chargé à l'ouverture du chapitre
- **Étapes** : réinitialiser, démarrer, passer à l'acte II **en se tenant déjà dans le bunker** (téléportation préalable : ouvrir le chapitre, y aller, réinitialiser, démarrer et avancer sans bouger).
- **Attendu** : les objets sont posés aussitôt (`objets poses`) sans devoir s'éloigner. **Attention** : une réinitialisation **conserve** le registre des poses et les lieux révélés (les objets déjà posés restent dans le monde) ; pour ce test, utiliser une partie neuve, ou un chapitre pas encore posé. Un badge encore porté termine le chapitre 1 dès l'approche du bunker.
- **Résultat** : ☐ OK ☐ KO

### V11 — Migration d'une sauvegarde de la phase 1
- **Étapes** : **copie** de la sauvegarde de test de la phase 1 arrivée à l'acte II (`Saves/Sandbox/2026-09-27_16-54-22`), chargée avec le nouveau code.
- **Attendu** : `etat charge : acte 2, revision N` ; journal : chapitre 1 ouvert ; carte : bunker révélé ; les entrées de journal de la phase 1 sont conservées.
- **Résultat** : ☐ OK ☐ KO

### V12 — Symbole effacé
- **Étapes** : sur la carte, effacer le symbole « Bunker (Artemis) » ; sauvegarder, recharger.
- **Attendu** (par conception) : le symbole revient au chargement suivant ; la zone reste révélée.
- **Résultat** : ☐ OK ☐ KO

### V13 — Debug « Terminer le chapitre en cours »
- **Étapes** : réinitialiser, démarrer, avancer à l'acte II, puis « Terminer le chapitre en cours » quatre fois.
- **Attendu** : `chapitre termine : …` pour les quatre chapitres dans l'ordre, puis acte III ; code d'appel 7149 ; quatre lieux sur la carte ; aucune erreur.
- **Résultat** : ☐ OK ☐ KO

### Tests des aides au joueur (ajoutées après la session du 2026-09-27)

> Depuis l'ajout des groupes de pose, les messages de pose sont `pose <groupe> : objets poses` (ex. `pose ch1_bunker : objets poses`, `pose ch5_base_guard : objets poses`) et `pose <groupe> : N corps sur M`.

#### A01 — Pensées d'arrivée et de découverte
- **Étapes** : sur une partie neuve (ou après réinitialisation), jouer les chapitres 1 et 2 sans debug de fin de chapitre.
- **Attendu** : en approchant de chaque entrée, une pensée (« Une cabane... et un escalier qui descend loin sous terre. », « La clinique. Le classeur près du bureau, peut-être. ») et `arrivee : <chapitre>` dans `console.txt` ; à la prise du badge : « Un badge Artemis. Ils étaient là. » ; à la fin de la lecture des ordres : « West Point. La clinique... » et `document lu : ArtemisMissionOrders`. Pensées visibles même avec « Effets à l'écran » décoché.
- **Résultat** : ☐ OK ☐ KO

#### A02 — Objectifs précis dans le journal
- **Attendu** : chaque objectif nomme le lieu, l'étage et le meuble (bureau au fond de la grande salle à -4, classeur de la salle d'examen, registre du bureau du relais, archives de -17).
- **Résultat** : ☐ OK ☐ KO

#### A03 — Relais compréhensible
- **Étapes** : arriver au relais **sans** lire le registre ; entrer dans la salle de contrôle ; attendre deux minutes de jeu. Puis lire le registre.
- **Attendu** : pas de fin de chapitre avant la lecture ; pensée « Il doit y avoir des notes dans le bureau. » (`aide : hint_ch3_read`) ; carte nommée « **Carte annotée de V** » dans le bureau ; après la lecture : « Remettre le courant, puis écouter... », puis dans la minute (si le courant est là) `chapitre termine : ch3_relay -> ch5_base` et « 7-1-4-9... ». Sans courant : « Pas de courant. Il me faut un générateur. » (`aide : hint_ch3_power`).
- **Résultat** : ☐ OK ☐ KO

#### A04 — Garde, carte d'accès et plan à l'entrée de la base
- **Étapes** : chapitre 5 ouvert (sauvegarde de la session du 2026-09-27 : chapitre 5 déjà posé). Aller devant la porte est (debug « Aller au lieu du chapitre »).
- **Attendu** : `pose ch5_base_guard : 1 corps sur 1`… puis `pose ch5_base_guard : objets poses` ; un soldat mort devant la porte, avec **Carte d'accès Artemis** et **Plan d'accès de la base** ; aucune seconde pose du dossier. Le plan s'affiche (trois niveaux, chemin rouge, croix sur les archives, note de V) sans débordement.
- **Résultat** : ☐ OK ☐ KO

#### A05 — La carte d'accès ouvre les portes blindées
- **Étapes** : carte d'accès dans l'inventaire principal (pas dans un sac) ; ouvrir une porte blindée de la base avec E, puis par le menu contextuel ; survoler la carte dans l'inventaire.
- **Attendu** : la porte s'ouvre (bruit de déverrouillage) ; sans la carte, elle reste verrouillée ; au survol de la carte, les portes blindées de la base sont surlignées.
- **Résultat** : ☐ OK ☐ KO

#### A06 — Guide dans la base : étapes, pensées, lampes
- **Étapes** : descendre de la surface à -17 à pied, journal ouvert.
- **Attendu** : lampes rouges au sas, à chaque palier du puits, à -13 vers le second escalier, à -17 jusqu'aux archives ; ligne « Ici : ... » du journal qui change avec l'étage ; une pensée par étape (« Le sas est à l'ouest du hall. », « Ça descend... très loin. », « Niveau -13. Le second escalier est au sud. », « Encore plus bas. », « Le fond. Les archives sont au nord. »). Les lampes restent après la prise du dossier (acte III) et reviennent après un aller-retour loin de la base.
- **Résultat** : ☐ OK ☐ KO

#### A07 — Premier signal : le cri est un bruit, pas un sprinteur (décision du 2026-09-28)
- **Étapes** : partie neuve ou réinitialisée ; lire le carnet ; écouter le signal (vraie écoute, pas le debug « Passer à l'acte suivant », qui n'envoie pas de volume), trois fois dans des conditions différentes : radio forte dehors ; radio basse ou à l'intérieur ; avec des écouteurs.
- **Attendu** : aucun sprinteur ; `scene : cri entendu dans un rayon de N cases`, avec N plus grand dehors et à fort volume ; avec des écouteurs, `scene : cri sans bruit dans le monde (ecouteurs ou volume nul)`. Les zombies proches, dans le rayon, se dirigent vers le joueur.
- **Résultat** : ☐ OK ☐ KO

#### A08 — Bunker : faux morts
- **Étapes** : partie neuve, arriver au bunker (chapitre 1).
- **Attendu** : `pose ch1_bunker : 3 faux morts sur 3` ; soldats au sol immobiles, qui agrippent le personnage quand il passe à côté ; prendre le badge ne déclenche rien de particulier.
- **Résultat** : ☐ OK ☐ KO

## 3. Récapitulatif

| Test | Sujet | Résultat | Remarques |
|---|---|---|---|
| V01 | Chargement | ☑ OK ☐ KO | |
| V02 | Acte II, chapitre 1, carte, radio | ☑ OK ☐ KO | |
| V03 | Pose au bunker | ☑ OK ☐ KO | |
| V04 | Documents lisibles | ☑ OK ☐ KO | |
| V05 | Badge → chapitre 2 | ☑ OK ☐ KO | |
| V06 | Clinique → chapitre 3 | ☑ OK ☐ KO | |
| V07 | Relais, courant, code d'appel | ☑ OK ☐ KO | |
| V08 | Base, dossier, acte III | ☑ OK ☐ KO | 2026-09-29 : dossier reposé après redémarrage, `ch5_base -> acte 3`, Siege Night rétabli |
| V09 | Une seule pose après rechargement | ☐ OK ☐ KO | |
| V10 | Lieu déjà chargé | ☐ OK ☐ KO | |
| V11 | Migration de la sauvegarde de phase 1 | ☐ OK ☐ KO | |
| V12 | Symbole effacé | ☐ OK ☐ KO | |
| V13 | Debug « Terminer le chapitre » | ☐ OK ☐ KO | |
| A01 | Pensées d'arrivée et de découverte | ☐ OK ☐ KO | |
| A02 | Objectifs précis | ☐ OK ☐ KO | |
| A03 | Relais compréhensible | ☐ OK ☑ KO | 2026-09-29 : registre du relais confondu avec le dossier de la clinique ; l'aide unique bloquait les suivantes. Corrigé (aide précise, aide après la bande), à retester |
| A04 | Garde, carte d'accès, plan | ☐ OK ☐ KO | |
| A05 | Portes blindées ouvertes par la carte | ☐ OK ☐ KO | |
| A06 | Guide dans la base | ☑ OK ☐ KO | 2026-09-29 : étapes du guide et lampes validées (chemin par le -16 ajouté après le premier passage) |
| A07 | Cri de la radio = bruit | ☑ OK ☐ KO | 2026-09-29 : `cri entendu dans un rayon de 42 cases` (radio 21 × 2), aucun sprinteur, zombies attirés (confirmé par l'utilisateur) |
| A08 | Bunker : faux morts | ☑ OK ☐ KO | 2026-09-29, partie neuve : 3 faux morts posés, agrippement validé par l'utilisateur |

## 4. Hors périmètre

- Mise en scène des chapitres (phase 2b), alarme de 23 h 15 et évasion du labo (phase 3).
- Multijoueur : la logique est prévue pour (autorité serveur, commande `map/setKnownInSquares`), mais le test se fait en solo.
