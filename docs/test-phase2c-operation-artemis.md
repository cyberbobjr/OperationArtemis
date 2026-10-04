# Opération Artemis — protocole de test de la phase 2c (mise en scène de l'acte II)

- Build : 42.21 — Rédigé le 2026-09-29 — Code contrôlé hors jeu (luacheck 0 avertissement sur 47 fichiers, tests purs OK, 148 clés FR = EN, largeurs des pages OK) et relu par Opus (2 problèmes élevés corrigés). **Rien n'est encore testé en jeu.**
- Détail des effets et de leurs causes : `conception-operation-artemis.md`, section 4 bis (« Scènes par étape clé ») et section 7 (« Plan de la phase 2c »).

## 1. Préparation

- **Partie neuve** conseillée (ou copie de sauvegarde). Dans une partie où un chapitre est déjà terminé, ses nouvelles poses ne se font pas : seul le chapitre en cours reçoit ses nouveaux groupes. Une sauvegarde arrêtée à la base (test V08) reçoit les sujets du labo.
- Options de la page « Opération Artemis » : `Mode debug` = oui, `Intensité` = normale (sauf mention).
- Surveillance : `.claude/tools/pzwatch.py`. Toutes les lignes du mod commencent par `[OperationArtemis]` et sont sans accents.
- Debug du mod (clic droit au sol) : « Aller au lieu du chapitre », « Aller au dépôt du chapitre », « Terminer le chapitre en cours ». Pour les zombies posés hors de vue (relais), **ne pas se téléporter directement** : arriver de loin, ou s'éloigner d'au moins 60 cases après la téléportation.
- Heure du jeu : menu de debug vanilla (pour l'aube et la nuit).

## 2. Tests

### Bunker de March Ridge (chapitre 1)

#### C01 — Groupe électrogène et masque à gaz
- **Étapes** : descendre au niveau -4, aller dans la salle des machines (9944-9956, 12615-12623, à une quinzaine de cases du bureau).
- **Attendu** : `pose ch1_bunker_generator : groupe electrogene en X,Y,-4`. Un vieux groupe électrogène, déjà branché : clic droit → « Allumer » proposé sans compétence. Un masque à gaz au sol tout près, avec un filtre (infobulle).
- **Résultat** : ☐ OK ☐ KO

#### C02 — La sirène
- **Étapes** : allumer le groupe.
- **Attendu** : dans la minute de jeu : pensée « Une sirène ?! Et ça sent les gaz... », sirène en boucle depuis la cabane d'entrée, `alerte ch1_bunker : sirene declenchee (rayon 100)`, `sirene ch1_bunker : son lance`. Les zombies des environs convergent vers la cabane. Le bunker devient toxique (fatigue, puis dégâts) ; **avec le masque porté, aucun effet** (le filtre s'use).
- **Résultat** : ☐ OK ☐ KO

#### C03 — Arrêt et une seule fois
- **Étapes** : couper le groupe ; le rallumer.
- **Attendu** : `sirene arretee (groupe arrete)`, le son s'arrête. Au redémarrage, plus de sirène. (Variante : le laisser tourner 20 minutes de jeu → `fin du cycle`.)
- **Résultat** : ☐ OK ☐ KO

#### C04 — Brume de l'aube
- **Étapes** : régler l'heure juste avant l'aube (vers 5 h), descendre dans le bunker, remonter et sortir de la cabane.
- **Attendu** : `brouillard impose : 0.3 pendant 60 min`, `brume ch1_bunker : a l'aube, sortie de ...` ; brume légère. `brouillard leve` une heure de jeu plus tard. À midi, rien ; une seconde sortie à l'aube, rien.
- **Résultat** : ☐ OK ☐ KO

### Clinique de West Point (chapitre 2)

#### C05 — Applique de secours
- **Attendu** : `pose ch2_clinic_scene : applique en 11883,Y,0`. Une applique murale dans le couloir, dont la lumière chaude clignote (courtes coupures, puis une plus longue, toutes les 5 s). Sans réseau électrique. Si on la démonte, la lumière disparaît. **À regarder** : le sprite de l'applique pourrait s'afficher « éteint » alors que la lampe éclaire (décor sans interrupteur).
- **Résultat** : ☐ OK ☐ KO

#### C06 — Salle d'examen fermée à clé
- **Attendu** : `porte verrouillee, zombie Nurse pose`. La porte de la salle d'examen (11883,6878) est fermée à clé ; en approchant, on entend frapper derrière. La porte tient. Depuis le couloir, on peut l'ouvrir (règle vanilla des portes intérieures).
- **Résultat** : ☐ OK ☐ KO

#### C07 — Patient zéro
- **Attendu** : `pose ch2_clinic_scene : 1 zombies sur 1`. Un homme en blouse d'hôpital à l'accueil, qui encaisse nettement plus de coups qu'un zombie ordinaire. S'éloigner de plus de 150 cases puis revenir (ou sauvegarder et recharger) : `zombie suivi retrouve : patient_zero`, toujours aussi résistant.
- **Résultat** : ☐ OK ☐ KO

#### C08 — Dossier du patient
- **Attendu** : la page affiche « Sédatifs : sans effet » et « Tissus : anormalement durs », sans chevaucher le tampon ; la transcription parle de l'infirmière K. Dunn isolée en salle d'examen 2 et du patient qui erre encore. Pensée : « Six juillet. Ils savaient dès le premier jour. Un relais radio, entre Brandenburg et Riverside. » (FR et EN).
- **Résultat** : ☐ OK ☐ KO

### Relais (chapitre 3)

#### C09 — Zombies autour du relais
- **Étapes** : arriver de loin (plus de 100 cases).
- **Attendu** : `pose ch3_relay_zombies : 5 zombies sur 5` avant l'arrivée (moins si une partie de l'anneau n'est pas encore chargée : noter le nombre) ; aucun zombie posé à moins de 25 cases. Allumer un groupe électrogène près de la station : les zombies à portée du bruit arrivent.
- **Résultat** : ☐ OK ☐ KO

#### C10 — La radio de la salle de contrôle
- **Attendu** : `pose ch3_relay_radio : radio posee en 4836,6277,0`. Une radio sur la table, à la bonne hauteur, sans emplacement de pile ; elle ne s'allume pas sans courant.
- **Résultat** : ☐ OK ☐ KO

#### C11 — La bande de V
- **Étapes** : registre lu, courant rétabli, allumer la radio, écouter jusqu'au bout (environ 1 minute).
- **Attendu** : `bande ch3_tape : lecture`, lignes ambrées au-dessus de la radio avec des parasites (code 7-1-4-9, Rosewood-Sud, 23 h 15 - 1 h 15). `bande ch3_tape : terminee`, `bande ch3_tape entendue par ...`, puis `chapitre termine : ch3_relay -> ch5_base` dans la minute ; journal et code d'appel.
- **Résultat** : ☐ OK ☐ KO

#### C12 — Bande interrompue et aide
- **Étapes** : éteindre la radio en cours de bande, la rallumer ; dans une autre partie, rester 3 minutes avec le courant et le registre lu sans allumer la radio.
- **Attendu** : `bande ch3_tape : interrompue`, puis la bande repart du début. Aide : « Il y a du courant. La radio sur la table de la salle de contrôle... » (`aide : hint_ch3_radio`).
- **Résultat** : ☐ OK ☐ KO

#### C13 — Miller
- **Attendu** : `pose ch3_relay_miller : 1 zombies sur 1`. Un homme en combinaison de mécanicien, sprinteur, derrière la station. Après un aller-retour de plus de 150 cases : `zombie suivi retrouve : miller`, il sprinte encore. Abattu : `zombie suivi abattu : miller, objet dans le corps`, et la carte « Carte d'identité : Dale Miller, technicien » dans le corps ; tué par le feu : carte au sol.
- **Résultat** : ☐ OK ☐ KO

#### C14 — Registre du relais
- **Attendu** : la ligne « 10/07 : Miller parti en courant. Il ne dormait plus. » sur la page, sans débordement ; la transcription dit d'allumer la radio de la salle de contrôle.
- **Résultat** : ☐ OK ☐ KO

### Base secrète (chapitre 5)

#### C15 — Fenêtre de deux heures
- **Attendu** : l'objectif du chapitre 5, le journal du chapitre 3 et le plan de la base (ligne manuscrite « Capteurs : 23 h 15 - 1 h 15 ») donnent la fenêtre de 23 h 15 à 1 h 15.
- **Résultat** : ☐ OK ☐ KO

#### C16 — Lampes rouges qui clignotent
- **Attendu** : à l'étage du joueur, les lampes rouges ont des ratés irréguliers ; les autres étages restent allumés. Aucune baisse d'images par seconde.
- **Résultat** : ☐ OK ☐ KO

#### C17 — Sujets du labo
- **Attendu** : `pose ch5_base_subjects : N zombies sur N` (une ligne par salle). Des zombies en blouse de patient, assis dos au mur, au labo du niveau -17 et dans les salles du -16. Ils se lèvent quand ils voient ou entendent le joueur. Après un rechargement : `zombie suivi retrouve : lab_subject`, de nouveau assis s'il est sur une case contre un mur, centré et dos au mur (sinon il reste debout).
- **Résultat** : ☐ OK ☐ KO

#### C18 — Lecture du dossier
- **Attendu** : deux pensées, la seconde « Ils vont venir me chercher. Ou me faire taire. ».
- **Résultat** : ☐ OK ☐ KO

#### C19 — Remontée dans le brouillard
- **Étapes** : dossier en main (acte III), remonter à la surface de la base.
- **Attendu** : `remontee avec le dossier : ch5_base`, `brouillard impose : 0.8 pendant 120 min`, pensée « Du brouillard. Tant mieux : ils me verront moins. ». Une seule fois par partie.
- **Résultat** : ☐ OK ☐ KO

### Transverse

#### C20 — Scènes rapprochées
- **Étapes** : prendre le dossier puis le lire aussitôt (deux scènes en moins d'une minute).
- **Attendu** : la pensée de la prise du dossier et celles de la lecture s'affichent toutes.
- **Résultat** : ☐ OK ☐ KO

#### C21 — Rechargement pendant un effet
- **Étapes** : sauvegarder et recharger pendant la sirène, puis pendant un brouillard.
- **Attendu** : la sirène reprend si le groupe tourne encore (sinon `zone dechargee` ou `groupe arrete`) ; le brouillard imposé disparaît au rechargement (limite connue du moteur). Aucune erreur.
- **Résultat** : ☐ OK ☐ KO

#### C22 — Nouveau personnage dans la même carte
- **Étapes** : dans une partie où l'opération a commencé, créer un nouveau personnage (après une mort, ou « nouveau personnage » dans la carte existante). Variante : debug « Réinitialiser l'état ».
- **Attendu** : `nouveau personnage : operation reprise du debut (acte 0, ...)`. Journal caché (sans debug), plus de repères de l'enquête sur la carte (la zone déjà découverte reste visible). En relançant l'opération : badge et documents de nouveau dans leurs meubles (sans doublon s'ils y étaient encore) ; groupe électrogène, zombies posés, radio et applique non doublés. Si l'ancien personnage avait pris la carte d'accès, un garde est reposé devant la base.
- **Résultat** : ☐ OK ☐ KO

## 3. Récapitulatif

| Test | Sujet | Résultat | Remarques |
|---|---|---|---|
| C01 | Groupe et masque | ☐ OK ☐ KO | |
| C02 | Sirène, toxicité, masque | ☐ OK ☐ KO | |
| C03 | Arrêt, une seule fois | ☐ OK ☐ KO | |
| C04 | Brume de l'aube | ☐ OK ☐ KO | |
| C05 | Applique de secours | ☑ OK ☐ KO | 2026-09-29, partie neuve : validé par l'utilisateur |
| C06 | Salle d'examen | ☑ OK ☐ KO | 2026-09-29, partie neuve : validé par l'utilisateur |
| C07 | Patient zéro | ☑ OK ☐ KO | 2026-09-29, partie neuve : posé en approchant, plus résistant, abattu (validé) |
| C08 | Dossier du patient | ☐ OK ☐ KO | |
| C09 | Zombies autour du relais | ☑ OK ☐ KO | 2026-09-29, partie neuve : 5 zombies sur 5 posés hors de vue (validé) |
| C10 | Radio de la salle | ☐ OK ☑ KO | Radio posée, mais une station tirée au hasard occupait sa fréquence fixe (103,4) : textes mêlés. Corrigé (fréquence libre à la pose et à chaque lecture), à retester |
| C11 | Bande de V | ☑ OK ☐ KO | 2026-09-29 : bande écoutée et validée ; texte jaune lisible (validé) |
| C12 | Bande interrompue, aide | ☐ OK ☑ KO | L'aide « radio » suivait l'aide « registre » une minute après, registre non lu. Corrigé (aides dans l'ordre, aide « après la bande » en tête), à retester |
| C13 | Miller | ☐ OK ☐ KO | 2026-09-29 : posé deux fois (`1 zombies sur 1`) ; carte d'identité sur son corps à vérifier |
| C14 | Registre du relais | ☐ OK ☐ KO | |
| C15 | Fenêtre de deux heures | ☑ OK ☐ KO | 2026-09-29 : ligne « Capteurs » du plan lisible |
| C16 | Lampes qui clignotent | ☑ OK ☐ KO | 2026-09-29 : lampes fixes acceptées ; déplacées dans les couloirs du vrai chemin (par le -16), étape du -16 vue, « guident un peu » |
| C17 | Sujets du labo | ☐ OK ☐ KO | Non croisés par l'utilisateur (hors du chemin, accepté) ;  2026-09-29 : partie neuve, 5 posés **sans erreur de suivi** (correction du bit « femme » confirmée), 2 retrouvés à leur retour ; position assise à vérifier |
| C18 | Lecture du dossier | ☑ OK ☐ KO | 2026-09-29 |
| C19 | Remontée dans le brouillard | ☑ OK ☐ KO | 2026-09-29 : brouillard imposé à la remontée et pensée (validé) |
| C20 | Scènes rapprochées | ☑ OK ☐ KO | 2026-09-29 : pensées du dossier puis de l'acte III, toutes affichées |
| C21 | Rechargement pendant un effet | ☐ OK ☐ KO | |
| C22 | Nouveau personnage | ☐ OK ☐ KO | 2026-09-29 : variante debug OK (acte 0, documents reposés : badge, dossier du patient, registre, dossier Artemis ; groupe électrogène posé une fois). Création d'un personnage à tester |

## 4. Hors périmètre

- Le multijoueur (prévu dans le code : autorité serveur, lampes et sirène jouées par chaque client ; la bulle de la bande n'est vue que par le joueur qui allume la radio).
- L'alarme de la base, la garnison et les gyrophares : phase 3.
