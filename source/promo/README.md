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
| 01_notebook | Approche accroupie du bunker ; introduction au mystère. |
| 02_clinic | Déplacement dans la clinique. |
| 03_relay | Relais radio, geste vanilla du personnage. |
| 04_archives | Archives du laboratoire souterrain, approche à la lampe. |
| 05_escape | Sortie de la base, course et sirène. |
| 06_pursuit | Poursuite avec jusqu'à trois zombies figurants. |
| 07_ferry | Quai de Brandenburg. |
| 08_checkpoint | Abords du checkpoint. |
| 09_extraction | Zone d'extraction, vraie fumée verte Signal Smoke et son d'hélicoptère hors champ. |

Ce sont des scènes de tournage, pas des tests du parcours nominal. Le script ne termine pas les chapitres, ne modifie pas la progression et ne fabrique pas de victoire. Il ne crée ni bateau navigable, ni hélicoptère visible, ni PNJ humain. L'état de la partie de test et la présence des objets du mod doivent être inspectés sur les prises avant de les employer dans la promotion.

Les assertions nommées vérifient les préconditions, le chargement des lieux, l'équipement et les actions. Les délais sont bornés. Le nettoyage restaure les mains, l'heure, la position, les flags et l'interface, retire les accessoires et les seuls zombies créés par le tournage, et arrête les sons et fumées créés. Il ne remonte pas le temps de la simulation : exploration, fatigue, IA et modifications ordinaires du monde peuvent persister dans cette partie dédiée.

## Capture et montage

FFmpeg capture la fenêtre `Project Zomboid`, à 30 images/s, sans curseur. Le son est enregistré en stéréo par loopback de la sortie audio Windows ; aucun microphone d'entrée n'est ouvert. Les dépendances SoundCard/Numpy sont installées séparément sous `C:/Users/cyber/.codex/scratch/artemis-recording-deps/` et ne sont pas incorporées au mod.

Le surveillant démarre au premier `ROLL`, coupe les neuf prises aux repères `ACTION`/`CUT`, puis extrait des captures réelles. Une session interrompue reste distincte d'une session `FINISHED`. Un film complet peut alimenter la maquette locale ; les adresses publiques des images Steam restent à renseigner dans `steam-images.json` après leur mise en ligne autorisée. Les fichiers racine `README.steam*` n'incluent pas d'URL inventée.

Après vérification des neuf prises, préparer les montages français et anglais :

```powershell
python OperationArtemis/source/promo/capture.py --edit OperationArtemis/source/promo/captures/takes/<identifiant> --language fr
python OperationArtemis/source/promo/capture.py --edit OperationArtemis/source/promo/captures/takes/<identifiant> --language en
```

Le montage dure environ 44 secondes : neuf plans de jeu, titres courts, affiche d'ouverture et de fin. Son direct conservé ; aucune musique additionnelle n'est ajoutée automatiquement. Vérifier le rythme et le son avant publication. Le script n'envoie rien à Steam.

## État de validation au 4 octobre 2026

- Scénario : compilation Lua, construction de deux scènes fraîches sans action au chargement et luacheck sans avertissement ; pas encore exécuté en jeu.
- Capture : essai technique réel de deux secondes, vidéo centrale 1600 × 900 et piste stéréo 48 kHz. Le jeu était en pause et la piste était silencieuse ; le son de gameplay reste à confirmer pendant une prise.
- Trailer et captures promotionnelles : en attente du lancement Lua et de l'inspection des prises. Les simulations du moteur ne constituent pas cette validation.
