"""Montage du teaser v2 (TEASER.md) à partir d'une prise teaser.lua capturée par capture.py.

    python teaser_edit.py captures/takes/<token> [--language fr|en|both]

Extraits en temps réel (aucune accélération, aucune image inventée), titres sur bandeau,
son direct du jeu, carton final sur l'affiche. Sortie : <prise>/teaser-<langue>.mp4.
Les instants sont relatifs au repère ROLL de chaque plan (capture.json) et ont été choisis
sur la prise 1791136801146 ; les revérifier pour une autre prise.
"""
from pathlib import Path
import argparse
import json
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent
POSTER = ROOT.parent / "art/20261004-cinematic/poster-source.png"
FONT = Path("C:/Windows/Fonts/arialbd.ttf")
W, H, FPS = 1600, 900, 30

# (plan, début après ROLL, durée, titre fr, titre en)
CUTS = [
    ("01_carnet", 0.1, 4.6, "UN CARNET. UNE FRÉQUENCE.", "A NOTEBOOK. A FREQUENCY."),
    ("02_voix", 0.8, 5.4, "ÉCOUTEZ V.", "LISTEN TO V."),
    ("03_bunker", 3.9, 2.3, "ENQUÊTEZ", "INVESTIGATE"),
    ("04_clinique", 5.4, 2.3, "RÉCUPÉREZ LES PREUVES", "RECOVER THE EVIDENCE"),
    ("05_labo", 0.0, 5.1, "ÉCHAPPEZ AU LABORATOIRE", "ESCAPE THE LAB"),
    ("06_evasion", 0.3, 4.2, "SURVIVEZ À LA TRAQUE", "SURVIVE THE PURSUIT"),
    ("07_sterilisation", 4.0, 3.3, "ILS VONT TOUT EFFACER", "THEY WILL ERASE EVERYTHING"),
    ("08_extraction", 0.2, 5.0, "EXFILTRATION", "EXTRACTION"),
]
# Music (assets/teaser-music.mp3, Suno, 120 BPM): body = music 2.25-34.45 s, so its percussion
# entry (16.95 s) lands on the lab alarm and its breakdown (33.95 s) just before the closing card;
# closing card = the bass drop at 46.0 s, cut on the beat, faded out. Game sound stays under it.
MUSIC = ROOT.parent.parent / "assets/teaser-music.mp3"
MUSIC_BODY = (2.25, 34.45)
MUSIC_CLOSING = (46.0, 4.0)
GAME_UNDER_MUSIC = 0.45
CLOSING = {"fr": "Survivre n'était que le début.", "en": "Survival was only the beginning."}
FOOTER = "Project Zomboid · Build 42.21"
ENCODE = ["-r", str(FPS), "-c:v", "libx264", "-preset", "medium", "-crf", "18", "-pix_fmt", "yuv420p",
          "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2"]


def ffmpeg(*args):
    argv = [f"{a:.3f}" if isinstance(a, float) else str(a) for a in args]
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *argv], check=True)


def text_filter(work, name, text, size, y, box=True):
    path = work / (name + ".txt")
    path.write_text(text, encoding="utf-8")
    font = FONT.as_posix().replace(":", r"\:")
    file = path.as_posix().replace(":", r"\:")
    # The band runs to the bottom edge: it also hides the -debug overlay (coordinates, version).
    band = f"drawbox=x=0:y={y - 28}:w=iw:h=ih-{y - 28}:color=black@1.0:t=fill," if box else ""
    return (band + f"drawtext=fontfile='{font}':textfile='{file}':fontsize={size}:fontcolor=white:"
            f"x=(w-text_w)/2:y={y}")


def rolls(take):
    data = json.loads((take / "capture.json").read_text(encoding="utf-8"))
    marks = {}
    for marker in data["markers"]:
        if marker["event"] == "ROLL":
            marks[marker["shot"]] = marker["seconds"]
    return marks


def build(take, language, work, music=True):
    source = take / "session.mp4"
    assert source.exists(), "session.mp4 absent : la prise doit être terminée (FINISHED) par capture.py"
    marks = rolls(take)
    parts = []
    for index, (shot, start, length, fr, en) in enumerate(CUTS):
        assert shot in marks, "Plan absent de la prise : " + shot
        title = fr if language == "fr" else en
        caption = text_filter(work, f"t{index}", title, 46, H - 110)
        fade = (f",fade=t=in:st=0:d=0.12,fade=t=out:st={length - 0.15:.2f}:d=0.15")
        part = work / f"{index:02d}.mp4"
        ffmpeg("-ss", marks[shot] + start, "-t", length, "-i", source,
               "-vf", f"scale={W}:{H}," + caption + fade,
               "-af", f"afade=t=in:st=0:d=0.08,afade=t=out:st={length - 0.12:.2f}:d=0.12",
               *ENCODE, part)
        parts.append(part)
    # Closing card: the poster (with its title) over a blurred copy, slogan and footer.
    end = work / "closing.mp4"
    slogan = text_filter(work, "slogan", CLOSING[language], 44, H - 150)
    footer = text_filter(work, "footer", FOOTER, 26, H - 70, box=False)
    ffmpeg("-loop", "1", "-framerate", FPS, "-i", POSTER, "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
           "-t", 3.8, "-filter_complex",
           f"[0:v]split[a][b];[a]scale={W}:{W},boxblur=20:2,crop={W}:{H}[bg];"
           f"[b]scale=-1:{H - 160}[fg];[bg][fg]overlay=(W-w)/2:24,{slogan},{footer},"
           "fade=t=in:st=0:d=0.4,fade=t=out:st=3.3:d=0.5[v]",
           "-map", "[v]", "-map", "1:a", *ENCODE, end)
    parts.append(end)
    listing = work / "concat.txt"
    listing.write_text("".join(f"file '{p.as_posix()}'\n" for p in parts), encoding="utf-8")
    joined = work / "joined.mp4"
    ffmpeg("-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", joined)
    # Game sound peaks at 0 dBFS (siren, shot): loudness normalisation with a -1.5 dB true peak.
    output = take / f"teaser-{language}.mp4"
    if music:
        a, b = MUSIC_BODY
        c, d = MUSIC_CLOSING
        body = b - a
        graph = (f"[1:a]atrim={a}:{b},asetpts=PTS-STARTPTS,afade=t=in:d=0.4,afade=t=out:st={body - 0.03:.3f}:d=0.03[m1];"
                 f"[1:a]atrim={c}:{c + d},asetpts=PTS-STARTPTS,afade=t=in:d=0.03,afade=t=out:st={d - 1.4:.2f}:d=1.4[m2];"
                 "[m1][m2]concat=n=2:v=0:a=1[m];"
                 f"[0:a]volume={GAME_UNDER_MUSIC}[g];"
                 "[g][m]amix=inputs=2:normalize=0:duration=first,loudnorm=I=-16:TP=-1.5:LRA=11[a]")
        ffmpeg("-i", joined, "-i", MUSIC, "-filter_complex", graph, "-map", "0:v", "-map", "[a]",
               "-c:v", "copy", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", output)
    else:
        ffmpeg("-i", joined, "-c:v", "copy", "-af", "loudnorm=I=-16:TP=-1.5:LRA=11", "-c:a", "aac",
               "-b:a", "192k", "-ar", "48000", "-movflags", "+faststart", output)
    return output


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("take", type=Path)
    parser.add_argument("--language", choices=("fr", "en", "both"), default="both")
    parser.add_argument("--no-music", action="store_true", help="son direct du jeu seulement")
    args = parser.parse_args()
    assert args.no_music or MUSIC.exists(), f"Musique absente : {MUSIC}"
    take = args.take.resolve()
    for language in (("fr", "en") if args.language == "both" else (args.language,)):
        with tempfile.TemporaryDirectory() as tmp:
            output = build(take, language, Path(tmp), music=not args.no_music)
        probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                output], capture_output=True, text=True, check=True)
        print("TEASER", output, f"{float(probe.stdout):.1f} s")


if __name__ == "__main__":
    main()
