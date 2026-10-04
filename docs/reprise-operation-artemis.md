# Prompt de reprise — Opération Artemis (après la phase 5 écrite)

À coller au début d'une nouvelle session Claude Code, ouverte dans `C:\Users\cyber\Zomboid\Workshop`.

---

On reprend le développement du mod Project Zomboid **Opération Artemis** (Build **42.21**), un scénario de fin de partie : une enquête à travers Knox (acte II), puis une exfiltration de la zone (acte III), avec une mise en scène aux étapes clés. La **cible finale, la feuille de route et l'état de chaque phase** sont en section 0 de la conception.

État au 2026-09-29 :
- phases 0, 1a, 1b **validées en jeu** ;
- phase 2 (2a mécanique, 2b aides, 2c mise en scène de l'acte II) **clôturée** : validée en jeu de bout en bout sur une partie neuve ;
- phase 3 (épreuves : alarme de la base, capteurs et fenêtre de V, portique des archives, garnison, gyrophares, évasion du labo) **écrite et contrôlée hors jeu** (luacheck, tests purs, deux relectures Opus), **pas encore testée en jeu**.

Mise à jour du 2026-10-01 : phase 3 en partie validée (jalon J1), phase 4 (hélicoptère, fin) écrite et médias validés, phase 5 (fleuve, checkpoint, fins par sortie, stérilisation) écrite ; ni la 4 ni la 5 ne sont testées en jeu. Voir « Tâches suivantes ».

## À lire d'abord, dans cet ordre

1. `CLAUDE.md` et l'index `.claude/pz-knowledge/README.md`. Surtout : `world-placement.md`, `world-map.md`, `power-and-lights.md`, `staging-effects.md`, `quest-building-blocks.md`, `radio-dynamic.md`, `knox-geography.md`, `kahlua-lua.md`, `logs-and-tools.md`.
2. `OperationArtemis/docs/conception-operation-artemis.md` : section 0 (cible et feuille de route), 4 bis (mise en scène décidée effet par effet), « Décisions de la phase 3 », 7 (plans détaillés, dont « Plan de la phase 3 », et **journal de développement**).
3. Protocoles : `OperationArtemis/docs/test-phase3-operation-artemis.md` (P01-P13, à faire) ; les protocoles des phases 1 et 2 sont clos.
4. Le code du mod : `C:\Users\cyber\Zomboid\Workshop\OperationArtemis\Contents\mods\batman_OperationArtemis\` (id `batman_OperationArtemis`, dossiers `common` et `42.21`, 49 fichiers Lua, `sandbox-options.txt`, `scripts/Artemis_items.txt`, traductions FR et EN). Projet local depuis le 2026-09-29 (`OperationArtemis\workshop.txt` privé, sans `id=` ni aperçu) ; l'ancien dossier `C:\Users\cyber\Zomboid\mods\batman_OperationArtemis` a été **déplacé**, pas copié : ne jamais le recréer (deux mods de même id se gêneraient).

## Règles de travail (demandées par l'utilisateur)

- Réponses en **français** ; **commentaires du code en français**.
- **Ne jamais modifier le Workshop Steam** (`D:\SteamLibrary\steamapps\workshop\content\108600`, lecture seule) : tout le code d'Artemis est dans le projet ci-dessus ; `C:\Users\cyber\Zomboid\mods` ne sert qu'aux correctifs `batman_…Fix` d'autres mods.
- Ne citer et n'intégrer que des mods publiés pour la **Build 42.xx**, en indiquant la variante chargée.
- **Chaque effet de mise en scène a une cause lisible dans le monde du jeu** (mécanique vanilla de préférence, ou document qui prévient le joueur). Proposer les effets un par un à l'utilisateur (trois choix plus un libre) avant de les coder.
- Boucle **plan / réalisation / contrôle / action** pour chaque phase :
  - **plan** : des sous-agents **Opus** (`model: "opus"`) recensent les méthodes du moteur 42.21 (`E:\pz-decompiled\42.21.0\java`, Lua vanilla dans `D:\SteamLibrary\steamapps\common\ProjectZomboid\media`) ;
  - **réalisation** : **SOLID / KISS / YAGNI** ;
  - **contrôle** : `luacheck --std lua51 --no-global --no-unused-args --codes`, recherche de `next(` (absent de Kahlua), `.claude/tools/artemis_plot_test.py`, `.claude/tools/artemis_check_translations.py`, relecture par un sous-agent **Opus** ;
  - **action** : corrections, documentation, base de connaissances, page de présentation.
- Textes des documents et pensées : les modifier dans `.claude/tools/additions_5.py` (ou `additions_4.py`, `additions_3.py`, `additions_2c.py`, `additions_help.py`), puis lancer `.claude/tools/artemis_gen_translations_2a.py`, qui refuse toute ligne plus large que la page. Ne pas modifier ces clés directement dans les JSON : la génération suivante les écraserait.
- **Point d'avancement régulier** à l'utilisateur. Pendant les tests en jeu, surveiller `console.txt` avec l'outil Monitor sur `python -u "C:/Users/cyber/Zomboid/Workshop/.claude/tools/pzwatch.py" <scratchpad>` et **cocher les résultats dans le protocole** au fur et à mesure.

## Page de présentation (artefact)

- Adresse : https://claude.ai/artifact/PwAsutZcWUk9r1PssiRBXZ.
- Pour la modifier depuis une nouvelle session : `Artifact` action `read` avec cette adresse, écrire la page dans le nouveau scratchpad, puis la republier avec `url` pour garder la même adresse.

## Clés API (images et voix)

- Runware (images) et ElevenLabs (voix) : les valeurs sont dans `.claude/pz-knowledge/.env` (`RUNWARE_API_KEY`, `ELEVEN_LABS_KEY`), fichier ignoré par git. Les charger dans l'environnement d'une commande sans jamais les afficher ni les écrire ailleurs.

## Tâches suivantes

1. **Jalon J1 atteint le 2026-09-30** (parcours nominal N1-N9 validé ; phase 3 : 8/13, cas limites P06, P08, P09, P12, P13 reportés). Ne pas refaire tester le nominal : l'utilisateur l'a joué plusieurs fois.
2. **Jalon J1** (enquête complète) une fois la phase 3 validée.
3. **Phase 4** : décisions, plan et code faits le 2026-09-30 (conception, « Décisions » et « Plan de la phase 4 » ; recherche `OperationArtemis/docs/recherche-phase4-operation-artemis.md`), relectures Opus corrigées. Dépend du mod `batman_SignalSmoke` (projet `Workshop\SignalSmoke`, fumée et fusée). Médias faits le 2026-09-30 (image Runware, voix de V par ElevenLabs en ton confidentiel et effet de bande, mixage sur « The First Light » ; outil `OperationArtemis/source/media/artemis_media.py`). **Reste** : test en jeu `test-phase4-operation-artemis.md` (E1-E10) et `SignalSmoke/docs/test-v1.md` (S1-S5, dont la taille des modèles).
4. **Phase 5** (routes A et C, fins par sortie, stérilisation) : décisions prises une par une le 2026-09-30 / 2026-10-01 (conception, « Décisions » et « Plan de la phase 5 » ; recherches et relevés de terrain `recherche-phase5-operation-artemis.md` ; carte explicative https://claude.ai/artifact/WxCV4wUDQ6DYeUbCTF1Mj2), code écrit (lots 0-5), relecture Opus corrigée. Faits le 2026-10-01 : textes des fins validés, voix des variantes (8 pistes, voix lancée à 8 s dans toutes les pistes), moteur du passeur (Work With Sounds, CC BY 4.0, crédit dans `OperationArtemis/CREDITS.md`), balises de fumée verte (`Artemis_BeaconDirector`). **Reste** : test en jeu `test-phase5-operation-artemis.md` (F1-F17).
5. **Phase 6** (intégrations optionnelles) : décisions, code et relecture Opus faits le 2026-10-02 (conception, « Décisions » et « Plan de la phase 6 » ; recherche `recherche-phase6-operation-artemis.md` ; textes `.claude/tools/additions_6.py`). **Reste** : test en jeu `test-phase6-operation-artemis.md` (G1-G9). Prochaine phase : 7 (finition : multijoueur coopératif, équilibrage, relecture des textes, page Workshop). Textes : `.claude/tools/additions_5.py`.
6. Question ouverte pour la phase 7 : un « défi Opération Artemis » dans Nouvelle partie → Défis (`addChallenge`, solo, sans écran sandbox) et une liste de mods partagée.

## Faits utiles déjà établis (ne pas les redécouvrir)

- En solo, `sendServerCommand` ne fait rien : le client lit la ModData `batman_Artemis` directement. Le serveur écrit seulement via `Artemis_Store` ; les transitions passent par `Artemis_Progress.commit`, qui joue aussi la scène serveur. Les scènes sont mises en file (`recentScenes`) : plusieurs scènes dans la même minute sont toutes jouées.
- `ClientState.get()` recopie tout l'état : ne pas l'appeler à chaque tick (s'abonner à `Artemis_StateWatcher`).
- Les options sont lues avec `getSandboxOptions():getOptionByName("OperationArtemis.X")`.
- Acte II : données dans `shared/Artemis/Artemis_Story.lua` (chapitres, poses par type et par groupe, `alarm`, `mist`, `tape`, `surfacing`, profils `TRACKED`) ; pose sur `LoadChunk` et chaque minute (`server/Artemis_Director.lua`, `server/Artemis/Artemis_Placement.lua`) ; objectifs (`Artemis_Goals` : `hasItem`, `hasRead`, `heard`, `powered`, `squarePowered`, `all`).
- Zombies spéciaux (patient zéro, Miller, sujets) : `server/Artemis/Artemis_Tracked.lua` les reconnaît à leur retour dans le monde par `getPersistentOutfitID` + zone et leur rend leurs traits.
- Effets d'ambiance indépendants du chapitre en cours : `server/Artemis_Alarm.lua` (+ `client/Artemis_AlarmFX.lua`), `server/Artemis_Mist.lua`, `server/Artemis_Surfacing.lua`, `client/Artemis_WorldLights.lua`, `client/Artemis_RelayTape.lua`.
- Phase 3 : `server/Artemis_BaseAlarm.lua` (sondage 1 s : évasion démarrée par un porteur du dossier dans la base hors des archives, réussite ou abandon, capteurs hors de la fenêtre 23 h 15 - 1 h 15, sirènes d'étage) ; règles pures dans `shared/Artemis/Artemis_Trial.lua` et `Artemis_Ambience.lua` ; données `baseAlarm`, `escape` et garnison dans `Artemis_Story` (ch5). Brouillard : `server/Artemis/Artemis_Weather.lua` (côté serveur, interpolation 1, non sauvegardé).
- Aucun poste militaire vanilla à Fallas Lake : chapitre 1 au bunker de March Ridge, chapitre 2 à la clinique de West Point.
- Siege Night 2.7.3 plante à l'ouverture de son onglet sans le correctif local `C:\Users\cyber\Zomboid\mods\batman_SiegeNightPanelFix` (confirmé en jeu) : le garder actif pendant les tests.
- La description de `42.21/mod.info` date de l'acte II (« in progress ») : à réécrire avant toute publication (phase 7).
