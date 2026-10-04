# Opération Artemis — test du parcours nominal (jalon J1)

- Build : 42.21 — Rédigé le 2026-09-30, à la demande de l'utilisateur : valider **l'histoire entière dans le cas nominal**, sans les cas aux bornes (reportés, voir `test-phase3-operation-artemis.md`).
- Portée : du carnet à la sortie du labo avec le dossier (acte III ouvert). La suite (route de l'hélicoptère, fin) est la phase 4, pas encore écrite.
- Raccourcis autorisés : téléportations du menu **Opération Artemis (debug)** (« Aller au lieu du chapitre », « Aller au dépôt du chapitre ») et « Recevoir le carnet Artemis ». **Ne pas** utiliser « Terminer le chapitre en cours » : chaque objectif doit être atteint normalement.
- Partie : de préférence **neuve** (sinon « Réinitialiser l'état » : les zombies déjà posés, dont la garnison, ne sont pas reposés). Options : `Mode debug` = oui, `Intensité` = normale, Siege Night + son correctif actifs.
- Surveillance : `.claude/tools/pzwatch.py` ; une étape est KO dès qu'une erreur Lua du mod apparaît.

## Étapes

| # | Action | Attendu (en jeu / journal) | Résultat |
|---|---|---|---|
| N1 | Recevoir le carnet (debug) et le lire | Transcription du carnet ; acte I ; `debugAdvance`/lecture journalisée | ☑ OK |
| N2 | Radio sur 108,0 MHz, écouter la chaîne | Diffusion Artemis, cri, acte II ouvert au chapitre 1 ; journal (K) et marque sur la carte | ☑ OK |
| N3 | Bunker de March Ridge : aller au dépôt, prendre le badge | `chapitre termine : ch1_bunker -> ch2_clinic` ; pensée, journal et carte mis à jour | ☑ OK |
| N4 | Clinique de West Point : prendre le dossier du patient zéro | `chapitre termine : ch2_clinic -> ch3_relay` | ☑ OK |
| N5 | Relais radio : lire le registre, rétablir le courant, écouter la bande de V | `document lu`, bande jouée ; `chapitre termine : ch3_relay -> ch5_base` ; base révélée | ☑ OK |
| N6 | Base : fouiller le garde de l'entrée (carte d'accès, plan de V), lire le plan, entrer, descendre au -17 | Plan lisible ; garnison posée hors de vue ; alarme des capteurs si hors de 23 h 15 - 1 h 15 | ☑ OK |
| N7 | Archives : prendre le dossier et sortir de la salle | `chapitre termine : ch5_base -> acte 3` ; `evasion ch5_base : debut` ; sirène, gyrophares, garnison qui converge | ☑ OK |
| N8 | Remonter et sortir du bâtiment de surface avec le dossier | `evasion ch5_base : reussie` ; pensées de sortie, brouillard, journal ; sièges Siege Night rétablis | ☑ OK |
| N9 | Bilan du journal | Aucune erreur Lua du mod sur tout le parcours | ☑ OK |

## Remarques

- 2026-09-30 : **N1 à N9 validés par l'utilisateur**, parcours joué au moins trois fois (phases 1, 2 et 3, dont la session du 2026-09-30 : base, évasion et sortie observées dans `console.txt`, sans erreur Lua du mod). **Jalon J1 atteint.**
