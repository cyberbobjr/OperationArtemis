# Opération Artemis — recherche de la phase 5 (routes du fleuve et du checkpoint, fins, stérilisation)

Recherche Opus en lecture seule du 2026-09-30. **Rien n'est testé en jeu.** Route A (fleuve) : recherche en cours au moment de l'écriture, à ajouter ici.

## Route C (checkpoint) — synthèse

- **Infection** : lire `BodyDamage:isInfected()` sur le serveur (synchronisé en MP). `CharacterStat.ZOMBIE_INFECTION` n'est pas l'infection (progression vers la mort, 0 avec Mortalité « Jamais »). Fausse infection (`isFakeInfected`) → test négatif. Aucun test ni objet de test vanilla. ZVirusVaccine installé (3615135168, `ZVirusVaccine42BETA`, variante 42.20) : son résultat négatif est un instantané sans date ni propriétaire, pas un laissez-passer ; son remède fait `setInfected(false)`.
- **Lieu** : la cour du QG du Knox Boundary Camp (12476-12493 × 4302-4323), fermée, avec 6 cages grillagées 4×4 (ex. 12481-12484 × 4307-4310), une infirmerie (12494-12497 × 4303-4312) et un projecteur ; accès unique par le portail x 12476, y 4302-4305. Les tentes n'ont pas de porte. Autres checkpoints routiers vanilla : 13416,3959 ; 14523,3982 ; 15553-15600 × 3858-3982.
- **Portails** : `IsoDoor` doubles ; verrouiller tous les éléments, `setKeyId(≥ 100000000)` (sinon `-1` en extérieur), `syncIsoObject` en MP ; `forceLocked` inutilisable.
- **Quarantaine** : sondage serveur à la minute, `flags.quarantine`, durée en heures de monde ; sommeil déjà limité par le vanilla sous menace ; réveil forcé `forceAwake` à la 20e heure ; radio de campagne posée (`IsoRadio` + `AddDeviceText`, bruit qui attire) comme haut-parleur ; détenu mort posé dès l'entrée, relevé à la 20e heure (`reanimateNow`, sauf `HoursForCorpseRemoval <= 0`).
- **Vagues** : `Artemis_Waves` a des compteurs de module → une instance par route (la zone B est dans le même camp, à ≈ 90 cases).
- **Fins** : `Progress.onExtractionSuccess` est codé pour B → `Progress.onExit(player, route, variant)` générique, `ending.variant` (`dossier`, `cure`, `nodossier`), nouvelles clés de chronique ; remède par `FindItem("LabItems.CmpSyringeWithCure")` (et `CmpSyringeReusableWithCure`). L'épilogue et la voix actuels sont écrits pour la route B.
- **Stérilisation** : ne jamais utiliser `StartFire`/`explode` (dégâts durables à la carte). Possible sans dégât : `IsoTrap` avec `Base.PipeBomb` posé par le serveur (explosion sans feu), `triggerThunderEvent` (éclair et grondement synchronisés), sons `PipeBombExplode`/`BurnedObjectExploded`, `player:Kill(nil)` sur le serveur.

## Décisions à soumettre (non encore posées à l'utilisateur)

1. Lieu : cage du QG (recommandé) / toute la cour / checkpoint routier séparé (13416,3959).
2. Test sanguin : action du mod au poste de test à l'entrée et à la sortie / idem + ZVirusVaccine remplace le test d'entrée / un seul test à la fin.
3. Positif à la fin : refus, cage rouverte / fin d'échec racontée / mort en quarantaine.
4. Sortie après le négatif : fondu à la guérite sud / bateau sur l'Ohio / hélicoptère de la route B.
5. Sans dossier : route C seulement, quarantaine de 72 h / toutes les routes / aucune.
6. Stérilisation : frappe entendue puis fin d'échec sans mort / frappe réelle puis mort / zone brûlée simulée.
7. Médias des fins : textes variants et voix commune raccourcie / une voix par fin / seule la chronique change.

## Route A (fleuve) — synthèse

- **Aucun bateau pilotable ni nage en vanilla 42.21** ; une case d'eau bloque tout déplacement. Mods Build 42 installés : BoatCoreMP (3781735032) + WorkingMotorboatB42MP (3781923154), variante `42` (min 42.20) ; AquatsarYachtClubB42 (3646414716, médias 42.17) ; TrueSwimming (3802372726). Détection : `player:getVehicle()` puis `BoatCoreMP.isBoat(v)` ou `AquaConfig.isBoat(v)`. Pièges : collision `vehicle BoatMotor` entre BoatCore et Aquatsar, le bateau BoatCore freine devant tout sol (tablier de pont compris), physique non testée en 42.21. Quais : Brandenburg 1634,5581 (à 150 cases du pont), West Point 11823,6574, Riverside 6037,5211, Wyandotte, Louisville East Docks (en amont du Clark Memorial).
- **Le joueur peut quitter la carte** : monde de ±250 cellules, génération procédurale au-delà ; `WorldGenOverride.lua` prolonge l'Ohio à l'ouest (x ≤ 0, y 4800-5119) et au nord-est (x ≥ 19800, y 0-299), et l'autoroute du Clark Memorial au nord (x 12590-12609, y ≤ 900). Serveur dédié `-no-worldgen` : rien au-delà.
- **Pont Esther Kinsella : un moignon** (tablier x 1482-1509, y 5400-5516, s'arrête au milieu du fleuve) avec zones militaires vanilla (soldats zombies) sur le tablier et un camp sur la rive sud ; un bateau le contourne par le nord. **Clark Memorial** : tablier continu jusqu'au bord de la carte, il barre l'Ohio aux bateaux.
- **Sortie ouest recommandée** : x ≤ 0, y 4800-5119 (≈ 1600 cases au nord-ouest du pont). La sortie nord-est évite tout pont.
- **Épreuve du pont** : soldats (`addZombiesInOutfit`, zones Army), projecteurs sur groupe électrogène posé (lampes client, recréées), sirène (modèle `Artemis_Alarm`), tirs lointains `MetaAssaultRifle1` (ambiance), déclenchement par sondage serveur ; ravitaillements = débarquement détecté, horde hybride (`Artemis_Waves` à généraliser en `spawnRing(center, cfg)`).
- **Trois conceptions** : A1 bateau de mod requis (bateau et dépôts de V, pont de nuit, ligne ouest ; coût élevé) ; A2 sans mod, barrage militaire sur le Clark Memorial franchi à pied ou en véhicule (coût faible, perd le bateau) ; A3 hybride avec passeur de V si aucun mod de bateau (coût moyen, proche de la route B).

## Décisions de la route A à soumettre

1. Transport : mod de bateau requis / hybride avec passeur / pont terrestre seulement.
2. Ligne de sortie : ouest x ≤ 0 / ouest plus loin x ≤ -200 / nord terrestre (Clark) ; et la sortie nord-est sans pont : interdite, gardée ou ignorée.
3. Départ : libre / bateau de V posé en amont (clé dans le dossier) / dépôts de V obligatoires.
4. Épreuve du pont : furtive / couper le groupe électrogène à terre / passage en force.
5. Nage : ignorée / fin distincte (dossier mouillé sauf sac étanche) / refusée.

## Décisions prises (2026-09-30)

Carte explicative : https://claude.ai/artifact/WxCV4wUDQ6DYeUbCTF1Mj2 (fond tiré de `worldmap.xml`, repères placés à la main).

| Sujet | Décision |
|---|---|
| Route A, transport | **Hybride** : un mod de bateau détecté (`BoatCoreMP.isBoat` / `AquaConfig.isBoat`) permet de naviguer ; sans mod, un passeur de V fait la traversée. |
| Route A, sorties | **Deux sorties, deux épreuves** : l'ouest (x ≤ 0, y 4800-5119) après le pont Esther Kinsella gardé ; le nord-est (x ≥ 19800, y 0-299) après un barrage flottant de l'armée à l'est des quais de Louisville. |
| Route A, départ | **Bateau de V** : un bateau posé à un quai (Riverside par défaut), clé et emplacement dans le dossier, point affiché sur la carte ; tout autre bateau de mod fonctionne aussi. |
| Route A, épreuve | **Couper les projecteurs** : projecteurs sur groupe électrogène à terre (pont Kinsella, barrage nord-est) ; groupe coupé → passage dans le noir ; passage éclairé → sirène et horde. |
| Route A, nage | **Ignorée** : sortir à la nage ne fait pas gagner ; une pensée prévient qu'on ne passera pas à la nage avec le dossier. |
| Route A, passeur (sans mod de bateau) | **Projecteurs puis appel** : couper le groupe du pont Kinsella, puis appeler au talkie depuis le quai de Brandenburg ; le passeur arrive à l'aube, tenir sur le quai, embarquer (fondu). |
| Route C, lieu | **Pont Clark Memorial** (côté Louisville) : enclos de quarantaine posé par le mod au pied du pont ; après le test négatif, la barrière s'ouvre et traverser le pont vers le nord (y ≤ 900, route générée) est la sortie. Remplace les cages du Knox Boundary Camp (même camp que la route B : confus). Lieu exact à relever ; l'icône `route_c` de `Story.EXFIL_POINTS` (12472,4240) est à déplacer. Les décisions « Lieu » et « Sortie après le négatif » de la liste ci-dessus sont ainsi tranchées ensemble. |
| Route C, test sanguin | **Deux protocoles militaires** : à l'entrée, le test de ZVirusVaccine (kit et feuille de résultat du mod) ; à la fin, un second test du checkpoint sur l'état réel du personnage (`BodyDamage:isInfected()` côté serveur) qui seul ouvre la barrière. Par défaut, sans ZVirusVaccine actif, le test d'entrée est une action du mod au poste (à confirmer en revue). |
| Route C, test final positif | **Refus, enclos rouvert** : la barrière reste fermée, l'enclos s'ouvre, la partie continue. Avec ZVirusVaccine (`ZVirusVaccine42BETA`, variante 42.20) actif, le joueur doit trouver le remède (`LabItems.CmpSyringeWithCure` / `CmpSyringeReusableWithCure`, qui fait `setInfected(false)`) puis revenir refaire la quarantaine. Sans ce mod, aucun remède vanilla : la route C est fermée à ce personnage, les routes A et B restent possibles. |
| Sans dossier | **Checkpoint seul, 72 h** : sans dossier, seule la route C accepte le joueur, quarantaine de 72 h ; fin « tu survis, personne ne saura » (`ending.variant = "nodossier"`). Hélicoptère et passeur ne viennent pas. |
| Stérilisation (option sandbox) | **Zone brûlée simulée** : à l'échéance, le joueur survit mais le monde change (brouillard de cendres, grondements et éclairs `triggerThunderEvent`, zombies plus nombreux et agressifs), routes B et C fermées (l'armée est partie) ; seul le fleuve reste. Aucun feu ni explosion réels (pas de `StartFire`/`explode`). |
| Médias des fins | **Tronc commun + variantes** : paragraphes communs (Artemis, dossier) ; 2-3 paragraphes de sortie propres à chaque route (bateau, passeur, checkpoint, checkpoint sans dossier), enregistrés à part avec la même voix (George, `eleven_v3`, effet de bande) ; même musique ; image par sortie ou commune. |
| Route A, bateau du nord-est | **Second bateau de V** aux quais est de Louisville (≈ 12823,1153) : le Clark Memorial coupe l'Ohio en deux bassins (ouest : Riverside, Brandenburg, Kinsella, sortie ouest ; est : quais de Louisville, sortie nord-est). Le dossier dit « Riverside pour l'ouest, Louisville pour l'est ». |

## Relevés de terrain (deux recherches Opus, 2026-10-01, lecture seule, rien testé en jeu)

### Route C : pont Clark Memorial (plan ASCII : scratchpad `plan_clark_sud.txt`)
- Tablier entièrement à **z 0** (aucune rampe), y 900 → rive ; parapets bas enjambables (`walls_garage_02_20`) ; chaussée x 12592-12606 ; rive ouest en herbe dès y ≈ 1033, rive est à y 1120. Au nord de y 900 : prefab généré `highway_NS_00` (`WorldGenOverride.lua:9-10`).
- **Barrage vanilla en plein fleuve, x 12590-12608** : y 961 barrière militaire `fencing_01_96` (solidtrans), y 962-963 double grillage barbelé `fencing_01_88/89` (CantClimb), y 964 blocs `street_decoration_01_28`. À pied, impossible de passer au nord de y 960 sans le casser : **c'est la barrière du checkpoint** ; le mod y ouvre un passage après le test négatif.
- Embouteillage vanilla (véhicules) sur x 12593-12605, y 966-1199. Aucune zone `Army` ni tente à 150 cases.
- **Enclos** : cases intérieures x 12613-12618, y 1167-1172, esplanade dallée extérieure entre la salle de sport (mur sud y 1164) et les restaurants (y 1182) ; lampadaire en 12620,1172.
- **Ligne de sortie** : y ≤ 958 sur x 12590-12609 (dans les données vanilla ; y ≤ 899 n'existe qu'avec le monde généré).
- Grillage : `fencing_01_88/89` (N), `90/91` (O), poteau `92` ; `IsoObject.new(cell, sq, sprite)` + `sq:transmitAddObjectToSquare(o, -1)`. Un grillage n'est plié que par `FenceThumpersRequired` zombies (50 par défaut). Portail : `IsoThumpable.new(cell, sq, "fixtures_doors_fences_01_128", "fixtures_doors_fences_01_130", false, {})`, `setIsDoor(true)`, `setKeyId`, `setLockedByKey(true)`, `setIsDismantable(false)`, `AddSpecialObject` + `transmitCompleteItemToClients`, puis `sync()` (le verrou n'est pas transmis seul). Éviter `IsoDoor` « fences » (100 PV).
- Barrière : retirer des objets par `sq:transmitRemoveItemFromSquare(obj)` plutôt que changer le sprite (collision).
- ZVirusVaccine : prélèvement (`LabSyringe` + `AlcoholedCottonBalls` → `CmpSyringeWithBlood`, `md.IsInfected` figé au prélèvement), test à moins d'une case d'un spectromètre (`demonius_vaccine_01_8..11`, vérifié côté client), résultat `LabTestResultNegative` **sans ModData**. Détection serveur recommandée : envelopper `require("HealthSystem/BloodTestLogic_Server").ProcessTest` (renvoie `"Positive"`/`"Negative"`/`"InvalidSample"`). Remède : guérison toujours (`CurePlayer` : `setInfected(false)`, etc.). Mod actif : `getActivatedMods()` contient `ZVirusVaccine42BETA`.

### Route A : fleuve
- **Deux bassins** (voir décision ci-dessus).
- Bateau : `getScriptManager():getVehicle(nom)` ; BoatCore → `Base.BoatSunseekerYacht` ; Aquatsar → `Base.BoatMotor` (collision de nom avec BoatCore : préférer le Sunseeker si les deux sont actifs). Création `addVehicleDebug(script, IsoDirections.N, nil, sq)` sur une case d'eau, réussite si `getSqlId() ~= -1`, puis `setDebugZ(0.75)` (hypothèse). Clé `v:createVehicleKey()` ou `setKeyId(id ≥ 100000000)` ; carburant `getPartById("GasTank"):setContainerContentAmount(n)` + `transmitPartModData`.
- Cases : Riverside **6037,5212** (eau, direction N, ponton x 6041-6042) ; Louisville est : quai 12812-12834 × 1120-1133, emplacements de bateaux de mod 12823,1153.
- Sorties dans la carte : ouest **x ≤ 20, 4800 ≤ y ≤ 5118** ; nord-est **x ≥ 19780, y ≤ 299**.
- Kinsella : chenal de ≈ 200 cases (eau y 5201-5399), rive nord inaccessible, moignon terminé en y 5400 (route x 1494-1506). Groupe **1497,5404** sur la chaussée, projecteurs `lighting_outdoor_01_51` (rayon 24) en 1484/1495/1506,5400. Les projecteurs ne couvrent pas le chenal : « passage éclairé » = **règle** (bateau occupé dans 1480-1510 × 5201-5399 pendant que le groupe tourne).
- Barrage nord-est : zone x 13090-13110 × 900-1190 (pas d'objet bloquant sur l'eau) ; groupe 13100,1193 ; projecteurs 13090/13100/13110, 1192.
- Groupe : `isActivated`, `setActivated`, `setFuel`, aucun événement ; « Éteindre » vanilla sans compétence (30 tics).
- Passeur, Brandenburg : joueur en **1637,5577** (tête du ponton), bateau en 1637,5570. **Aucun son vanilla de bateau** : `.ogg` propre (CC0).
