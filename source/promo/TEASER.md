# Teaser Opération Artemis — découpage v2 (tourné le 2026-10-04)

Remplace les neuf plans « carte postale » de `film.lua` : chaque plan doit contenir **une menace, une action rapide du joueur et une information** (document, voix ou objectif). Durée visée : 40 à 45 s au montage, coupes de plus en plus courtes. Images réelles du jeu ; chaque effet a une cause visible à l'écran.

Fil narratif : *un carnet → une voix → une preuve → la base se réveille → la zone va être effacée → il faut sortir.*

| # | Plan (durée montée) | Ce qu'on voit | Menace et cause | Action rapide du joueur | Interface visible |
|---|---|---|---|---|---|
| 1 | **Le carnet** — nuit, pluie (3 s) | Inventaire d'un soldat zombie au sol, le carnet taché de sang glisse dans l'inventaire du joueur, puis la page : « Si ça tourne mal, écoute le 108.0. La nuit. D'abord les chiffres, ensuite la voix. — V. » | Un râle hors champ ; une main de zombie entre dans le cadre (figurant qui rampe). | Fermer le carnet et se relever d'un bond. | **Inventaire + document** (fenêtre PrintMedia du mod) |
| 2 | **La voix** — relais KY-7, nuit (5 s) | Le joueur démarre le vrai groupe électrogène ; la radio s'allume, bulles jaunes de V : « Sept. Un. Quatre. Neuf... » puis « Ils ne nous évacueront pas. Ils ont besoin de plus de données. » | Le bruit du générateur attire une vague (cause réelle : bruit) ; des silhouettes apparaissent à la fenêtre. | Éteindre la lampe, s'accroupir sous la fenêtre. | Bulles radio |
| 3 | **Le bunker** — March Ridge -4, lampe torche (5 s) | Faisceau sur trois corps de soldats. Les ordres de mission dans le bureau. Flash du document : « 4 juillet » — deux jours avant les premiers malades. | Un des « morts » se relève dans le dos du joueur (cadavre réanimé). | Pivoter, reculer en courant, **claquer la porte** au nez du zombie. | Inventaire (transfert) + document |
| 4 | **La clinique** — West Point (3 s) | L'applique clignote. Le dossier du patient zéro. | Coups violents dans une porte fermée (l'infirmière enfermée), la porte tremble. | Arracher le dossier du classeur et sortir en courant. | Document (flash 1 s) |
| 5 | **Le laboratoire** — base, niveau -17 (6 s) | Lampes rouges, sujets assis immobiles. Carte : « Ils n'essayaient pas de soigner. Ils mesuraient. » Le joueur prend le dossier dans les archives… | **Le portique sonne** (cause : la puce du dossier) : sirène, lumières rouges qui battent, les sujets assis tournent la tête et se lèvent. | Sprint immédiat vers l'escalier. | Pensée : « Le portique ! Toute la base va rappliquer... » |
| 6 | **L'évasion** — couloirs et sortie de la base (6 s) | Garnison en treillis qui charge dans le couloir. | Sprinteurs militaires derrière le joueur. | **Un tir** au revolver sur le plus proche, **fermer une porte** en passant, sprint ; sortie dans le brouillard. | Pensée : « Du brouillard. Tant mieux : ils me verront moins. » |
| 7 | **La stérilisation** — campagne, crépuscule (4 s) | Le joueur ouvre le journal : compte à rebours rouge. Un grondement : « Ce n'est pas un orage. » | Tonnerre sans pluie, horde de sprinteurs à l'horizon (cause : l'armée efface la zone). | Recharger en marchant, regarder l'horizon, repartir en courant. | **Journal Artemis** (objectif en rouge) |
| 8 | **L'extraction** — Knox Boundary Camp, aube (6 s) | Fumée verte, rotor qui approche, ombre au sol, fusée verte. | Horde en treillis qui sort de la lisière, plus rapide que le joueur. | Sprint vers la fumée, geste « par ici », coupe au noir au moment où un zombie se jette sur lui. | Compte à rebours d'embarquement |
| — | **Carton final** (3 s) | « OPÉRATION ARTEMIS » — « Survivre n'était que le début. » | Voix de V : « Et toi, tu as écouté. » | — | Montage |

## Ce qui existe déjà (vérifié dans les sources)

- Documents du mod : Literature avec `printMedia` ; affichage sans effet sur l'histoire par `ISReadABook.displayPrintMedia` (vanilla `ISReadABook.lua:252-264`). Journal : `Artemis_JournalUI.toggle()`.
- Bulles de la bande : `radio:AddDeviceText(texte, 252, 237, 51, …)` ; textes `IG_UI.json` l.22, 76-82.
- Scènes du mod : `Artemis_StagingFX` / `Artemis_Staging` (`alarm_ch5_gate`, `escape_ch5_base` brouillard, `sterilization_strike`, `extraction_inbound`, `extraction_landed`).
- Vagues : `Artemis_Waves` (anneau hors de vue, sprinteurs) ; fumée `SignalSmoke.start` ; fusée `WorldFlares.launchFlare` ; tonnerre `triggerThunderEvent`.
- PZDirector : figurants poursuivants, tir réel, sprint, porte, gestes, lumière, sons.

## À développer avant le tournage

1. **Plans avec interface** : option par plan pour garder l'inventaire, la fenêtre du document et le journal visibles (aujourd'hui `hideUI` masque tout), et cacher seulement le HUD parasite.
2. **Cadavre qui se relève** (plan 3) et **sujets assis qui se lèvent** (plan 5) : figurant posé en cadavre puis réanimé à un repère.
3. **Coups dans une porte** (plan 4) : figurant derrière une porte fermée avec bruit de frappe réel.
4. **Courant réel au relais** (plan 2) : poser et démarrer un vrai groupe électrogène (cause du bruit et de la vague). Corrige aussi l'échec « Alimenter reellement le relais ».
5. **Sirène et lumières rouges battantes** (plan 5) hors de l'état « alarme » du mod : la partie de tournage est à l'acte 4 et ne les déclenche plus d'elle-même.
6. Réglage du rythme : prises courtes, déclenchement des menaces pendant l'action plutôt qu'après.

État de la sauvegarde `PZPuppet_Artemis_Passeur` : acte 4 (fin atteinte par le passeur), chapitres 1, 2, 3 et 5 révélés.

## Réalisation (2026-10-04)

- Script de tournage : `teaser.lua` (installé sous `Zomboid/Lua/PZPuppet/scenarios/OperationArtemisTrailer/teaser.lua`). Montage : `teaser_edit.py`.
- Prise retenue : `captures/takes/1791136801146` (8 plans, rapport `passed`, aucune erreur Lua). Livrables : `captures/teaser/teaser-v2-fr.mp4` et `teaser-v2-en.mp4`, 36,2 s, 1600 × 900, 30 i/s, son direct normalisé (−16 LUFS, crête −1,5 dB). La v1 (34,7 s) est conservée à côté.
- Mise en scène : nuit réelle (2 h – 3 h ; à 23 h en juillet il fait encore clair), cadrage serré 0,6 pour les documents et le labo, 0,75 pour les poursuites, menaces placées dans le champ, brouillard d'évasion léger (0,15) coupé à la coupe, brume naturelle neutralisée sur les plans extérieurs suivants, clair de lune artificiel pour la stérilisation.
- L'acteur est immortel pendant la prise (mode dieu seulement : les zombies attaquent et agrippent à l'image) ; son inventaire est rangé dans un sac de son inventaire (aucun spoiler à l'écran) puis rendu.
- La sauvegarde de tournage est à l'acte 4 : alarme, stérilisation et extraction sont mises en scène avec les fonctions du mod (fumée Signal Smoke, brouillard Artemis, sirène, éclair), chacune avec sa cause à l'image.

### Musique (v3)

`assets/teaser-music.mp3` (Suno, fournie par l'utilisateur, 60 s, 120 BPM). Calage dans `teaser_edit.py` : corps = musique 2,25 – 34,45 s (entrée de la percussion à 14,7 s sur l'alarme du labo, coupure à 31,65 s), carton final = entrée des basses à 46,0 s, raccordée sur le temps puis fondue. Son du jeu à −7 dB dessous, mixage normalisé (−15,6 LUFS intégrés, crête −1,6 dB). Livrables : `captures/teaser/teaser-v3-fr.mp4` et `teaser-v3-en.mp4`. `--no-music` redonne la version au son direct (v2).

### Limites et pistes

- Les coups de l'infirmière (plan 4) et le mort qui se relève (plan 3) existent mais se lisent peu ; le plan 7 (forêt) reste le plus faible.
- Pas d'hélicoptère visible (le mod n'en a pas), fumée verte peu lisible de jour.
- Validation humaine à faire : rythme, lisibilité des titres, son. Rien n'est publié.

### Refaire le tournage et le montage

```powershell
cd C:\Users\cyber\Zomboid\Workshop\PZDirector\tools
python tournage.py --scenario OperationArtemisTrailer/teaser.lua
python tournage.py --scenario OperationArtemisTrailer/teaser.lua --shot 05_labo
cd C:\Users\cyber\Zomboid\Workshop\OperationArtemis\source\promo
python teaser_edit.py captures/takes/<prise> --language both
```

Les instants de `teaser_edit.py` (`CUTS`) sont relatifs au repère ROLL de chaque plan et ont été calés sur la prise retenue : les revérifier sur une nouvelle prise.
