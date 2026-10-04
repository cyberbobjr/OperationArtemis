# Opération Artemis — test de la phase 4 (route de l'hélicoptère, carte, fin)

- Build : 42.21 — Rédigé le 2026-09-30, mis à jour le 2026-10-02 — Code de la phase 4 contrôlé hors jeu (luacheck 0 avertissement sur 63 fichiers, 116 tests purs, clés FR = EN, deux relectures Opus corrigées). **Les tests de ce protocole restent à faire en jeu.**
- Mods : `batman_OperationArtemis` **et** `batman_SignalSmoke` (requis, projet `Workshop\SignalSmoke`), Siege Night et son correctif si voulu.
- Médias intégrés (lot 9 terminé le 2026-09-30) : image de victoire, voix de V en FR et EN et musique « The First Light ». Bande sonore validée par l'utilisateur ; voix lancée à 8 s depuis le remixage du 2026-10-01. Affichage et lecture des médias dans l'écran de fin à vérifier en jeu (E7).
- Raccourcis : menu **Opération Artemis (debug)** (« Aller à la zone d'atterrissage » à l'acte III), heure par le menu de debug vanilla, radio militaire par la console Lua : `getPlayer():getInventory():AddItem("Base.WalkieTalkie5")`.
- Parcours nominal d'abord (décision de l'utilisateur) ; les cas limites sont listés à la fin et ne sont pas à faire maintenant.

## Parcours nominal

| # | Action | Attendu | Résultat |
|---|---|---|---|
| E1 | Partie à l'acte III avec le dossier (debug ou partie en cours), **lire le dossier** | Texte du dossier qui nomme les lieux ; sur la carte : icône d'hélicoptère rouge « Évacuation aérienne (Knox Boundary Camp) », repères du fleuve selon la présence d'un mod de bateau et repère du checkpoint (phase 5 intégrée ; plus de repères gris « à venir ») | ☐ |
| E2 | Journal (K) | Section « Évacuation » avec les trois routes ; objectif de l'hélicoptère : appeler avec une radio militaire sur la chaîne Artemis | ☐ |
| E3 | Talkie militaire (`WalkieTalkie5`) en main, allumé, réglé sur 108,0, micro actif ; clic droit sur la radio → **Appeler l'évacuation (radio)** | Le personnage dit l'indicatif ; quelques secondes plus tard la radio répond « Indicatif reçu… » ; pensée ; journal « La base a répondu… » ; `appel d'evacuation accepte` | ☐ |
| E4 | « Aller à la zone d'atterrissage », régler l'heure sur 4 h 55, attendre 5 h | `extraction : rotor en approche` ; pensée « Un rotor… » ; son de l'hélicoptère qui tourne et se rapproche, ombre et flèche ; zombies attirés, quelques apparitions hors de vue (`extraction : vague…`), dernière vague en sprinteurs | ☐ |
| E5 | Tenir jusqu'à 5 h 30 | `extraction : helicoptere pose` ; pensée « Il s'est posé ! » ; fusée verte dans le ciel ; au sol : cercle vert pulsé, fusée verte allumée au centre, fumée verte de part et d'autre | ☐ |
| E6 | Entrer dans le cercle avec le dossier et y rester | « Embarquement : 10 s » qui décompte ; `extraction reussie` | ☐ |
| E7 | Écran de victoire | Fondu au blanc, jeu en pause, image de victoire, musique « The First Light » et voix de V dans la langue du jeu (FR ou EN ; voix à 8 s), épilogue qui défile puis la chronique (jours, heures, zombies tués, journal) ; boutons « Terminer » et « Continuer (épilogue) » | ☐ |
| E8 | « Continuer » | Retour au jeu ; journal : bouton « Revoir l'écran de fin » ; à la radio sur 108,0, message final de V (dans les 10 minutes de jeu) | ☐ |
| E9 | Recharger la partie, puis « Revoir l'écran de fin » → « Fermer » ; enfin « Terminer » sur une copie de sauvegarde | Pas d'écran au chargement après « Continuer » ; « Terminer » écrit `Zomboid\Lua\OperationArtemis\chronique_…txt` et revient au menu | ☐ |
| E10 | Bilan du journal | Aucune erreur Lua d'Artemis ni de Signal Smoke | ☐ |

## Cas limites (reportés)

- Rendez-vous manqué (quitter la zone avant l'atterrissage) : journal « L'hélicoptère est reparti sans moi », retour le lendemain à 5 h.
- Appel passé pendant le créneau (5 h 10) : premier passage le lendemain.
- Rechargement pendant la tenue ou l'atterrissage ; sommeil jusqu'au rendez-vous.
- Mort pendant la tenue ; nouveau personnage après une fin (fenêtre « relancer l'opération ? »).
- Manette sur l'écran de fin ; Échap pendant l'écran ; option « Musique » à 0.
- Radio posée (poste US Army) au lieu du talkie ; micro coupé ; mauvaise fréquence (infobulles).
- Écran partagé ; multijoueur.
