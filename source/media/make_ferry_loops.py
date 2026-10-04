"""Boucles du moteur du passeur (route A sans mod de bateau), tirées d'enregistrements Work With Sounds
(Wikimedia Commons, CC BY 4.0, crédit obligatoire : voir assets/ferry/CREDITS.md).

Méthode (sounds-and-noise.md) : extraire L + X secondes d'un passage régulier, fondre les X dernières
secondes sur les X premières (acrossfade), normaliser à -20 LUFS, sortir en Vorbis mono.
Usage : python make_ferry_loops.py  -> assets/ferry/candidat_*.ogg
"""
import pathlib
import subprocess

ASSETS = pathlib.Path(__file__).resolve().parents[2] / "assets" / "ferry"
CROSSFADE = 0.3
LOOP_SECONDS = 20

# (nom, fichier source, début en secondes) : passages réguliers repérés au profil de volume.
CANDIDATES = [
    ("A_tahti_1922", "WWS_MSThtistart.ogg", 40.0),
    ("B_seffle_bulbe", "WWS_Seffleboatengine.ogg", 200.0),
    ("C_tahti_court", "WWS_MSThti.ogg", 4.0),
]


def make_loop(name, source, start):
    out = ASSETS / f"candidat_{name}.ogg"
    length = LOOP_SECONDS + CROSSFADE
    graph = (
        f"[0:a]atrim=start={start}:duration={length},asetpts=PTS-STARTPTS,aformat=sample_fmts=fltp:channel_layouts=mono,"
        f"asplit=2[a][b];"
        f"[a]atrim=start={CROSSFADE},asetpts=PTS-STARTPTS[body];"
        f"[b]atrim=duration={CROSSFADE},asetpts=PTS-STARTPTS[head];"
        f"[body][head]acrossfade=d={CROSSFADE}:c1=tri:c2=tri,loudnorm=I=-20:TP=-2,aresample=44100[out]"
    )
    subprocess.run(["ffmpeg", "-y", "-v", "error", "-i", str(ASSETS / source), "-filter_complex", graph,
                    "-map", "[out]", "-c:a", "libvorbis", "-q:a", "5", str(out)], check=True)
    return out


if __name__ == "__main__":
    for name, source, start in CANDIDATES:
        print("écrit", make_loop(name, source, start))
