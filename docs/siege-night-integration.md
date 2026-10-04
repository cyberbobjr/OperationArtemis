# Siege Night : piloter le mod depuis Opération Artemis

Notes propres au projet Opération Artemis (`Artemis_SiegeNightBridge.lua`), sorties le 2026-09-30 de la base `.claude/pz-knowledge` (qui ne garde que le moteur). Revérifier à chaque mise à jour de Siege Night.

## Piloter Siege Night depuis un autre mod
- Build : 42.21 — Date : 2026-09-27 — Statut : confirmé statiquement (Siege Night 2.7.3, Workshop 3669589584 ; callbacks et commande vérifiés directement)
- `local SN = require("SiegeNight_Shared")` donne la même table que le mod. Callbacks officiels : `SN.onSiegeStart`, `onSiegeEnd`, `onWaveStart`, `onBreakStart` et `onMiniHorde` (`shared/SiegeNight_Shared.lua:561-577`).
- Démarrage manuel : `sendClientCommand(player, "SiegeNightModule", "CmdSiegeStart", {})` (`server/SiegeNight_Server.lua:2080`). En solo, `isPlayerAdmin` est vrai. Arrêt : `CmdSiegeStop`.
- La taille se règle en écrivant dans `SandboxVars.SiegeNight.*`, lu en direct par `SN.getSandbox`. Ces écritures dans la table Lua ne sont pas sauvegardées (les options enregistrées viennent des valeurs Java) et sont effacées quand le jeu réécrit `SandboxVars` (chargement, admin MP qui applique des options) : les réappliquer périodiquement.
- **Couper le cycle automatique** (corrigé le 2026-09-27, relecture) : changer `FirstSiegeDay` / `FrequencyDays` en cours de partie **ne suffit pas**, car la date est déjà enregistrée dans la ModData `SiegeNight.nextSiegeDay` (`SiegeNight_Shared.lua:493`, test `SiegeNight_Server.lua:2548`). Méthode retenue par `batman_OperationArtemis` (`server/Artemis_SiegeNightBridge.lua`) :
  - masquer `Enabled` et `MiniHorde_Enabled` (indépendants) à `false` ; `Enabled = false` coupe tout `onServerTick` (`:2388`), et `MiniHorde_Enabled` les mini-hordes (`SiegeNight_MiniHorde.lua:309-349`) ;
  - ne suspendre que si `SN.getWorldData().siegeState == SN.STATE_IDLE`, sinon le siège reste bloqué ;
  - **repousser la date dépassée** (`nextSiegeDay = jour + SN.getNextFrequency()`, puis `ModData.transmit("SiegeNight")`), pendant la suspension et au rétablissement. Sinon, au retour d'`Enabled`, `currentDay >= nextSiegeDay` lance aussitôt un siège de rattrapage, même à 3 h du matin ;
  - les chemins manuels (`CmdSiegeStart`, vote, debug) **ne vérifient pas** `Enabled` : un siège lancé pendant la suspension resterait ACTIVE sans zombies. Parade : `SN.onSiegeStart(cb)` qui rétablit `Enabled` jusqu'à la fin du siège ;
  - la valeur de référence du joueur se lit dans les options enregistrées : `getSandboxOptions():getOptionByName("SiegeNight.Enabled"):getValue()` (jamais masquée, à jour après une modification admin).
- Limites connues : pendant la suspension, la chaleur des mini-hordes ne décroît plus mais `recentKills` s'accumule (une mini-horde peut partir juste après le rétablissement) ; en MP, les `SandboxVars` du client ne sont pas masqués.
- Impossible sans remplacer le fichier serveur (2 769 lignes) : imposer un point ou une direction (`initializeClusters`, `pickPrimaryDirection`, `getSpawnPosition` sont `local`). Un siège se termine quand le nombre de kills est atteint, à l'aube ou à l'arrêt manuel. Aucun hook de mort du joueur.

