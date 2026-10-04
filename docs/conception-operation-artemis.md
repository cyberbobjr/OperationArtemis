# Opération Artemis — conception d'un scénario de fin de partie (Enquête Knox + Exfiltration)

- Créé le 2026-09-27, mis à jour le 2026-09-28 — Build cible : 42.21 — Mode : solo d'abord, multijoueur ensuite
- Statut : **en développement**. Phases 0 et 1 validées en jeu ; phase 2 en cours (voir la feuille de route, section 0). Les API citées sont confirmées statiquement (Lua vanilla 42.21, Java décompilé `E:\pz-decompiled\42.21.0\java`, mods installés), puis en jeu quand un test l'indique.
- Mod : projet local `C:\Users\cyber\Zomboid\Workshop\OperationArtemis\Contents\mods\batman_OperationArtemis\` (aucune modification du Workshop). Les mods Workshop cités sont des **dépendances optionnelles**, détectées au lancement.

**Sommaire** : 0. Vue d'ensemble (cible, feuille de route) · 1. Intention · 2. Lore vanilla · 3. Les trois actes · 4. Épreuves · 4 bis. Mise en scène · 5. Architecture · 6. Options · 7. Méthode et plans détaillés par phase, journal · 8. Décisions · 9. Risques

## 0. Vue d'ensemble

### La cible : ce que vit le joueur dans la version 1.0

Opération Artemis donne une **fin** à une partie de Project Zomboid : une enquête à travers Knox, puis une sortie de la zone d'exclusion.

1. **Le carnet** (acte I). Sur le corps d'un soldat zombie, un carnet taché de sang donne une fréquence radio et un mot manuscrit signé « V ».
2. **Le signal**. La nuit, la radio capte la chaîne Artemis ; un cri sort du haut-parleur et attire les zombies proches. Le journal (touche K) ouvre l'enquête.
3. **L'enquête** (acte II). Quatre lieux vanilla, révélés un à un sur la carte : le bunker de March Ridge (badge), la clinique de West Point (dossier du patient zéro), le relais radio (registre, bande de V, code d'appel), la base secrète de Rosewood (dossier Artemis, au niveau -17). Le personnage commente ses découvertes, les objectifs nomment l'endroit exact, et chaque lieu a sa mise en scène.
4. **L'évasion du labo** (épreuve). Prendre le dossier déclenche l'alarme annoncée par V ; la garnison converge ; il faut remonter.
5. **L'exfiltration** (acte III). Trois routes au choix, qui consomment le surplus de la partie : l'hélicoptère (relais, code d'appel, tenir la zone d'atterrissage), le fleuve (bateau, pont gardé), le checkpoint (quarantaine d’une heure maximum, test sanguin).
6. **La fin**. Un écran de victoire affiche la fin obtenue et la chronique de la partie ; le joueur choisit « Terminer » (retour au menu) ou « Continuer » (épilogue).

**Critères de la version 1.0** :
- le parcours complet, du carnet à l'écran de fin, se joue **en solo sans debug**, sur une partie neuve comme sur une sauvegarde avancée ;
- les **trois routes** d'exfiltration et leurs fins ;
- chaque effet a une **cause lisible** dans le monde du jeu ; le joueur n'est jamais perdu (objectifs précis, pensées, aides) ;
- textes en **français et en anglais** ; options sandbox pour la difficulté et les effets ;
- **aucune erreur Lua** du mod dans `console.txt` sur un parcours complet.

Le multijoueur coopératif est prévu dans le code dès le départ (autorité serveur), mais il n'est validé qu'en phase 7. Les intégrations de mods (phase 6) sont des bonus.

### Feuille de route

| Phase | Contenu | Ce que le joueur y gagne | État au 2026-09-29 |
|---|---|---|---|
| 0 | Socle : état persistant, journal, commandes de debug | — | ✅ Fait, validé en jeu |
| 1a | Acte I, mécanique : carnet sur un soldat, chaîne radio, écoute | Le début de l'histoire | ✅ Validé en jeu (T01-T17 ; réserves : T02 sans debug, T17 étapes 3, 4, 6) |
| 1b | Acte I, mise en scène : lecture du carnet, premier signal | La peur du premier signal | ✅ Validé ; cri de la radio refait en bruit réel le 2026-09-28, à retester (A07) |
| 2a | Acte II, mécanique : 4 lieux, poses, objectifs, documents, carte, journal | L'enquête jouable | ✅ Clôturée le 2026-09-29 (validée de bout en bout ; cas limites V09-V13 non joués, acceptés) |
| 2b | Acte II, aides : pensées, objectifs précis, relais lisible, carte d'accès et plan de la base, lampes guides, faux morts | Ne jamais être perdu | ✅ Clôturée le 2026-09-29 |
| 2c | Acte II, mise en scène (décisions du 2026-09-28, section 4 bis ; plan en section 7) | L'ambiance de chaque lieu | ✅ Clôturée le 2026-09-29 (non joués, acceptés : sirène et brume du bunker, carte de Miller, nouveau personnage, retest de la radio et des aides) |
| 3 | Épreuves : moteur d'épreuve, alarme de la base annoncée, garnison, gyrophares, évasion du labo | Le point culminant de l'enquête | 🟡 Testée en jeu le 2026-09-30 : 8/13 validés (P01-P05, P07, P10, P11) ; cas limites P06, P08, P09, P12, P13 reportés ; parcours nominal J1 validé (jalon J1 atteint) |
| 4 | Acte III, route B (hélicoptère) ; **points d'évacuation révélés sur la carte** après le dossier (demande de l'utilisateur du 2026-09-29) ; écran de fin, chronique, épilogue | Une vraie fin | 🟡 Réalisée le 2026-09-30 (code, médias validés) ; test en jeu à faire (E1-E10) |
| 5 | Routes A (fleuve) et C (checkpoint), fins bonus, option « Stérilisation » | Le choix de la sortie | 🟡 Codée le 2026-10-01 (lots 0-5) ; relecture, médias des variantes et test en jeu (F1-F16) à faire |
| 6 | Intégrations optionnelles : Siege Night après le dossier (son pilotage de base est fait), ComputerMod, chapitre 4 bonus (Tikitown, Crossroads), DeadMansDossier | Des bonus selon la liste de mods | 🟡 Codée le 2026-10-02 ; relecture et test en jeu à faire |
| 7 | Finition : multijoueur coopératif, équilibrage, relecture des textes, page Workshop | La publication | ⬜ Proposée |

**Jalons** :
- **J1, l'enquête complète** (fin de la phase 3) : du carnet à la sortie du labo avec le dossier.
- **J2, une première fin** (fin de la phase 4) : une partie peut se terminer ; première version partageable, en bêta.
- **J3, version 1.0** (fin de la phase 5) : les trois routes ; puis phases 6 et 7 avant la publication.

**Prochaines étapes** : jalon J1 atteint le 2026-09-30 (`OperationArtemis/docs/test-parcours-nominal-operation-artemis.md`) → phase 4 (route de l'hélicoptère, points d'évacuation sur la carte, fin) ; cas limites reportés de la phase 3 plus tard.

Chaque phase suit la boucle plan / réalisation / contrôle / action (section 7) et se termine par un protocole de test en jeu dans `OperationArtemis/docs/test-phase*-operation-artemis.md`.

## 1. Intention

PZ n'a pas de fin. Une fois la base autonome, il ne reste qu'à attendre la mort. Opération Artemis ajoute :

- **un but** : découvrir ce qu'est l'Opération Artemis, puis quitter la zone d'exclusion ;
- **une raison de partir loin** : les indices sont répartis sur toute la carte de Knox ;
- **un usage du surplus** : carburant, munitions, matériaux, électricité et médecine deviennent des prérequis ;
- **des hordes qui ont un sens** : ce sont des épreuves liées à l'histoire (tenir une zone d'atterrissage, sortir du labo, passer une quarantaine), pas des sièges aléatoires ;
- **une vraie fin** : un écran de victoire, une chronique de la partie et une sortie propre vers le menu.

## 2. Ancrage dans le lore vanilla

Tout ce qui suit existe dans les fichiers du jeu. Le scénario s'y greffe sans contredire le lore officiel.

| Élément vanilla | Source | Usage dans le scénario |
|---|---|---|
| Zone d'exclusion « below the curve of the Ohio river », checkpoints au nord, déploiement militaire au sud de Louisville, déclaration du général McGrew le 9 juillet 1993 | `media/lua/shared/Translate/EN/RadioData.json:716-760` (ex. l.721) | Cadre de l'Exfiltration |
| Chronologie de la presse, 5-15 juillet 1993 : maladie à Muldraugh le 6 juillet, blocus, « Knox Virus » | `Translate/EN/Print_Text.json:11-39` | Dates des documents trouvés |
| AEBS : « Operation Artemis », « they need more data », « escaped », « came from the East » | `Translate/EN/DynamicRadio.json:2-73` | **Nom et fil rouge du scénario** |
| Base secrète `SecretBase` (5534,12437 ; 138×92) et `SecretLab` de z = -1 à z = -17 | `media/maps/Muldraugh, KY/objects.lua:33816-33830` | Lieu final de l'Enquête |
| Carte-cachette WorldStashMap17 (Base.RosewoodMap) : « patrol blindspot », « V will turn off sensors at 23.15 » | `lua/shared/StashDescriptions/WorldStashDesc.lua:199-205`, `Translate/EN/Stash.json:314-316` | Le mystérieux « V » et la fenêtre d'infiltration de 23 h 15 |
| Zones `Army` au sud de Louisville (ligne y ≈ 3950-4100), pont Esther Kinsella à Brandenburg (1448-1538, 5400-5567), zone près de Fallas Lake (7242,8313) et Old Army Road | `objects.lua` (zones `ZombiesType` Army) | Points de contrôle militaires |
| Clark Memorial Bridge (x = 12599, y = 900-1119), vers l'Indiana | `media/maps/Muldraugh, KY/streets.xml:6188` | Sortie nord (route « Checkpoint ») |
| L'Ohio, zone `WaterFlow` « The big river » | `objects.lua`, `worldmap-annotations.lua` | Route « Fleuve » |
| Parkings `radio` (1632,5752 ; 11093,6707 ; 8169,11639 ; 1517,14861), probablement des stations | `objects.lua` | Station relais de la route « Hélicoptère » |
| Aéroport de Louisville (≈ 15330-15610, 2470-3300) | `objects.lua` | Lieu optionnel |

> Les emplacements « probables » sont déduits des noms de zones et doivent être vérifiés en jeu avant de figer les coordonnées.

### Proposition de trame (fiction du mod)

Artemis n'est pas une opération de sauvetage : c'est une **opération de collecte de données**. La zone est maintenue fermée pour étudier l'infection (« they need more data »). « V » est un technicien ou chercheur de la base secrète qui a tenté de faire sortir les données : il coupe les capteurs à 23 h 15 et a laissé des cartes à ceux qui pourraient finir le travail.

La seule façon de sortir est d'avoir **quelque chose que les militaires veulent** : le dossier Artemis et des échantillons. L'Enquête donne donc le moyen de l'Exfiltration, et la fin de partie a un sens.

Le texte exact (documents, émissions) reste à écrire. La trame ne tranche pas « l'origine » de l'infection : elle garde l'ambiguïté du lore vanilla (« came from the East », « escaped »).

## 3. Structure en trois actes

### Acte I — Le Signal (déclenchement)

- **Déclencheur (décidé le 2026-09-27)** : l'opération commence **quand le joueur trouve une note sur l'Opération Artemis sur le corps d'un zombie militaire**. Il n'y a pas de jour imposé : la note elle-même est le déclencheur.
  - La note apparaît sur un zombie en tenue Army à sa mort : `OnZombieDead` + `getOutfitName()`, comme le fait DeadMansDossier. Chaque zombie militaire a une chance (sandbox) de la porter. Un minimum est garanti au bout de K zombies Army tués (sandbox), pour ne pas rester bloqué. Une seule note existe par partie, tant qu'elle n'a pas été lue.
  - Option sandbox facultative : `NoteMinDay` (0 par défaut, donc disponible dès le début) pour les joueurs qui veulent la réserver à la fin de partie.
  - La lecture de la note (Literature avec `printMedia`) **démarre l'opération** : le journal s'ouvre, l'état passe à l'acte I, et la note donne une fréquence militaire fixe, choisie parmi les fréquences libres (le vanilla occupe déjà 95,0 MHz et la plage aléatoire de l'AEBS 88,0-108,0).
- Sur cette fréquence, une **chaîne radio dynamique** de catégorie Military diffuse en boucle des chiffres et des fragments. Quand le joueur l'entend (`OnDeviceText` avec le code `ART1`), le premier lieu est révélé sur la carte et l'acte II commence.

### Acte II — L'Enquête (4 chapitres + finale)

Chaque chapitre = un lieu, un indice principal, une preuve à rapporter, et la révélation du lieu suivant. Le noyau utilise **uniquement des lieux vanilla** ; des variantes « bonus » s'activent si les mods de carte correspondants sont actifs.

| # | Chapitre | Lieu (noyau vanilla) | Variante si mod actif | Ce qu'on y trouve | Preuve |
|---|---|---|---|---|---|
| 1 | Le poste abandonné | Bunker militaire désaffecté de March Ridge (entrée 9921-9926, 12622-12629 ; z -4). *Décision du 2026-09-27 : aucun poste militaire vanilla n'existe à Fallas Lake* | Crossroads-Checkpoint (11557-11958, 7959-8100 ; sous-sols Army z -1 à -4, pièces laboratory) | Ordres de mission Artemis, liste de secteurs, mention de « V » | Badge Artemis (objet) |
| 2 | Les dossiers médicaux | Clinique de West Point (11879-11888, 6872-6886, z 0 ; choix du 2026-09-27) | ComputerMod : mails et notes sur un ordinateur de la clinique ; ComputerModLaptop : portable de chercheur | Dossiers patients du 6 juillet, prélèvements envoyés « à la base » | Dossier patient |
| 3 | Le relais | Station relais avec pylône entre Brandenburg et Riverside (4827-4837, 6277-6285) ; les parkings `radio` ne sont pas des stations | — | Journal du relais : Artemis émet d'ici ; code d'appel pour l'extraction | Code d'appel + remettre le relais sous tension (réutilisé à l'acte III) |
| 4 | Le labo satellite (optionnel) | — | Labo secret de Tikitown (6856-6882, 7556-7589, z -1 à -5) ou labo d'AnruisiTown | Échantillons, notes de « V » | Échantillons (ZVirusVaccine : `LabItems.MatInfectedBlood`, `HumanBrain*`) |
| 5 | **La base secrète** (finale) | `SecretBase` 5534,12437 → `SecretLab` z -1 à -17 | — | Le **Dossier Artemis** au niveau le plus bas | Dossier Artemis |

**La finale** : la carte WorldStashMap17 (renommée « Carte annotée de V ») indique la brèche de patrouille. De **23 h 15 à 1 h 15** (fenêtre de 2 heures, décision du 2026-09-28), les « capteurs » sont coupés. Si le joueur entre hors de cette fenêtre, l'alarme des capteurs sonne tant qu'il est dans la base (phase 3). Sortir des archives avec le dossier déclenche l'alarme **dans tous les cas** (portique), mais le plan de V l'annonce (« Dossier marqué : alarme ! ») : **épreuve « Évasion du labo »**.

### Acte III — L'Exfiltration (3 routes au choix)

Le dossier ouvre les trois routes. Chacune a ses prérequis, qui consomment le surplus accumulé, et une épreuve finale.

| Route | Prérequis | Épreuve finale | Condition de victoire |
|---|---|---|---|
| **A. Le Fleuve** | Bateau (BoatCore/WorkingMotorboat ou Aquatsar), X L de carburant, vivres pour N jours, carte des patrouilles | Passer le pont gardé de nuit (Clark Memorial au nord, ou Esther Kinsella à l'ouest), avec des hordes sur les berges à chaque ravitaillement | Être **dans un bateau** au-delà d'une ligne de sortie, avec le dossier dans l'inventaire |
| **B. L'Hélicoptère** | Relais du chapitre 3 alimenté, code d'appel, fusées éclairantes, zone d'atterrissage dégagée | Rendez-vous donné 2-3 jours plus tard ; **tenir la zone d'atterrissage H heures** contre des vagues dirigées (son de rotor HEEF en approche) | Être dans le rayon de la zone à l'heure H, vivant, avec le dossier |
| **C. Le Checkpoint** | Test d'entrée (ZVirusVaccine ou action du mod) ; dossier pour la variante de fin | Quarantaine d’une heure de jeu maximum, avec ou sans dossier, dans un enclos au pied du pont Clark Memorial, sous attaque ; incident à 30 minutes | Test final négatif sur l'état réel (`BodyDamage:isInfected()`), puis traverser le pont vers le nord |

**Fins** :
- **Sortie avec dossier** : fin principale.
- **Sortie avec le remède** (bonus) : si le joueur a produit `LabItems.CmpSyringeWithCure` (ZVirusVaccine) avant de partir.
- **Sortie sans dossier** : la route C reste possible en quarantaine d’une heure maximum. C'est une fin « tu survis, personne ne saura ».
- Mort : écran de mort vanilla. La chronique est quand même écrite.

**Après une exfiltration réussie (décidé le 2026-09-27)** : un écran de victoire affiche la fin obtenue et la chronique, puis **laisse le choix au joueur** :
- **« Terminer »** : la chronique est écrite dans un fichier, puis la partie est sauvegardée et on revient au menu (`getCore():exitToMenu()`). Un drapeau dans `ModData` réaffiche l'écran de fin si la partie est rechargée.
- **« Continuer (épilogue) »** : la partie continue à l'endroit de l'exfiltration. Le journal marque la victoire et la fin obtenue ; les épreuves du scénario s'arrêtent ; les sièges pilotés par le mod reviennent à leur réglage d'origine. L'écran de fin reste accessible depuis le journal. Le contenu de l'épilogue (ex. revenir chercher d'autres survivants, contrats) est à concevoir plus tard.

**Option « Stérilisation »** (sandbox, désactivée par défaut) : après la lecture du dossier, un compte à rebours de N jours se lance avant le bombardement de la zone. Cela ajoute de l'urgence à la fin de partie ; à l'échéance, la zone est « brûlée » de façon simulée : routes B et C fermées, seul le fleuve reste (décision de la phase 5).

## 4. Les épreuves (le « piment »)

### Constat sur Siege Night (Workshop 3669589584, v2.7.3)

Ce qu'on peut faire depuis un autre mod :
- s'abonner aux callbacks officiels `SN.onSiegeStart`, `onSiegeEnd`, `onWaveStart` et `onBreakStart` (`shared/SiegeNight_Shared.lua:561-577`, table obtenue par `require("SiegeNight_Shared")`) ;
- démarrer un siège avec `sendClientCommand(player, "SiegeNightModule", "CmdSiegeStart", {})` (`server/SiegeNight_Server.lua:2080`) ;
- régler la taille via `SandboxVars.SiegeNight.*` ;
- couper le cycle automatique avec `FirstSiegeDay` / `FrequencyDays` très grands. **Ne pas** utiliser `Enabled = false`, qui coupe tout le moteur (`:2388`).

Ce qu'on ne peut pas faire sans copier son fichier serveur de 2 769 lignes :
- imposer un point d'ancrage libre ou une direction : `initializeClusters`, `pickPrimaryDirection` et `getSpawnPosition` sont `local` ;
- choisir la fin : son siège réussit quand le nombre de kills est atteint ou à l'aube, pas après « H heures tenues ».

### Décision proposée

1. **Un petit moteur d'épreuve dans notre mod** :
   - apparition dirigée par `addZombiesInOutfit` (13 arguments, valide en 42.21) sur un arc autour du point à tenir ;
   - attraction par `getWorldSoundManager():addSound(...)` ;
   - vagues et pauses, minuteur de tenue, compteur, `OnPlayerDeath`.
   Il contrôle entièrement le point, la direction, la durée et la condition de victoire, ce que les épreuves exigent.
2. **Siege Night en option**, pour la pression de fond entre les actes :
   - s'il est actif, le mod le pilote : cycle automatique coupé pendant les actes I et II, puis réactivé avec une fréquence qui augmente après la lecture du dossier (« ils savent ») ;
   - ses callbacks alimentent la chronique.
3. **Tenues des épreuves** : Army pour l'évasion du labo, civils pour la quarantaine. Les zombies « spéciaux » se font par la tenue et la santé (`health`), **sans** modifier temporairement `ZombieLore` comme le fait Siege Night : l'effet de bord sur RealismZombies n'est pas vérifié.

| Épreuve | Déclencheur | Paramètres (sandbox) |
|---|---|---|
| Alarme de la base | Entrée hors fenêtre de 23 h 15 | Zombies Army sur les niveaux traversés |
| Évasion du labo | Prise du dossier | Vagues depuis l'entrée, durée jusqu'à la sortie de la zone |
| Rive gardée | Chaque arrêt de ravitaillement de la route A | Petite horde sur la berge |
| Zone d'atterrissage | Heure H - 2 h | 3 à 6 vagues dirigées, tenir H heures |
| Quarantaine | Entrée dans l'enclos | Vagues pendant une heure maximum, test d'infection final |

### Décisions de la phase 3 (2026-09-29, revue des effets avec l'utilisateur)

Chaque effet a une cause lisible ; pas d'apparition de zombies sans cause.

| Sujet | Décision |
|---|---|
| Déclencheur de l'alarme au dossier | **Portique des archives** : le dossier porte une puce ; quand il sort des archives, le détecteur de la porte fait sonner l'alarme. Le plan de V prévient (« le dossier est marqué, la porte des archives sonnera »). Le dossier reste dans le classeur |
| Entrée hors de la fenêtre (23 h 15 – 1 h 15) | **Alarme dès l'entrée** : capteurs actifs, l'alarme sonne quand le joueur entre dans la base hors fenêtre. Elle sonne **tant qu'il est dedans** ; si la fenêtre s'ouvre (23 h 15), V la coupe. Le journal et le plan le disent |
| Durée de l'alarme du portique | **Jusqu'à la sortie** de l'emprise de la base : sirène et bruit qui attire tant que le joueur est dans la base |
| Garnison | **Sur les niveaux traversés** au retour (-16, -13, sas, surface), soldats zombies en tenue militaire, santé normale, posés d'avance ; nombre selon l'intensité. L'alarme les attire vers le joueur qui remonte |
| Réussite de l'évasion | **Sortir de l'emprise** de la base avec le dossier : l'alarme s'arrête, pensée et entrée de journal, puis la suite de l'acte III |
| Gyrophares | **Clignotement lent** (0,6 s allumé, 0,6 s éteint) en rouge vif pendant l'alarme ; retiré s'il ne se voit toujours pas en jeu |
| Moteur d'épreuve | **Pas de vagues en phase 3** : seulement le suivi de l'épreuve (début, fin, réussite, journal). Les vagues dirigées viendront en phase 4 (zone d'atterrissage) |

### Décisions de la phase 4 (à partir du 2026-09-30, questions une par une)

Recherche : `recherche-phase4-operation-artemis.md`.

| Sujet | Décision |
|---|---|
| Military Drop | **Pont « Military Drop transporte »** (contrat de `MilitaryDrop/docs/analyses/idee-10-extraction.md`) : si Military Drop est actif, son hélicoptère fait l'extraction (le code 7149 d'Artemis remplace sa confiance) et Artemis raconte (acte `DONE`, fin, chronique). Sans lui, Artemis garde **sa propre route B minimale**. L'extraction de Military Drop n'étant pas encore codée, la phase 4 d'Artemis réalise la route B autonome et expose son côté du contrat (événements, détection douce, fréquence réservée) |
| Révélation des points d'évacuation | À la **lecture du dossier** : le dossier nomme les lieux du protocole d'évacuation (texte à compléter, largeur de page à revérifier) ; ils apparaissent sur la carte du monde comme les chapitres |
| Icônes de la carte | **Icônes dessinées pour le mod** (hélicoptère, bateau, barrière) avec leur nom ; routes A et C marquées « à venir » tant qu'elles ne sont pas jouables |
| Zone d'atterrissage (route B) | **Knox Boundary Camp** (camp militaire vanilla au sud de Louisville), champ intérieur ≈ 12560,4218 (à confirmer en jeu : végétation procédurale) |
| Appareil d'appel | **Radio militaire** (talkie militaire, radio de sac ManPack, poste HAM US Army), n'importe où, sans condition de relais ; action du mod qui fait prononcer le code 7149 (transmission vanilla réelle) |
| Fréquence d'appel | **Chaîne Artemis** (108,0 MHz par défaut, option sandbox) ; la réponse de la base y passe |
| Rendez-vous | **Créneau quotidien** ouvert par l'appel : chaque jour à l'aube au camp |
| Créneau et tenue | Rotor entendu vers **5 h**, environ **30 minutes** de jeu à tenir dans la zone, atterrissage vers 5 h 30 ; durée réglable (option sandbox) |
| Vagues | **Hybride** : le bruit (rotor, fusée) attire les zombies présents ; apparitions hors de vue seulement s'il y en a trop peu ; dernière vague en sprinteurs |
| Fusées | **Pas obligatoires** : le pilote lance lui-même une fusée au-dessus du camp en arrivant (`WorldFlares`) |
| Échec | Joueur absent ou sorti de la zone : l'hélicoptère repart et **revient au créneau du lendemain**, sans nouvel appel (pensée et journal) |
| Hélicoptère | **Son, ombre et flèche** (vol de Military Drop) ; une fois posé, **zone marquée au sol** où se tenir, idéalement **fumigène vert** au sol (à la Escape from Tarkov ; faisabilité à vérifier, repli : marqueur vert pulsé + lueur verte) |
| Météo | Brouillard éventuel **dissipé** à l'arrivée du rotor (le pilote a besoin de visibilité) |
| Extraction | **Rester dans la zone** marquée quelques secondes avec le dossier (compte à rebours à l'écran ; sortir l'interrompt), puis fondu au blanc et écran de fin |
| Nouveau personnage après une fin | **Le joueur choisit** : garder la partie terminée ou relancer l'opération |
| Radio en épilogue | **Message final de V** sur la chaîne |
| Écran de victoire | **Grandiose et gratifiant** : image générée (Runware), épilogue qui défile (ce qui s'est passé), chronique ; **voix de V** (ElevenLabs, FR et EN) **et musique** (Suno : l'utilisateur a des crédits, pas de clé d'API connue) ; puis « Terminer » ou « Continuer (épilogue) » (décision du 2026-09-27) |
| Fusée au sol | **Modèle Blender original** (la fusée du mod B41 venait d'EHE, licence TEHE : non réutilisable) posé dans la zone, avec la fumée verte et la lampe verte |
| Musique de fin | « The First Light » (Suno), fournie par l'utilisateur : `OperationArtemis/assets/The First Light.mp3` |
| Radio de l'appel (clarté, retour du concepteur) | **V laisse un talkie de l'Armée américaine dans le classeur des archives**, réglé sur la chaîne Artemis, pile neuve (groupe de pose `ch5_base_radio`, option `tuneRadio`) ; mot manuscrit dans le dossier et objectif du journal qui le disent. Toute autre radio militaire convient |
| Routes A et C « à venir » sur la carte | **Les implémenter maintenant** (phase 5 avancée, demande de l'utilisateur du 2026-09-30) plutôt que de les cacher |
| Fumigènes et fusée | **Mod à part requis, `batman_SignalSmoke`** (projet `Workshop\SignalSmoke`, décision du 2026-09-30) : bibliothèque (fumée colorée et fusée posées par le serveur, vues de tous, restaurées au chargement) + objets jouables dès la v1 (grenades fumigènes de couleur, fusée de route au modèle Blender original) ; réutilisable par Military Drop (extraction, Mayday). Artemis le déclare en `require=` |

### Décisions de la phase 5 (2026-09-30 / 2026-10-01, questions une par une)

Recherche : `recherche-phase5-operation-artemis.md`. Carte explicative de la route A : https://claude.ai/artifact/WxCV4wUDQ6DYeUbCTF1Mj2.

| Sujet | Décision |
|---|---|
| Route A, transport | **Hybride** : avec un mod de bateau (détection `BoatCoreMP.isBoat` / `AquaConfig.isBoat`), on navigue ; sans mod, un passeur de V |
| Route A, sorties | **Deux sorties, deux épreuves** : ouest (x ≤ 0, y 4800-5119) après le pont Esther Kinsella gardé ; nord-est (x ≥ 19800, y 0-299) après un barrage flottant de l'armée à l'est des quais de Louisville |
| Route A, départ | **Bateau de V** au quai de Riverside, clé et emplacement dans le dossier, point sur la carte ; tout bateau de mod convient |
| Route A, épreuve | **Couper les projecteurs** : projecteurs sur groupe électrogène à terre ; groupe coupé → passage dans le noir ; passage éclairé → sirène et horde |
| Route A, nage | **Ignorée** : ne fait pas gagner ; pensée qui l'explique |
| Route A, passeur | **Projecteurs puis appel** : couper le groupe du pont Kinsella, appeler au talkie depuis le quai de Brandenburg, passeur à l'aube, tenir le quai, embarquer (fondu) |
| Route C, lieu | **Pont Clark Memorial**, côté Louisville : enclos posé par le mod ; après le test négatif, la barrière s'ouvre et traverser le pont vers le nord est la sortie (remplace le camp de tentes, trop proche de la route B) |
| Route C, test | **Deux protocoles** : test de ZVirusVaccine à l'entrée (action du mod si ce mod est absent) ; test final du checkpoint sur l'état réel (`BodyDamage:isInfected()`), seul à ouvrir la barrière |
| Route C, test positif | **Refus, enclos rouvert** ; avec ZVirusVaccine, trouver le remède puis revenir ; sans lui, route C fermée à ce personnage (A et B restent) |
| Sans dossier | **Checkpoint seul, une heure maximum** ; fin « tu survis, personne ne saura » ; hélicoptère et passeur ne viennent pas |
| Stérilisation | **Zone brûlée simulée** : à l'échéance, cendres, grondements, zombies plus nombreux et agressifs, routes B et C fermées, seul le fleuve reste ; aucun feu réel |
| Médias des fins | **Tronc commun + variantes** : paragraphes de sortie propres à chaque route, enregistrés avec la même voix ; même musique |
| Bateau du nord-est | **Second bateau de V** aux quais est de Louisville : le Clark Memorial coupe l'Ohio en deux bassins (relevé du 2026-10-01) |
| Balises (retour de l'utilisateur) | **Toujours une fumée verte là où le joueur doit aller pour sortir** (`batman_SignalSmoke`) : zone d'atterrissage, bateaux de V et lignes de sortie du fleuve, groupe de Kinsella puis quai du passeur, poste du checkpoint puis passage du barrage ; posées à la lecture du dossier, retirées quand l'étape est passée (`Story.BEACONS`, `Artemis_BeaconDirector`) |
| Textes des fins | Variantes de l'épilogue **validées** par l'utilisateur (2026-10-01) |
| Son du passeur | **Boucle A, bateau à moteur Tähti de 1922** (Work With Sounds / Werstas, CC BY 4.0, crédit dans `CREDITS.md`), jouée par chaque client pendant l'approche puis au quai (`Artemis_FerryFX`) |

### Décisions de la phase 6 (2026-10-01 / 2026-10-02, questions une par une)

Recherche : `recherche-phase6-operation-artemis.md`.

| Sujet | Décision |
|---|---|
| Siege Night, fréquence | **Moitié du réglage du joueur** après la lecture du dossier (1 jour au moins), options enregistrées jamais modifiées |
| Siege Night, siège de l'acte III | **Le soir de la lecture du dossier**, programmé dans Siege Night (avertissement, siège à l'heure de début) ; V prévient à la radio |
| Siege Night, suspension | **Pendant toutes les épreuves de l'acte III** (transport en approche ou posé, quarantaine, sirène d'un poste gardé), comme pendant l'évasion |
| Computer Mod | **CD + portable de V** : CD gravé dans le classeur de la clinique, portable de V dans les archives de la base ; contenu bonus |
| Chapitre 4 bonus | **Tikitown seul** : notes de V au -4, échantillons à la morgue du -5 ; chapitre sauté sans la carte |
| Disponibilité du chapitre 4 | **Figée à l'entrée dans l'acte II**, journal de debug en cas de saut |
| Chapitre 1 | **March Ridge gardé** ; Crossroads-Checkpoint cité compatible |
| Dead Man's Dossier | **Compatibilité citée** seulement |
| Ravitaillement | **Caisse d'Artemis** sans dépendance, au premier engagement sur une route, fumée verte ; Knox Airdrop cité compatible |
| Railroader | **Mention seule** |

## 4 bis. Dramaturgie : la mise en scène des étapes clés

> Demandée le 2026-09-27. Les effets sont **à confirmer** par la recherche sur les méthodes du moteur 42.21 (sprinteurs individuels, sons vanilla, météo, fondus, panique). Aucun fichier audio ou image maison n'est prévu tant que le vanilla suffit.

### Principes

- **Une courbe de tension, pas un bruit constant.** Chaque scène suit quatre temps : calme inquiétant → signes avant-coureurs → pic → relâchement. Les effets forts restent rares pour garder leur impact.
- **Annoncer avant de frapper.** Un sprinteur ou une horde est toujours précédé d'un signe : cri lointain, silence soudain, grésillement radio, brouillard. Le joueur doit pouvoir réagir ; la peur vient de l'attente, pas d'une mort injuste.
- **Le lore comme décor.** Les effets racontent l'histoire : la voix de « V » qui se coupe, les sujets du labo, les soldats tombés à leur poste.
- **Le joueur garde la main.** Option sandbox `DramaIntensity` (faible / normale / forte) : elle règle le nombre de sprinteurs, la fréquence des cris et la durée des effets visuels. Les fondus et textes à l'écran peuvent être désactivés.

### Palette d'effets (module « Mise en scène »)

| Famille | Effets prévus | Usage |
|---|---|---|
| Présence | Faux cadavres qui se relèvent, rampants, zombies assis immobiles, sprinteurs, « tanks » (santé élevée) | Surprise, pic |
| Son | Cri lointain, hurlement humain, alarme, sirène, coups de feu au loin, rotor d'hélicoptère, grésillement radio, tonnerre | Annonce, ambiance |
| Monde | Brouillard, orage, lumières qui clignotent ou s'éteignent, fusée éclairante | Ambiance, lisibilité |
| Personnage | Hausse de panique, pensées affichées au-dessus du personnage (« Ce n'était pas un zombie… ») | Tension intérieure |
| Écran | Fondu au noir ou au blanc, compte à rebours, cartouche de chapitre (« Chapitre 2 — Les dossiers médicaux ») | Rythme, transitions |

Une **scène** est une suite de repères décrits en données : `{ at = <secondes ou minutes de jeu>, cue = "sound" | "zombies" | "fog" | "thought" | "fade" | "panic" | "lights", … }`. Le moteur de mise en scène les joue dans l'ordre, et chaque type de repère a un seul gestionnaire (principe ouvert/fermé : ajouter un effet = ajouter un gestionnaire, sans toucher aux scènes).

### Scènes par étape clé

**Acte I — La note**
- *Calme inquiétant.* Le soldat qui porte la note est tombé seul, loin des autres.
- *Lecture de la note.* Fondu bref vers le noir, cartouche « Opération Artemis ». Pensée : « Qui écrit ça sur un soldat… ? ».
- *Première écoute, de nuit de préférence.* Grésillement, chiffres récités, puis une voix humaine coupée net par un cri dans la radio. Silence de deux secondes, puis un hurlement **dehors**, au loin. La panique monte d'un cran. **Décision du 2026-09-28** : le cri sort vraiment du haut-parleur. C'est un bruit qui attire les zombies ordinaires des environs, avec la portée vanilla du haut-parleur (volume, intérieur ou extérieur, écouteurs = aucun bruit) × 2 × intensité. Il n'y a plus de sprinteur surgi de nulle part.

**Chapitre 1 — Le poste abandonné**
- Le poste est trop calme : des soldats en uniforme au sol. **Décision du 2026-09-28** : ce sont des **faux morts** (mécanique vanilla). Tombés à leur poste et infectés, ils agrippent qui passe trop près, quoi que fasse le joueur. Plus de réveil lié au badge, qui n'avait pas de cause dans le monde du jeu.
- **Décision du 2026-09-28 — groupe électrogène piégé** : un groupe de secours à l'arrêt dans le bunker. Le démarrer pour avoir de la lumière remet aussi l'alerte sous tension : la sirène hurle et attire le secteur (vrai bruit). C'est le choix du joueur, et la cause se voit.
- Relâchement : **décision du 2026-09-28** : une brume du matin est imposée (environ une heure, légère) seulement si le joueur ressort du bunker à l'aube. La météo imposée par un mod n'est pas sauvegardée.

**Chapitre 2 — Les dossiers médicaux**
- **Décisions du 2026-09-28** :
  - **éclairage de secours** : une lampe sur batterie dans le couloir du bureau, qui clignote parce que la batterie faiblit. Elle marche sans réseau et guide vers le bureau ;
  - **coups sourds** : une salle d'isolement verrouillée contient un **vrai zombie**, qui frappe la porte quand il entend le joueur (comportement vanilla). Le joueur choisit d'ouvrir ou non ;
  - **patient zéro résistant, expliqué** : un zombie en blouse d'hôpital, plus résistant, erre dans la clinique. Le dossier du patient explique pourquoi (il résiste aux sédatifs, ses tissus sont anormalement durs) ; le joueur est prévenu en le lisant. Ce n'est pas le zombie enfermé ;
  - **pensée** après la lecture du dossier : « Six juillet. Ils savaient dès le premier jour. Un relais radio, entre Brandenburg et Riverside. »

**Chapitre 3 — Le relais**
- **Décisions du 2026-09-28** :
  - **bruit du générateur** : des zombies ordinaires sont **posés d'avance aux alentours du relais** (avec les objets du chapitre, hors de la vue du joueur). Le générateur du joueur les attire, par la mécanique vanilla. Pas de cris scénarisés ;
  - **voix de V** : une radio posée dans la salle de contrôle. Quand le relais a du courant et que le joueur l'allume, elle rejoue la bande de V ligne par ligne, avec le code d'appel ;
  - **technicien Miller** : un seul sprinteur, un technicien du relais exposé à l'agent. Le registre le signale (« Miller s'est enfui en courant, il ne dormait plus »). Son corps porte une **pièce d'identité à son nom** : on le reconnaît après l'avoir abattu.

**Finale — La base secrète**
- **Décisions du 2026-09-28** :
  - *fenêtre* : **pas de compte à rebours à l'écran**. Le journal donne la fenêtre et le joueur lit l'heure sur sa montre. La fenêtre dure **2 heures** (23 h 15 – 1 h 15), 30 minutes de jeu étant trop court ;
  - *descente* : les lampes rouges de V **clignotent** (batteries qui faiblissent, comme à la clinique) ;
  - *sujets* : des zombies **assis vanilla** en blouse de patient dans les salles du labo. Ils se lèvent quand ils voient ou entendent le joueur ; aucun script ne les lève ;
  - *le dossier* (phase 3) : l'alarme sonne **toujours** à la prise du dossier, **mais elle est annoncée** : le coffre a son propre capteur que V ne contrôle pas, et le plan le dit (« le coffre sonnera, prépare ta sortie »). C'est un vrai bruit qui attire ;
  - *évasion* (phase 3) : une **garnison posée d'avance** (soldats zombies en tenue de combat, santé normale) dans les niveaux proches de la sortie, présente dès l'arrivée. L'alarme l'attire vers le joueur. Pas de sprinteurs ni de « tanks » ;
  - *alarme* : pas de fondu rouge ; les lampes rouges passent en **clignotement rapide** (gyrophares) ;
  - *remontée* : **brouillard épais imposé** à la sortie, quelle que soit l'heure (choix assumé de l'utilisateur ; météo non sauvegardée) ;
  - *pensée* « Ils vont venir me chercher. Ou me faire taire. » : **à la lecture du dossier**.

**Acte III — Les trois routes**
- *Le Fleuve.* De nuit sous le pont gardé : coups de feu au loin, rafales de sirène. Chaque ravitaillement sur la berge attire une petite horde avec un sprinteur de tête.
- *L'Hélicoptère.* Le rotor se fait entendre de loin, puis de plus en plus fort. Le brouillard se lève, la zone est éclairée par les fusées. Les vagues se succèdent, la dernière est composée de sprinteurs. À l'arrivée : fondu au blanc, puis l'écran de fin.
- *Le Checkpoint.* Annonces régulières par haut-parleur (textes et grésillements). À la vingtième heure, un cri **à l'intérieur** de l'enclos : quelqu'un s'est transformé. Le test final est une vraie attente.

### Sécurité et performance

- Plafond de zombies actifs par scène (réglé par `DramaIntensity`), nettoyage à la fin.
- Aucun effet global permanent : la météo, les lumières et les écrans reviennent à la normale à la fin de la scène, même en cas de mort ou de rechargement (état de scène dans la ModData du mod).
- Sprinteurs : par zombie, **sans** modifier temporairement les réglages globaux de la partie (voir section 4).

## 5. Architecture du mod

### Emplacement et métadonnées

`C:\Users\cyber\Zomboid\Workshop\OperationArtemis\Contents\mods\batman_OperationArtemis\` avec `42.21/mod.info`, `42.21/media/...` et un dossier `common/` (même structure que les correctifs, voir `.claude/pz-knowledge/mod-loading.md`).

```
name=batman_Operation Artemis
id=batman_OperationArtemis
versionMin=42.21
```

Aucun `require` dur. Les intégrations sont détectées par `getActivatedMods()` et par la présence des tables (`SN`, `BoatCoreMP`, `AquaConfig`, `ComputerModComputerTypes`, `ComputerModLaptop`…) ou des objets de script (`getScriptManager():FindItem`). La table `ComputerMod` n'existe pas (relevé du 2026-10-01).

> Nommage : la règle `batman_` + `Fix`/`Compatibility` de `CLAUDE.md` vise les **mods de correctif**. Ce mod est un mod de contenu. Je propose le préfixe `batman_` sans `Fix`, à valider.

### Découpage (fichiers courts, une responsabilité chacun)

| Fichier | Rôle |
|---|---|
| `shared/Artemis/Artemis_Story.lua` | **Données** de l'histoire : chapitres, étapes, conditions, récompenses, textes (clés de traduction) |
| `shared/Artemis/Artemis_State.lua` | État persistant `ModData.getOrCreate("batman_Artemis")` : acte, étape, drapeaux, registre des objets placés, journal, chronique |
| `shared/Artemis/Artemis_Config.lua` | Lecture des options sandbox et valeurs par défaut |
| `server/Artemis_Director.lua` | Machine à états : évalue les conditions (objet possédé, zone atteinte, heure, code radio, épreuve réussie) et applique les effets |
| `server/Artemis_Placement.lua` | Pose des indices et conteneurs à l'arrivée d'une zone (`LoadGridsquare`), une seule fois, via le registre `"x,y,z"` |
| `server/Artemis_Radio.lua` | Chaîne dynamique Military (`DynamicRadio.channels`, `RadioBroadCast`/`RadioLine` avec codes) et réception (`OnDeviceText`) |
| `server/Artemis_Trials.lua` | Moteur d'épreuve : apparition dirigée, attracteur sonore, vagues, minuteur, échec/réussite |
| `shared/Artemis/Artemis_Scenes.lua` | **Données** des scènes dramatiques (suites de repères) |
| `server/Artemis_Staging.lua` + `client/Artemis_StagingFX.lua` | Joueur de scènes : repères côté serveur (zombies, météo, sons qui attirent) et côté client (sons d'ambiance, pensées, fondus, compte à rebours) |
| `server/Artemis_Exfil.lua` | Routes A/B/C : prérequis, détection (bateau à X,Y, rayon de la zone d'atterrissage, enclos), fins |
| `server/Artemis_Integrations.lua` | Adaptateurs optionnels : SiegeNight, BoatCore/Aquatsar, HEEF, ZVirusVaccine, ComputerMod, DeadMansDossier, Railroader |
| `client/Artemis_JournalUI.lua` | Onglet « Opération Artemis » : objectifs, indices lus, lieux révélés |
| `client/Artemis_Map.lua` | Révélation des lieux (`WorldMapVisited:setKnownInSquares`) et symboles quand la carte est ouverte |
| `client/Artemis_EndingUI.lua` | Écran de fin plein écran, écriture de la chronique (`getFileWriter`), puis `getCore():exitToMenu()` |
| `scripts/artemis_items.txt` | Objets : carnet, badge, dossiers (Literature + `printMedia`), carte propre au mod (`ItemType = base:map`, hors distributions), fusées |
| `lua/shared/StashDescriptions/Artemis_StashDesc.lua` | Cartes-cachettes du mod (`StashUtil.newStash`, `addStamp`, `addContainer`) |
| `lua/shared/Translate/EN|FR/*.json` | Textes (documents, émissions radio, journal) |

### Format d'une étape (exemple)

```lua
{
    id = "ch1_badge",
    act = 2, chapter = 1,
    reveal = { x1 = 7200, y1 = 8250, x2 = 7300, y2 = 8350 },   -- zone révélée sur la carte
    place = { { kind = "container", x = 7242, y = 8313, z = 0, items = { "batman_Artemis.MissionOrders" } } },
    complete = { type = "hasItem", item = "batman_Artemis.ArtemisBadge" },
    onComplete = { journal = "IGUI_Artemis_Ch1_Done", next = "ch2_records" },
}
```

Les types de condition sont un petit vocabulaire fermé : `hasItem`, `inArea`, `timeWindow`, `heardCode`, `trialWon`, `inBoatBeyond`, `notInfected`. On peut ajouter un chapitre sans toucher au moteur.

### Briques vanilla confirmées (42.21)

- **Carte-cachette forcée** : `StashSystem.doStashItem(StashSystem.getStash("…"), map)`, puis `AddItem`. C'est le chemin du panneau de debug (`client/DebugUIs/StashDebug.lua:94-99`). Contenu posé au chargement du bâtiment par `StashSystem.doBuildingStash`. Piège : un bâtiment **déjà visité** est ignoré. Pour ces lieux, poser via notre `Artemis_Placement` plutôt que par la cachette.
- **Documents longs** : Literature avec `modData.printMedia = {id, title, info, text}`, affiché par `ISReadABook` (`shared/TimedActions/ISReadABook.lua:209-261`). `PrintMediaDefinitions.MiscDetails[id]` révèle une zone sur la carte (`:300-320`).
- **Radio** : `DynamicRadio.channels` (`server/radio/ISDynamicRadio.lua:15-24, 111-117`), diffusion comme `ISWeatherChannel.lua:88-116`, réception par `Events.OnDeviceText`. Codes courts (4 caractères).
- **Carte du monde** : `WorldMapVisited.getInstance():setKnownInSquares(...)`. Les symboles libres passent seulement par l'interface ouverte (`mapAPI:getSymbolsAPIv2()`). DeadMansDossier fournit aussi `addStashMarker` en option.
- **Fin** : `getCore():exitToMenu()` sauvegarde puis quitte ; un drapeau dans `ModData` réaffiche l'écran de fin si la partie est rechargée.

### Mods optionnels : versions Build 42 uniquement

Règle : le scénario ne cite et n'intègre **que des mods publiés pour la Build 42**, avec une variante `42`/`42.x` et le tag Workshop « Build 42 ». Les mods réservés à la Build 41 sont exclus (ex. Horde Night 2714850307, tagué Build 41). Pour un nouveau mod, vérifier avant de l'intégrer ses dossiers de variante, `versionMin`/`versionMax` dans `mod.info`, et ses tags via l'API Steam (`.claude/pz-knowledge/logs-and-tools.md`).

Vérification du 2026-09-27 (dossiers locaux + tags Steam) :

| Mod (`id`) | Workshop | Variante chargée en 42.21 | Bornes `mod.info` | Tag | À noter |
|---|---|---|---|---|---|
| SiegeNight | 3669589584 | `42` | — | Build 42 | |
| BoatCoreMP | 3781735032 | `42` | min 42.20 | Build 42 | |
| WorkingMotorboatB42MP | 3781923154 | `42` | min 42.20 | Build 42 | |
| AquatsarYachtClubB42 | 3646414716 | `42.17` | min 42.14 | Build 42 | |
| HEF (Helicopter Event Framework) | 3672792485 | `42.13.0` | min 42.13.0 | Build 42 | Variante ancienne : à tester en 42.21 |
| ZVirusVaccine42BETA | 3615135168 | `42.20` | min 42.20 | Build 42 | Titre « B42.14 to B42.20 » : 42.21 non annoncé, à tester |
| ResearchLabInternProfession | 3615135168 | `42.20` | min 42.20.4 | Build 42 | |
| ComputerModkum / ComputerModLaptop | 3725497089 / 3798992436 | `42` | min 42.20 | Build 42 | |
| DeadMansDossier | 3675740871 | `42` | min 42.0.0 | Build 42 | |
| Crossroads-Checkpoint | 3686455777 | `42.0` | — | Build 42 | |
| tikitown (+ Drazion's Tilepack) | 3037854728 (+ 3046728955) | `42` | min 42.0.0 | Build 41 + 42 | Utiliser la variante `42` |
| AnruisiTown | 3659676359 | `42` | — | Build 42 | |
| KnoxAirdrop | 3799630525 | `42` | min 42.0 | Build 42 | Solo uniquement |
| Railroader | 3774360904 | `42` | — | Build 42 | |
| KnoxDetectionKit | 3688879406 | `42` | min 42.0.0 | Build 42 | Aucun objet-preuve |
| ZScienceSkill | 3659195975 | `42.13` | — | Build 42 | Variante ancienne : à tester en 42.21 |

Aucun de ces mods ne déclare de `versionMax` qui exclurait la 42.21, sauf deux variantes anciennes non chargées en 42.21 : `42.14` de ZVirusVaccine (max 42.19) et `42.19` de ResearchLabInternProfession (max 42.20.3), remplacées par leurs variantes `42.20`. Une variante plus ancienne que 42.21 n'est pas une preuve de compatibilité : chaque intégration reste derrière une garde (`if Table and Table.fn then`) et se teste en jeu.

## 6. Options sandbox (première liste)

- Déclenchement par la note : `NoteDropChance` (chance par zombie Army), `NoteGuaranteeKills` (minimum garanti), `NoteMinDay` (0 = dès le début).
- Difficulté des épreuves : multiplicateur de zombies, durée de tenue de la zone d'atterrissage, durée de quarantaine.
- `SterilizationCountdown` (0 = désactivé).
- `DramaIntensity` (faible / normale / forte) et `ScreenEffects` (fondus et textes à l'écran, activés par défaut).
- `SiegeNightControl` (écrit) : ne pas toucher à Siege Night / suspendre ses sièges pendant l'enquête (défaut) / les suspendre dès le début jusqu'au dossier. À venir : fréquence des sièges accrue après le dossier.
- `UseModdedLocations` (Crossroads, Tikitown, AnruisiTown si actifs).
- `DebugMode` : commandes pour sauter une étape, lancer une épreuve, téléporter vers un lieu (tests).

> Les options `type = enum` doivent utiliser `numValues` + `default = <index>` (`.claude/pz-knowledge/load-warnings.md`).

## 7. Méthode, plans détaillés par phase et journal

La liste des phases et leur état sont dans la **feuille de route (section 0)**. Critères de validation en jeu des phases à venir :

| Phase | Validation en jeu |
|---|---|
| 3 | Vagues dirigées, fin sur réussite ou mort, pas de zombies orphelins |
| 4 | Rendez-vous, tenue de la zone, écran de fin, chronique écrite |
| 5 | Détection du bateau (BoatCore et Aquatsar), test d'infection |
| 6 | Chaque intégration absente ne casse rien |
| 7 | Parcours complet à deux joueurs, reconnexion en cours d'acte |

Chaque phase se teste sur une **copie** de sauvegarde, avec un redémarrage complet du jeu, puis la lecture de `console.txt` (erreurs `f:0` et lignes `Artemis`).

### Méthode de développement

Chaque phase suit une boucle **plan / réalisation / contrôle / action** :
1. **Plan** : des sous-agents (Opus) recensent les méthodes Lua et Java du moteur 42.21 nécessaires, et vérifient si l'existant suffit avant d'écrire du code maison (KISS, YAGNI). Le plan de la phase est ajouté ci-dessous.
2. **Réalisation** : code commenté en français ; une responsabilité par fichier (SOLID) ; fonctions pures pour la logique, et effets de bord isolés (écriture ModData, apparition d'objets, UI).
3. **Contrôle** : `luacheck`, validation des JSON, vérification des API utilisées dans le Lua et le Java 42.21, puis relecture par un sous-agent Opus.
4. **Action** : corrections, mise à jour de cette conception, de la base de connaissances (`.claude/pz-knowledge/`) et de la page de présentation.

### Plan de la phase 1 (Acte I)

Découpée en **1a** (mécanique : note, radio, progression) et **1b** (mise en scène de la note et de la première écoute, après la recherche sur les effets).

Méthodes du moteur retenues ; toutes existent en 42.21 et suffisent, le code maison se limite à la colle :

| Besoin | Méthode existante | Code du mod |
|---|---|---|
| Mort d'un zombie militaire | `Events.OnZombieDead(zombie)` + `zombie:getOutfitName()` | Filtre des 4 tenues Army ; marqueur anti double déclenchement (mort par le feu) |
| Note dans le cadavre | `zombie:getInventory():AddItem()` avant la création du corps (`IsoDeadBody.java:327`) | Ajout seulement si absente (`containsType`) |
| Décision d'apparition | `ZombRand`, jour et heure de jeu | Politique pure : chance, minimum garanti après K tués, jour minimum, réapparition après N jours |
| Document lisible | Literature + `modData.printMedia` (`OnCreate`), `ISReadABook` + `PZAPI.UI.PrintMedia` | Script d'objet, fonction `OnCreate`, `Print_Media.json`, `Print_Text.json`, `ItemName.json` en FR et EN |
| Lire = démarrer | `ISReadABook:complete` (solo et serveur) | Enveloppe qui conserve la valeur de retour et ignore une lecture interrompue |
| Chaîne radio | `OnLoadRadioScripts` → `DynamicRadioChannel.new` + `AddChannel` | Fréquence **réglable** (option `RadioFrequency`, 108,0 MHz par défaut, arrondie au pas de 0,2 MHz), `uuid` fixe, vérification par `getRadioChannel` avec message si la fréquence est déjà prise |
| Diffusion en boucle | `RadioBroadCast`, `RadioLine` (codes), `setAiringBroadcast`, `EveryTenMinutes` | Relance quand la diffusion est terminée ou perdue au rechargement |
| Écoute | `Events.OnDeviceText` (client), code `ART1` | Filtre code, distance ±5 cases et étage, acte 1 ; commande `heardSignal` |
| Progression | `sendClientCommand` / `OnClientCommand` | Transitions centralisées côté serveur (`Artemis_Progress`) et revalidées |

Nouvelles options sandbox : `NoteChance` (4 par défaut), `NoteGuaranteeKills` (30, 0 = aucune garantie), `NoteMinDay` (0), `NoteRespawnDays` (7, minimum 1 : avec 0, un carnet perdu bloquerait la partie).

Nouveaux fichiers :
- `shared/Artemis/Artemis_NotePolicy.lua` : décision d'apparition, pure ;
- `shared/Artemis/Artemis_Items.lua` : `OnCreate` de la note ;
- `server/Artemis/Artemis_Progress.lua` : transitions d'acte et journal ;
- `server/Artemis_NoteDrop.lua`, `server/Artemis_ReadHook.lua` et `server/Artemis_Radio.lua` ;
- `client/Artemis_RadioListener.lua` ;
- `scripts/Artemis_items.txt`.

### Plan de la phase 1b (mise en scène de l'acte I)

**Déclenchement.** Le serveur fait avancer l'état (`Artemis_Progress`). Le **client** remarque le passage à un nouvel acte (révision de la ModData) et joue la partie client de la scène. En solo, le serveur ne peut pas envoyer de message au client, donc ce choix marche en solo comme en multijoueur. Au chargement de la partie, l'acte courant est mémorisé sans rejouer de scène. Le **serveur** joue sa propre partie (zombies, bruit qui attire) au moment de la transition.

**Scènes en données** (`shared/Artemis/Artemis_Scenes.lua`) : une scène = une liste de repères `{ at = secondes, cue = type, … }`. Un gestionnaire par type de repère ; ajouter un effet ne touche pas les scènes.

| Repère | Côté | Méthode moteur (vérifiée) |
|---|---|---|
| `sound` | client | `getWorld():getFreeEmitter(x, y, z):playSound(nom)` ; `getSoundManager():playUISound(nom)` |
| `panic` | client | `player:getStats():set(CharacterStat.PANIC, v)` (le battement de cœur suit) |
| `thought` | client | `player:addLineChatElement(texte, r, g, b)` |
| `fade` | client | `UIManager.setFadeBeforeUI`, `UIManager.FadeOut`, `UIManager.FadeIn` |
| `sprinter` | serveur | `addZombiesInOutfit` puis `zombie:doSprinter()`, attiré par `getWorldSoundManager():addSound` |

**Scènes de l'acte I :**
- *Lecture du carnet* : fondu au noir d'une seconde, pensée « Qui écrit ça sur un soldat… ? », légère montée de panique.
- *Premier signal* : grésillement (`RadioStatic`), cri humain dans la radio (`VoiceMaleDeathEaten`, bas), deux secondes de silence, cri lointain dehors (`MetaScream`, à ~60 cases), panique forte. Dix secondes plus tard, selon `DramaIntensity` (0, 1 ou 3 sprinteurs), des sprinteurs en tenue militaire apparaissent à ~30 cases et sont attirés vers le joueur. *Remplacé le 2026-09-28 : le cri est un vrai bruit, sans sprinteur (section 4 bis).*

**Options** : `DramaIntensity` (1 faible, 2 normale, 3 forte), `ScreenEffects` (fondus et pensées, activés par défaut).

### Plan de la phase 2 (acte II, l'enquête)

Recherche du 2026-09-27 par quatre sous-agents Opus : placement, carte, lieux, relais et finale. Tout est confirmé statiquement dans le Java 42.21 et le Lua vanilla, rien n'est testé en jeu. Détails et références : `.claude/pz-knowledge/world-placement.md`, `world-map.md`, `power-and-lights.md`, `knox-geography.md`, `staging-effects.md`. Lieux relevés hors jeu avec `.claude/tools/lotheader_parser.py`.

**Constat qui modifie la conception** : il n'existe **aucun poste militaire vanilla près de Fallas Lake**. La zone `Army` y est le comptoir d'armurerie d'un magasin de jardinage. **Décision de l'utilisateur (2026-09-27)** : le chapitre 1 se passe dans le **bunker militaire désaffecté de March Ridge** ; la radio et le journal de l'acte II sont réécrits (« secteur March Ridge », « le bunker »). Le chapitre 2 se passe dans la **clinique de West Point**.

**Parcours** (noyau vanilla ; le chapitre 4 bonus, Tikitown ou AnruisiTown, passe en phase 6 avec les intégrations) :

| Chapitre | Lieu (coordonnées relevées) | Posé par le mod | Objectif (condition) | Révèle ensuite |
|---|---|---|---|---|
| Entrée dans l'acte II (signal entendu) | — | — | — | Zone de March Ridge + symbole sur la carte |
| 1. Le poste abandonné | Bunker de March Ridge : cabane d'entrée 9921-9926, 12622-12629, escalier 9921,12624-12626 jusqu'à z -4 ; salle 9950-9972, 12600-12650, z -4 | Caisse militaire (conteneur créé si besoin) : **ordres de mission** + **badge Artemis** ; 3 soldats morts en uniforme autour | Avoir le badge (`hasItem`) | Clinique de West Point |
| 2. Les dossiers médicaux | Clinique de West Point, pièce `clinic` 11879-11888, 6872-6886, z 0 (classeur 11879,6882) | **Dossier du patient** (6 juillet, prélèvements envoyés « à la base », mention du relais) | Avoir le dossier | Station relais |
| 3. Le relais | Station relais avec pylône 4827-4837, 6277-6285, z 0 ; salle de contrôle 4832-4837, 6277-6280 ; bureau 4836,6285 | **Journal du relais** et carte vanilla **WorldStashMap17** dans le bureau ; **radio posée** dans la salle de contrôle, sans pile | Relais sous tension (générateur à portée, ou réseau encore actif) et joueur dans la station | Base secrète + fenêtre de 23 h 15 ; **code d'appel** noté dans l'état (acte III) |
| 5. La base secrète | SecretBase : entrée 5584,12483-12484, z 0 ; escaliers jusqu'à z -17 ; archives 5564-5573, 12430-12434, z -17 (classeur 5568,12430) | **Dossier Artemis** | Avoir le dossier → **acte III** | Routes d'exfiltration (phase 4) |

L'alarme de la base (entrée hors de la fenêtre de 23 h 15) et l'évasion du labo sont des épreuves de la **phase 3**.

**Méthodes retenues** (tout existe en 42.21) :

| Besoin | Méthode | Référence |
|---|---|---|
| Moment de la pose | Événement vanilla **`LoadChunk`** (une fois par chunk de 8×8, à la fin du chargement, après les histoires de bâtiment et le butin) : si la case visée existe et que son bâtiment est entièrement chargé (`isFullyStreamedIn()`), on pose. Tentative aussi quand le chapitre devient actif (lieu déjà chargé). **Pas** `LoadGridsquare` (chaque case, avant les histoires), **pas** de sondage (question de l'utilisateur du 2026-09-27) | `IsoChunk.java:3540-3612`, `RandomizedBuildingBase.ChunkLoaded`, `BuildingDef.java:389` |
| Conteneur | Chercher un conteneur des types voulus dans la pièce ; s'il n'est pas encore rempli, le remplir d'abord (`ItemPicker.fillContainer`, `setExplored(true)`) ; sinon créer une caisse (`IsoObject.new`, `createContainersFromSpriteProperties`, `transmitAddObjectToSquare`). Synchronisation MP : `sendAddItemToContainer` | `world-placement.md` |
| Anti-doublon | Registre `placed[chapitre]` dans la ModData, écrit après une pose complète | — |
| Faux cadavres | `RandomizedWorldBase.createRandomDeadBody(sq, dir, 2, 0, "ArmyCamoGreen")`, `setFakeDead(false)`, marque dans la ModData du corps ; relevés en 2b par `reanimateNow`. Créés à l'arrivée du joueur (délai `HoursForCorpseRemoval`) | `RandomizedWorldBase.java:444-507` |
| Preuve obtenue | Sondage de l'inventaire (`containsTypeRecurse`) pour chaque joueur ; en solo, `getSpecificPlayer(i)` (`getOnlinePlayers()` est vide) | `LuaManager.java:3834` |
| Courant du relais | `sq:haveElectricity()` (générateurs) ou `sq:hasGridPower()` dans une pièce | `IsoGridSquare.java:8223`, `:10150` |
| Radio du relais | `IsoRadio.new` sur le sprite `appliances_com_01_0`, sans pile ; message de V affiché par `AddDeviceText` (2b) | `IsoWaveSignal.java:184-209` |
| Carte de la finale | `StashSystem.getStash("WorldStashMap17")`, `doStashItem`, `AddItem` : les annotations vanilla (« V will turn off sensors at 23.15 ») restent dans l'objet | `StashSystem.java:149-180` |
| Révélation | Client : `WorldMapVisited.getInstance():setKnownInSquares` (blocs de 32 cases) ; en MP, en plus la commande vanilla `map/setKnownInSquares` | `ClientCommands.lua:1239` |
| Symbole sur la carte | Client : `UIWorldMap` caché, créé une fois par session, `getSymbolsAPIv2()` (`addTexture`, `addUntranslatedText`) ; doublons évités en cherchant le symbole existant. Le joueur peut l'effacer comme une note, mais il **revient au chargement suivant** (choix : un repère de quête reste disponible). En MP, les révélations sont communes à tous les joueurs (coopération) | `ISWorldMap.lua:643-647` |
| Documents | Objets Literature avec `printMedia`, un seul `OnCreate` pour tous les documents | Acquis de la phase 1 |

**Écarté** : `PrintMediaDefinitions.MiscDetails`. La révélation est désactivée par défaut, et le survol de l'icône d'un identifiant de mod provoque une erreur Lua. Écartées aussi l'alarme vanilla, impossible à arrêter, et les marqueurs de Dead Man's Dossier, non sauvegardés.

**Architecture** (une responsabilité par fichier) :
- `shared/Artemis/Artemis_Story.lua` : les **données** des chapitres (lieu, poses, objectif, révélation, entrée de journal, suivant). Ajouter un chapitre ne touche pas le moteur.
- `shared/Artemis/Artemis_State.lua` : schéma 2 : `chapter` (chapitre en cours), `placed`, `revealed`, `callCode` ; migration depuis le schéma 1.
- `server/Artemis/Artemis_Placement.lua` : pose d'un chapitre (conteneur, caisse, corps), idempotente.
- `server/Artemis/Artemis_Goals.lua` : vocabulaire fermé des objectifs (`hasItem`, `powered`), une fonction par type.
- `server/Artemis_Director.lua` : pose sur `LoadChunk` ; vérifie l'objectif du chapitre en cours seulement pour les joueurs proches du lieu (`EveryOneMinute`, test de distance d'abord) ; appelle `Progress.completeChapter`.
- `client/Artemis_Map.lua` : applique les révélations et les symboles listés dans l'état.
- Scènes : le déclencheur client passe d'un numéro d'acte à un **identifiant de scène** (`lastScene = {id, by, seq}`), pour jouer aussi les scènes de chapitre.
- Objets : badge, ordres de mission, dossier du patient, journal du relais, dossier Artemis ; textes FR et EN.
- Debug : aller au lieu du chapitre, poser maintenant, terminer le chapitre.

**Découpage** :
- **2a, mécanique** : données, pose, objectifs, progression, documents, carte, journal, debug.
- **2b, aides au joueur** (fait) et **2c, mise en scène** (décisions du 2026-09-28, détail dans « Scènes par étape clé ») :
  - chapitre 1 : faux morts (fait) ; groupe électrogène piégé qui déclenche la sirène ; brume du matin si sortie à l'aube ;
  - chapitre 2 : éclairage de secours clignotant ; zombie enfermé qui frappe ; patient zéro résistant expliqué par le dossier ; pensée « Six juillet » ;
  - chapitre 3 : zombies posés autour du relais ; radio posée qui rejoue la bande de V ; technicien Miller sprinteur avec sa pièce d'identité ;
  - base : fenêtre de 2 heures sans compte à rebours ; lampes rouges clignotantes ; sujets assis vanilla ; brouillard à la remontée ; pensée à la lecture du dossier.
  - phase 3 : alarme annoncée à la prise du dossier, garnison posée d'avance, gyrophares.

Chaque sous-phase passe par contrôle, puis action, puis un protocole de test en jeu.

**Retour du test en jeu (2026-09-27), traité en 2b** (écrit le 2026-09-28, test A01-A08 à faire) :
- **Le personnage parle au fil de ses découvertes** (demande de l'utilisateur) : pensées (`thought`) à l'arrivée sur chaque lieu (une fois), à la prise de la preuve, à la fin de la lecture de chaque document (l'indice et la piste suivante), et à la fin du chapitre.
- **Relais compréhensible** : au test, le chapitre 3 s'est terminé dès l'entrée dans la salle de contrôle (réseau encore actif), avant que le joueur ait rien lu ; l'utilisateur « n'a pas compris ce qui s'est passé ». Nouvelle règle : registre du relais **lu** + relais **sous tension** + joueur dans la salle de contrôle ; la bande de V passe alors sur la radio du relais et donne le code d'appel. Pensées d'aide : pas de courant (« il me faut un générateur »), courant mais registre non lu (« des notes dans le bureau ? »). Suppose un registre des documents lus dans l'état (enveloppe de `ISReadABook:complete`, déjà utilisée pour le carnet).
- **Portes de la base et orientation** (retour du test) : **toutes les portes blindées** du bâtiment militaire sont verrouillées. Leur sprite porte `forceLocked` : verrouillage permanent, 2000 PV, aucune clé vanilla (`IsoDoor.java:633-664`, `power-and-lights.md`) et escaliers introuvables, risque de frustration. Proposition : le **badge Artemis devient la clé de la base**. Le moteur n'accepte comme clé qu'un objet de classe `Key` dont le `keyId` égale celui de la porte (`ItemContainer.haveThisKeyId`, `ItemContainer.java:3052` ; `IsoDoor.java:1283, 1348`). Le badge passe donc en `ItemType = base:key`, et le mod donne à toutes les portes de la base un même `keyId` quand elles sont chargées. S'y ajoutent un **plan d'accès** dessiné en document (entrée est, sas, escalier 0 → -13, escalier -13 → -17, archives) et des pensées de guidage à chaque palier. Les niveaux souterrains n'apparaissent pas sur la carte du monde.
- **Recherche dans la base trop fastidieuse** (retour du test : « la base est immense, on n'a aucun indice ») ; proposition soumise à l'utilisateur :
  - un plan d'accès dessiné, en document : entrée est, sas, escalier 0 → -13, couloir, escalier -13 → -17, archives avec le classeur marqué ;
  - un balisage de lampes rouges de secours laissées par V (sas, escaliers, porte des archives), lampes client (`addLamppost`) reposées au rechargement de la zone ;
  - un objectif du chapitre 5 qui se précise selon l'étage du joueur, avec une pensée à chaque palier ;
  - le badge qui ouvre les portes blindées ;
  - les mêmes précisions pour les autres chapitres : le meuble à fouiller, nommé dans l'objectif.
- **Carte de V reconnaissable** : au test, la carte WorldStashMap17 posée au relais passait pour une carte vanilla quelconque. La renommer à la pose (« Carte annotée de V », `setName` + `setCustomName`) et l'annoncer par une pensée.

~~À prévoir en 2c : fusionner `done_ch5_base` dans `act3`.~~ Fait en 2b : `act3` porte la pensée de la prise du dossier, et aucune scène `done_ch5_base` n'existe.

### Plan de la phase 2c (mise en scène de l'acte II)

Recherche du 2026-09-29 par trois sous-agents Opus (bunker et clinique ; relais ; base et points transverses). Tout est confirmé statiquement dans le Java 42.21 et le Lua vanilla, rien n'est testé en jeu. Références : `staging-effects.md` (zombies suivis, assis, brouillard, sirène), `power-and-lights.md` (groupe électrogène, toxicité et masque, portes, clignotement, radio sans pile), `kahlua-lua.md` (`%`), `quest-building-blocks.md` (carte d'identité), `knox-geography.md` (plans).

**Décisions complémentaires de l'utilisateur (2026-09-29)** :
- groupe du bunker **toxique** comme en vanilla, avec une pensée d'avertissement. Un masque à gaz avec filtre, ou un appareil respiratoire, protège des gaz (`IsoGameCharacter.java:13927-13939`) ;
- éclairage de secours de la clinique : une **applique murale** vanilla (`lighting_indoor_02_44-47`) ;
- le chapitre 3 se termine **après l'écoute de la bande de V** ;
- les sujets du labo sont **rassis** quand ils réapparaissent (le jeu ne sauvegarde pas la position assise).

**Constats qui orientent la réalisation** :
- un zombie spécial perd tout à la virtualisation (santé retirée au hasard, vitesse du réglage de la partie, position assise, ModData). On le reconnaît à son retour par `getPersistentOutfitID()` et une zone, sur `OnZombieCreate`, puis on réapplique son trait ;
- aucun événement vanilla pour le démarrage d'un groupe électrogène ni pour l'allumage d'une radio : lecture de `isActivated()` sur **une** case chargée à la minute ; enveloppe de `ISRadioAction:performToggleOnOff` ;
- un brouillard imposé doit être posé **côté serveur** avec une interpolation de 1 (sinon il pulse), et il disparaît au rechargement ;
- dans Kahlua, `%` tronque vers zéro : une plage horaire qui passe minuit s'écrit `((t - debut) + 1440) % 1440 < duree` ;
- les radios vanilla du relais sont dans le bureau, à pile ; le Ham de la salle de contrôle est un décor. Le mod pose sa propre radio, sans pile.

**Lot 0 — socle commun** (réutilisé par tous les lieux) :

| Besoin | Réalisation |
|---|---|
| Scènes rapprochées | `State.withScene` ajoute à une file `recentScenes` (4 au plus) au lieu d'écraser `lastScene` (migration) ; `Artemis_SceneTrigger` joue dans l'ordre les scènes plus récentes que la dernière vue |
| Valeurs de drapeau | `State.withFlagValue` / `flagValue` (fonctions pures ; schéma inchangé) |
| Nouveaux types de pose | `Artemis_Placement` : `generator`, `wallLight`, `lockedRoom` (porte verrouillée + zombie), `zombies` (tenue, assis et orienté contre un mur, anneau hors de vue des joueurs), `radio`, chacun avec sa condition de pose. Nouveaux **groupes** : les parties en cours les reçoivent aussi |
| Zombies suivis | `server/Artemis_TrackedZombies.lua` : à la pose, clé `persistentOutfitID` enregistrée ; sur `OnZombieCreate`, test de la clé et de la zone, puis trait réappliqué (`sprint`, `health`, `sit`) ; sur `OnZombieDead`, objet de fin (carte d'identité, au sol si le zombie brûle). Sert au patient zéro, à Miller et aux sujets |
| Lampes | `client/Artemis/Artemis_Lamps.lua` : ensemble de lampes `addLamppost` (entretenir, retirer, clignoter par `setActive`), sorti de `Artemis_Guide` ; motifs purs dans `shared/Artemis/Artemis_Blink.lua` (`failing`, `lowBattery`, et `alarm` prêt pour la phase 3) |
| Brouillard | `server/Artemis/Artemis_Weather.lua` + repère serveur `fog` : force selon `DramaIntensity`, plafond `MaxFogIntensity` respecté, envoi MP forcé, fin seulement si la valeur est toujours la nôtre (Siege Night) |
| Effets hors du chapitre en cours | `Artemis_Director` appelle les effets d'ambiance **avant** le filtre du chapitre (le badge peut être pris avant que le joueur démarre le groupe) ; nouvelle tentative de pose pour un joueur à moins de 80 cases (anneau posé hors de vue) |
| Logique pure testable | `shared/Artemis/Artemis_Ambience.lua` (étapes de l'alerte, fenêtre de l'aube), `Artemis_Ring.lua` (points de l'anneau), `Artemis_Tape.lua` (repères de la bande) ; ajoutés à `.claude/tools/artemis_plot_test.py` |

**Lot 1 — bunker** :
- **Groupe électrogène piégé** : `Base.Generator_Old`, état 70, réservoir au tiers (carburant 3 sur 10), déjà branché, avec un **masque à gaz** et son filtre posé à côté, dans la salle des machines (9948,12620, z -4, à 16 cases du bureau : il l'éclaire). Au démarrage (lu à la minute, une fois par partie) : pensée « Ça sent les gaz… faut pas que ça tourne longtemps. », sirène `VehicleSirenWall` en boucle côté client, bruit serveur émis **en surface** à la cabane (rayon 60/100/150 selon l'intensité, volume 60) chaque minute. Arrêt : groupe coupé, fin d'un cycle de 20 minutes de jeu ou zone déchargée.
- **Brume de l'aube** : sortie de la cabane dans les 10 minutes après avoir été sous terre, entre l'aube − 1 h et l'aube + 1 h 30, une fois : brume 0,2/0,3/0,4 pendant 60 minutes.

**Lot 2 — clinique** :
- **Applique de secours** : applique murale vanilla sur un mur du couloir (vers 11884,6879 ; case et orientation à fixer à la réalisation) et lampe qui clignote (motif `lowBattery`).
- **Salle d'examen verrouillée** : `medclinic` 11879-11882, 6876-6880, porte unique 11883,6878 verrouillée (`setLockedByKey` + synchro), une infirmière zombie (`Nurse`) à l'intérieur. Un zombie seul n'abîme pas la porte ; elle s'ouvre depuis le couloir si le joueur le veut.
- **Patient zéro** : homme en `HospitalPatient` à l'accueil (11884,6885), santé 4/6/9 selon l'intensité (costaud vanilla : 3,5), suivi pour la garder.
- **Textes** : dossier du patient complété (sédatifs sans effet, aiguille qui plie, tissus anormalement durs, l'infirmière K. Dunn mordue et isolée en salle d'examen 2, « il erre encore dans la clinique ») ; pensée « Six juillet. Ils savaient dès le premier jour. Un relais radio, entre Brandenburg et Riverside. »

**Lot 3 — relais** :
- **Zombies autour** : anneau de 15 à 22 cases autour de la salle de contrôle, 3/5/8 zombies en tenue aléatoire, posés quand aucun joueur n'est dans l'anneau, chacun à au moins 25 cases de tout joueur (relecture : exiger 40 cases et tout l'anneau chargé bloquait la pose sur un écran plus petit que 1080p). Le générateur (rayon 20 à 25, divisé par 2 à l'intérieur) les attire par la mécanique vanilla.
- **Radio de la bande** : radio sans pile posée sur la table de la salle de contrôle (4836,6277), éteinte, sur une fréquence muette. Quand une radio de la salle est allumée avec du courant, elle rejoue la bande de V (7 lignes ambre et 3 parasites, une ligne toutes les 7 s). Chaque allumage relance la bande depuis le début ; l'éteindre l'interrompt. À la fin, le client envoie `HEARD_TAPE` ; le serveur revérifie la salle et le courant, puis marque `heard`.
- **Nouvel objectif** : registre lu **et** bande entendue (la bande exige le courant). Aides dans l'ordre : lire le registre, remettre le courant, puis « Il y a du courant. La radio de la salle de contrôle... ». Objectif et journal réécrits.
- **Miller** : un homme en `Mechanic`, derrière le bâtiment (vers 4818,6274, à confirmer), posé hors de vue, sprinteur suivi dans un rayon de 120 cases. À sa mort, une carte d'identité vanilla `Base.IDcard` au nom de « Dale Miller », technicien, dans le corps (au sol s'il brûle). Registre : « 10/07 : Miller s'est enfui en courant. Il ne dormait plus. »

**Lot 4 — base** :
- **Fenêtre de 2 heures** : textes FR/EN de l'objectif du chapitre 5, du journal du chapitre 3 et du plan de la base (ligne manuscrite « Capteurs : 23 h 15 - 1 h 15 »). Aucune fonction d'horaire avant la phase 3 (YAGNI).
- **Lampes rouges qui clignotent** (motif `failing`), limitées à l'étage du joueur.
- **Sujets assis** : `HospitalPatient`, assis contre un mur et orientés, dans le labo de z -17 (5561-5573, 12437-12442) et les salles de z -16 ; 2, 5 ou 7 selon l'intensité ; rassis à leur retour s'ils sont sur une case contre un mur (zombies suivis).
- **Brouillard à la remontée** : acte III, dossier en main, joueur revenu à la surface dans l'emprise de la base, une fois : brouillard 0,8 pendant 1/2/3 h.
- **Pensée finale** : scène `read_ArtemisDossier` avec une seconde pensée à 4,5 s, « Ils vont venir me chercher. Ou me faire taire. »

**Reporté à la phase 3** : la phrase du plan « le coffre sonnera, prépare ta sortie » (à n'écrire qu'avec l'alarme ; le dossier est dans un classeur, il faudra poser un coffre ou adapter le texte), la fonction de fenêtre horaire, la garnison (même type de pose `zombies`, debout, `ArmyCamoGreen`) et les gyrophares (motif `alarm`).

**Ordre de réalisation** : lot 0, puis les lots 1 à 4, chacun contrôlé (luacheck, tests purs, JSON, parité FR/EN, largeur des pages), puis une relecture Opus d'ensemble et un protocole de test `OperationArtemis/docs/test-phase2c-operation-artemis.md`.

### Plan de la phase 3 (épreuves : alarme de la base, garnison, évasion du labo)

Recherche du 2026-09-29 par deux sous-agents Opus (alarme ; garnison et évasion), confirmée statiquement dans le Java 42.21. Décisions de l'utilisateur : section « Décisions de la phase 3 ».

**Constats** :
- un bruit compte l'étage ×3 dans la distance, traverse les murs avec une pénalité (×1,2 autre pièce, ×1,4 dehors) et ne vit que 16 mises à jour : il faut le réémettre (`WorldSoundManager.java:230-244, 345-352, 465`) ;
- un zombie qui entend part vers le bruit (`pathToSound`) ; la recherche de chemin sait prendre les escaliers en Java, mais le code natif est actif par défaut : **non vérifiable hors jeu** ;
- les zombies virtuels n'entendent qu'un bruit de rayon ≥ 50, à plat : sous 50, rien ne bouge hors de la base (`ZombiePopulationManager.java:452-471`) ;
- l'éclairage est recalculé ~15 fois par seconde (option) et semble fondu : les coupures < 0,1 s du motif `failing` passaient inaperçues ;
- aucun événement ne signale qu'un joueur change de pièce : sondage serveur limité à 1 s réelle (une minute de jeu peut durer 60 s réelles).

**Arbitrages** : attirer la garnison par **une sirène par étage de garnison** (rayon 45, sur le chemin du retour : -16, -13, surface), sans dépendre des escaliers ni attirer les zombies hors de la base ; fin de l'alarme du portique = sortie du porteur hors du bâtiment de surface (même règle que la réussite).

**Réalisation** :

| Élément | Réalisation |
|---|---|
| Données (`Artemis_Story`, ch5) | `alarm` (source `base`, sirène qui suit le joueur, portique : salle des archives 5564-5573 × 12430-12434, z -17 ; capteurs : fenêtre 23 h 15 + 120 min, volumes « dans la base » = hall de surface en intérieur + sous-sol ; scènes ; lampes rouge vif `alarm`) ; `escape` (emprise du bâtiment 5528-5600 × 12428-12512, sirènes d'étage 5554,12467,-16 / 5548,12488,-13 / 5544,12486,0, rayon 45) ; garnison en deux groupes (`ch5_base_garrison_lab` : -16 et -13 ; `ch5_base_garrison_surface` : bureau est et garage), 4/6/8 soldats `ArmyCamoGreen`, posés d'avance à 20 cases au moins du joueur, dans des recoins reliés au chemin sans porte |
| Logique pure | `Artemis_Ambience` : `isInSensorWindow` (`%` sur dividende positif), `isInsideBase`, `isWindowJustOpened`, cause de l'alarme de base ; `Artemis_Trial` (nouveau) : `isInBase`, `isEscaped`, `canStart` (ni en cours, ni réussie), `step` (`success`, `abandon`, `running`) ; `Artemis_Plot` : `startTrial`, `finishTrial` (journal, `surfaced`), `abandonTrial` |
| Serveur | Réalisé en **un seul module** `Artemis_BaseAlarm` (sondage 1 s réelle) au lieu des `Artemis_AlarmCore` et `Artemis_Escape` prévus (KISS : l'alerte du bunker n'a pas été refactorée). Début de l'épreuve = un joueur vivant porte le dossier dans la base (sous-sol ou hall intérieur) hors des archives (portique, mais aussi reconnexion, dossier repris sur un cadavre ou reposé plus loin), jamais après une réussite ; réussite ou abandon ; capteurs hors fenêtre tant qu'un joueur est dedans, coupés par V à 23 h 15 (pensée seulement dans les 10 premières minutes) ; sirènes d'étage toutes les 5 s ; rien n'est décidé sans joueur connecté ; épreuve abandonnée et alarme coupée si le module cesse d'agir (mod désactivé, histoire finie ou redémarrée). `Artemis_Surfacing` attend la fin de l'épreuve ; Siege Night suspendu pendant l'épreuve (règle réappliquée chaque minute) |
| Client | `Artemis_AlarmFX` : sirène jouée à la position du joueur local tant qu'il est dans la base (jamais étouffée) ; gyrophares : `Artemis_Blink` motif `alarm` 0,6 s / 0,6 s synchronisé, `failing` élargi ; `Artemis_Lamps` : couleur changeable (`setR/G/B`) ; `Artemis_Guide` : rouge vif et motif `alarm` pendant l'alarme ; journal : ligne d'épreuve en rouge |
| Textes (`additions_3.py`) | plan de V (capteurs sinon alarme, dossier marqué, portique), objectif ch5, journal (J_Ch3, J_Ch5, J_Escape), pensées (portique, capteurs, coupure par V, sortie), objectif d'épreuve |

**Tranché par l'utilisateur** : un joueur entré pendant la fenêtre et encore dans la base à 1 h 15 fait sonner l'alarme.

**Tests** : protocole `OperationArtemis/docs/test-phase3-operation-artemis.md` (portique, dossier reposé, sortie, capteurs puis coupure par V, fenêtre qui se ferme, garnison posée hors de vue et attirée, rechargement pendant l'alarme, mort pendant l'évasion, Siege Night, gyrophares avec l'option d'éclairage à 5 et 60 images/s).

### Plan de la phase 4 (route B, points d'évacuation, fin)

Recherches du 2026-09-30 (trois sous-agents Opus, lecture seule) : `recherche-phase4-operation-artemis.md`. Décisions : section « Décisions de la phase 4 ». Principe d'état : les nouvelles données vivent dans `state.flags` (`extraction`, `ending`, `endingChoice`, `killsAtStart`), que `State.migrate` recopie déjà en entier : pas de changement de schéma.

**Lots** (chacun contrôlé : luacheck, recherche de `next(`, tests purs, parité FR/EN, largeur des pages) :

| Lot | Contenu | Fichiers |
|---|---|---|
| 0. Données | `Story.EXFIL_POINTS` (hélicoptère au Knox Boundary Camp, fleuve au pont Esther Kinsella, checkpoint au camp de tentes ; routes A et C « à venir ») ; `Story.EXTRACTION` (zone d'atterrissage, rayon de la zone marquée, cases de fumée à côté, créneau 5 h, arc des vagues, minimum de zombies, sprinteurs de la dernière vague) ; option sandbox `ExtractionHoldMinutes` (30) | `shared/Artemis/Artemis_Story.lua`, `sandbox-options.txt`, traductions |
| 1. Carte | Trois icônes SDF blanches 64×64 (générées en Python) déclarées dans un fichier shared ; `Artemis_Map` parcourt aussi `EXFIL_POINTS` quand le dossier est lu (`readDocs`) ; texte du dossier complété avec les lieux (générateur de textes) | `shared/Artemis_MapSymbols.lua`, `client/Artemis_Map.lua`, `media/ui/Artemis/*.png`, `additions_4.py` |
| 2. Appel radio | Menu contextuel « Appeler l'évacuation (code 7149) » sur une radio militaire (`getIsHighTier`, allumée, sur la chaîne Artemis, micro actif, portée ou à 2 cases), acte III ; action courte puis `player:Say` (transmission vanilla) ; commande serveur revérifiée ; le serveur ouvre le créneau quotidien (`flags.extraction`), journal, pensée ; réponse de la base sur la chaîne | `client/Artemis_RadioCall.lua`, `shared/Artemis/Artemis_MilRadio.lua` (d'après `MilitaryDrop_Radio`), `server/Artemis_Server.lua`, `server/Artemis_Radio.lua` |
| 3. Extraction (serveur) | Règles pures `Artemis_Extraction` (états `idle` → `inbound` 5 h → `holding` → `landed` 5 h + durée → `boarding` → `done` ; manqué → lendemain) ; module serveur par sondage de 1 s réelle (modèle `Artemis_BaseAlarm`) ; réussite = porteur du dossier dans la zone marquée N secondes après l'atterrissage → acte `DONE`, `flags.ending` ; ne rien décider sans joueur | `shared/Artemis/Artemis_Extraction.lua`, `server/Artemis_ExtractionDirector.lua`, `Artemis_Plot`, `Artemis_Progress` |
| 4. Vagues hybrides | Bruit du rotor réémis (rayon ≥ 50) ; apparitions hors de vue sur l'arc seulement sous le minimum ; dernière vague en sprinteurs ; plafond | `server/Artemis/Artemis_Waves.lua` (réutilise `Artemis_Placement`, `Artemis_Staging`) |
| 5. Hélicoptère | Copie adaptée de `MilitaryDrop_Flight` et `MilitaryDrop_Heli` (phase `landed`) : son, ombre, flèche ; fusée `WorldFlares` au passage en `landed` ; brouillard dissipé à `inbound` (`Artemis_Weather`) | `shared/Artemis/Artemis_Flight.lua`, `client/Artemis_Heli.lua` |
| 6. Zone d'extraction | Fumée verte et fusée par l'API de `batman_SignalSmoke` (mod requis), marqueur pulsé ; compte à rebours à l'écran | `client/Artemis_ExtractionFX.lua`, `client/Artemis_Countdown.lua`, modèle et script d'objet |
| 7. Écran de victoire | Fondu blanc, pause solo, image plein écran, épilogue qui défile, chronique (jours, zombies tués depuis le carnet, lieux, fin), musique + voix de V (un OGG par langue, `playMusic`), « Terminer » (chronique écrite par `getFileWriter`, `exitToMenu`) ou « Continuer » (`flags.endingChoice`) ; réouverture au chargement si `DONE` sans « Continuer » ; bouton dans le journal | `client/Artemis_EndingUI.lua`, `shared/Artemis/Artemis_Chronicle.lua` |
| 8. Épilogue | Message final de V sur la chaîne à `DONE` ; nouveau personnage après une fin : fenêtre « garder la partie terminée / relancer l'opération » ; pont Military Drop (côté Artemis : événements `batman_OnExtraction…` déclarés, écoute qui passe à `DONE`, fréquence réservée) | `server/Artemis_Radio.lua`, `server/Artemis_NewCharacter.lua`, `shared/Artemis_Bridge.lua` |
| 9. Médias | Image de victoire (Runware) ; épilogue lu par V (ElevenLabs, FR et EN) ; musique « The First Light » (Suno, `OperationArtemis/assets/The First Light.mp3`) ; mixage ffmpeg en un OGG par langue ; modèle de fusée (skill `pz-blender-assets`) | `media/ui/Artemis/`, `media/sound/`, `scripts/` |

**Ordre** : 0 → 1 → 2 → 3 → 5 → 6 → 4 → 7 → 8 → 9, puis relecture Opus et protocole `test-phase4-operation-artemis.md` (parcours nominal d'abord, cas limites ensuite).

### Plan de la phase 5 (routes A et C, fins, stérilisation)

Recherches : `recherche-phase5-operation-artemis.md` (synthèses et relevés de terrain du 2026-10-01). Décisions : section « Décisions de la phase 5 ». Nouvelles données dans `state.flags` (`sterilization`, `checkpoint`, `river`, `ferry`) : pas de changement de schéma.

| Lot | Contenu | Fichiers |
|---|---|---|
| 0. Socle (fait) | Vagues en instances (`Waves.new`), fin générique `Progress.onExit(player, route, exit)` et `Plot.finishExit`, fins et variantes (`Artemis_Endings` : paragraphes, sous-titre, son, image, chronique), option « Stérilisation » (compte à rebours, frappe, après-frappe, routes B et C fermées), textes FR/EN (`additions_5.py`) | `Artemis_Waves`, `Artemis_Endings`, `Artemis_Chronicle`, `Artemis_EndingUI`, `Artemis_Sterilization`, `Artemis_SterilizationDirector`, `Artemis_Radio`, `Artemis_JournalUI`, `Artemis_Map` |
| 1. Données | `Story.CHECKPOINT` (enclos, portail, poste, barrage, ligne de sortie, durée d’une heure maximum avec ou sans dossier, vagues civiles), `Story.RIVER` (bateaux de V, sorties, postes gardés, passeur), points de carte (deux bateaux, quai du passeur, checkpoint), anciens repères à retirer, textes du dossier | `Artemis_Story`, `additions_5.py` |
| 2. Route C | Site posé au chargement (grillage, portail verrouillé, poste de test, haut-parleur, détenu mort) ; test d'entrée (ZVirusVaccine : enveloppe de `ProcessTest` ; sinon action du mod) ; quarantaine (pure : `Artemis_Quarantine`) avec vagues, annonces, détenu relevé après 30 minutes de jeu ; test final sur l'état réel ; passage ouvert dans le barrage vanilla ; sortie y ≤ 958 | `Artemis_Quarantine`, `Artemis_CheckpointSite`, `Artemis_CheckpointDirector`, `Artemis_CheckpointTest` (client) |
| 3. Route A, bateau | Bateaux de V (pose différée, clés posées avec le dossier), postes gardés (groupe électrogène, projecteurs, zone de passage), passage éclairé → sirène et horde sur les berges, sorties ouest et nord-est, nage ignorée | `Artemis_River` (pur), `Artemis_RiverDirector` |
| 4. Route A, passeur | Appel au talkie depuis le quai de Brandenburg (groupe de Kinsella coupé), créneau à l'aube, tenue du quai, embarquement (fondu), son de moteur propre (CC0) | `Artemis_FerryDirector`, `Artemis_RadioCall` |
| 5. Journal et radio | Objectifs des trois routes, diffusions, pensées | `Artemis_JournalUI`, `Artemis_Radio`, `Artemis_Scenes` |
| 6. Médias | Paragraphes des variantes validés, voix et mixages par variante ; image par sortie ou commune | `source/media/artemis_media.py` |
| 7. Contrôle | luacheck, tests purs, traductions, relecture Opus, protocole `test-phase5-operation-artemis.md` | |

### Plan de la phase 6 (intégrations optionnelles)

| Lot | Contenu | Fichiers |
|---|---|---|
| 1. Siege Night | Fréquence divisée par deux après le dossier, siège du soir de la lecture (V à la radio, journal, pensée), suspension pendant les épreuves de l'acte III | `Artemis_SiegePlan` (pur), `Artemis_SiegeNightBridge`, `Artemis_Radio` |
| 2. Computer Mod | CD de la clinique, portable de V ; champs remplis avant la première utilisation | `Artemis_ComputerMod`, `Artemis_Placement` (option `computer`), `Artemis_Story` |
| 3. Chapitre 4 | Chapitres optionnels (`requires`), disponibilité figée à l'acte II (`Artemis_ModMaps`), bordereau au relais (`ifChapter`), labo de Tikitown (notes de V, échantillons de ZVirusVaccine en option `optionalItems`, sujets assis) | `Artemis_ModMaps`, `Artemis_Plot`, `Artemis_Progress`, `Artemis_Story`, `Artemis_items.txt` |
| 4. Ravitaillement | Caisse de V au premier engagement, balise verte jusqu'à ce qu'elle soit vidée | `Artemis_SupplyDirector`, `Artemis_BeaconDirector`, `Artemis_Progress` |
| 5. Textes et contrôle | `additions_6.py`, tests purs, relecture Opus, protocole `test-phase6-operation-artemis.md` | |

### Journal de développement

| Date | Phase | Étape | Résultat |
|---|---|---|---|
| 2026-09-27 | 0 | Réalisation | Squelette, état ModData, journal, debug, FR/EN |
| 2026-09-27 | 0 | Contrôle | luacheck 0 avertissement ; relecture : 1 problème (sondage manette du menu contextuel) |
| 2026-09-27 | 0 | Action | Correctif `setTest()` appliqué ; base de connaissances complétée |
| 2026-09-27 | 1 | Plan | Recherche des API terminée (note, radio, effets), vérifiée par sondage ; plans 1a et 1b rédigés ; faits consignés (`radio-dynamic.md`, `quest-building-blocks.md`, `staging-effects.md`) |
| 2026-09-27 | 1a | Réalisation | Carnet sur les zombies militaires, lecture = début de l'opération, chaîne 108,0 MHz, écoute → acte II, commande de debug « Recevoir le carnet », 4 options sandbox, textes FR/EN |
| 2026-09-27 | 1a | Contrôle | luacheck 0 avertissement (15 fichiers) ; 12 JSON valides, clés FR = EN ; relecture Opus : 0 critique, 0 élevé, 4 moyens, 9 mineurs |
| 2026-09-27 | 1a | Action | Carnet lisible par un personnage illettré (`base:picture`), aucun carnet sur un zombie en feu (le corps brûle avec), réapparition au moins après 1 jour, debug réservé aux rôles autorisés en multijoueur, radio muette avant la lecture du carnet, horloge partagée (`Artemis_Clock`), table de debug unifiée, infobulles et orage mentionnés ; mise en scène serveur branchée sur les transitions (`Progress.commit`) |
| 2026-09-27 | 1b | Réalisation | Minuterie de repères, scènes en données, effets client (sons, panique, pensées, fondus), sprinteurs serveur, options `DramaIntensity` et `ScreenEffects` |
| 2026-09-27 | 1b | Contrôle | luacheck 0 avertissement (21 fichiers), JSON valides ; relecture Opus : 0 critique, 3 élevés, 5 moyens, 6 mineurs |
| 2026-09-27 | 1b | Action | Panique fixée côté serveur (écrasée sinon en MP) ; scène jouée seulement par le joueur déclencheur (`lastScene`) ; `RadioZap` au lieu de `RadioStatic` (son en boucle) ; minuterie robuste aux erreurs ; fondu entrant comme au réveil vanilla ; sprinteurs sur case dehors, libre, au sol, lancés vers le joueur (`pathToCharacter`) ; joueur revérifié à chaque repère ; debug sans scène rejouée ; droits via `checkPermissions` ; luacheck 0 avertissement. **Acte I prêt pour un test en jeu.** |
| 2026-09-27 | 1 | Évolution | **Pilotage de Siege Night** avancé depuis la phase 6 (demande de l'utilisateur, pour éviter un réglage manuel) : `server/Artemis_SiegeNightBridge.lua` masque en mémoire `SandboxVars.SiegeNight.Enabled` et `MiniHorde_Enabled` selon l'acte, sans modifier les options enregistrées ni couper un siège en cours ; option `SiegeNightControl` (ne pas toucher / suspendre pendant l'enquête (défaut) / suspendre jusqu'au dossier). Protocole de test : T17 |
| 2026-09-27 | 1 | Contrôle / Action | Relecture Opus du pont Siege Night : 0 critique, 2 élevés, 3 moyens. Corrigé : date de siège dépassée repoussée d'un cycle (pas de siège de rattrapage au rétablissement, pas d'annonce « ce soir » pendant la suspension) ; siège lancé à la main pendant la suspension rouvert via `SN.onSiegeStart` ; valeurs de référence lues dans les options enregistrées (`getOptionByName`) ; interrupteurs comparés un par un ; garde si l'option est introuvable. Entrée erronée de la base de connaissances corrigée |
| 2026-09-27 | 1 | Évolution | Fréquence de la radio **réglable** (option `RadioFrequency`, demande de l'utilisateur, au cas où un autre mod occuperait 108,0 MHz). Textes du journal et du carnet paramétrés (`%1`) ; le carnet est traduit à sa création avec la fréquence. luacheck 0 avertissement, paramètres FR = EN |
| 2026-09-27 | 1 | Test en jeu | Session de test (partie neuve, option A) : T01, T02, T03, T05 OK ; T04 : page conforme, mais le texte n'apparaît qu'après clic sur le bouton « transcription » vanilla. **Évolution demandée** : `client/Artemis_NoteReader.lua` ouvre la transcription automatiquement pour le carnet (constructeur `PZAPI.UI.PrintMedia` remplacé le temps de l'appel, puis `win:onClickNewspaperButton()`). À revérifier après redémarrage. Constat : `print` Lua perd les accents dans `console.txt` |
| 2026-09-27 | 1 | Test en jeu | Suite de la session : T04 (texte ouvert automatiquement), T06, T07, T08 (carnet obtenu à 4 %), T09 (rechargement en actes I et II), T11 OK ; T10 à refaire à l'acte 0 ; T12 OK mais **retour de l'utilisateur** : chaîne muette avant le carnet = trop scripté. **Évolution** : station de chiffres seule avant la lecture (`NUMBERS_STATION`, sans code), diffusion complète ensuite. Ajout d'un diagnostic debug dans `Artemis_NoteDrop` (`soldat compte : N sur 30`, tenue militaire non reconnue) |
| 2026-09-27 | 1 | Test en jeu — bilan | **17/17 tests validés** (réserves : T02 sans debug, T11 démarrage non observé, T17 étapes 3, 4 et 6). Corrections faites pendant la session : lecture des options à la volée (`getSandboxOptions():getOptionByName`), fondu entrant seulement après un fondu au noir. Pilotage de Siege Night vérifié de bout en bout : suspension, jour 5 sans siège, date repoussée, siège manuel rouvert puis resuspendu. **Phase 1 terminée.** Détail : `OperationArtemis/docs/test-phase1-operation-artemis.md` |
| 2026-09-27 | 1 | Évolution | Deux améliorations acceptées : messages de journal **sans accents** (15 messages, protocole de test mis à jour) ; phrase clé **écrite à la main** sur la page du carnet (« Écoute le %1. / La nuit. » et « — V. », police vanilla `SdfCaveat`, encre bleue, inclinée de 4 à 6°), qui remplace la fréquence imprimée en bas de page. luacheck 0 avertissement, JSON valides, clés et paramètres FR = EN. Rendu à vérifier en jeu (T04) |
| 2026-09-27 | 2 | Plan | Quatre recherches Opus (placement, carte, lieux, relais/finale), consignées dans la base de connaissances (`world-placement.md`, `world-map.md`, `power-and-lights.md`, lieux dans `knox-geography.md`) ; outil `lotheader_parser.py`. Aucun poste militaire à Fallas Lake : chapitre 1 déplacé au bunker de March Ridge, chapitre 2 à la clinique de West Point (choix de l'utilisateur). Plan 2a/2b rédigé |
| 2026-09-27 | 2a | Réalisation | Données des chapitres (`Artemis_Story`), transitions pures (`Artemis_Plot`), état schéma 2 (chapitre, poses, révélations, code d'appel, scènes par identifiant), pose sur `LoadChunk` (`Artemis_Placement`, `Artemis_Director`), objectifs (`Artemis_Goals` : objet porté, courant), carte (`Artemis_Map` : zone + symbole), journal (chapitre, objectif, code d'appel), 5 documents lisibles, radio et journal réécrits pour March Ridge, debug (terminer le chapitre, aller au lieu), migration d'une sauvegarde de phase 1 à l'acte II |
| 2026-09-27 | 2a | Contrôle | luacheck 0 avertissement (31 fichiers) ; JSON valides, clés et paramètres FR = EN ; pages de documents validées par un analyseur qui imite `PrintMedia.lua` ; scénario complet des fonctions pures exécuté sous Lua (`.claude/tools/artemis_plot_test.py`, 29 vérifications). Relecture Opus : **2 critiques/élevés bloquants**, 1 élevé, 4 moyens, 7 mineurs |
| 2026-09-27 | 2a | Action | Corrigé : dossier de la base jamais posé (bâtiment du labo plus large que la zone chargée : pose aussi quand une pièce est explorée, avec nouvelle tentative par minute pour un joueur proche) ; caisse de secours sans conteneur (constructeur `IsoObject.new(getCell(), sq, sprite)`) ; registre écrit avant la pose (pas de doublon après une erreur) ; abonnés client isolés ; réinitialisation de debug qui garde poses et révélations ; pas de chapitre hors de l'acte II ; butin transmis en MP ; corps dans la pièce du dépôt, hors escaliers ; téléportation réservée aux rôles de debug en MP. Base de connaissances corrigée. **Phase 2a prête pour un test en jeu** : [test-phase2a-operation-artemis.md](test-phase2a-operation-artemis.md) |
| 2026-09-28 | 2b-1 | Aides au joueur | Suite au test en jeu arrêté (V01-V07 validés, V08 : base trop difficile). **Plan** : recherche Opus (clé de mod, portes `forceLocked`, lampes, renommage, étage, zones). **Réalisation** : objectifs précis ; pensées à l'arrivée, à la prise des preuves, à la lecture des documents et aux blocages (scènes de données) ; registre des documents lus ; relais = registre lu + courant, avec aides ; carte de V renommée ; registre des poses par groupe ; garde tombé devant la base avec **carte d'accès** (objet `base:key`, `keyId` 714900149 donné aux portes `forceLocked` de la base, `shared/Artemis_BaseDoors.lua`) et **plan d'accès dessiné** ; guide de la base (étape selon l'étage, pensées, lampes rouges de secours) ; debug « Aller au dépôt du chapitre ». **Contrôle** : luacheck 0 avertissement (33 fichiers), clés et parité FR/EN, largeur des pages, tests purs ; relecture Opus : 1 critique (`next()` absent de Kahlua dans le guide), 1 élevé (portes en MP), 3 moyens. **Action** : tout corrigé (test de table vide sans `next`, présence de lampe par `getLamppostPositions`, réapplication du `keyId` autour du joueur sur un client MP, aide « courant » sans distance et après 3 minutes, garde reposé si la carte est perdue avec le corps, pose en attente qui ne bloque plus l'objectif, journal limité à 2 relectures par seconde). Base de connaissances complétée. Tests A01-A06 ajoutés au protocole |
| 2026-09-28 | — | Cohérence | Question de l'utilisateur : pourquoi un sprinteur après l'écoute, pourquoi des corps qui se réveillent à la prise du badge ? Aucune cause dans le monde du jeu. **Décisions de l'utilisateur** : (1) le cri de la radio est un vrai bruit qui attire les zombies ordinaires. Sa portée est celle du haut-parleur calculée par le vanilla (`DeviceData.getDeviceSoundVolumeRange`, 0 avec des écouteurs), envoyée par le client et bornée par le serveur, × 2 × intensité (0,5/1/1,5). Repère `noise`, sprinteurs retirés des scènes ; (2) les soldats du bunker sont des faux morts (`addZombiesInOutfit`, `isFakeDead`). Principe retenu pour la suite : **chaque effet doit avoir une cause lisible dans le monde du jeu** |
| 2026-09-28 | 2c | Décisions | Revue des effets un par un avec l'utilisateur (trois choix plus un libre par effet). Retenus : groupe électrogène piégé (sirène), brume du matin à l'aube, éclairage de secours clignotant, zombie enfermé, patient zéro résistant expliqué par le dossier, pensée « Six juillet », zombies posés autour du relais, radio posée de V, technicien Miller sprinteur avec pièce d'identité, fenêtre de 23 h 15 portée à 2 heures sans compte à rebours, lampes rouges clignotantes, sujets assis vanilla, alarme toujours mais annoncée, garnison posée d'avance, gyrophares, brouillard imposé à la remontée, pensée finale à la lecture du dossier. Retirés : cris au crépuscule, compte à rebours, fondu rouge, sprinteurs et « tanks » sans cause |
| 2026-09-29 | 2c | Plan | Trois recherches Opus (bunker et clinique ; relais ; base et transverse), consignées dans la base de connaissances (zombies suivis par `persistentOutfitID`, zombies assis non sauvegardés, brouillard imposé côté serveur, groupe électrogène sans événement et toxique en intérieur, masque à gaz, radio sans pile, `%` de Kahlua). Décisions de l'utilisateur : toxicité avec avertissement, applique murale, fin du chapitre 3 après la bande de V, sujets rassis. Plan en 5 lots rédigé (section « Plan de la phase 2c ») |
| 2026-09-29 | 2c | Réalisation | Lot 0 : file de scènes (`recentScenes`), registres de valeurs, types de pose par condition (`zombies` avec anneau, assis, profil suivi ; `generator`, `worldItem`, `wallLight`, `lockedRoom`, `radio`), zombies suivis (`Artemis_Tracked`, clé `persistentOutfitID`), ensemble de lampes qui clignotent (`Artemis_Lamps`, `Artemis_Blink`), brouillard serveur (`Artemis_Weather`, repère `fog`). Lot 1 : groupe électrogène, masque à gaz, alerte et sirène (`Artemis_Alarm`, `Artemis_AlarmFX`), brume de l'aube (`Artemis_Mist`). Lot 2 : applique de secours (`Artemis_WorldLights`), infirmière enfermée, patient zéro résistant, dossier et pensée « Six juillet ». Lot 3 : anneau de zombies, radio sans pile, bande de V (`Artemis_RelayTape`, commande `heardTape`, objectif `heard`, aide), Miller sprinteur et sa carte d'identité, registre. Lot 4 : fenêtre de 2 heures, lampes rouges qui clignotent, sujets assis, remontée dans le brouillard (`Artemis_Surfacing`), seconde pensée du dossier. Textes par le générateur (`additions_2c.py`) |
| 2026-09-29 | 2c | Contrôle | luacheck 0 avertissement (47 fichiers), aucun `next(`, tests purs OK (file de scènes, clignotement, anneau, clés de tenue, alerte, aube, bande), 148 clés FR = EN (nouvel outil `artemis_check_translations.py`), largeurs des pages OK, seules les clés voulues modifiées. Relecture Opus : 0 critique, 2 élevés, 3 moyens, 8 faibles |
| 2026-09-29 | 2c | Action | Corrigé : bande jouée sans courant avec une radio à pile (`canBePoweredHere` toujours vrai sur pile → courant de la case) ; anneau du relais jamais posé sur un petit écran (pose point par point, loin des joueurs) ; réinitialisation de debug qui perdait groupe électrogène et applique ; `LoadChunk` qui recopiait l'état à chaque chunk (registre lu brut) ; sujets rassis n'importe où (seulement contre un mur, centrés, animation orientée) ; patient zéro qui pouvait apparaître sous les yeux (`minPlayerDistance`) ; sirène sans fin si le mod est désactivé ; fréquence de la radio qui pouvait tomber sur la chaîne Artemis ; une autre radio n'interrompt plus la bande, rejouable après le chapitre. Base de connaissances complétée. **Phase 2c prête pour un test en jeu** : [test-phase2c-operation-artemis.md](test-phase2c-operation-artemis.md) |
| 2026-09-29 | 2c | Test en jeu | Début du test groupé. Corrigé : identifiant de tenue **négatif pour une zombie femme** (bit de signe), qui empêchait de suivre 4 sujets du labo sur 5. Hors du mod : onglet de Siege Night 2.7.3 en erreur (`getUIText` local déclaré après usage), corrigé par le mod local `batman_SiegeNightPanelFix`. **Évolution demandée par l'utilisateur** : un nouveau personnage dans une carte existante recommence l'opération (`server/Artemis_NewCharacter.lua`, événement `OnNewGame`, solo). Le redémarrage (aussi le debug « Réinitialiser ») efface l'histoire, repose documents et preuves (groupes « à ramasser », sans doublon dans le meuble), garde les objets du monde, retire les repères de carte des lieux non révélés ; carte d'accès reposée si aucun corps de garde ne la porte ; soldats du bunker séparés en groupe `ch1_bunker_soldiers` (migration du registre) |
| 2026-09-29 | 2c | Test en jeu (suite) | Parcours complet après réinitialisation : carnet tombé sur un soldat, cri de la radio (42 cases, sans sprinteur), bunker (documents et groupe électrogène posés), clinique, relais (radio, Miller, bande de V écoutée et validée), base (dossier reposé, sujet suivi retrouvé), **acte III atteint**, Siege Night rétabli. Aucune erreur du mod. **Retours et corrections** : texte de la bande peu lisible → jaune ; registre du relais manqué (aides : une aide déjà dite bloquait les suivantes ; nouvelle aide après la bande) ; mise en scène de la clinique jamais posée car le chapitre s'est terminé avant (poses en attente retentées pour tous les lieux révélés). À relancer : sirène, brume, clinique, anneau du relais, Miller, sujets assis, brouillard de la remontée |
| 2026-09-29 | 1 | Évolution | **Demande de l'utilisateur** : le carnet s'ouvre comme les autres documents (page, puis bouton « transcription » vanilla). `client/Artemis_NoteReader.lua`, qui ouvrait la transcription automatiquement (évolution du 2026-09-27), est supprimé. luacheck 0 avertissement (47 fichiers) |
| 2026-09-29 | 2c | Test en jeu (partie neuve) | Parcours complet sans debug jusqu'à l'acte III et la remontée : carnet au 25e soldat, cri (40 cases), bunker (documents, 3 faux morts, groupe électrogène), clinique (applique, infirmière, patient zéro, tous posés en approchant), relais (anneau 5/5, radio, Miller, bande écoutée), base (dossier, 5 sujets suivis sans erreur, 2 retrouvés), brouillard imposé à la remontée. Aucune erreur du mod ; correctif de Siege Night confirmé. **Retours et corrections** : carnet ouvert comme les autres documents (retrait de `Artemis_NoteReader`) ; lampes de la base dans les couloirs, chemin réel par le -16 (recherche de chemin dans les tuiles, nouvelles étapes et aide « mauvais bloc ») ; station qui se mêlait à la bande (fréquence libre) ; aides du relais remises dans l'ordre |
| 2026-09-29 | 2 | Clôture | **Phase 2 clôturée** par l'utilisateur : acte II jouable de bout en bout, avec aides et mise en scène, validé en jeu sur une partie neuve. Tests non joués acceptés en l'état (cas limites V09-V13, sirène et brume du bunker, carte de Miller, nouveau personnage). Phase 3 lancée |
| 2026-09-29 | 3 | Décisions | Revue des effets avec l'utilisateur : alarme par le portique des archives (dossier marqué), alarme dès l'entrée hors fenêtre tant que le joueur est dedans (coupée par V à 23 h 15), alarme du portique jusqu'à la sortie de la base, garnison sur les niveaux traversés, réussite en sortant de l'emprise, gyrophares en clignotement lent, pas de vagues avant la phase 4 |
| 2026-09-29 | 3 | Plan | Deux recherches Opus (alarme ; garnison et évasion). Bruit : étage ×3, 16 mises à jour, pénalité des pièces ; zombies virtuels sourds sous un rayon de 50 ; escaliers non vérifiables hors jeu → sirène par étage de garnison (rayon 45). Portique et capteurs par sondage serveur à 1 s. Clignotement invisible expliqué (recalcul de l'éclairage ~15/s, fondu). Plan rédigé (section « Plan de la phase 3 ») |
| 2026-09-29 | 3 | Réalisation | Alarme de la base et évasion (`server/Artemis_BaseAlarm.lua`, `shared/Artemis/Artemis_Trial.lua`, règles pures dans `Artemis_Ambience` et `Artemis_Plot`), garnison posée d'avance (2 groupes, 4/6/8 soldats), sirène qui suit le joueur dans la base, gyrophares rouges synchronisés (motif `alarm`, couleur des lampes par `setR/G/B`), objectif rouge dans le journal, Surfacing et Siege Night suspendus pendant l'épreuve ; textes dans `additions_3.py` (plan de V, objectif, journal, pensées), 159 clés FR = EN |
| 2026-09-29 | 3 | Contrôle | luacheck 0 avertissement (49 fichiers), pas de `next(`, tests purs OK, largeurs OK ; relecture Opus : 0 critique, 1 élevé, 2 moyens, 7 faibles. API Java vérifiées (`getCurrentRoomDef`, `setPos`, `setR/G/B` repris par `LightingJNI`, `addSound` diffusé en MP) |
| 2026-09-29 | 3 | Action | Évasion démarrée par un porteur dans la base hors des archives (plus seulement au passage de la porte : reconnexion, cadavre, dossier reposé) ; pas d'abandon sans joueur connecté ; pas de nouvelle évasion après la réussite ; épreuve abandonnée et alarme coupée quand le module cesse d'agir ; alarme resynchronisée sur la cause voulue ; pensée de l'acte III tue si l'évasion a déjà commencé ; Siege Night réévalué chaque minute ; pensée de coupure de V seulement à l'ouverture de la fenêtre ; sirène client limitée à la base (étage compris) ; alerte du bunker muette tant que le lieu n'est pas révélé (après un redémarrage) ; fonction morte `isGateCrossed` retirée. Nouveau test P13. Seconde relecture Opus des correctifs : 0 critique, 0 élevé, 3 faibles corrigés (départ seulement dans le sous-sol ou le hall intérieur, pas dans la marge extérieure ; suspension de Siege Night levée si le mod est désactivé ; porteur sorti cherché seulement près de la base). luacheck 0 avertissement, tests purs OK |
| 2026-09-29 | — | Organisation | Mod **déplacé** (pas copié) de `Zomboid\mods\batman_OperationArtemis` vers le projet local `Zomboid\Workshop\OperationArtemis\Contents\mods\batman_OperationArtemis` (demande de l'utilisateur) ; `workshop.txt` privé ajouté ; chemins des outils et des documents mis à jour ; contrôles relancés depuis le nouvel emplacement (luacheck 0 avertissement, tests purs et traductions OK) |
| 2026-09-30 | 3 | Test en jeu | Partie solo neuve (Siege Night + correctif) : P01-P05, P07, P10, P11 validés ; P06, P08, P09, P12, P13 (cas limites) reportés à la demande de l'utilisateur. Parcours nominal N1-N9 validé (joué plusieurs fois) : **jalon J1 atteint** |
| 2026-09-30 | 4 | Plan | Trois recherches Opus (route B, carte et fin, compléments) : `recherche-phase4-operation-artemis.md`. 17 décisions prises une par une (section « Décisions de la phase 4 »), dont le pont Military Drop et le mod à part `batman_SignalSmoke` pour la fumée et la fusée |
| 2026-09-30 | 4 | Réalisation | Lots 0-3, 5, 7, 8 : données et option, icônes de carte SDF (`.claude/tools/artemis_map_icons.py`), révélation à la lecture du dossier, appel par radio militaire (`Artemis_RadioCall`, `Artemis_MilRadio`), automate de l'extraction (`Artemis_Extraction`, `Artemis_ExtractionDirector`, état « appelé » pour un appel pendant le créneau), vagues hybrides (`Artemis_Waves`), hélicoptère client (`Artemis_Flight`, `Artemis_Heli`), zone et compte à rebours (`Artemis_ExtractionFX`), écran de victoire et chronique (`Artemis_EndingUI`, `Artemis_Chronicle`, `Artemis_Ending`), journal (objectif de l'acte III, bouton « Revoir l'écran de fin »), nouveau personnage après une fin (`Artemis_RestartChoice`), pont Military Drop (`Artemis_Bridge`), diffusions radio de l'acte III et de la fin. Lot 6 : fumée et fusée par `batman_SignalSmoke` (projet `Workshop\SignalSmoke`, v0.1.0 écrite le même jour), déclaré en `require=` |
| 2026-09-30 | 4 | Contrôle | luacheck 0 avertissement (63 fichiers), pas de `next(`, 116 tests purs OK (extraction, vol, chronique), 217 clés FR = EN, largeurs OK. Signal Smoke : 11 tests purs, luacheck OK. Relectures Opus lancées |
| 2026-09-30 | 4 | Action | Relectures Opus corrigées. Artemis : nom provisoire « Bob » pendant `OnNewGame` (choix enregistré par la fenêtre de relance), écran partagé (joueur 0 seulement), écran de fin à la manette (`activeWhilePaused`, boutons A/B), Échap (écran masqué sous le menu de pause), molette, vitesse rétablie, vague finale avant l'intervalle, micro vérifié côté client seulement, appel refusé si un autre mod assure le transport, fusée retirée du sol à l'arrêt. Signal Smoke : **échelle des modèles** (`scale = 0.0066`, le moteur ignore `UnitScaleFactor`), lampes (présence, couleur × 0,5), entrée remplacée, émetteurs, plafond de 75 feux, minuterie de la grenade, souffle pendant toute la fumée. Téléportation de debug vers la zone d'atterrissage. Protocole `test-phase4-operation-artemis.md` (nominal E1-E10). Reste : médias (lot 9) |
| 2026-09-30 | 4 | Médias (lot 9) | Image de victoire (Runware, fumée verte, n° 1 choisie par l'utilisateur), voix de V (ElevenLabs, George, `eleven_v3` créatif, texte annoté, ton confidentiel, effet « vieille bande »), mixage sur « The First Light » en FR et EN : **bande sonore finale validée par l'utilisateur**. Outil `source/media/artemis_media.py`. Phase 4 entièrement réalisée ; test en jeu à faire (E1-E10, et Signal Smoke S1-S5) |
| 2026-10-01 | 5 | Plan | Décisions des routes A et C, des fins et de la stérilisation prises une par une (carte explicative de la route A), deux recherches de terrain Opus (pont Clark Memorial et ZVirusVaccine ; bateaux, postes gardés, passeur) : l'Ohio est coupé en deux bassins → second bateau de V. Plan en 7 lots |
| 2026-10-01 | 5 | Réalisation | Lot 0 : vagues en instances, fin générique (`Artemis_Endings`, `Progress.onExit`), chronique et écran de fin par variante, option « Stérilisation » (`Artemis_Sterilization`, `Artemis_SterilizationDirector`). Lot 1 : `Story.RIVER`, `Story.FERRY`, `Story.CHECKPOINT`, cinq points de carte, anciens repères retirés, dossier réécrit. Lot 2 : checkpoint (`Artemis_Quarantine`, `Artemis_CheckpointSite`, `Artemis_Checkpoint`, `Artemis_CheckpointDirector`, `Artemis_CheckpointVaccine`, `Artemis_CheckpointClient`). Lots 3-4 : fleuve (`Artemis_River`, `Artemis_Boats`, `Artemis_RiverDirector`, `Artemis_RiverFX`, projecteurs liés au groupe dans `Artemis_WorldLights`) et passeur (`Artemis_Rendezvous` commun avec l'hélicoptère, `Artemis_FerryDirector`, appel routé dans `Artemis_RadioCall`, zone généralisée dans `Artemis_ExtractionFX`). Lot 5 : journal à trois routes, pensées, haut-parleur, téléportations de debug |
| 2026-10-01 | 5 | Contrôle | luacheck 0 avertissement (79 fichiers), pas de `next(`, 142 tests purs OK, 303 clés FR = EN, largeurs OK, clés dynamiques présentes. Relecture Opus lancée. Protocole `test-phase5-operation-artemis.md` (F1-F16). Reste : médias des variantes (lot 6, texte à valider) |
| 2026-10-01 | 5 | Action | Relecture Opus corrigée : portail déverrouillé hors de l'acte III (joueur enfermé à vie), règle du portail revue (personne ne reste enfermé, quarantaine d'un joueur déconnecté ignorée), option « Demander à sortir de l'enclos », créneau de l'hélicoptère annulé quand la route se ferme (stérilisation, transport repris par un autre mod), appels refusés sans le dossier (pensée), points de carte selon la présence d'un mod de bateau, poste du fleuve suivi seulement une fois posé, bateau non reposé sur une case occupée, haut-parleur sur une fréquence libre, réponse radio en entiers 0-255 sur un poste posé, réponse « parasites » après la stérilisation, diffusion du passeur, même distance d'appel client et serveur, options visibles à la manette, réveil joué côté client, enclos posé seulement si toutes ses cases sont chargées, frappe jouée pour chaque joueur, hordes plafonnées, pensée « enclos occupé ». 144 tests purs OK, luacheck 0 avertissement. Reste : son du moteur du passeur (aucun son vanilla de bateau), médias des variantes |
| 2026-10-01 | 5 | Évolution | Balises de fumée verte de l'acte III (`Artemis_BeaconDirector`, 9 balises relevées hors de l'eau dans `worldmap.xml`) ; corrigé au passage : fumées du passeur et projecteurs de Kinsella qui tombaient sur l'eau. Son du passeur : trois boucles candidates tirées de Work With Sounds (CC BY 4.0, `assets/ferry`, `source/media/make_ferry_loops.py`). 154 tests purs OK, luacheck 0 avertissement (80 fichiers) |
| 2026-10-01 | 5 | Médias (lot 6) | Son du passeur (boucle A, Work With Sounds, CC BY 4.0, `Artemis_FerryFX`). Voix des fins : 24 paragraphes générés (FR, EN) et vérifiés par transcription, insérés dans la voix validée (alignement Vosk hors ligne, la clé ElevenLabs n'ayant pas le droit de transcription), effet de bande à gain fixe (le graphe complet produisait au hasard des NaN avec ffmpeg 8.1), 8 pistes mixées sur « The First Light », branchées dans `Artemis_Endings`. Image commune |
| 2026-10-01 | 4-5 | Médias | Retour de l'utilisateur (« le son est top, mais 16 secondes avant les paroles c'est trop long ») : voix lancée à **8 s** au lieu de 16 dans les dix pistes de fin (`VOICE_START_SECONDS`), remixées sans régénérer de voix |
| 2026-10-02 | 6 | Plan et réalisation | Trois recherches Opus (Siege Night et mods annexes, Computer Mod, cartes de mods) ; dix décisions une par une ; lots 1 à 5 codés. luacheck 0 avertissement (85 fichiers), 170 tests purs OK, 354 clés FR = EN. Relecture Opus lancée |
| 2026-10-02 | 6 | Contrôle et action | Relecture Opus (0 bloquant, 3 majeurs) corrigée : relevé du chapitre 4 déplacé à la première minute de jeu (pendant `OnInitGlobalModData`, la métagrille n'a pas encore ses pièces : `getRoomAt` renvoie nil) et marqué indisponible s'il est déjà dépassé ; suspension de Siege Night possible pendant son avertissement (épreuves seulement), siège de ce soir gardé au lieu d'être repoussé d'un cycle ; fin de l'avertissement de V calculée en heures de monde ; préavis minimal de 3 h (sinon le lendemain) ; siège déjà en cours compté comme siège du dossier ; avertissement joué pour chaque joueur ; échantillons en plusieurs exemplaires ; CD et portable marqués et nommés ; caisse marquée ; fumée de la caisse sans attendre le dossier ; numéros de chapitre continus ; pensée de la caisse décalée ; caisse annoncée aussi après un appel déjà fait. Accepté et documenté : avec la fréquence divisée par deux, Siege Night atteint plus vite ses paliers de taille (plafonnés par ses sièges terminés). luacheck 0 avertissement, 173 tests purs OK |

### Archive : fichiers et protocoles d'origine des phases 0 et 1

> Archive. L'état actuel est dans la feuille de route (section 0) ; les protocoles en vigueur sont dans `test-phase1-operation-artemis.md` et `test-phase2a-operation-artemis.md`.

**Phase 0 écrite le 2026-09-27**, non testée en jeu. `luacheck` : 0 avertissement ; les 6 JSON de traduction sont valides.

| Fichier | Rôle |
|---|---|
| `42.21/mod.info`, `common/` | `id=batman_OperationArtemis`, `versionMin=42.21` |
| `42.21/media/sandbox-options.txt` | Page « Opération Artemis » : `Enabled` (oui), `DebugMode` (non) |
| `shared/Artemis/Artemis_Const.lua` | Clés (`batman_Artemis`), actes 0 à 4, commandes, `log` |
| `shared/Artemis/Artemis_Config.lua` | Lecture des options avec valeurs par défaut ; debug si `DebugMode` ou jeu lancé avec `-debug` |
| `shared/Artemis/Artemis_State.lua` | Fonctions pures : `new`, `migrate`, `start`, `advance`, `withAct` |
| `server/Artemis/Artemis_Store.lua` | Seule écriture dans ModData ; révision toujours croissante ; `transmit` en multijoueur |
| `server/Artemis_Server.lua` | `OnInitGlobalModData` (charge et normalise), `OnClientCommand` (debug : démarrer, avancer, réinitialiser) |
| `client/Artemis/Artemis_ClientState.lua` | Lecture de l'état : ModData directe en solo, copie reçue du serveur en multijoueur |
| `client/Artemis/Artemis_JournalUI.lua` | Fenêtre du journal, rafraîchie quand la révision change |
| `client/Artemis_Client.lua` | Touche du journal (options de mod, **K** par défaut), menu contextuel « Journal » et sous-menu de debug |
| `shared/Translate/{EN,FR}/{IG_UI,ContextMenu,Sandbox}.json` | Textes FR et EN |

Choix de la phase 0 :
- Le journal reste **invisible** tant que l'opération n'a pas commencé, sauf en mode debug : la note doit rester une surprise.
- En solo, le client lit la ModData directement, car `sendServerCommand` ne fait rien en solo en 42.21 (voir `.claude/pz-knowledge/quest-building-blocks.md`).

**Protocole de test de la phase 0 :**
1. Copier une sauvegarde, activer `batman_Operation Artemis` dans la liste des mods de cette copie, redémarrer le jeu.
2. Au chargement : `console.txt` contient `[OperationArtemis] etat charge : acte 0, revision 1`, sans erreur `f:0` liée à `Artemis`.
3. Sans debug : ni la touche K ni le clic droit n'affichent quoi que ce soit.
4. Activer `DebugMode` (options sandbox de la partie, ou lancement avec `-debug`). Clic droit au sol : « Journal : Opération Artemis » et « Opération Artemis (debug) ».
5. Debug, « Démarrer l'opération » : le journal ouvert passe à « Acte I : le Signal » avec l'entrée datée. Répéter « Passer à l'acte suivant » jusqu'à l'épilogue ; « Réinitialiser l'état » revient à « En sommeil ».
6. Sauvegarder, quitter, recharger : l'acte et le journal sont conservés (ligne `etat charge : acte N`).
7. Vérifier les textes en français puis en anglais (langue du jeu), et la touche dans Options > Mods.

**Protocole de test de la phase 1 (acte I)** — version détaillée, avec 15 tests, résultats attendus et grille à remplir : [test-phase1-operation-artemis.md](test-phase1-operation-artemis.md). Résumé :
1. Même préparation que la phase 0 (copie de sauvegarde, mod activé, redémarrage complet). Au chargement, `console.txt` contient `[OperationArtemis] chaine radio creee sur 108 MHz`.
2. Avec `DebugMode`, clic droit → « Recevoir le carnet Artemis ». Vérifier l'icône, le nom (« Carnet de liaison taché de sang ») et l'action « Inspecter » ; la fenêtre affiche la page crème, puis le texte du carnet.
3. À la fin de la lecture : fondu au noir d'une seconde, pensée « Qui écrit ça sur un soldat... ? », panique légère ; le journal (K) passe à « Acte I : le Signal ».
4. Régler une radio sur **108,0 MHz**, en main puis posée à côté de soi. Au plus tard 10 minutes de jeu plus tard, la chaîne « ARTEMIS » diffuse. À la ligne « Ici relais Artemis… » ou « À quiconque reçoit ce message… » :
   - claquement de parasites, cri dans la radio, silence, hurlement lointain, panique forte et battement de cœur, pensée « Ce cri... ça venait de dehors. » ;
   - le journal passe à « Acte II : l'Enquête » ;
   - environ 15 s plus tard, avec l'intensité normale, un sprinteur en tenue militaire surgit à ~30 cases et fonce vers le joueur (`[OperationArtemis] scene : 1 sprinteur(s) sur 1`).
5. Carnet réel : réinitialiser, mettre `NoteChance = 100`, tuer un zombie en tenue militaire, fouiller le corps. Le carnet s'y trouve (`carnet Artemis place sur un zombie en tenue ...`). Refaire en le tuant par le feu : aucun carnet, par conception.
6. Personnage Illettré : « Inspecter » doit fonctionner.
7. Avant la lecture du carnet, le 108,0 doit rester muet.
8. Sauvegarder, quitter, recharger pendant l'acte II : aucune scène rejouée, la radio reprend sa diffusion.

## 8. Décisions

Prises le 2026-09-27 :
1. Déclenchement : la note trouvée sur un zombie militaire lance l'opération (section 3, acte I).
2. Compte à rebours « Stérilisation » : option sandbox, désactivée par défaut.
3. Fin : le joueur choisit entre « Terminer » (retour au menu) et « Continuer (épilogue) » (section 3, fins).
4. Lieux des mods de carte : bonus facultatifs ; le parcours principal n'utilise que des lieux vanilla.

Prises ensuite :
5. Nom et `id` : `batman_OperationArtemis` est conservé (préfixe `batman_` pour retrouver tous les mods de l'utilisateur).
6. Langue des textes : français et anglais.
7. Chapitres 1 et 2 : bunker de March Ridge et clinique de West Point (2026-09-27).
8. Cohérence (2026-09-28) : chaque effet a une cause lisible dans le monde du jeu ; cri de la radio en bruit réel, faux morts au bunker.
9. Mise en scène de l'acte II (2026-09-28) : effet par effet, section 4 bis ; fenêtre de la base portée à 2 heures.

## 9. Risques et points à vérifier

- Les lieux de l'acte II sont relevés et confirmés en jeu (test du 2026-09-27). Restent à relever pour l'acte III : checkpoint sud, zone d'atterrissage, points de sortie du fleuve.
- `LoadGridsquare` se déclenche à chaque rechargement : le registre anti-doublon est indispensable.
- Deux systèmes de bateaux actifs (BoatCore et Aquatsar) : la détection doit accepter les deux.
- HEEF : un seul événement à la fois, et un centre qui suit le joueur. Il sert au son d'approche, pas à un hélicoptère visible.
- ZVirusVaccine est en BETA et variante 42.20 : ses objets sont utilisés seulement s'ils existent (`getScriptManager():FindItem`).
- Performance : limiter le nombre de zombies actifs par épreuve (plafond sandbox) et nettoyer les vagues restantes à la fin.
