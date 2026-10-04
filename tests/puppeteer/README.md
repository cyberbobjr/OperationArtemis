# Campagne solo Operation Artemis / PZPuppeteer

Accès direct : [tableau des scénarios](RESULTATS.md), [index des rapports et preuves](reports/README.md), [bugs corrigés et encore ouverts](reports/BUGS.md). Les preuves brutes sont rangées dans `reports/runs/`, les pièces avant correctif dans `reports/fixes/`, les contrôles hors jeu dans `reports/inspection/` et les captures isolées dans `reports/snapshots/`.

Préparée le 2026-10-03 pour **42.21.0**. Surveillance en jeu commencée le même jour : le premier essai de 01 s’est arrêté sur la garde du nom de sauvegarde, avant toute action de préparation ou de progression. Consulter le tableau pour les résultats réels à jour. Cette session ne dispose pas de contrôle natif de la console du jeu; les commandes sont collées par le joueur.

Sources conservées ici; copies installées sous `C:/Users/cyber/Zomboid/Lua/PZPuppet/scenarios/OperationArtemis/`. `suite.lua` contient les adaptateurs, chaque fichier numéroté retourne une fabrique neuve via `PZPuppet.loadScenario`. Le chargement ne lance rien, n’ajoute aucun événement et n’importe aucun module du mod. L’exécution ajoute temporairement les seuls observateurs nécessaires, retirés dans `finally`.

Le [tableau complet](RESULTATS.md) donne les 31 commandes, les préconditions, les attendus, les observations, les preuves et les statuts. Chaque scénario a aussi son fichier sous `reports/`.

Le collecteur archive également les scénarios `ArtemisDiagnostic/` séparément : un diagnostic réussi ne change pas le statut d'une route nominale. Il relit les métadonnées avant chaque archivage afin de conserver les précisions ajoutées pendant une longue attente. `--watch --include-current` permet de rattacher la surveillance à une exécution déjà commencée sans lancer de commande de jeu.

## Partie dédiée et ordre d’exécution

**Les nouveaux parcours utilisent maintenant un plan séquentiel** : voir [CAMPAGNES.md](CAMPAGNES.md). Après redémarrage complet avec les nouvelles sources, lancer le collecteur puis une seule commande `runBatchFile` pour 01–08, les négatifs compatibles et la fin choisie. Chaque enfant garde ses actions réelles et son propre rapport ; erreur, annulation ou archive refusée arrêtent la suite. Les anciennes instructions `runFile` ci-dessous restent utiles pour les reprises explicites, mais ne constituent plus la procédure recommandée d’une nouvelle campagne.

1. Lancer le jeu avec `-debug`. Activer **batman_OperationArtemis**, sa dépendance obligatoire **batman_SignalSmoke**, et **batman_PZPuppeteer**. Les projets locaux sont chargeables directement : ne rien copier dans le Workshop Steam. Redémarrer complètement.
2. Créer une **nouvelle** partie Sandbox, nommée par exemple **PZPuppet_Artemis_Helicoptere**. Toutes les fabriques exigent ce préfixe ou un nom exact déclaré par testSave, et refusent client/serveur. Personnage vivant, lettré, non sourd, hors véhicule, file d’actions vide. Une journée de **60 minutes** convient à la préparation, mais n'est pas une précondition obligatoire des transports ; relever la durée réelle dans le rapport. Intensité normale, réseau électrique encore actif. Préparer nourriture, eau, lumière et équipement de combat. Ne pas activer d’actions instantanées. La mortalité et la fatigue restent réelles; un décès annule le test.
3. Pour la campagne de base, désactiver stérilisation, mods de bateaux, Vaccine et transport Military Drop. Choisir les cartes optionnelles dès la création pour leurs campagnes séparées, avec leurs dépendances. Ne pas activer tous les fournisseurs de bateaux simultanément pour le premier essai.
4. Démarrer la surveillance **avant** le jeu, dans un terminal PowerShell :

```powershell
python C:/Users/cyber/Zomboid/Workshop/OperationArtemis/tests/puppeteer/collect_results.py --watch
```

5. Console Lua, première commande exacte :

```lua
PZPuppet.runFile("OperationArtemis/01_chargement_carnet.lua",{playerIndex=0})
```

Si la nouvelle partie dédiée reçoit un nom automatique, indiquer son nom exact dans le troisième argument, pour **chaque** scénario. Le nom est comparé strictement à `getWorld():getWorld()`; aucun joker ou changement de sauvegarde n’est effectué. Exemple pour la partie de test créée pendant cette campagne :

```lua
PZPuppet.runFile("OperationArtemis/01_chargement_carnet.lua",{playerIndex=0},{testSave="2026-10-03_18-48-28"})
```

Ce paramètre désigne explicitement une partie de test dédiée; ne jamais y indiquer une sauvegarde personnelle. La fabrique est relue depuis le disque à chaque `runFile`, sans rechargement Lua global.

Après un échec partiel de **03** avec le badge déjà acquis réellement, utiliser `{testSave="<nom exact>",resume=true}`. La reprise accepte le chapitre bunker ou clinique, conserve le badge et les ordres déjà pris, et le signale dans les assertions et la console. Elle ne rejoue pas le transfert d’un objet déjà en inventaire et ne modifie pas la progression. L’acquisition initiale reste prouvée par le rapport de la tentative précédente.

Avant chaque lecture, le scénario vérifie `tooDarkToRead`. Si nécessaire, il crée une lampe `Base.HandTorch` chargée comme condition de test, l’équipe en main secondaire et l’allume avec les callbacks vanilla. Une assertion exige ensuite que le jeu autorise la lecture. Le nettoyage éteint et retire cette seule lampe et restaure les mains. Le refus réel dans le bunker sombre a été observé lors de la campagne; la reprise éclairée de 03 a ensuite passé ses 24 assertions en jeu, sans nouvelle erreur Lua. Le badge a été acquis lors de la première tentative, les ordres lors de la suivante, et leur lecture lors de la reprise finale; ces acquisitions ne sont pas présentées comme rejouées dans un seul passage.

Fermer la console, reprendre à vitesse normale et laisser les commandes de mouvement tranquilles. Après le rapport et son archivage, lancer **02 → 03 → 04 → 05 → 06 → 07 → 08 → 09 → 10**, une commande à la fois. Si 05 ouvre `ch4_lab`, insérer **20** avant 06. Utiliser les commandes du tableau, sans copier plusieurs appels ensemble : le moteur refuse les scénarios concurrents.

```lua
PZPuppet.printStatus()
-- arrêt volontaire (rapport cancelled, traduit échoué/interrompu dans le tableau) :
PZPuppet.stop()
```

**Ne pas poursuivre après une précondition manquante ou une nouvelle erreur Lua.** L’archivage conserve le rapport brut du moteur, le contexte de console propre au scénario, les erreurs nouvelles et le contexte antérieur. Une erreur d’un autre mod reste à attribuer séparément. Les erreurs à `f:0`, la variante chargée, les remplacements et la version doivent être examinés au démarrage : une réussite du moteur n’efface pas une initialisation interrompue.

## Routes et branches séparées

Une fin met l’état partagé à l’acte IV. Les autres routes exigent **une autre partie dédiée**, obtenue en rejouant 01–08; aucun scénario ne réinitialise l’histoire ni ne termine un chapitre par debug. Les téléportations servent à se placer avant les objectifs locaux; elles ne valident pas l’accès naturel aux lieux ni la descente complète. **08 n’utilise aucune téléportation** : la remontée réelle de -17 à la surface a été observée dans la première tentative de cette campagne, puis la reprise depuis la porte a confirmé la sortie, le dossier conservé et l'évasion réussie. Les deux [rapports distincts](reports/08_evasion.md) conservent la preuve du trajet et l'échec initial d'approche de la porte, corrigé uniquement dans le test.

- Hélicoptère : **09 puis 10**. **17 avant 09** teste les refus de radio. **18 après 09** teste un rendez-vous manqué; refaire ensuite 10. 09 suppose que l’hélicoptère est le premier engagement, pour vérifier sa caisse. Military Drop remplace cette route lorsqu’il annonce son transport : l’adaptateur refusera cette précondition.
- Passeur : **11 puis 12**, sans fournisseur de bateau. 11 appelle réellement avec les projecteurs allumés, éteint le générateur via `ISActivateGenerator`, puis rappelle depuis le quai.
- Checkpoint : **13 puis 14**. Depuis le correctif autorisé du 2026-10-04, la quarantaine dure **au maximum une heure de jeu**, avec ou sans dossier, avec incident à la demi-heure. À jour de 60/90 minutes, une heure de jeu dure environ **2 min 30 / 3 min 45 réelles** à vitesse normale. Pendant cette attente, rester éveillé et vivant. Le scénario ne modifie pas le minuteur. **24** abandonne volontairement la quarantaine et **28** laisse expirer une autorisation : ces variantes exigent leur propre branche. L'autorisation d'entrée reste distincte de la quarantaine. Pour 28, effectuer le test de la caisse manuellement et lancer immédiatement le scénario sans entrer; 13 entrerait dans l’enclos.
- Sans dossier : déposer le dossier avec une vraie action du jeu avant 13; lancer **29** après l’entrée, durée maximale d'une heure de jeu. **27**, avec `depositDossier=true`, dépose puis reprend le véritable dossier par les actions vanilla et teste le refus radio pendant son absence. **26** exige un personnage de test réellement infecté ; `infectionFixture=true` prépare temporairement cet état via les données corporelles du jeu et restaure les valeurs dans `finally`. Cette préparation est explicitement exclue du parcours nominal.

Pour le 14, l'option moteur `{playerIndex=0,manualStop=false}` autorise les actions et déplacements du joueur pendant l'attente : manger, boire ou combattre en restant dans l'enclos et éveillé. Le scénario journalise toutes les 30 secondes la phase, les heures écoulées/restantes et la durée effective du jour, sans modifier le temps. Il retire cet observateur dans `finally`. L'accélération par les commandes normales du jeu peut réduire l'attente réelle; la sortie automatique attend une file d'actions vide et une vitesse de déplacement admise par le moteur, pendant au plus 300 s. La déclaration de réanimation par l'autorité est vérifiée; la réanimation physique et son rendu restent une vérification distincte.

Les archives du 2026-10-03 décrivent l'ancien comportement 24/72 heures et sont conservées comme preuves historiques. Le [rapport du correctif d'une heure](reports/QUARANTAINE-UNE-HEURE.md) distingue les vérifications hors jeu, l'entrée réelle du 13, la fin naturelle de quarantaine avant le lancement du 14 et la sortie réelle du 14. Si la quarantaine finit avant le lancement du 14, `completedQuarantine=true` vérifie cet état déjà acquis naturellement et teste uniquement la sortie ; il ne valide pas à lui seul l'attente ni ne change la progression.
- Remède : avoir un remède réel en inventaire avec le dossier, puis **13 → 30**. La fin doit enregistrer `hasCure=true`. Ce test ne prouve pas la synthèse ou l’injection du remède.
- Bateaux : activer BoatCore MP + Working Motorboat **ou** Aquatsar avec leurs dépendances sur une nouvelle partie. Après 08, aller au bateau de V par le menu debug de placement, récupérer sa clé et embarquer par l’interface du jeu. Lancer **15** (Riverside → ouest) ou **16** (Louisville → nord-est), avec `manualStop=false` comme dans le tableau. Le joueur **pilote réellement** le bateau; Lua ne déplace jamais le véhicule et ne fabrique jamais l’événement de sortie. Garder le poste traversé éclairé pour l’assertion d’alarme. Deux bassins distincts; ne pas essayer de traverser Clark Memorial en bateau. La pose, les collisions, la clé, le carburant et la navigation nécessitent aussi une observation dédiée.

Les tests 10/12 règlent l’heure à 4 h 57 **avant** le créneau et placent le joueur à six cases du centre; ensuite approche et tenue s’écoulent normalement, sans saut de temps. Le délai de tenue configuré doit rester 30 min pour la campagne standard. Avec une journée de 90 minutes, prévoir environ 2 min 15 réelles, hors marche et aléas, jusqu'à l'embarquement. Garder la vitesse normale pendant le test, notamment la marche automatique. Le personnage marche dans le cercle puis reste dix secondes. `OnPreUIDraw` observe l’écran réel malgré la pause solo et attend désormais le **clic manuel sur Continuer**. Le paramètre explicite `autoContinue=true` réactive le clic du vrai bouton après 12 secondes, utilisé dans la première fin C réussie. Le rendu complet et la bande sonore de 219 s nécessitent la procédure manuelle ci-dessous. Si le menu Échap masque l’écran, fermer ce menu; si l’adaptateur échoue pendant la pause, cliquer Continuer manuellement puis examiner l’erreur dans la console.

## Options, stérilisation et intégrations

Pour **19** ou **22**, préparer une nouvelle branche avec le dossier encore **non lu**, tout en progressant normalement :

```lua
PZPuppet.runFile("OperationArtemis/07_archives_portique.lua",{playerIndex=0},{deferDossierRead=true})
```

Puis 08. Pour 19, régler `SterilizationDays=1` **à la création**, maintenir le personnage vivant et éveillé et laisser la journée s’écouler normalement (timeout 6 000 s). Le scénario lit le dossier et attend la frappe sans changer `deadlineHours`. Pour 22, activer Siege Night et le contrôle Artemis avant création. Le scénario vérifie la programmation du siège et les options inchangées; son déroulement réel et la suspension pendant une extraction exigent une procédure complémentaire.

**21** vérifie les véritables données du CD de la clinique; le portable est ajouté avec :

```lua
PZPuppet.runFile("OperationArtemis/21_computer_contenus.lua",{playerIndex=0},{laptop=true})
```

La base doit déjà être révélée et les objets encore dans leurs classeurs. Ce test inspecte les contenus réellement posés; lecture des notes à l’écran et premier démarrage Computer Mod restent manuels. **23** attend un vrai prélèvement/analyse Vaccine au poste, réalisé par le joueur. Le menu intégré « test de l’armée » est absent quand Vaccine est actif; ne pas appeler directement sa logique serveur pour fabriquer un résultat.

Dépendances observées : ComputerModLaptop → ComputerModkum; Vaccine sélectionne la variante 42.20, `versionMin=42.20`, ce qui ne constitue aucune validation 42.21. Le labo satellite actuellement décrit dans `Artemis_Story` exige **Tikitown réellement chargé dans la carte**, pas le seul abonnement; Crossroads/Anruisi ne sont pas des variantes du chapitre mises en œuvre dans ce code. HEEF, Knox Airdrop, Railroader, Science et Detection Kit ne doivent pas être annoncés comme intégrations validées sur la seule foi des anciens protocoles.

## Nettoyage et persistance

`diagnostic_porte_base.lua` est une inspection en lecture seule, distincte du parcours : clé réelle de la porte, clé correspondante en inventaire, verrou, barricades, obstruction et possibilité d’ouverture vanilla. Son nom moteur est `ArtemisDiagnostic/porte_base`; son succès signifie seulement que l’inspection a abouti, pas que 06 a réussi. Ne pas lancer 07 tant que l’échec d’ouverture de 06 n’est pas expliqué.

La reprise réelle de 06 a ensuite réussi les 44 étapes : fenêtres des capteurs, sortie du hall et ouverture de la porte blindée du sas avec la carte du garde. Le premier échec ciblait une serrure extérieure ordinaire indépendante de cette carte; voir [TEST-06](reports/ANOMALIES.md). Le placement debug dans le hall ne valide pas l'accès extérieur naturel. Dans 07, le placement debug prépare le couloir extérieur aux archives à `5575,12432,-17`; la porte blindée est ensuite ouverte par une action vanilla, suivie de l'entrée à pied, de la récupération et de la lecture du dossier, puis du franchissement du portique. La descente complète vers les archives reste une procédure distincte. Dans 08, toute la remontée doit utiliser les déplacements du jeu, sans téléportation après le départ de l'évasion.

`finally` retire les observateurs, masque les menus créés, ferme notre journal, remet les mains d’origine quand une radio/carnet de fixture a été ajouté, retire de leur conteneur les seules fixtures suivies par ce scénario et remet l’heure de préparation. Les fixtures utilisent `instanceItem`, API vanilla 42.21. Le helper moteur `D.spawnItem`, initialement fondé sur un global `InventoryItemFactory` absent de la session, a été corrigé pour utiliser cette API sur autorisation. Aucun alias global n'est ajouté. La radio de bande est remise hors tension en cas d’échec. Les documents pris dans le monde sont conservés : ils servent aux scénarios suivants. Le générateur de Kinsella coupé reste coupé, volontairement.

Les progressions, scènes, poses du mod, morts, objets consommés, dégâts, passage ouvert du barrage et choix Continuer **ne sont pas réversibles par finally**. Aucun fichier de sauvegarde n’est restauré ou édité par ces outils. Remettre l’heure affichée ne restaure pas le monde ni les jours écoulés. Une interruption du processus ne peut pas exécuter un nettoyage Lua; utiliser une nouvelle partie dédiée après une telle interruption.

## Procédures distinctes encore nécessaires

| Procédure | Ce qu’elle doit vérifier | Statut de cette campagne |
|---|---|---|
| Visuel FR/EN | Carnet et transcription via bouton vanilla, tous documents et plan; carte/repères selon bateaux et stérilisation; journal, guide, lampes/gyrophares à 5/60 FPS, fumées/fusées, compteur embarquement, texte et boutons de chaque fin | non exécuté |
| Audio | Cri radio et attraction selon volume/écouteurs; sirènes; bande complète; rotor/passeur; chaque voix de fin à 8 s, musique entière 219 s, option musique zéro | non exécuté |
| Sauvegarde/rechargement | Arrêter le scénario, relever act/rev/chapter/trials; sauvegarder uniquement la partie dédiée via menu; redémarrer complètement; reprendre radio/bande/évasion/transport/quarantaine. Aucun double spawn; après Continuer, pas de nouvel écran de fin | non exécuté |
| Fin « Terminer » | Sur une branche dédiée déjà victorieuse, rejouer écran depuis journal puis cliquer Terminer; vérifier chronique UTF-8 dans Lua/OperationArtemis et retour au menu, puis comportement au chargement | non exécuté |
| Corps et mises en scène | Carnet provenant d’un vrai soldat mort sans debug, faux morts bunker, masque/filtre et toxicité, sirène bunker unique, patient zéro résistant, Miller sprinteur/carte d’identité, sujets assis et garnison hors de vue | non exécuté |
| Réseau électrique coupé | Au relais sans réseau, connecter/approvisionner/démarrer un vrai générateur, vérifier refus sans courant puis bande et progression avec courant | non exécuté |
| Intégrations complètes | Computer UI, Vaccine prélèvement-remède, siège réellement annoncé/démarré/suspendu/rétabli, bateau de V et sécurité des collisions; Military Drop via son vrai transport et retour Artemis | non exécuté |
| Multijoueur | Serveur dédié 42.21 + deux clients; droits, commandes rejetées, synchro documents/progression, audio/fumée, occupation enclos, déconnexion/reconnexion, transport et fin commune | non exécuté |

Pour le contrôle de rechargement 25, enregistrer une vraie référence **dans un état stable avant** de sauvegarder et quitter :

```lua
PZPuppet.runFile("OperationArtemis/31_reference_rechargement.lua",{playerIndex=0})
```

Sauvegarder immédiatement via le jeu, redémarrer complètement puis lancer :

```lua
PZPuppet.runFile("OperationArtemis/25_sauvegarde_rechargee.lua",{playerIndex=0})
```

## Préparation et contrôles statiques

Après l'échec du premier 14 sur le trajet du pont, la reprise ne rejoue pas la quarantaine. Elle exige une entrée `passed`, la voie ouverte, l'acte 3 et le personnage à pied sur l'approche sud. Les points déjà dépassés vers le nord sont ignorés; les déplacements restants utilisent les actions vanilla. La première tentative échouée reste archivée séparément.

```lua
PZPuppet.runFile("OperationArtemis/14_fin_checkpoint.lua",{playerIndex=0,manualStop=false},{testSave="2026-10-03_18-48-28",resume=true})
```

Fermer la console et garder la vitesse normale pendant la marche. L'écran de fin, s'il apparaît réellement, est observé et attend désormais le clic du joueur sur Continuer. `autoContinue=true` dans les paramètres réactive explicitement le clic automatique après 12 secondes. La reprise n'est validée qu'après son rapport réel.

```powershell
python C:/Users/cyber/Zomboid/Workshop/OperationArtemis/tests/puppeteer/verify.py
```

Pour installer ou mettre à jour les scénarios, copier les fichiers `.lua` de ce dossier vers `C:/Users/cyber/Zomboid/Lua/PZPuppet/scenarios/OperationArtemis/`, après sauvegarde de chaque copie installée qui diffère. Conserver `manifest.json` et les résultats actuels. Le générateur initial et les scripts ponctuels de migration/enregistrement ont été supprimés après la campagne : leurs valeurs historiques pouvaient écraser les métadonnées affinées pendant les tests.

La référence est un compte rendu texte sous `Lua/PZPuppet/OperationArtemis-reload-reference.txt`, lié au nom de partie. Le test vérifie acte, chapitre, évasion, lecture du dossier, fin et choix Continuer. La révision doit augmenter : `Artemis_Server` appelle `Store.save` à l’initialisation, qui incrémente légitimement ce compteur. Le test ne demande donc pas son identité stricte. Il ne valide pas à lui seul toutes les poses, radios, alarmes, effets ou phases de transport.

`verify.py` vérifie la compilation Lua 5.1, la construction des 31 fabriques neuves sans exécuter leurs callbacks, les assertions/délais/finally, les chemins `require` avec casse exacte, l’absence de commandes debug de progression, luacheck et l’identité des sources avec les copies installées. **Aucune simulation de réussite Artemis.** Voir [preuves de préparation et écarts des protocoles](INSPECTION.md).
