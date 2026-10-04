# Sources des médias

Les ressources chargées par le jeu se trouvent dans `Contents/mods/batman_OperationArtemis/42.21/media/`. Ce dossier contient les outils de production et les entrées nécessaires pour les refaire.

À conserver dans `out/` :

- `voice_EN_raw.mp3`, `voice_FR_raw.mp3` : voix originales validées.
- `var_<langue>_<variante>_<paragraphe>.mp3` : paragraphes retenus pour les différentes fins.
- `align_EN.json`, `align_FR.json`, `stt_EN.json`, `stt_FR.json` : alignements et transcriptions existants, pour éviter une nouvelle transcription payante.
- `voice_EN.wav`, `voice_FR.wav` : voix avec effet de bande, entrées actuelles de la commande `mix`.

L'image de victoire retenue est conservée dans `../../assets/victory_source.png`. Les sources de musique et de bateau restent dans `../../assets/`.

Les découpes de `out/assemble/`, les WAV de variantes, les auditions et les images candidates sont des intermédiaires ou des essais. Ils peuvent être supprimés après vérification des sorties et sont ignorés par Git.

Pour reconstruire les variantes depuis les MP3 et alignements conservés, avec FFmpeg disponible :

```powershell
python source/media/artemis_media.py assemble FR
python source/media/artemis_media.py assemble EN
```

Ces commandes reconstruisent les intermedíaires et remplacent les OGG correspondants dans `Contents`. Elles ne font pas appel à un service de génération. Ne pas les lancer simplement pour nettoyer les fichiers.

Les commandes `tts`, `variants`, `samples`, `expressive`, `confidential`, `align` sans cache et `image` peuvent appeler des services externes payants ; elles ne sont pas nécessaires à ce nettoyage.
