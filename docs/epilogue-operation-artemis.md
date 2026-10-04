# Opération Artemis — épilogue (écran de victoire)

Texte **validé par l'utilisateur le 2026-09-30** (déjà dans le jeu : clés `IGUI_Artemis_Epilogue_1` à `12`, `additions_4.py`).

État des médias (outil `OperationArtemis/source/media/artemis_media.py`) :
- **Image** : faite. Runware (FLUX), 1344 × 768 agrandie en 1920 × 1080, proposition n° 1 de la seconde série (fumée verte) choisie par l'utilisateur : `media/ui/Artemis/victory.png` (source : `assets/victory_source.png`).
- **Voix de V** : faite le 2026-09-30. George (`JBFqnCBsd6RMkjVDRZzb`), `eleven_v3` en mode créatif, texte annoté (section « Interprétation de la voix »), puis effet « vieille bande ». Durées : FR 104 s, EN 106 s. Clé ElevenLabs lue dans `.claude/.env` (la clé n'a pas la permission `voices_read` : voix prédéfinies par identifiant).
- **Son** : fait. `media/sound/ArtemisVictoryFR.ogg` et `EN.ogg` (218,8 s ; voix à partir de 8 s depuis le 2026-10-01 (16 s jugé trop long par l'utilisateur), musique abaissée sous la voix, normalisé à −16 LUFS ; moyenne −14,1 dB, crête −1 dB), script `scripts/Artemis_sounds.txt`.
- **Variantes de la phase 5** : faites le 2026-10-01. Paragraphes annotés (« Jeu eleven_v3 — variantes ») générés avec George, `eleven_v3` créatif, vérifiés par transcription (Vosk, `source/media/stt_vosk.py`) ; insérés dans la voix brute validée aux bornes des paragraphes (alignement par transcription horodatée, `artemis_media.py align`), puis effet de bande à gain fixe et mixage (`assemble`) : `media/sound/ArtemisVictory{A,Aferry,C,Cnodossier}{FR,EN}.ogg`, 218,8 s, moyenne -14 dB comme la bande validée. Image commune (celle de l'hélicoptère).

- Lu par **V** (homme, voix calme, fatiguée, émue sans emphase ; il parle au joueur, tutoiement).
- Mixé sur « The First Light » (3 min 39) : environ 2 min 30 de voix, avec des silences ; la musique ouvre seule (8 s) et ferme seule.
- À l'écran : le texte défile au rythme de la voix, puis la **chronique de la partie** (générée d'après l'état : jours, lieux, zombies tués depuis le carnet, fin obtenue).
- Une fois validé, le texte passe dans `.claude/tools/additions_4.py` (clés `IGUI_Artemis_Epilogue_*`).

## Français

Ici V.

Si tu entends ce message, c'est que tu es sorti. Que le dossier est sorti.

Pendant des semaines, j'ai regardé Knox mourir derrière des écrans. Ils appelaient ça un périmètre. Artemis n'a jamais été une opération de sauvetage : ils avaient besoin de plus de données. Et les données, c'était nous.

Le 4 juillet, ils savaient déjà. À West Point, ils attendaient devant la porte de la clinique. À March Ridge, ils ont prélevé, compté, classé. Et quand le relais s'est tu, ils ont fermé les portes et laissé la zone faire le reste.

Je n'ai pas pu sortir le dossier moi-même. Alors j'ai laissé des lampes allumées, une bande dans une machine, des chiffres sur une fréquence que personne n'écoutait.

Et toi, tu as écouté.

Tu as traversé le comté. Tu es descendu dix-sept étages sous Rosewood, tu as couru sous les sirènes, tu as tenu la zone jusqu'à l'aube. Ce que tu portes maintenant, ce sont des noms. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh. Tous ceux qu'on a comptés sans jamais les sauver.

Ce dossier va passer de main en main. Des journalistes. Des juges, peut-être. Ils ne pourront plus dire qu'ils ne savaient pas.

En bas, les lumières de Louisville s'éloignent. Le jour se lève sur l'Ohio.

Tu as survécu. Tu es sorti. Et grâce à toi, quelqu'un saura.

Merci.

Fin de transmission.

## English

This is V.

If you're hearing this, you made it out. The file made it out.

For weeks, I watched Knox die behind screens. They called it a perimeter. Artemis was never a rescue operation: they needed more data. And the data was us.

On July fourth, they already knew. In West Point, they were waiting outside the clinic door. At March Ridge, they took samples, counted, filed. And when the relay went silent, they shut the doors and let the zone do the rest.

I couldn't get the file out myself. So I left lights on, a tape in a machine, numbers on a frequency nobody listened to.

And you listened.

You crossed the county. You went seventeen floors down under Rosewood, you ran through the sirens, you held the zone until dawn. What you carry now are names. March Ridge, West Point, Riverside, Muldraugh. Everyone they counted and never saved.

That file will pass from hand to hand. Reporters. Judges, maybe. They'll never be able to say they didn't know.

Down there, the lights of Louisville are fading. The sun is rising over the Ohio.

You survived. You got out. And because of you, someone will know.

Thank you.

End of transmission.

## Interprétation de la voix (eleven_v3)

Voix **George** (voix prédéfinie ElevenLabs `JBFqnCBsd6RMkjVDRZzb`), modèle `eleven_v3` en mode créatif (stabilité 0), ton confidentiel validé par l'utilisateur le 2026-09-30 ; puis effet « vieille bande » (`TAPE_FILTER` de `source/media/artemis_media.py`). Les mots sont ceux du texte validé : seules les indications entre crochets et quelques points de suspension sont ajoutées.

## Jeu eleven_v3 — Français

[quietly] Ici V.

[pause] Si tu entends ce message... c'est que tu es sorti. [sighs] [whispers] Que le dossier est sorti.

[hushed, tired] Pendant des semaines, j'ai regardé Knox mourir... derrière des écrans. [bitterly] Ils appelaient ça un périmètre. Artemis n'a jamais été une opération de sauvetage : ils avaient besoin de plus de données. [voice breaking] Et les données... c'était nous.

[low, grave] Le 4 juillet, ils savaient déjà. À West Point, ils attendaient devant la porte de la clinique. À March Ridge, ils ont prélevé, compté, classé. [pause] Et quand le relais s'est tu... ils ont fermé les portes, et laissé la zone faire le reste.

[regretful] Je n'ai pas pu sortir le dossier moi-même. [softly] Alors j'ai laissé des lampes allumées... une bande dans une machine... des chiffres, sur une fréquence que personne n'écoutait.

[pause] [emotional, whispers] Et toi... tu as écouté.

[warmly, with growing emotion] Tu as traversé le comté. Tu es descendu dix-sept étages sous Rosewood, tu as couru sous les sirènes, tu as tenu la zone jusqu'à l'aube. [pause] Ce que tu portes maintenant, ce sont des noms. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh. [voice breaking] Tous ceux qu'on a comptés... sans jamais les sauver.

[firmly, quietly] Ce dossier va passer de main en main. Des journalistes. Des juges, peut-être. [pause] Ils ne pourront plus dire qu'ils ne savaient pas.

[softly, relieved] En bas, les lumières de Louisville s'éloignent. Le jour se lève sur l'Ohio.

[emotional] Tu as survécu. Tu es sorti. [pause] Et grâce à toi... quelqu'un saura.

[whispers, grateful] Merci.

[pause] [quietly] Fin de transmission.

## Jeu eleven_v3 — English

[quietly] This is V.

[pause] If you're hearing this... you made it out. [sighs] [whispers] The file made it out.

[hushed, tired] For weeks, I watched Knox die... behind screens. [bitterly] They called it a perimeter. Artemis was never a rescue operation: they needed more data. [voice breaking] And the data... was us.

[low, grave] On July fourth, they already knew. In West Point, they were waiting outside the clinic door. At March Ridge, they took samples, counted, filed. [pause] And when the relay went silent... they shut the doors, and let the zone do the rest.

[regretful] I couldn't get the file out myself. [softly] So I left lights on... a tape in a machine... numbers, on a frequency nobody listened to.

[pause] [emotional, whispers] And you... you listened.

[warmly, with growing emotion] You crossed the county. You went seventeen floors down under Rosewood, you ran through the sirens, you held the zone until dawn. [pause] What you carry now are names. March Ridge, West Point, Riverside, Muldraugh. [voice breaking] Everyone they counted... and never saved.

[firmly, quietly] That file will pass from hand to hand. Reporters. Judges, maybe. [pause] They'll never be able to say they didn't know.

[softly, relieved] Down there, the lights of Louisville are fading. The sun is rising over the Ohio.

[emotional] You survived. You got out. [pause] And because of you... someone will know.

[whispers, grateful] Thank you.

[pause] [quietly] End of transmission.

## Jeu eleven_v3 — variantes, Français

Paragraphes validés des variantes (section « Variantes de la phase 5 »), annotés comme la voix d'origine : seules les indications entre crochets et quelques points de suspension sont ajoutées. Format lu par `artemis_media.py variants` : `- <variante>.<paragraphe> : texte`.

- A.7 : [warmly, with growing emotion] Tu as traversé le comté. Tu es descendu dix-sept étages sous Rosewood, tu as couru sous les sirènes, tu as éteint leurs projecteurs et tu as passé le pont dans le noir. [pause] Ce que tu portes maintenant, ce sont des noms. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh. [voice breaking] Tous ceux qu'on a comptés... sans jamais les sauver.
- A.9 : [softly, relieved] Derrière toi, le pont s'efface dans la brume. Le fleuve t'emporte... et le jour se lève sur l'Ohio.
- Aferry.7 : [warmly, with growing emotion] Tu as traversé le comté. Tu es descendu dix-sept étages sous Rosewood, tu as couru sous les sirènes, tu as éteint leurs projecteurs et tu as attendu le passeur jusqu'à l'aube. [pause] Ce que tu portes maintenant, ce sont des noms. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh. [voice breaking] Tous ceux qu'on a comptés... sans jamais les sauver.
- Aferry.9 : [softly, relieved] Le moteur du passeur tousse dans la brume. Derrière vous, Knox n'est plus qu'une rive. Le jour se lève sur l'Ohio.
- C.7 : [warmly, with growing emotion] Tu as traversé le comté. Tu es descendu dix-sept étages sous Rosewood, tu as couru sous les sirènes, et tu as attendu derrière leur grillage... qu'ils acceptent de te croire. [pause] Ce que tu portes maintenant, ce sont des noms. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh. [voice breaking] Tous ceux qu'on a comptés... sans jamais les sauver.
- C.9 : [softly, relieved] Le pont est derrière toi. Au bout, l'Indiana. Le jour se lève sur l'Ohio.
- Cnodossier.2 : [pause] Si tu entends ce message... c'est que tu es sorti. [sighs] [whispers] Sans le dossier.
- Cnodossier.7 : [tired, warmly] Tu as traversé le comté. Tu as vu ce qu'il y avait à voir. Tu as attendu trois jours derrière leur grillage... et ils t'ont laissé passer.
- Cnodossier.8 : [quietly, regretful] Le dossier est resté là-bas, quelque part dans la zone. [pause] Et les noms avec lui. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh.
- Cnodossier.9 : [softly] Le pont est derrière toi. Le jour se lève sur l'Ohio.
- Cnodossier.10 : [emotional] Tu as survécu. C'est déjà beaucoup. [pause] [sadly] Mais personne ne saura.
- Cnodossier.11 : [whispers, tender] Prends soin de toi.

## Jeu eleven_v3 — variantes, English

- A.7 : [warmly, with growing emotion] You crossed the county. You went seventeen floors down under Rosewood, you ran through the sirens, you killed their floodlights and slipped past the bridge in the dark. [pause] What you carry now are names. March Ridge, West Point, Riverside, Muldraugh. [voice breaking] Everyone they counted... and never saved.
- A.9 : [softly, relieved] Behind you, the bridge fades into the mist. The river carries you away... and the sun is rising over the Ohio.
- Aferry.7 : [warmly, with growing emotion] You crossed the county. You went seventeen floors down under Rosewood, you ran through the sirens, you killed their floodlights and waited for the ferryman until dawn. [pause] What you carry now are names. March Ridge, West Point, Riverside, Muldraugh. [voice breaking] Everyone they counted... and never saved.
- Aferry.9 : [softly, relieved] The ferryman's engine coughs in the mist. Behind you, Knox is just a riverbank now. The sun is rising over the Ohio.
- C.7 : [warmly, with growing emotion] You crossed the county. You went seventeen floors down under Rosewood, you ran through the sirens, and you waited behind their fence... until they agreed to believe you. [pause] What you carry now are names. March Ridge, West Point, Riverside, Muldraugh. [voice breaking] Everyone they counted... and never saved.
- C.9 : [softly, relieved] The bridge is behind you. At the end of it, Indiana. The sun is rising over the Ohio.
- Cnodossier.2 : [pause] If you're hearing this... you made it out. [sighs] [whispers] Without the file.
- Cnodossier.7 : [tired, warmly] You crossed the county. You saw what there was to see. You waited three days behind their fence... and they let you through.
- Cnodossier.8 : [quietly, regretful] The file stayed back there, somewhere in the zone. [pause] And the names with it. March Ridge, West Point, Riverside, Muldraugh.
- Cnodossier.9 : [softly] The bridge is behind you. The sun is rising over the Ohio.
- Cnodossier.10 : [emotional] You survived. That's already a lot. [pause] [sadly] But no one will know.
- Cnodossier.11 : [whispers, tender] Take care of yourself.

## Image de l'écran (proposition, Runware)

Illustration peinte, format 16:9 (1920 × 1080) : à l'aube, un hélicoptère militaire en silhouette s'éloigne au-dessus de l'Ohio ; en contrebas, un camp militaire abandonné et un filet de fumée verte qui monte d'un champ ; la campagne du Kentucky, une lumière dorée et froide à la fois, un sentiment de soulagement. Pas de texte ni de logo dans l'image (le titre est dessiné par le jeu).

## Variantes de la phase 5 (validées par l'utilisateur le 2026-10-01)

Décision du 2026-10-01 : **tronc commun + variantes**. Chaque fin garde les paragraphes de l'hélicoptère et n'en remplace que quelques-uns (clés `IGUI_Artemis_Epilogue_<variante>_<n>`, `additions_5.py`, module `Artemis_Endings`). Même voix (George, `eleven_v3`, effet de bande), même musique : seuls les paragraphes remplacés sont à enregistrer, puis remontés dans la voix existante. Texte **validé par l'utilisateur le 2026-10-01**.

### Bateau (sorties ouest et nord-est) (`A`)

**FR**

- § 7 : Tu as traversé le comté. Tu es descendu dix-sept étages sous Rosewood, tu as couru sous les sirènes, tu as éteint leurs projecteurs et tu as passé le pont dans le noir. Ce que tu portes maintenant, ce sont des noms. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh. Tous ceux qu'on a comptés sans jamais les sauver.
- § 9 : Derrière toi, le pont s'efface dans la brume. Le fleuve t'emporte, et le jour se lève sur l'Ohio.

**EN**

- § 7 : You crossed the county. You went seventeen floors down under Rosewood, you ran through the sirens, you killed their floodlights and slipped past the bridge in the dark. What you carry now are names. March Ridge, West Point, Riverside, Muldraugh. Everyone they counted and never saved.
- § 9 : Behind you, the bridge fades into the mist. The river carries you away, and the sun is rising over the Ohio.

### Passeur de Brandenburg (`Aferry`)

**FR**

- § 7 : Tu as traversé le comté. Tu es descendu dix-sept étages sous Rosewood, tu as couru sous les sirènes, tu as éteint leurs projecteurs et tu as attendu le passeur jusqu'à l'aube. Ce que tu portes maintenant, ce sont des noms. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh. Tous ceux qu'on a comptés sans jamais les sauver.
- § 9 : Le moteur du passeur tousse dans la brume. Derrière vous, Knox n'est plus qu'une rive. Le jour se lève sur l'Ohio.

**EN**

- § 7 : You crossed the county. You went seventeen floors down under Rosewood, you ran through the sirens, you killed their floodlights and waited for the ferryman until dawn. What you carry now are names. March Ridge, West Point, Riverside, Muldraugh. Everyone they counted and never saved.
- § 9 : The ferryman's engine coughs in the mist. Behind you, Knox is just a riverbank now. The sun is rising over the Ohio.

### Checkpoint du pont Clark Memorial, avec le dossier (`C`)

**FR**

- § 7 : Tu as traversé le comté. Tu es descendu dix-sept étages sous Rosewood, tu as couru sous les sirènes, et tu as attendu derrière leur grillage qu'ils acceptent de te croire. Ce que tu portes maintenant, ce sont des noms. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh. Tous ceux qu'on a comptés sans jamais les sauver.
- § 9 : Le pont est derrière toi. Au bout, l'Indiana. Le jour se lève sur l'Ohio.

**EN**

- § 7 : You crossed the county. You went seventeen floors down under Rosewood, you ran through the sirens, and you waited behind their fence until they agreed to believe you. What you carry now are names. March Ridge, West Point, Riverside, Muldraugh. Everyone they counted and never saved.
- § 9 : The bridge is behind you. At the end of it, Indiana. The sun is rising over the Ohio.

### Checkpoint, sans le dossier (72 h) (`Cnodossier`)

**FR**

- § 2 : Si tu entends ce message, c'est que tu es sorti. Sans le dossier.
- § 7 : Tu as traversé le comté. Tu as vu ce qu'il y avait à voir. Tu as attendu trois jours derrière leur grillage, et ils t'ont laissé passer.
- § 8 : Le dossier est resté là-bas, quelque part dans la zone. Et les noms avec lui. Ceux de March Ridge, de West Point, de Riverside, de Muldraugh.
- § 9 : Le pont est derrière toi. Le jour se lève sur l'Ohio.
- § 10 : Tu as survécu. C'est déjà beaucoup. Mais personne ne saura.
- § 11 : Prends soin de toi.

**EN**

- § 2 : If you're hearing this, you made it out. Without the file.
- § 7 : You crossed the county. You saw what there was to see. You waited three days behind their fence, and they let you through.
- § 8 : The file stayed back there, somewhere in the zone. And the names with it. March Ridge, West Point, Riverside, Muldraugh.
- § 9 : The bridge is behind you. The sun is rising over the Ohio.
- § 10 : You survived. That's already a lot. But no one will know.
- § 11 : Take care of yourself.
