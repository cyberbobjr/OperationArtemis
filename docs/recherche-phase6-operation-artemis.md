# Opération Artemis — recherche de la phase 6 (intégrations optionnelles)

Recherches Opus en lecture seule du 2026-10-01. **Rien n'est testé en jeu.** Sauf mention « hypothèse », tout est confirmé statiquement.

## Siege Night (3669589584, v2.7.3, variante 42)

- **Fréquence sans toucher aux options enregistrées** : Siege Night relit `SandboxVars.SiegeNight` à chaque appel (`shared/SiegeNight_Shared.lua:168-193`). `getNextFrequency()` lit `FrequencyDays`/`FrequencyDaysMax` en direct (`Shared:258-265`), à la fin d'un siège (`server/SiegeNight_Server.lua:1916-1917`), au chargement d'une date dépassée (`:2611`) et au redémarrage pendant un siège (`:2656`). Masquer ces deux valeurs comme `Enabled` dans `Artemis_SiegeNightBridge`, réappliquées chaque minute, valeur d'origine relue par `getOptionByName`. Mini-hordes : `MiniHorde_CooldownMinutes`, `MaxPerDay`, `NoiseThreshold` lus en direct (`server/SiegeNight_MiniHorde.lua:437-451`). `FirstSiegeDay` sans effet après le début.
- **Taille** : `siegeCount` dépend de `FrequencyDays` (`Shared:437-442`) mais est plafonné à `totalSiegesCompleted + 1` (`Server:1865-1870`) : pas d'explosion, progression plus rapide en jours.
- **Date du prochain siège** : ModData globale `"SiegeNight"`, `nextSiegeDay` (`Shared:490-493`) ; jour = `getWorldAgeDays() + 1` (change vers 7 h). Rapprocher côté serveur : `nextSiegeDay = max(aujourd'hui + 1, min(nextSiegeDay, aujourd'hui + fréquence))` puis `ModData.transmit("SiegeNight")`.
- **Risques** : `nextSiegeDay <= aujourd'hui` pendant les heures de siège (20 h - 6 h) lance le siège aussitôt sans avertissement (`Server:2559-2562`) ; aucun rappel public pour l'état `WARNING` ; sièges plus fréquents → chevauchement avec les épreuves de l'acte III (le pont ne suspend que pendant l'évasion, `Bridge:125-126`). MP : masquage serveur suffisant (le client ne lit pas ces options).
- **Siège ponctuel** : `nextSiegeDay = aujourd'hui` écrit de jour → avertissement puis siège à 20 h (exige `Enabled` vrai, `Server:2388`). `CmdSiegeStart` déconseillé (refusé aux non-admins en MP, `Server:1977-1981` ; immédiat, sans avertissement).

## Dead Man's Dossier (3675740871, variante 42)

- Pages lâchées par les zombies Police, Army, médicaux, pompiers, gardes forestiers (`server/deadmansdossier_server.lua:897-942`) — même source que la note d'Artemis ; mission vers une cachette fixe ; ModData serveur `DeadMansDossier_Missions`.
- API client seulement : `DeadMansDossier.addStashMarker(tierKey, x, y, label)`, `removeStashMarker`, `openStashMap` (`client/deadmansdossier_mapmarker.lua:35-50`) ; un repère par `tierKey` (écraserait la mission du joueur), en mémoire seulement, effacé au retour au menu.
- **Apport quasi nul** (les symboles d'Artemis sont persistants et partagés). Recommandation : abandonner, citer la coexistence.

## Knox Airdrop (3799630525, variante 42, solo seulement)

- Pas d'API : `KnoxAirdrop` ne contient que `update` (`client/KnoxAirdrop.lua:7, 578`). Largage à un point possible par `KACore.newDrop(ModData.getOrCreate("KnoxAirdrop_v1"), heures, KAConfig, ZombRand, "medical", {x, y, z = 0, hint})` (`shared/KACore.lua:59-79`) : données internes, fragile ; caisse posée seulement si la case est chargée ; recalage possible près du joueur (hypothèse).

## Railroader (3774360904, variante 42)

- `RR.API` en lecture seule (`shared/Railroader/RR_API.lua:566-687`) : aucun moyen de faire apparaître ou de commander un train. Mention de compatibilité seulement.

## Décisions à soumettre

- A. Fréquence des sièges après le dossier : moitié / option sandbox / inchangée, prochain siège rapproché.
- B. Siège ponctuel : soir de la lecture du dossier / veille de l'extraction / aucun.
- C. Suspension étendue : toutes les épreuves de l'acte III / hélicoptère et quarantaine / aucune.
- D. Dead Man's Dossier : abandon / compatibilité citée / repère temporaire.
- E. Knox Airdrop : ravitaillement solo / mention / caisse d'Artemis sans dépendance.
- F. Railroader : mention / abandon / sortie par le train plus tard.

## Computer Mod (ComputerModkum 3725497089, ComputerModLaptop 3798992436, variante 42, min 42.20)

- Ordinateurs reconnus : tuiles vanilla `appliances_com_01_72` à `_79` (`shared/ComputerMod_ComputerTypes.lua:228-240`) ; portable `laptop486` (objet d'inventaire, utilisable **posé au sol** seulement, `ComputerMod_ContextMenu.lua:1029`). Bureau : courant exigé (`client/ComputerMod_Power.lua:115-142`) ; portable sur batterie. Pièces en panne au hasard (1 % cassée).
- **Pas d'API publique.** Champs conservés s'ils sont remplis avant le premier démarrage (`UI_State.lua:2699-2748`) : `ComputerModDesktopNotes = {{key, name, text}}`, `ComputerModNotepadText`, `ComputerModPasswordEnabled`/`Password`, mail (`ComputerModMailSpawnInitialized`, `ComputerModMailMessages`…) ; fonctions serveur `ComputerModMail.ensureAccount`, `sendMessage` (2 000 caractères) ; `ComputerModComponents.ensure(data, graine, true, âge)` pour des pièces à 100 %.
- **Méthode la moins fragile : CD vierge** `ComputerMod.BlankCD` avec ModData `ComputerModDiscLabel` et `ComputerModDiscContents = {{type="note", key, label, text}}` (`server/ComputerMod_CD_Server.lua:169-180`), lisible dans tout ordinateur du mod.
- Détection : la table `ComputerMod` n'existe pas (conception l.321 à corriger) → `ComputerModComputerTypes` / `ComputerModMail` ou `getActivatedMods()` avec `ComputerModkum`.
- **Clinique de West Point** : un ordinateur reconnu `appliances_com_01_75` en **11881,6881,0**, à 2 cases du classeur du dossier patient ; d'autres dans le bureau voisin (11878,6880 / 6884 / 6886 ; 11875,6883 / 6885).
- Portable de chercheur faisable (ModData de l'objet, `ComputerModLaptop_Core.lua:101-121` ; `initializeLaptop` locale à reproduire, `ComputerModLaptop_Spawns.lua:23-31`).
- Fragilités : champs internes du mod (mises à jour), contenu modifiable par le joueur, copie client qui peut écraser une note en MP (hypothèse), texte figé dans la langue du serveur.

## Cartes de mods (lieux bonus)

- **Tikitown** (`tikitown`, variante 42, requiert `tikitown_tiles`) : cellules 25-30 × 26-30. Labo = bâtiment 0 de la cellule 26_29 (x 6856-6880, y 7556-7587, z -1 à -5), sous un bureau. Entrées 6862-6863,7580 et 6857,7561 ; escalier unique 6877-6879,7572 (porte de palier 6877,7571) ; chemin 71 cases jusqu'à la morgue. -1 quartier militaire (armystorage), -2 médical, -3 cellules, **-4 bureaux** (bureaux 6863,7572 et 6866,7576, classeur 6861,7570 : notes de V), **-5 morgue et stockage** (tiroirs de morgue `crate` 6862-6865,7559, armoires medicine 6861,7575-7576 : échantillons). Détour depuis le relais ≈ 1 300 cases.
- **AnruisiTown** (variante 42) : cellules 46-50 × 43-46. Complexe 12561-12592 × 11540-11587, z 0 à -10 ; labo au -3 (12570-12578,11544-11548), armurerie et archives au -6. Détour ≈ 10 000 cases.
- **Crossroads-Checkpoint** (variante 42.0, 4 packs de tuiles requis) : retire 7 bâtiments vanilla de la cellule 45_32. Bunker 11759-11944 × 7981-8065, z 0 à -5 ; labo au -1 (11846-11849,8004-8008, 17 caisses `crate`), chemin 221 cases par la porte 11860,7988 ; aucun bureau `desk` en sous-sol ; -5 probablement inaccessible. À ≈ 1 100 cases de la clinique (contre ≈ 6 000 depuis March Ridge).
- **Détection d'une carte chargée** : `getWorld():getMap()` = noms de dossiers séparés par `;` (solo : figé dans `map_ver.bin` à la création ; MP : `Map=` du serveur). Un mod de carte activé après la création **n'est jamais ajouté**. Test : ID dans `getActivatedMods()` + dossier dans `getMap()` + sonde de métagrille `getRoomAt(x, y, z)`. Sauvegardes de l'utilisateur : `Sandbox/2026-09-27_16-54-22` et `2026-09-29_13-49-26` contiennent les trois cartes ; les parties créées depuis le 29-09 16 h 23 sont vanilla seulement.
- **Insertion du chapitre 4** : `ch3_relay.next = "ch4_lab"`, `ch4_lab.next = "ch5_base"`, `Plot.completeChapter` saute un chapitre indisponible (ensemble `available` calculé côté serveur, module pur) ; migration dans `Plot.normalize` ; schéma inchangé.

## Décisions prises

| Sujet | Décision |
|---|---|
| Siege Night, fréquence après le dossier | **Moitié du réglage du joueur** (1 jour minimum), prochain siège rapproché en conséquence ; options enregistrées jamais modifiées |
| Siege Night, siège de l'acte III | **Le soir de la lecture du dossier** : V prévient à la radio (« ils savent, ils envoient tout ce soir ») ; siège programmé dans Siege Night (`nextSiegeDay` = aujourd'hui, écrit de jour : avertissement puis siège à 20 h) ; dossier lu pendant les heures de siège → le lendemain soir |
| Siege Night, suspension | **Pendant toutes les épreuves de l'acte III** : créneau de l'hélicoptère ou du passeur en approche ou posé, quarantaine en cours, sirène d'un poste gardé ; le siège reporté a lieu après (comme pendant l'évasion) |
| Computer Mod | **CD + portable de V** : CD gravé (`ComputerMod.BlankCD`, ModData `ComputerModDiscContents`) dans le classeur de la clinique (mails internes, notes de l'infirmière) ; portable de V (`ComputerModLaptop.Laptop4861993`, notes dans sa ModData, batterie) dans la base secrète. Contenu bonus, jamais nécessaire pour avancer |
| Chapitre 4 bonus | **Tikitown seul** : notes de V dans les bureaux du -4, échantillons à la morgue du -5 ; sans la carte Tikitown chargée, le chapitre est sauté |
| Chapitre 1 | **March Ridge gardé** ; Crossroads-Checkpoint cité compatible seulement |
| Disponibilité du chapitre 4 | **Figée à l'entrée dans l'acte II** (`state.flags`), avec une ligne de journal de debug expliquant un saut (mod actif, carte absente). Partie déjà à l'acte II sans relevé : relevé fait au chargement, chapitre 4 seulement si le chapitre en cours le précède |
| Dead Man's Dossier | **Compatibilité citée** seulement, aucune intégration |
| Ravitaillement | **Caisse d'Artemis**, sans dépendance : une seule fois, au premier engagement sur une route (appel de l'hélicoptère ou du passeur accepté, test d'entrée du checkpoint, bateau de V pris), V fait déposer une caisse militaire (soins, vivres, munitions) près de ce point de sortie, annoncée à la radio et marquée d'une fumée verte. Knox Airdrop cité compatible |
| Railroader | **Mention seule** (compatibilité) |
