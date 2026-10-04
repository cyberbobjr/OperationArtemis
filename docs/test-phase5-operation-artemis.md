# Opération Artemis — test en jeu de la phase 5 (routes A et C, fins, stérilisation)

Mise à jour du gameplay (2026-10-03) : quarantaine plafonnée à une heure de jeu, avec ou sans dossier, incident du détenu à 30 minutes. Pour la campagne nominale réelle, utiliser les scénarios de `tests/puppeteer/` et leurs rapports ; les préparations par progression debug décrites dans ce protocole historique ne prouvent pas un parcours nominal. Le nouveau délai n’est pas encore validé en jeu.

Parcours **nominaux** seulement (les cas aux bornes viendront après). Build 42.21, partie solo en mode debug, mods `batman_OperationArtemis` et `batman_SignalSmoke` actifs. Pour aller vite : menu contextuel « Opération Artemis (debug) » → « Avancer d'un acte » jusqu'à l'acte III, puis prendre le dossier dans les archives (ou le donner par la console) et le **lire**. Les téléportations « Aller au checkpoint », « Aller au poste du pont Kinsella », « Aller au quai du passeur », « Aller au bateau de V » sont dans le même menu à l'acte III.

Rien de ce qui suit n'a encore été testé en jeu.

| N° | Test | Attendu | État |
|---|---|---|---|
| F1 | Lire le dossier, ouvrir la carte du monde | Cinq repères en couleur : hélicoptère (Knox Boundary Camp), bateau de V à Riverside, bateau de V à Louisville, quai du passeur (Brandenburg), point de contrôle (pont Clark Memorial). Plus aucun ancien repère gris « à venir » | ☐ |
| F2 | Ouvrir le journal | Section « Évacuation » avec trois lignes : Hélicoptère, Fleuve, Checkpoint, chacune avec son objectif | ☐ |
| F3 | Checkpoint, sans ZVirusVaccine : « Aller au checkpoint » | Enclos grillagé 6 × 6 avec portail fermé, caisse militaire devant, radio dans l'enclos. Clic droit sur la caisse : « Faire le test sanguin (armée) » | ☐ |
| F4 | Faire le test, entrer dans l'enclos | Pensée « Négatif... », le portail s'ouvre ; une fois dedans, il se referme ; journal « Une heure de quarantaine maximum » ; annonce du haut-parleur ; un détenu mort dans l'enclos | ☐ |
| F5 | Laisser passer 30 minutes de jeu (accélération normale possible) | Le détenu se relève, cri, pensée ; le personnage est réveillé s'il dormait. Des civils viennent au grillage | ☐ |
| F6 | Fin de la quarantaine | Pensée « Négatif. Ils ouvrent le barrage », le portail s'ouvre. Au barrage du pont (y 961-964), un passage de 3 cases est ouvert | ☐ |
| F7 | Traverser le pont vers le nord | Au nord du barrage : écran de fin, sous-titre « Point de contrôle - pont Clark Memorial », chronique « quarantaine au pont Clark Memorial » | ☐ |
| F8 | Passeur, sans mod de bateau : « Aller au quai du passeur », appeler à la radio militaire | Option « Appeler le passeur (radio) » ; la radio grésille, pensée « Il ne passera pas devant les projecteurs » | ☐ |
| F9 | « Aller au poste du pont Kinsella », éteindre le groupe électrogène | Les trois projecteurs s'éteignent ; journal : « Projecteurs de Kinsella : éteints » | ☐ |
| F10 | Revenir au quai, appeler | Réponse du passeur sur la radio, journal « il viendra chaque jour à l'aube » | ☐ |
| F11 | Attendre l'aube (5 h) au quai | Moteur de bateau qui approche du large (son du mod), pensée « Un moteur sur l'eau », zombies qui arrivent ; vers 5 h 30, fumée verte et fusée sur le ponton, cercle vert, compte à rebours en se tenant au bout du ponton avec le dossier, puis écran de fin « le passeur de Brandenburg » | ☐ |
| F12 | Avec un mod de bateau (BoatCore + Working Motorboat ou Aquatsar) : « Aller au bateau de V (Riverside) » | Un bateau sur l'eau le long du ponton, la clé posée sur le ponton, réservoir à 60 % | ☐ |
| F13 | Naviguer vers l'ouest, passer le pont Kinsella projecteurs allumés | Sirène au bout du pont, pensée « Ils m'ont vu ! », horde sur les berges | ☐ |
| F14 | Continuer jusqu'au bord ouest (x ≤ 20) | Écran de fin « Voie fluviale - l'Ohio », chronique « Sortie à l'ouest, après le pont Esther Kinsella » | ☐ |
| F15 | Option sandbox « Stérilisation de la zone » à 1 jour, nouvelle partie jusqu'à la lecture du dossier | Pensée « Stériliser la zone... », journal ; ligne rouge du compte à rebours dans le journal | ☐ |
| F16 | Attendre l'échéance | Tonnerre et éclairs, panique, pensées ; journal « Ils ont frappé » ; brouillard ; repères hélicoptère et checkpoint gris ; la radio de la base ne répond plus ; une horde arrive dans l'heure et demie | ☐ |
| F17 | Après la lecture du dossier, se rendre à chaque lieu (téléportations de debug) | Une fumée verte (avec lueur verte la nuit) marque : le champ d'atterrissage ; avec un mod de bateau, le pied du ponton de Riverside, le quai de Louisville et les deux lignes de sortie ; sans mod, le groupe de Kinsella (disparaît quand on le coupe) puis le quai du passeur ; le poste du checkpoint, remplacé par une fumée au nord du barrage une fois le passage ouvert | ☐ |

À vérifier en passant (hypothèses du code) : flottaison du bateau posé par le mod, collision du grillage, verrou du portail, projecteurs éteints quand le groupe s'arrête, végétation sur l'esplanade du checkpoint et au ponton.
