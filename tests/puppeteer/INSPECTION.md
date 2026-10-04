# Inspection de préparation — 2026-10-03

Ce document conserve l'inspection **à la préparation du 2026-10-03**. Ses conclusions initiales et nombres de tests ne décrivent pas l'état courant. Les exécutions suivantes, correctifs autorisés et défauts encore ouverts sont dans [RESULTATS.md](RESULTATS.md), l'[index des rapports](reports/README.md) et le [bilan des bugs](reports/BUGS.md).

**Conclusion : scénarios préparés, tests en jeu non exécutés.** Aucun processus `ProjectZomboid` ou Java du jeu n’était accessible lors de la préparation. Le contrôle natif de la console n’est pas disponible dans cette session. Les commandes sont installées et prêtes à coller dans une partie dédiée. Aucun résultat des protocoles historiques n’est reporté comme réussite de cette campagne.

## Version, chargement et dépendances

- `C:/Users/cyber/Zomboid/console.txt:59` : `version=42.21.0 4a0e9546ec demo=false`. Ce journal contient plusieurs chargements/rechargements à `f:0`; ce n’est pas une nouvelle exécution des scénarios. Chargement Artemis à la ligne 6860, chaîne créée 7180, état acte 0/révision 1 à 7184, carnet lu 9358. Aucun marqueur de cette campagne PZPuppeteer dans ce journal à la préparation.
- JAR installé : `D:/SteamLibrary/steamapps/common/ProjectZomboid/projectzomboid.jar`, SHA-256 **e1a69eb743ede60b213a0fe7f8b83d4fcab773036d256cc4543a336f3b058a33**. Identique à `E:/pz-decompiled/42.21.0/projectzomboid.jar.sha256`. `java/zombie/core/Core.java:5094` construit `GameVersion(42,21,"")`. Les sources Lua relues viennent de cette installation. Le JSON [environment](reports/inspection/environment.json) conserve tailles/hashes du journal et du JAR. La nouvelle session devra encore confirmer sa propre version au démarrage.
- [Artemis mod.info](../../Contents/mods/batman_OperationArtemis/42.21/mod.info) : dossier/id `batman_OperationArtemis`, nom `batman_Operation Artemis`, `versionMin=42.21`, **require=\batman_SignalSmoke**. Projet de développement local; aucun dossier numérique Workshop n’est la source du mod testé. PZPuppeteer local : `id=batman_PZPuppeteer`, `modversion=0.1.0`, variante `42.21`, `versionMin=42.21`.
- Dépendances optionnelles relues en lecture seule : `3725497089/mods/ComputerMod/42/mod.info` → `ComputerModkum`, version minimum 42.20; `3798992436/mods/ComputerModLaptop/42/mod.info` → `ComputerModLaptop`, `require=ComputerModkum`; `3615135168/mods/ZVirusVaccine42BETA/42.20/mod.info` → `ZVirusVaccine42BETA`, version 3.1, minimum 42.20, packs et tiledef 723. Ces variantes présentes ne prouvent ni activation ni compatibilité réellement jouée en 42.21.
- Bateaux : le code détecte `BoatCoreMP.isBoat` ou `AquaConfig.isBoat`, puis cherche `Base.BoatSunseekerYacht` avant `Base.BoatMotor`. Le passeur est choisi en absence de script de bateau. Les bateaux et Vaccine nécessitent des campagnes avec leurs propres préconditions; ils ne sont pas forcés par les adaptateurs.

## Fonctionnalités et API effectivement utilisées

| Sujet | Preuve dans le code actuel | Conséquence pour les scénarios |
|---|---|---|
| Carnet | [Artemis_ReadHook.lua](../../Contents/mods/batman_OperationArtemis/42.21/media/lua/server/Artemis_ReadHook.lua), wrapper `ISReadABook:complete`; [Progress.lua:66](../../Contents/mods/batman_OperationArtemis/42.21/media/lua/server/Artemis/Artemis_Progress.lua#L66) | Objet de préparation seulement; vraie lecture via `ISInventoryPaneContextMenu.readItem`; pas d’appel direct à Progress |
| Signal | `Artemis_Radio.lua` chaîne UUID et émission périodique; `Artemis_RadioListener.lua` écoute `OnDeviceText`/ART1 | Observer l’événement réellement reçu et l’acte II; ne jamais déclencher artificiellement ART1 |
| Bunker/clinique | [Story.lua:132](../../Contents/mods/batman_OperationArtemis/42.21/media/lua/shared/Artemis/Artemis_Story.lua#L132), objectifs possession badge/dossier patient | Les objets doivent provenir des conteneurs placés par le mod, transfert vanilla contrôlé |
| Relais | `Story.lua:254`, objectifs registre lu + `ch3_tape` entendue; `Progress.lua:148` vérifie salle/courant; `Artemis_RelayTape.lua:106` enveloppe `ISRadioAction:performToggleOnOff` | L’ancien seul objectif de courant n’est pas suffisant; action réelle de la radio posée, interruption puis bande complète |
| Base/archives | `Story.lua:315` et suivantes: dossier -17, garde/clé/plan; volumes capteurs et portique; `Artemis_BaseAlarm.lua` sondage à 1 s | Carte réellement récupérée sur le garde, porte vanilla, alarmes observées; prise du dossier et franchissement à pied |
| Remontée | `Story.lua:408` guide et puits, `.claude/pz-knowledge/knox-geography.md:28–37` chemin par -16 | Pathfinding réel dans 08; aucune téléportation pour valider l’évasion. Les coordonnées sont des hypothèses de navigation à confirmer, pas un trajet déjà joué dans cette campagne |
| Hélicoptère/passeur | `Story.lua:550–680`, `Progress.lua:213/255`, `Artemis_Rendezvous.lua` phases et boardingSince | Appel depuis vrai callback de menu, créneau quotidien 5 h, attente normale, 10 s dans cercle avec dossier |
| Checkpoint | `Story.lua:711/712`, `Artemis_Checkpoint.lua`, `Artemis_CheckpointDirector.lua`, `Artemis_CheckpointSite.lua:150` | 24/72 h, infection réelle; le code **déverrouille** le portail, sans l’ouvrir automatiquement; action vanilla `ISOpenCloseDoor` sur IsoThumpable ajoutée à l’adaptateur |
| Fleuve | `Story.lua:605`, `Artemis_RiverDirector.lua` sortie seulement à bord avec dossier | Deux sorties réelles; pilotage manuel contrôlé par assertions, aucune mutation des coordonnées du bateau |
| Fins | `Artemis_Endings.lua`, `Progress.lua:310`, `Artemis_EndingUI.lua:59/250` | État final route/exit/dossier/remède comparé aux objets réels; écran solo en pause observé via OnPreUIDraw, vrai bouton Continuer |
| Stérilisation | `Artemis_Sterilization.lua`, `Artemis_SterilizationDirector.lua`, dossier lu | Délai de monde jamais modifié; fermeture B/C, A conservée |
| Optionalité | `Story.lua:282` nécessite Tikitown; `Artemis_ModMaps.lua` relève carte/probe | Exécuter 20 seulement si réellement disponible; ne pas inventer un chapitre Crossroads ou Anruisi |
| Computer/Vaccine/Siege | `Artemis_ComputerMod.lua`, `Artemis_CheckpointVaccine.lua`, `Artemis_SiegeNightBridge.lua` | Contenus posés et programmation vérifiables; actions UI réelles supplémentaires séparées |

API vanilla vérifiées dans l’installation 42.21 : `shared/TimedActions/ISReadABook.lua:442–495` (constructeur/durée réelle, fastread); `client/ISUI/ISInventoryPaneContextMenu.lua:2825` (`readItem` et transfert); `shared/RadioCom/ISRadioAction.lua:60/222` (allumer et constructeur mode/character/device/secondaryItem); `shared/TimedActions/ISActivateGenerator.lua` (autorité/complete); `shared/TimedActions/ISOpenCloseDoor.lua` (`ToggleDoor` dans complete); `client/ISUI/ISContextMenu.lua:70/1166` (arguments des callbacks et création du menu); `ISButton.lua:70/441` (forceClick, visibilité/activation). API Java relues : `DeviceData.java:269/371/400/587` (pile, micro, volume, puissance), `ItemContainer.java:1474`, `IsoWorld.java:2997` (nom de sauvegarde).

## Écarts des anciens protocoles

- Les coches N1–N9 et phases 1–3 portent sur les sessions historiques. Les reprendre aujourd’hui demanderait une nouvelle exécution avec les sources actuelles.
- Le carnet n’ouvre plus automatiquement sa transcription : le récapitulatif phase 1 indique que ce comportement a été retiré le 29 septembre. La vérification visuelle doit utiliser le bouton vanilla et ne pas attendre un module `Artemis_NoteReader` absent du code actuel.
- L’ancien récit Fallas Lake/sprinteur de premier signal et le relais qui se termine dès alimentation sont dépassés. Le code actuel utilise March Ridge et le vrai cri/bruit, puis la bande et le registre.
- L’hélicoptère ne requiert pas les consommables, fusées ou attente de 2–3 jours décrits par la conception initiale. Le serveur actuel vérifie acte III, transport propre, route ouverte, dossier et radio militaire. Le créneau revient quotidiennement à l’aube; les fusées/fumées sont posées par le mod.
- La carte affiche des points selon la présence de bateaux; l’attente systématique de cinq repères n’est pas correcte dans la campagne sans bateau.
- Le checkpoint déverrouille son portail; les protocoles « s’ouvre » ne prouvent pas une animation automatique. L’adaptateur ouvre réellement la porte avec le personnage.
- Le micro est contrôlé **seulement côté client**, intentionnellement (`Artemis_MilRadio.status(...,ignoreMic=true)` sur l’autorité : vanilla ne transmet pas cet état). Le test négatif 17 n’exige donc pas un refus serveur du micro et n’envoie aucune commande contournant son menu désactivé.
- Pour une fin sans dossier/remède, vérifier les variantes réellement implémentées (`Cnodossier`, `hasCure`) plutôt qu’inventer une route ou un déclencheur de conception.

## Validation et limites

Contrôles réalisés : compilation Lua 5.1, 31 constructions de fabriques neuves et inspection de leurs étapes sans exécuter les callbacks, délais bornés, finally présents, absence d’appels debug de progression, `require` résolus avec casse exacte, **luacheck 0 avertissement / 0 erreur**. Les sources et les copies de chargement sont comparées par hash après installation.

Le journal préexistant contient déjà des erreurs de chargement (police, options, rooms/metaID, zone mannequin et ressources). Elles sont antérieures à la campagne. Elles ne constituent ni des échecs de ces tests non lancés, ni des bugs Artemis confirmés. Un monde neuf avec les seuls mods de base permettra de séparer ces erreurs des nouvelles.

**Aucun nouveau bug Artemis confirmé en jeu.** Les essais 01 et 02 passent après correction des adaptateurs. 03 a révélé une approche insuffisante du bureau, puis un refus vanilla de lecture dans le noir; badge et ordres ont été pris par de vraies actions. Le scénario reprend ces acquisitions explicitement et prépare désormais une lampe en main via les callbacks vanilla.

Après autorisation explicite de l’utilisateur, le moteur local `PZPuppeteer` a également été corrigé : les deux helpers de création utilisent `instanceItem` au lieu du global absent `InventoryItemFactory`, et `approachContainer` effectue une marche réelle puis contrôle portée physique, verrou et présence dans le panneau de butin. **57 tests hors jeu passent**, luacheck sans avertissement; les nouvelles fonctions chargées depuis le projet moteur restent à valider après son rechargement. Le mod Artemis, le Workshop Steam et les sauvegardes n’ont pas été modifiés.
