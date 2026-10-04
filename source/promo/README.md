# Tournage Operation Artemis

Les affiches de `../art/20261004-cinematic/` sont des illustrations promotionnelles. Les images de la page Steam et les séquences du trailer doivent provenir du jeu réellement exécuté, avec une trace des prises dans `captures/takes/<identifiant>/capture.json`.

## Lancement

Activer `batman_PZDirector`, `batman_PZPuppeteer`, `batman_OperationArtemis` et `batman_SignalSmoke` dans une partie solo dédiée, avec le jeu en `-debug`, Build 42.21, personnage vivant et à pied. Les noms de sauvegarde acceptés commencent par `PZDirector_Artemis_` ou `PZPuppet_Artemis_`. Une partie de test existante peut servir ; le script refuse une sauvegarde personnelle.

Le fichier `film.lua` est installé sous `C:/Users/cyber/Zomboid/Lua/PZPuppet/scenarios/OperationArtemisTrailer/film.lua`. Après une modification de la source, recopier ce fichier avant de rejouer.

Lancer d'abord le surveillant externe :

```powershell
python OperationArtemis/source/promo/capture.py --watch
```

Dans la console Lua du jeu :

```lua
PZPuppet.runFile("OperationArtemisTrailer/film.lua",{playerIndex=0})
```

Fermer la console et le menu pause, reprendre à vitesse normale et laisser le personnage agir. Le compte à rebours laisse huit secondes actives ; le chargement des décors se fait entre les prises. La caméra du jeu suit le personnage. Choisir un zoom lisible avant le lancement ; la capture recadre le centre de la fenêtre du jeu à 1600 × 900 maximum. Aucune autre fenêtre du bureau n'est enregistrée.

Arrêt d'urgence : `Ctrl+Maj+F11` ou `PZDirector.stop("Arret du tournage")`. Une interruption conserve les fichiers déjà capturés et ne produit pas un film réussi.

Pour reprendre une seule prise après inspection :

```lua
PZPuppet.runFile("OperationArtemisTrailer/film.lua",{playerIndex=0},{shot="04_archives",seconds=10})
```

## Plans

| Prise | Décor et action prévue |
|---|---|
| 01_notebook | Bunker souterrain ; récupération réelle des ordres de mission. Heure maintenue : 10 h. |
| 02_clinic | Clinique ; récupération réelle du dossier patient. 11 h. |
| 03_relay | Activation de la vraie radio du relais par son action vanilla. 12 h. |
| 04_archives | Archives souterraines ; récupération du dossier à la lampe. 12 h. |
| 05_escape | Sortie de la base, course et sirène. |
| 06_pursuit | Assaillant proche, tir réel puis fuite ; second poursuivant sprinteur libéré au départ. 16 h. |
| 07_ferry | Quai de Brandenburg : signe d'arrêt puis déplacement rapide. 7 h. |
| 08_checkpoint | Contrôle des abords du checkpoint, arme en joue. 10 h. |
| 09_extraction | Vraie fumée verte Signal Smoke, signe d'appel puis course ; hélicoptère sonore hors champ. 8 h. |

Ce sont des scènes de tournage, pas des tests du parcours nominal. Le script ne force pas la progression et ne fabrique pas de victoire ; les actions réelles peuvent faire avancer les données du mod dans cette partie dédiée. Il ne crée ni bateau navigable, ni hélicoptère visible, ni PNJ humain. L'état de la partie de test et la présence des objets du mod doivent être inspectés sur les prises avant de les employer dans la promotion.

Les assertions nommées vérifient les préconditions, le chargement des lieux, l'équipement et les actions. Les délais sont bornés. Le nettoyage restaure les mains, l'heure, la position, les flags et l'interface, retire les accessoires et les seuls zombies créés par le tournage, et arrête les sons et fumées créés. Il ne remonte pas le temps de la simulation : exploration, fatigue, IA et modifications ordinaires du monde peuvent persister dans cette partie dédiée.

Le réalisateur prépare maintenant le costume `field` (veste et pantalon camouflage, bottes, chapeau, sac ALICE), lampe primaire et radio secondaire, choisit un trajet praticable autour de chaque décor et éclaire les prises souterraines. Le script recharge automatiquement le module de production sans événements depuis son chemin local autorisé ; la même commande Lua reprend donc le script corrigé dans la session en cours.

## Teaser v2 (2026-10-04)

Nouveau découpage en 8 plans : [TEASER.md](TEASER.md). Tournage automatisé par la régie de PZDirector (`PZDirector/tools/tournage.py`) : jeu lancé avec l'agent ZombieBuddy, sauvegarde chargée, passage en fenêtre 1600 × 900 (la capture de fenêtre se fige en plein écran sans bordure), surveillant `capture.py --watch`, puis `teaser.lua`. Montage : `teaser_edit.py`. `film.lua` (bande-annonce en 9 plans) reste disponible ; il ne recharge plus le moteur PZPuppeteer pendant son exécution.

## Capture et montage

FFmpeg capture la fenêtre `Project Zomboid`, à 30 images/s, sans curseur. Le son est enregistré en stéréo par loopback de la sortie audio Windows ; aucun microphone d'entrée n'est ouvert. Les dépendances SoundCard/Numpy sont installées séparément sous `C:/Users/cyber/.codex/scratch/artemis-recording-deps/` et ne sont pas incorporées au mod.

Le surveillant démarre au premier `ROLL`, coupe les prises aux repères `ACTION`/`CUT`, puis extrait des captures réelles. Une session interrompue reste distincte d'une session `FINISHED`. L'inspection et l'approbation explicite des neuf prises permettent ensuite d'alimenter la maquette locale ; les adresses publiques des images Steam restent à renseigner dans `steam-images.json` après leur mise en ligne autorisée. Les fichiers racine `README.steam*` n'incluent pas d'URL inventée.

Après vérification des neuf prises, préparer les montages français et anglais :

```powershell
python OperationArtemis/source/promo/capture.py --edit OperationArtemis/source/promo/captures/takes/<identifiant> --language fr
python OperationArtemis/source/promo/capture.py --edit OperationArtemis/source/promo/captures/takes/<identifiant> --language en
```

Le montage prévu dure environ 25 secondes : amorce de menace, identité brève, indices et radio, puis coupes de 1,1 à 1,5 seconde dans la fuite. La poursuite possède deux repères `BEAT` pour choisir le tir et le départ de la course. Les vidéos gardent la vitesse réelle du jeu et le son direct. Aucune musique additionnelle n'est ajoutée automatiquement. Vérifier rythme, image et son avant publication. Le script n'envoie rien à Steam.

## État de validation au 4 octobre 2026

- Première exécution réelle : rapport `PZPuppet/reports/1791124522169-1.txt`, échec à la préparation de la lampe avant la première prise. L'équipement vanilla l'avait allumée ; un callback supplémentaire l'éteignait. Le script utilise désormais l'activation conditionnelle de PZDirector.
- Tournage `1791126684158` : neuf prises terminées techniquement, rejetées pour clipping, protection de l'acteur, zombies sans direction et défauts visuels. Les fichiers sont conservés dans leur dossier de prise ; aucune image de cette session n'alimente la page.
- Répétition `1791128039880`, rapport `1791128039867-2` : assertions d'heure, collisions et cheats désactivés réussies en 42.21.0 ; image réelle rejetée pour personnage marchant seul, menace hors cadre et manque de rythme. Son non silencieux capturé, contenu sonore non encore vérifié à l'écoute.
- Nouvelle séquence : tir avec consommation d'une munition, deux figurants aux allures vanilla individuelles, sprint maintenu dans l'action de chemin et cadrage 0,75. 37 contrats simulés et luacheck passent ; cette révision attend sa répétition réelle.
- Répétition `1791128935306-3` : arrêt avant le premier `ROLL`, car le cheat de munitions illimitées était actif. La régie désactive désormais aussi ce cheat et restaure sa valeur initiale. Aucune vidéo promotionnelle produite par cette tentative.
- Reprise `1791129185634`, rapport `1791129185624-4` : séquence tir/fuite terminée en jeu. Tir confirmé, sprint de six cases en 2,716 s, deux poursuivants visibles sur les images. Clip exploitable de 3,658 s ; lampadaire occultant brièvement l'acteur à éviter au montage. La piste est non silencieuse, mais reste à écouter. Les neuf plans complets restent à tourner et à inspecter. Un cas de contrat supplémentaire protège la fin d'un tir qui tue sa cible : 38 tests passent.
- Documents filmés : copies du type exact du mod, placées dans les meubles existants aux véritables sites, puis récupérées par transfert vanilla. Les originaux et la progression ne sont pas réinitialisés. Le tournage ne prouve pas la réussite des chapitres.
- Promotion : inspection des neuf prises requise puis `capture.py --approve <dossier> --review-note "constats"` pour alimenter la maquette locale. Un résultat technique `passed` n'approuve jamais automatiquement les images. Les URL Steam restent à intégrer après mise en ligne autorisée.
