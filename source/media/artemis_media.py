"""Médias de l'écran de victoire d'Opération Artemis (lot 9 de la phase 4).

Usage :
  python artemis_media.py voices                      liste les voix ElevenLabs (nom, id, étiquettes)
  python artemis_media.py tts <voice_id> <FR|EN>      voix de V : lit l'épilogue du document docs/epilogue-operation-artemis.md
  python artemis_media.py samples <FR|EN>             courts essais des voix candidates pour V
  python artemis_media.py image                       image 16:9 de l'écran de fin (Runware)
  python artemis_media.py mix <FR|EN>                 voix sur « The First Light », OGG Vorbis pour le jeu
  python artemis_media.py align <FR|EN>               repère les paragraphes dans la voix brute (transcription horodatée)
  python artemis_media.py variants <FR|EN> [id...]    voix des paragraphes propres aux fins (phase 5)
  python artemis_media.py assemble <FR|EN> [id...]    voix de chaque fin (paragraphes remplacés), bande, mixage

Les clés viennent de .claude/pz-knowledge/.env puis .claude/.env (RUNWARE_API_KEY, ELEVEN_LABS_KEY) : en mémoire,
jamais affichées ni écrites ailleurs. Sorties intermédiaires dans source/media/out, fichiers du jeu dans
le mod (media/sound, media/ui/Artemis).
"""
import difflib
import json
import pathlib
import re
import subprocess
import sys
import urllib.error
import urllib.request
import uuid

HERE = pathlib.Path(__file__).resolve().parent
PROJECT = HERE.parents[1]
WORKSHOP = PROJECT.parent
# Fichiers de clés (ignorés par git) : le second l'emporte s'il redéfinit une clé.
ENV_FILES = (WORKSHOP / ".claude" / "pz-knowledge" / ".env", WORKSHOP / ".claude" / ".env")
DOC = PROJECT / "docs" / "epilogue-operation-artemis.md"
MUSIC = PROJECT / "assets" / "The First Light.mp3"
MEDIA = PROJECT / "Contents" / "mods" / "batman_OperationArtemis" / "42.21" / "media"
OUT = HERE / "out"

# Voix : début après l'ouverture musicale seule, fin avant la fermeture seule.
VOICE_START_SECONDS = 8
VOICE_GAIN_DB = 2.0
MUSIC_UNDER_VOICE_DB = -9.0

IMAGE_PROMPT = (
    "Cinematic painted illustration, wide 16:9 landscape at sunrise. In the foreground, a thick plume of vivid bright "
    "emerald-green signal smoke rises from a military smoke grenade in a misty field behind a chain-link fence. "
    "A military helicopter, dark silhouette, flies away low over the wide Ohio river toward the rising sun. "
    "On the horizon, the skyline of Louisville fading in morning haze. Cold blue-teal shadows, warm golden light, "
    "sense of relief and melancholy, detailed matte painting, muted palette except the saturated green smoke, "
    "film grain. No text, no letters, no logo, no people."
)
IMAGE_NEGATIVE = "grey smoke, black smoke, text, letters, watermark, logo, signature, cartoon, anime, gore, blurry, deformed"


def keys():
    values = {}
    for path in ENV_FILES:
        if not path.exists():
            continue
        for line in path.read_text(encoding="utf-8").splitlines():
            if "=" in line and not line.strip().startswith("#"):
                name, _, value = line.partition("=")
                values[name.strip()] = value.strip().strip('"').strip("'")
    return values


def http(url, data=None, headers=None, method=None):
    body = None if data is None else (data if isinstance(data, bytes) else json.dumps(data).encode("utf-8"))
    request = urllib.request.Request(url, data=body, headers=headers or {}, method=method)
    try:
        with urllib.request.urlopen(request, timeout=300) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        body = error.read()
        # Runware renvoie parfois 504 alors que les images sont prêtes dans le corps de la réponse.
        if error.code == 504 and b'"imageURL"' in body:
            return body
        # Corps de la réponse seulement (jamais les en-têtes de la requête, qui portent la clé).
        error.read = lambda: body
        raise SystemExit(f"HTTP {error.code} sur {url.split('?')[0]} : {error.read()[:600].decode('utf-8', 'replace')}")


def epilogue(language):
    section = {"FR": "Français", "EN": "English"}[language]
    body = DOC.read_text(encoding="utf-8").split("## " + section, 1)[1].split("\n## ", 1)[0]
    paragraphs = [p.strip() for p in body.strip().split("\n\n") if p.strip()]
    return paragraphs


def cmd_voices():
    key = keys()["ELEVEN_LABS_KEY"]
    data = json.loads(http("https://api.elevenlabs.io/v1/voices", headers={"xi-api-key": key}))
    for voice in data.get("voices", []):
        labels = voice.get("labels") or {}
        print(f"{voice['voice_id']}  {voice['name']:<28} {voice.get('category', '')}  "
              + ", ".join(f"{k}={v}" for k, v in labels.items()))


def performance(language):
    """Texte annoté pour eleven_v3 (section « Jeu eleven_v3 » du document de l'épilogue)."""
    section = {"FR": "Jeu eleven_v3 — Français", "EN": "Jeu eleven_v3 — English"}[language]
    body = DOC.read_text(encoding="utf-8").split("## " + section, 1)[1].split("\n## ", 1)[0]
    return [p.strip() for p in body.strip().split("\n\n") if p.strip()]


def cmd_tts(voice_id, language):
    """Voix de V : texte annoté, eleven_v3 en mode créatif, puis effet de bande (voice_<langue>.mp3)."""
    text = "\n\n".join(performance(language))
    OUT.mkdir(parents=True, exist_ok=True)
    raw = OUT / f"voice_{language}_raw.mp3"
    raw.write_bytes(tts_raw(voice_id, text, "eleven_v3", {"stability": 0.0}))
    path = OUT / f"voice_{language}.wav"
    tape(raw, path)
    print("voix écrite :", path, f"{duration(path):.1f} s (brute : {duration(raw):.1f} s)")


# Voix prédéfinies d'ElevenLabs (identifiants publics), candidates pour V.
CANDIDATE_VOICES = {
    "Brian": "nPczCjzI2devNBz1zQrb",
    "Bill": "pqHfZKP75CvOlQylNhV4",
    "George": "JBFqnCBsd6RMkjVDRZzb",
}


def cmd_samples(language):
    key = keys()["ELEVEN_LABS_KEY"]
    text = " ".join(epilogue(language)[1:3])
    OUT.mkdir(parents=True, exist_ok=True)
    for name, voice_id in CANDIDATE_VOICES.items():
        payload = {"text": text, "model_id": "eleven_multilingual_v2",
                   "voice_settings": {"stability": 0.55, "similarity_boost": 0.75, "style": 0.25, "use_speaker_boost": True}}
        audio = http(f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128", payload,
                     {"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})
        path = OUT / f"sample_{language}_{name}.mp3"
        path.write_bytes(audio)
        print("essai :", path, f"{duration(path):.1f} s")


# Essais d'interprétation (voix retenue : George). Texte annoté pour eleven_v3 (indications de jeu).
EXPRESSIVE_SAMPLE_FR_V3 = (
    "[softly] Si tu entends ce message... [pause] c'est que tu es sorti. [exhales] Que le dossier est sorti. "
    "[tired] Pendant des semaines, j'ai regardé Knox mourir... derrière des écrans. [bitterly] Ils appelaient ça "
    "un périmètre. Artemis n'a jamais été une opération de sauvetage. Ils avaient besoin de plus de données. "
    "[voice breaking] Et les données... c'était nous."
)


def tts_raw(voice_id, text, model, settings):
    key = keys()["ELEVEN_LABS_KEY"]
    payload = {"text": text, "model_id": model, "voice_settings": settings}
    return http(f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format=mp3_44100_128", payload,
                {"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"})


def cmd_expressive():
    OUT.mkdir(parents=True, exist_ok=True)
    george = CANDIDATE_VOICES["George"]
    tries = {
        "v3": (EXPRESSIVE_SAMPLE_FR_V3, "eleven_v3", {"stability": 0.5}),
        "v2_expressif": (" ".join(epilogue("FR")[1:3]), "eleven_multilingual_v2",
                         {"stability": 0.3, "similarity_boost": 0.75, "style": 0.6, "use_speaker_boost": True}),
    }
    for label, (text, model, settings) in tries.items():
        path = OUT / f"sample_FR_George_{label}.mp3"
        path.write_bytes(tts_raw(george, text, model, settings))
        print("essai :", path, f"{duration(path):.1f} s")


# Interprétation « secret enregistré sur une vieille bande » (retour de l'utilisateur) : voix feutrée,
# confidentielle ; v3 en mode créatif (stabilité 0).
CONFIDENTIAL_SAMPLE_FR = (
    "[quietly] Si tu entends ce message... [pause] c'est que tu es sorti. [sighs] [whispers] Que le dossier est sorti. "
    "[hushed, tired] Pendant des semaines... j'ai regardé Knox mourir. Derrière des écrans. "
    "[bitterly, quietly] Ils appelaient ça... un périmètre. [pause] Artemis n'a jamais été une opération de sauvetage. "
    "[whispers] Ils avaient besoin de plus de données. [voice breaking] Et les données... [pause] c'était nous."
)

# Son de magnétophone : bande passante étroite, légère saturation, pleurage (wow) et scintillement
# (flutter), compression, puis souffle de bande ; clic de touche « lecture » au début.
TAPE_FILTER = (
    "[0:a]aresample=44100,highpass=f=280,lowpass=f=3600,"
    "acompressor=threshold=-22dB:ratio=4:attack=5:release=120,"
    "asoftclip=type=tanh:threshold=0.8,"
    "vibrato=f=0.7:d=0.03,vibrato=f=7.5:d=0.012,"
    "equalizer=f=1200:t=q:w=1.2:g=3,volume=1.4,adelay=450|450,apad=pad_dur=0.8[v];"
    "aevalsrc='0.9*sin(2*PI*180*t)*exp(-60*t)':d=0.12:s=44100,aformat=sample_fmts=fltp,adelay=150|150,apad[click];"
    "anoisesrc=color=pink:amplitude=0.018:sample_rate=44100,highpass=f=400,lowpass=f=6000[hiss];"
    # Un seul mélange : un concat du clic et de la voix suivi d'un amix saturait le signal (ffmpeg 8.1).
    "[v][click][hiss]amix=inputs=3:duration=first:normalize=0,loudnorm=I=-18:TP=-2[out]"
)


def tape(source, target):
    """Effet de bande. Intermédiaire en WAV flottant : avec ffmpeg 8.1, la conversion en 16 bits après loudnorm
    (192 kHz, double) sort un signal saturé ; en flottant, le signal est sain (vérifié le 2026-09-30)."""
    wav = target.with_suffix(".wav")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(source), "-filter_complex", TAPE_FILTER,
                    "-map", "[out]", "-ac", "1", "-ar", "44100", "-c:a", "pcm_f32le", str(wav)], check=True)
    if target.suffix == ".wav":
        return
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(wav), "-c:a", "libmp3lame", "-q:a", "3", str(target)],
                   check=True)


def cmd_confidential():
    OUT.mkdir(parents=True, exist_ok=True)
    raw = OUT / "sample_FR_George_confidentiel_brut.mp3"
    raw.write_bytes(tts_raw(CANDIDATE_VOICES["George"], CONFIDENTIAL_SAMPLE_FR, "eleven_v3", {"stability": 0.0}))
    target = OUT / "sample_FR_George_confidentiel_bande.mp3"
    tape(raw, target)
    print("essai :", raw, f"{duration(raw):.1f} s")
    print("essai :", target, f"{duration(target):.1f} s")


def cmd_image(count=3):
    for index in range(count):
        image_once(index + 1)


def image_once(number):
    key = keys()["RUNWARE_API_KEY"]
    task = [{
        "taskType": "imageInference",
        "taskUUID": str(uuid.uuid4()),
        "positivePrompt": IMAGE_PROMPT,
        "negativePrompt": IMAGE_NEGATIVE,
        "model": "runware:101@1",
        "width": 1344,
        "height": 768,
        "numberResults": 1,
        "outputFormat": "PNG",
        "steps": 28,
    }]
    data = json.loads(http("https://api.runware.ai/v1", task,
                           {"Authorization": "Bearer " + key, "Content-Type": "application/json"}))
    if data.get("errors"):
        print("erreur Runware :", data["errors"])
        return
    OUT.mkdir(parents=True, exist_ok=True)
    for result in data.get("data", []):
        path = OUT / f"victory_green_{number}.png"
        path.write_bytes(http(result["imageURL"]))
        print("image écrite :", path)


def duration(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True).stdout.strip()
    return float(out) if out else 0.0


def cmd_mix(language):
    mix(OUT / f"voice_{language}.wav", MEDIA / "sound" / f"ArtemisVictory{language}.ogg")


def mix(voice, target):
    target.parent.mkdir(parents=True, exist_ok=True)
    if not voice.exists():
        # Provisoire, tant que la voix n'est pas générée : la musique seule.
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(MUSIC), "-af", "loudnorm=I=-16:TP=-1.5",
                        "-c:a", "libvorbis", "-q:a", "5", "-ar", "44100", str(target)], check=True)
        print("musique seule (voix absente) :", target, f"{duration(target):.1f} s")
        return
    music_len = duration(MUSIC)
    voice_len = duration(voice)
    if VOICE_START_SECONDS + voice_len > music_len - 5:
        print(f"attention : voix trop longue ({voice_len:.1f} s) pour la musique ({music_len:.1f} s)")
    delay_ms = int(VOICE_START_SECONDS * 1000)
    # La musique baisse sous la voix (sidechaincompress), la voix est un peu remontée ; sortie normalisée.
    graph = (
        f"[1:a]aresample=48000,volume={VOICE_GAIN_DB}dB,adelay={delay_ms}|{delay_ms},apad[v];"
        f"[v]asplit=2[vmix][vkey];"
        f"[0:a]aresample=48000,volume=0dB[m];"
        f"[m][vkey]sidechaincompress=threshold=0.03:ratio=6:attack=40:release=600:makeup=1[mduck];"
        f"[mduck][vmix]amix=inputs=2:duration=first:normalize=0,loudnorm=I=-16:TP=-1.5,aresample=44100[out]"
    )
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(MUSIC), "-i", str(voice), "-filter_complex", graph,
                    "-map", "[out]", "-c:a", "libvorbis", "-q:a", "5", "-ar", "44100", str(target)], check=True)
    print("mixage écrit :", target, f"{duration(target):.1f} s")


# Fins de la phase 5 -------------------------------------------------------------------------------
# Chaque fin remplace quelques paragraphes de l'épilogue (Artemis_Endings). Pour garder intacte la voix
# validée, on découpe la voix brute d'origine aux silences entre paragraphes (repérés par une
# transcription horodatée), on y insère les paragraphes de la variante, générés avec la même voix et
# les mêmes réglages, puis on applique l'effet de bande et le mixage à l'ensemble.

GEORGE = "JBFqnCBsd6RMkjVDRZzb"
VARIANTS = ("A", "Aferry", "C", "Cnodossier")
TAG = re.compile(r"\[[^\]]*\]")
WORD = re.compile(r"[\wÀ-ÿ']+")


def words_of(text):
    return [w.lower().replace("’", "'") for w in WORD.findall(TAG.sub(" ", text))]


def variant_lines(language):
    """{ variante: { numéro: texte annoté } } (section « Jeu eleven_v3 — variantes »)."""
    section = {"FR": "Jeu eleven_v3 — variantes, Français", "EN": "Jeu eleven_v3 — variantes, English"}[language]
    body = DOC.read_text(encoding="utf-8").split("## " + section, 1)[1].split("\n## ", 1)[0]
    out = {}
    for match in re.finditer(r"^- (\w+)\.(\d+) : (.+)$", body, re.M):
        out.setdefault(match[1], {})[int(match[2])] = match[3].strip()
    return out


def multipart(fields, file_field, file_path):
    boundary = uuid.uuid4().hex
    parts = []
    for name, value in fields.items():
        parts.append(f"--{boundary}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{value}\r\n".encode())
    parts.append((f"--{boundary}\r\nContent-Disposition: form-data; name=\"{file_field}\"; "
                  f"filename=\"{file_path.name}\"\r\nContent-Type: audio/mpeg\r\n\r\n").encode())
    parts.append(file_path.read_bytes())
    parts.append(f"\r\n--{boundary}--\r\n".encode())
    return b"".join(parts), f"multipart/form-data; boundary={boundary}"


def cmd_align(language):
    """Bornes des paragraphes dans la voix brute : out/align_<langue>.json = [[début, fin], ...] (secondes)."""
    raw = OUT / f"voice_{language}_raw.mp3"
    cache = OUT / f"stt_{language}.json"
    if not cache.exists():
        body, content_type = multipart({"model_id": "scribe_v1", "timestamps_granularity": "word"}, "file", raw)
        data = http("https://api.elevenlabs.io/v1/speech-to-text", body,
                    {"xi-api-key": keys()["ELEVEN_LABS_KEY"], "Content-Type": content_type})
        cache.write_bytes(data)
    heard = [w for w in json.loads(cache.read_text(encoding="utf-8"))["words"] if w.get("type") == "word"]
    heard_words = [(words_of(w["text"]) or [""])[0] for w in heard]
    # Alignement de séquences entre le texte attendu et la transcription (qui se trompe sur quelques
    # mots) : chaque paragraphe va du premier au dernier de ses mots retrouvés.
    expected, owner = [], []
    for index, paragraph in enumerate(performance(language)):
        for word in words_of(paragraph):
            expected.append(word)
            owner.append(index)
    matcher = difflib.SequenceMatcher(None, expected, heard_words, autojunk=False)
    found = {}
    for block in matcher.get_matching_blocks():
        for k in range(block.size):
            index = owner[block.a + k]
            word = heard[block.b + k]
            span = found.setdefault(index, [word["start"], word["end"]])
            span[0] = min(span[0], word["start"])
            span[1] = max(span[1], word["end"])
    missing = [i + 1 for i in range(len(performance(language))) if i not in found]
    if missing:
        raise SystemExit(f"paragraphes introuvables dans la transcription : {missing}")
    spans = [found[i] for i in range(len(found))]
    (OUT / f"align_{language}.json").write_text(json.dumps(spans), encoding="utf-8")
    for index, (start, end) in enumerate(spans, 1):
        print(f"  § {index:2d} : {start:6.2f} - {end:6.2f} s")
    return spans


def cmd_variants(language, only=None):
    """Voix brute de chaque paragraphe de variante : out/var_<langue>_<variante>_<n>.mp3."""
    for variant, lines in variant_lines(language).items():
        if only and variant not in only:
            continue
        for number, text in sorted(lines.items()):
            path = OUT / f"var_{language}_{variant}_{number}.mp3"
            path.write_bytes(tts_raw(GEORGE, text, "eleven_v3", {"stability": 0.0}))
            print("paragraphe :", path.name, f"{duration(path):.1f} s")


def cut(source, start, end, target):
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(source), "-ss", f"{start:.3f}", "-to", f"{end:.3f}",
                    "-af", "aresample=44100,aformat=sample_fmts=flt:channel_layouts=mono", "-c:a", "pcm_f32le",
                    str(target)], check=True)


def silence(seconds, target):
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", "anullsrc=r=44100:cl=mono", "-t",
                    f"{seconds:.3f}", "-c:a", "pcm_f32le", str(target)], check=True)


def trimmed(source, target):
    """Paragraphe généré, silences de début et de fin retirés."""
    graph = ("aresample=44100,aformat=sample_fmts=flt:channel_layouts=mono,"
             "silenceremove=start_periods=1:start_threshold=-45dB,areverse,"
             "silenceremove=start_periods=1:start_threshold=-45dB,areverse")
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(source), "-af", graph, "-c:a", "pcm_f32le",
                    str(target)], check=True)


# Niveau moyen de la voix validée après l'effet de bande (volumedetect, 2026-09-30).
VOICE_MEAN_DB = -19.3


def mean_volume(path):
    out = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af", "volumedetect", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    return float(re.search(r"mean_volume: (-?[0-9.]+) dB", out)[1])


def nan_count(path):
    out = subprocess.run(["ffmpeg", "-hide_banner", "-i", str(path), "-af",
                          "astats=measure_overall=Number_of_NaNs:measure_perchannel=0", "-f", "null", "-"],
                         capture_output=True, text=True).stderr
    match = re.search(r"NaNs: ([0-9.]+)", out)
    return float(match[1]) if match else -1


CLICK = "aevalsrc='0.9*sin(2*PI*180*t)*exp(-60*t)':d=0.12:s=44100"


def tape_fixed_gain(source, target):
    """Effet de bande pour les voix montées des fins (entrée WAV mono en flottant).
    Avec ffmpeg 8.1, le graphe complet (clic généré dans le même graphe que la voix, puis loudnorm) a produit
    au hasard un fichier entièrement NaN ou saturé le 2026-10-01 : le clic de la touche « lecture » est donc
    écrit à part puis ajouté, le niveau est ramené à celui de la voix validée par un gain fixe mesuré, et
    chaque étape est vérifiée sans NaN (trois essais au plus)."""
    plain = TAPE_FILTER.replace(",loudnorm=I=-18:TP=-2[out]", "[out]")
    plain = plain.replace("[v][click][hiss]amix=inputs=3", "[v][hiss]amix=inputs=2")
    plain = re.sub(r"aevalsrc=.*?\[click\];", "", plain)
    assert "[click]" not in plain and "loudnorm" not in plain
    stage = target.with_name(target.stem + "_bande.wav")
    click = OUT / "click.wav"
    if not click.exists():
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "lavfi", "-i", CLICK, "-af", "adelay=150",
                        "-c:a", "pcm_f32le", str(click)], check=True)
    for _ in range(3):
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(source), "-filter_complex", plain,
                        "-map", "[out]", "-ac", "1", "-ar", "44100", "-c:a", "pcm_f32le", str(stage)], check=True)
        if nan_count(stage) != 0:
            continue
        gain = VOICE_MEAN_DB - mean_volume(stage)
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(stage), "-i", str(click), "-filter_complex",
                        f"[0:a]volume={gain:.2f}dB[v];[v][1:a]amix=inputs=2:duration=first:normalize=0,"
                        "alimiter=limit=0.79:level=false[out]", "-map", "[out]", "-c:a", "pcm_f32le", str(target)],
                       check=True)
        if nan_count(target) == 0:
            return
    raise SystemExit(f"effet de bande : NaN persistants pour {source.name}")


def cmd_assemble(language, only=None):
    """Voix de chaque fin : paragraphes d'origine, sauf ceux de la variante ; effet de bande ; mixage."""
    raw = OUT / f"voice_{language}_raw.mp3"
    spans = json.loads((OUT / f"align_{language}.json").read_text(encoding="utf-8"))
    total = duration(raw)
    # Bornes de coupe : au milieu du silence entre deux paragraphes.
    bounds = [0.0] + [(spans[i][1] + spans[i + 1][0]) / 2 for i in range(len(spans) - 1)] + [total]
    work = OUT / "assemble"
    work.mkdir(exist_ok=True)
    for variant, lines in variant_lines(language).items():
        if only and variant not in only:
            continue
        pieces = []
        for index in range(len(spans)):
            number = index + 1
            piece = work / f"{language}_{variant}_{number:02d}.wav"
            if number in lines:
                # Silences d'origine conservés autour du paragraphe remplacé.
                before = work / f"{language}_{variant}_{number:02d}_a.wav"
                after = work / f"{language}_{variant}_{number:02d}_c.wav"
                silence(spans[index][0] - bounds[index], before)
                trimmed(OUT / f"var_{language}_{variant}_{number}.mp3", piece)
                silence(bounds[index + 1] - spans[index][1], after)
                pieces += [before, piece, after]
            else:
                cut(raw, bounds[index], bounds[index + 1], piece)
                pieces.append(piece)
        listing = work / f"{language}_{variant}.txt"
        listing.write_text("".join(f"file '{p.as_posix()}'\n" for p in pieces), encoding="utf-8")
        joined = work / f"{language}_{variant}_raw.wav"
        subprocess.run(["ffmpeg", "-y", "-v", "error", "-f", "concat", "-safe", "0", "-i", str(listing),
                        "-c:a", "pcm_f32le", str(joined)], check=True)
        voice = OUT / f"voice_{language}_{variant}.wav"
        tape_fixed_gain(joined, voice)
        mix(voice, MEDIA / "sound" / f"ArtemisVictory{variant}{language}.ogg")


def main():
    args = sys.argv[1:]
    if not args:
        print(__doc__)
        return
    command = args[0]
    if command == "voices":
        cmd_voices()
    elif command == "tts":
        cmd_tts(args[1], args[2].upper())
    elif command == "confidential":
        cmd_confidential()
    elif command == "expressive":
        cmd_expressive()
    elif command == "samples":
        cmd_samples(args[1].upper())
    elif command == "image":
        cmd_image()
    elif command == "mix":
        cmd_mix(args[1].upper())
    elif command == "align":
        cmd_align(args[1].upper())
    elif command == "variants":
        cmd_variants(args[1].upper(), args[2:] or None)
    elif command == "assemble":
        cmd_assemble(args[1].upper(), args[2:] or None)
    else:
        print(__doc__)


if __name__ == "__main__":
    main()
