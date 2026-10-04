# Opération Artemis — test en jeu de la phase 6 (intégrations optionnelles)

Parcours **nominaux** seulement. Build 42.21, solo en mode debug. Rien de ce qui suit n'a encore été testé en jeu.

| N° | Mods | Test | Attendu | État |
|---|---|---|---|---|
| G1 | Siege Night (contrôle par défaut) | Lire le dossier de jour (avant 20 h) | Pensée « Ils savent... », journal « Ils envoient tout ce soir » ; la radio de la chaîne Artemis répète l'avertissement ; avertissement de Siege Night dans la journée, siège à 20 h | ☐ |
| G2 | Siege Night | Après ce siège, commande `!siege next` | Prochain siège à la moitié de l'intervalle réglé (1 jour au moins) ; les options sandbox de Siege Night n'ont pas changé | ☐ |
| G3 | Siege Night | Appeler l'hélicoptère, attendre l'aube un jour de siège prévu | Aucun siège pendant le créneau (approche et attente au sol) ; le siège reprend ensuite | ☐ |
| G4 | Computer Mod | Clinique de West Point : classeur du dossier patient | Un CD « Clinique WP - sauvegarde 07/93 » ; dans un ordinateur du mod (bureau voisin, avec courant) : trois notes (mail de la direction, notes de K. Dunn, résultats labo) | ☐ |
| G5 | Computer Mod + Laptop | Archives de la base (-17), classeur du dossier | Un portable ; posé au sol et allumé : trois notes du journal de V, sans mot de passe | ☐ |
| G6 | Tikitown (carte chargée à la création de la partie) | Relais terminé | Bordereau dans le bureau du relais ; journal « labo satellite sous Tikitown » ; repère « Labo satellite (Artemis) » sur la carte ; chapitre 4 dans le journal | ☐ |
| G7 | Tikitown | Descendre au -4, fouiller les bureaux, lire les notes de V | Pensées d'arrivée et de lecture ; chapitre 5 (base) ouvert ; sujets assis à la morgue du -5 (et échantillons si ZVirusVaccine est actif) | ☐ |
| G8 | Sans Tikitown | Relais terminé | Pas de bordereau, passage direct à la base (comme avant) ; `console.txt` : « chapitre optionnel ch4_lab : saute (...) » | ☐ |
| G9 | Aucun | Appeler l'hélicoptère (ou passeur, test d'entrée du checkpoint, arrivée au bateau de V) | Journal et pensée « Une caisse de V » ; caisse militaire (soins, vivres, munitions) près du point, avec une fumée verte qui s'éteint une fois la caisse vidée ; une seule caisse par partie | ☐ |
