# Opération Artemis — protocole de test de la phase 3 (alarme de la base, évasion du labo)

- Build : 42.21 — Rédigé le 2026-09-29 — Code contrôlé hors jeu (luacheck 0 avertissement sur 49 fichiers, tests purs OK, 159 clés FR = EN, largeurs des pages OK). **Session de test en jeu du 2026-09-30** (partie solo neuve, Siege Night + correctif du panneau, chapitre 5 atteint par le menu de debug d'Artemis) : résultats ci-dessous. **Bilan : 8 tests validés (P01-P05, P07, P10, P11), 5 cas limites reportés (P06, P08, P09, P12, P13).**
- Décisions et plan : `conception-operation-artemis.md`, sections « Décisions de la phase 3 » et « Plan de la phase 3 ».

## 1. Préparation

- Partie où la base est révélée (chapitre 5 ouvert ou acte III), de préférence neuve. Options : `Mode debug` = oui, `Intensité` = normale.
- Heure du jeu : menu de debug vanilla (pour se placer avant, pendant et après la fenêtre de 23 h 15 à 1 h 15).
- Surveillance : `.claude/tools/pzwatch.py`. Lignes du mod sans accents, préfixées `[OperationArtemis]`.
- Option vanilla « Lighting FPS » (Options > Affichage) : tester les gyrophares à la valeur par défaut, puis à 5 et à 60.

## 2. Tests

### P01 — Garnison posée hors de vue
- **Étapes** : approcher de la base, puis descendre jusqu'au -16.
- **Attendu** : la pose est journalisée **par point** : `pose ch5_base_garrison_surface : 1 zombies sur 1` deux fois (intensité normale) et `pose ch5_base_garrison_lab : 2 zombies sur 2` deux fois (-16 et -13) ; jamais un soldat qui apparaît sous les yeux. Soldats en tenue militaire dans le bureau près de la porte est, le garage près du sas, un cul-de-sac du -16 et le bout du couloir des chambrées du -13.
- **Résultat** : ✅ OK (2026-09-30 : surface 1 + 1 à l'approche, labo 2 + 2 à la descente, 6/6 ; aucun soldat apparu sous les yeux, d'après l'utilisateur)

### P02 — Entrée hors de la fenêtre
- **Étapes** : à 20 h, entrer dans le hall de la base.
- **Attendu** : sirène (à ta position, partout dans la base), pensée « Une alarme ! Les capteurs sont actifs... », `alerte ch5_base : capteurs actifs, <nom> est dans la base`. Lampes rouges vives qui clignotent lentement (0,6 s / 0,6 s). La garnison se met en mouvement. Sortir du bâtiment : `alerte ch5_base : arretee (plus personne dans la base)`.
- **Résultat** : ✅ OK (2026-09-30 : `alerte ch5_base : capteurs actifs, BrentNoland est dans la base`, `sirene ch5_base : son lance` à l'entrée dans le hall à 20 h ; sirène, pensée et lampes conformes d'après l'utilisateur ; en sortant du bâtiment, `alerte ch5_base : arretee (plus personne dans la base)` et `sirene ch5_base : son arrete`)

### P03 — V coupe les capteurs à 23 h 15
- **Étapes** : entrer vers 23 h (alarme), rester jusqu'à 23 h 15.
- **Attendu** : à 23 h 15, silence, pensée « Silence, d'un coup. 23 h 15 : V a coupé les capteurs. », `alerte ch5_base : arretee (fenetre de V, capteurs coupes)` ; lampes de nouveau sombres.
- **Résultat** : ✅ OK selon l'utilisateur (2026-09-30). Réserve : la ligne `alerte ch5_base : arretee (fenetre de V, capteurs coupes)` n'apparaît pas dans le `console.txt` de la session (surveillé jusqu'à l'image 77195) : preuve par le journal à reprendre à l'occasion

### P04 — La fenêtre se referme à 1 h 15
- **Étapes** : entrer après 23 h 15, rester dans la base après 1 h 15.
- **Attendu** : à 1 h 15, l'alarme des capteurs sonne (même règle que P02).
- **Résultat** : ✅ OK (2026-09-30 : entré à 0 h 20 sans alarme ni pensée, puis `alerte ch5_base : capteurs actifs, BrentNoland est dans la base` et `sirene ch5_base : son lance` à la fermeture de la fenêtre, confirmé par l'utilisateur)

### P05 — Le portique des archives
- **Étapes** : pendant la fenêtre (pas d'alarme), prendre le dossier et sortir des archives.
- **Attendu** : dès la porte franchie : sirène, pensée « Le portique ! Toute la base va rappliquer... », panique, `evasion ch5_base : debut (portique franchi par <nom>)`. Journal : ligne rouge « Évasion : l'alarme hurle... ». La garnison converge vers le chemin du retour (sirènes d'étage au -16, au -13 et en surface).
- **Résultat** : ✅ OK (2026-09-30 : fait **hors fenêtre**, alarme des capteurs déjà en cours ; `evasion ch5_base : debut (portique franchi par BrentNoland)` ; pensée, panique et journal conformes d'après l'utilisateur)

### P06 — Dossier reposé
- **Étapes** : dans une autre partie (ou avant P05), prendre le dossier, le reposer dans le classeur, sortir des archives.
- **Attendu** : rien (pas d'alarme).
- **Résultat** : ⏸ reporté (cas limite ; décision de l'utilisateur du 2026-09-30 : valider d'abord le parcours nominal, `test-parcours-nominal-operation-artemis.md`)

### P07 — Réussite de l'évasion
- **Étapes** : après P05, remonter et sortir du bâtiment de surface avec le dossier, à plus de quelques cases.
- **Attendu** : `evasion ch5_base : reussie (<nom>)` ; alarme coupée ; pensées « Dehors... Je suis sorti. » puis « Du brouillard. Tant mieux... » ; brouillard (`brouillard impose : 0.8`) ; journal « Sorti de la base avec le dossier... » ; aucune ligne `remontee avec le dossier` (Surfacing ne rejoue pas). Ensuite, redescendre aux archives avec le dossier et ressortir : **pas** de nouvelle évasion (seule l'alarme des capteurs peut sonner, hors fenêtre).
- **Résultat** : ✅ OK (2026-09-30 : `evasion ch5_base : reussie`, sirène arrêtée, `brouillard impose : 0.8 pendant 120 min` puis `brouillard leve` 120 min plus tard, aucune ligne `remontee avec le dossier` ; pensées « Dehors... » puis « Du brouillard... » et entrée du journal confirmées par l'utilisateur ; retour aux archives sans nouvelle évasion confirmé par l'utilisateur, aucune ligne `evasion … debut` dans le journal). Remarque : sirène coupée puis relancée 30 images plus tard avant la sortie réelle (passage bref hors du bâtiment, sans effet sur l'épreuve)

### P08 — Rechargement pendant l'évasion
- **Étapes** : pendant l'évasion, sauvegarder et recharger.
- **Attendu** : la sirène et les gyrophares reprennent au chargement ; l'épreuve continue et se termine normalement en sortant.
- **Résultat** : ⏸ reporté (cas limite ; décision de l'utilisateur du 2026-09-30 : valider d'abord le parcours nominal, `test-parcours-nominal-operation-artemis.md`)

### P09 — Mort pendant l'évasion
- **Étapes** : mourir dans la base pendant l'évasion ; créer un nouveau personnage.
- **Attendu** : `evasion ch5_base : abandonnee`, alarme coupée ; puis `nouveau personnage : operation reprise du debut`.
- **Résultat** : ⏸ reporté (cas limite ; décision de l'utilisateur du 2026-09-30 : valider d'abord le parcours nominal, `test-parcours-nominal-operation-artemis.md`)

### P10 — Siege Night
- **Étapes** : Siege Night actif, option par défaut ; faire l'évasion.
- **Attendu** : pas de siège pendant l'évasion (suspension au plus 1 minute de jeu après le portique), `sieges automatiques retablis` après la réussite.
- **Résultat** : ✅ par le journal (2026-09-30 : suspendus ~200 images après le portique, `sieges automatiques retablis (acte 3)` après la réussite, aucun siège pendant l'évasion)

### P11 — Gyrophares visibles
- **Étapes** : pendant une alarme, regarder les lampes à l'étage du joueur ; refaire avec « Lighting FPS » à 5 puis 60.
- **Attendu** : clignotement franc (0,6 s / 0,6 s), toutes les lampes ensemble, en rouge vif. Hors alarme, les lampes « faiblissantes » ont des ratés visibles.
- **Résultat** : ✅ OK selon l'utilisateur (2026-09-30 : lampes rouges clignotantes à l'option par défaut, puis à 5 et 60 images/s)

### P12 — La garnison prend-elle les escaliers ?
- **Étapes** : pendant P05, observer un soldat du -13 ou de la surface.
- **Attendu** : les soldats convergent sur leur propre étage (sirènes d'étage). Noter s'ils changent d'étage d'eux-mêmes (non garanti, pathfinding natif).
- **Résultat** : ⏸ reporté (cas limite ; décision de l'utilisateur du 2026-09-30 : valider d'abord le parcours nominal, `test-parcours-nominal-operation-artemis.md`)

### P13 — Dossier repris hors des archives
- **Étapes** : pendant l'évasion, poser le dossier dans le hall de surface, sortir du bâtiment (l'évasion est abandonnée, l'alarme se coupe), revenir et reprendre le dossier.
- **Attendu** : `evasion ch5_base : abandonnee` à la sortie ; dès le dossier repris dans le hall, l'alarme repart (`evasion ch5_base : debut`), sans repasser par les archives.
- **Résultat** : ⏸ reporté (cas limite ; décision de l'utilisateur du 2026-09-30 : valider d'abord le parcours nominal, `test-parcours-nominal-operation-artemis.md`)

## 3. Récapitulatif

| Test | Sujet | Résultat | Remarques |
|---|---|---|---|
| P01 | Garnison posée hors de vue | ☑ OK | 6/6 soldats, aucun apparu en vue |
| P02 | Entrée hors fenêtre | ☑ OK | alarme à l'entrée, arrêt à la sortie |
| P03 | V coupe à 23 h 15 | ☑ OK | selon l'utilisateur ; ligne de coupure non vue dans le journal |
| P04 | Fenêtre qui se referme | ☑ OK | silence à 0 h 20, alarme à 1 h 15 |
| P05 | Portique des archives | ☑ OK | fait hors fenêtre (alarme des capteurs en cours) |
| P06 | Dossier reposé | ⏸ reporté | cas limite, après le parcours nominal |
| P07 | Réussite de l'évasion | ☑ OK | réussite, brouillard, pensées, journal ; pas de seconde évasion |
| P08 | Rechargement pendant l'évasion | ⏸ reporté | cas limite, après le parcours nominal |
| P09 | Mort pendant l'évasion | ⏸ reporté | cas limite, après le parcours nominal |
| P10 | Siege Night | ☑ OK | suspendu au portique, rétabli après la réussite |
| P11 | Gyrophares visibles | ☑ OK | selon l'utilisateur (défaut, 5 et 60 images/s) |
| P12 | Garnison et escaliers | ⏸ reporté | cas limite, après le parcours nominal |
| P13 | Dossier repris hors des archives | ⏸ reporté | cas limite, après le parcours nominal |

## 4. Hors périmètre

- Vagues dirigées (moteur d'épreuve) : phase 4.
- Points d'évacuation sur la carte : phase 4.
- Multijoueur : prévu dans le code (décisions serveur, sirène et gyrophares par client), non testé.
