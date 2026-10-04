"""Record genuine PZDirector takes from the game window, with output loopback audio.

The watcher never controls the game or opens a microphone input. Outputs stay in
captures/ (ignored by Git). Run --probe for a short technical capture, or --watch
before launching OperationArtemisTrailer/film.lua in the Lua console.
"""
from pathlib import Path
import argparse
import datetime as dt
import json
import re
import shutil
import subprocess
import sys
import threading
import time
import wave

ROOT = Path(__file__).resolve().parent
CONSOLE = Path.home() / "Zomboid/console.txt"
DEPS = Path.home() / ".codex/scratch/artemis-recording-deps"
sys.path.insert(0, str(DEPS))
import numpy as np
import soundcard as sc

MARK = re.compile(r"\[ArtemisFilm\] (PREP|ROLL|ACTION|CUT|ABORT|FINISHED|FAILED)\|(\d+)\|([a-z0-9_]+)")
CROP = "crop=w='trunc(min(iw,1600)/2)*2':h='trunc(min(ih,900)/2)*2':x='(iw-ow)/2':y='(ih-oh)/2'"
TITLES = {
    "fr": ["UNE FRÉQUENCE. UN SECRET.", "ENQUÊTEZ", "ÉCOUTEZ V.", "RÉCUPÉREZ LES PREUVES",
           "ÉCHAPPEZ AU LABORATOIRE", "SURVIVEZ À LA TRAQUE", "LE FLEUVE", "LE CHECKPOINT", "EXFILTRATION"],
    "en": ["ONE FREQUENCY. ONE SECRET.", "INVESTIGATE", "LISTEN TO V.", "RECOVER THE EVIDENCE",
           "ESCAPE THE LAB", "SURVIVE THE PURSUIT", "THE RIVER", "THE CHECKPOINT", "EXTRACTION"],
}


def run(*args):
    subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-n", *map(str, args)], check=True)


class Recording:
    def __init__(self, directory):
        directory.mkdir(parents=True, exist_ok=False)
        self.directory = directory
        self.markers = []
        self.errors = []
        self.stop_audio = threading.Event()
        self.ready = threading.Event()
        self.audio_started = None
        self.audio_peak = 0
        self.started = time.perf_counter()
        self.utc = dt.datetime.now(dt.timezone.utc).isoformat()
        self.speaker = sc.default_speaker()
        if "microphone" in self.speaker.name.lower():
            raise RuntimeError("Select a game output device, not a microphone monitor")
        self.audio = threading.Thread(target=self.record_audio, daemon=True)
        self.audio.start()
        if not self.ready.wait(5) or self.errors:
            self.stop_audio.set()
            raise RuntimeError("Audio loopback unavailable: " + str(self.errors))
        self.started = time.perf_counter()
        self.log = (directory / "ffmpeg.log").open("w", encoding="utf-8")
        command = ["ffmpeg", "-hide_banner", "-loglevel", "warning", "-n", "-f", "gdigrab",
                   "-draw_mouse", "0", "-framerate", "30", "-i", "title=Project Zomboid",
                   "-vf", CROP, "-an", "-c:v", "libx264", "-preset", "veryfast",
                   "-crf", "18", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                   str(directory / "raw-video.mp4")]
        try:
            self.video = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.DEVNULL,
                                          stderr=self.log, creationflags=subprocess.CREATE_NO_WINDOW)
        except Exception:
            self.stop_audio.set()
            self.audio.join(5)
            self.log.close()
            raise
        print("RECORDING", directory.name, "1600x900 maximum / centered crop /", self.speaker.name, flush=True)

    def record_audio(self):
        try:
            loopback = sc.get_microphone(id=self.speaker.id, include_loopback=True)
            if not loopback.isloopback:
                raise RuntimeError("Not a loopback endpoint")
            with wave.open(str(self.directory / "raw-audio.wav"), "wb") as output:
                output.setnchannels(2)
                output.setsampwidth(2)
                output.setframerate(48000)
                with loopback.recorder(samplerate=48000, channels=[0, 1], blocksize=2048) as recorder:
                    self.audio_started = time.perf_counter()
                    self.ready.set()
                    while not self.stop_audio.is_set():
                        block = recorder.record(numframes=2048)
                        samples = (np.clip(np.nan_to_num(block), -1, 1) * 32767).astype("<i2")
                        self.audio_peak = max(self.audio_peak, int(np.abs(samples.astype("i4")).max()))
                        output.writeframes(samples.tobytes())
        except Exception as error:
            self.errors.append("audio: " + repr(error))
            self.ready.set()

    def mark(self, event, token, shot):
        self.markers.append({"event": event, "token": token, "shot": shot,
                             "seconds": round(time.perf_counter() - self.started, 4)})
        print(event, shot, flush=True)

    def finish(self, outcome):
        self.stop_audio.set()
        if self.video.poll() is None:
            try:
                self.video.stdin.write(b"q\n")
                self.video.stdin.flush()
                self.video.wait(10)
            except (BrokenPipeError, subprocess.TimeoutExpired):
                self.video.kill()
                self.video.wait(5)
        if self.video.returncode:
            self.errors.append("ffmpeg exit: " + str(self.video.returncode))
        self.audio.join(5)
        if self.audio.is_alive():
            self.errors.append("audio did not stop")
        self.log.close()
        data = {"utc": self.utc, "outcome": outcome, "errors": self.errors,
                "source": "Project Zomboid window, genuine gameplay; PZDirector staging",
                "crop": CROP, "fps": 30, "audioOutput": self.speaker.name,
                "audioOffsetSeconds": (self.audio_started or self.started) - self.started,
                "audioPeak": self.audio_peak,
                "gameAudioVerified": self.audio_peak > 0 and outcome == "FINISHED",
                "markerPrecision": "wall-clock console polling, approximately 0.1 s; encoder startup may add skew",
                "markers": self.markers}
        (self.directory / "capture.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
        if self.errors:
            raise RuntimeError("Recording failed: " + str(self.errors))
        offset = data["audioOffsetSeconds"]
        audio_args = ["-ss", str(-offset)] if offset < 0 else ["-itsoffset", str(offset)]
        run("-i", self.directory / "raw-video.mp4", *audio_args, "-i", self.directory / "raw-audio.wav",
            "-map", "0:v:0", "-map", "1:a:0", "-c:v", "copy", "-c:a", "aac", "-b:a", "192k",
            "-shortest", "-movflags", "+faststart", self.directory / "session.mp4")
        return data


def export(recording, data):
    """Keep complete takes and extract genuine game frames. No synthesized scenery."""
    starts = {}
    clips = []
    frames = {}
    for m in data["markers"]:
        if m["event"] == "ACTION":
            starts[m["shot"]] = m["seconds"]
        elif m["event"] == "CUT" and m["shot"] in starts:
            begin = starts.pop(m["shot"]) + 0.4
            duration = m["seconds"] - begin - 0.3
            if duration < 2:
                continue
            target = recording.directory / (m["shot"] + ".mp4")
            run("-ss", begin, "-i", recording.directory / "session.mp4", "-t", duration,
                "-c:v", "libx264", "-preset", "veryfast", "-crf", "18", "-c:a", "aac",
                "-b:a", "192k", "-movflags", "+faststart", target)
            frame = recording.directory / (m["shot"] + ".png")
            run("-ss", min(3, duration / 2), "-i", target, "-frames:v", "1", "-update", "1", frame)
            clips.append({"shot": m["shot"], "start": begin, "duration": duration,
                          "video": target.name, "frame": frame.name})
            frames[m["shot"]] = frame
    data["clips"] = clips
    (recording.directory / "capture.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
    # Only a complete, successful film becomes the local page's source of screenshots.
    if data["outcome"] == "FINISHED" and len(clips) == 9:
        for shot in ("01_notebook", "04_archives", "06_pursuit", "09_extraction"):
            shutil.copyfile(frames[shot], ROOT / "captures" / (shot + ".png"))
        (ROOT / "captures/provenance.json").write_text(json.dumps(data, indent=2), encoding="utf-8")
        subprocess.run([sys.executable, str(ROOT / "prepare_page.py")], check=True)
    print("EXPORTED", len(clips), "genuine game takes:", recording.directory, flush=True)


def trailer(directory, language):
    """Cut an offline trailer from completed takes. No upload and no fabricated frames."""
    data = json.loads((directory / "capture.json").read_text(encoding="utf-8"))
    assert data["outcome"] == "FINISHED" and not data["errors"] and len(data["clips"]) == 9, \
        "Nine completed takes required; inspect footage before editing"
    edit = directory / ("edit-" + language)
    edit.mkdir(exist_ok=False)
    font = Path("C:/Windows/Fonts/arialbd.ttf")
    assert font.exists(), "Title font missing"
    # drawtext reads UTF-8 text files, avoiding filter-escaping localized prose.
    def title(text, index):
        path = edit / (str(index) + ".txt")
        path.write_text(text, encoding="utf-8")
        safe_font = font.as_posix().replace(":", r"\:")
        safe_text = path.resolve().as_posix().replace(":", r"\:")
        return ("drawbox=x=0:y=720:w=iw:h=180:color=black@0.55:t=fill,"
                f"drawtext=fontfile='{safe_font}':textfile='{safe_text}':fontsize=40:"
                "fontcolor=white:x=(w-text_w)/2:y=760")
    parts = []
    poster = ROOT.parent / "art/20261004-cinematic/poster-source.png"
    picture = "scale=1600:900:force_original_aspect_ratio=decrease,pad=1600:900:(ow-iw)/2:(oh-ih)/2"
    encoding = ["-r", "30", "-c:v", "libx264", "-preset", "veryfast", "-crf", "18",
                "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2"]
    intro = edit / "00.mp4"
    run("-loop", "1", "-framerate", "30", "-i", poster, "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
        "-t", "2.5", "-vf", picture + ",fade=t=in:st=0:d=0.4,fade=t=out:st=2:d=0.5", *encoding, intro)
    parts.append(intro)
    for index, clip in enumerate(data["clips"], 1):
        length = min(4.2, clip["duration"] - 0.5)
        target = edit / (f"{index:02d}.mp4")
        run("-ss", "0.3", "-i", directory / clip["video"], "-t", length,
            "-vf", picture + "," + title(TITLES[language][index - 1], index), *encoding, target)
        parts.append(target)
    end = edit / "10.mp4"
    closing = "CHOISISSEZ VOTRE ISSUE\nProject Zomboid · Build 42.21" if language == "fr" else \
        "CHOOSE YOUR WAY OUT\nProject Zomboid · Build 42.21"
    run("-loop", "1", "-framerate", "30", "-i", poster, "-f", "lavfi", "-i", "anullsrc=r=48000:cl=stereo",
        "-t", "3.5", "-vf", picture + "," + title(closing, 10) + ",fade=t=out:st=3:d=0.5", *encoding, end)
    parts.append(end)
    listing = edit / "concat.txt"
    listing.write_text("".join("file '" + path.name + "'\n" for path in parts), encoding="utf-8")
    output = directory / ("trailer-" + language + ".mp4")
    run("-f", "concat", "-safe", "0", "-i", listing, "-c", "copy", "-movflags", "+faststart", output)
    print("TRAILER DRAFT", output, "Review image, framing and sound before publication", flush=True)


def watch(minutes):
    offset = CONSOLE.stat().st_size if CONSOLE.exists() else 0
    identity = CONSOLE.stat().st_ino if CONSOLE.exists() else None
    partial = b""
    recording = None
    token = None
    deadline = time.monotonic() + minutes * 60
    print("READY: watching Lua markers; close console and unpause after runFile", flush=True)
    try:
        while time.monotonic() < deadline:
            if recording and (recording.video.poll() is not None or recording.errors):
                raise RuntimeError("Capture stopped unexpectedly; inspect ffmpeg.log and capture.json")
            if CONSOLE.exists():
                stat = CONSOLE.stat()
                if stat.st_ino != identity or stat.st_size < offset:
                    identity, offset, partial = stat.st_ino, 0, b""
                with CONSOLE.open("rb") as log:
                    log.seek(offset)
                    chunk = log.read(1024 * 1024)
                    offset = log.tell()
                partial += chunk
                lines = partial.split(b"\n")
                partial = lines.pop()
                for raw in lines:
                    line = raw.decode("utf-8", "replace")
                    match = MARK.search(line)
                    if not match:
                        if "ERROR: General" in line or "LuaManager$GlobalObject" in line:
                            print("LUA LOG:", line[:350], flush=True)
                        continue
                    event, current, shot = match.groups()
                    if event == "ROLL" and recording is None:
                        token = current
                        recording = Recording(ROOT / "captures/takes" / token)
                    if recording is None or current != token:
                        continue
                    recording.mark(event, current, shot)
                    if event in ("FINISHED", "FAILED"):
                        done, recording = recording, None
                        data = done.finish(event)
                        export(done, data)
                        token = None
                        print("READY for another take", flush=True)
            time.sleep(0.1)
    except KeyboardInterrupt:
        print("Watcher stopped", flush=True)
    finally:
        if recording:
            recording.finish("WATCHER_STOPPED")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    mode = parser.add_mutually_exclusive_group(required=True)
    mode.add_argument("--watch", action="store_true")
    mode.add_argument("--probe", action="store_true")
    mode.add_argument("--edit", type=Path, metavar="TAKE_DIRECTORY")
    parser.add_argument("--language", choices=("fr", "en"), default="fr")
    parser.add_argument("--minutes", type=float, default=120)
    args = parser.parse_args()
    if not 1 <= args.minutes <= 240:
        parser.error("minutes must be between 1 and 240")
    if not shutil.which("ffmpeg"):
        raise RuntimeError("FFmpeg required")
    if args.edit:
        trailer(args.edit.resolve(), args.language)
    elif args.probe:
        timestamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
        recording = Recording(ROOT / "captures" / ("probe-" + timestamp))
        time.sleep(2)
        recording.finish("TECHNICAL_PROBE_ONLY")
        print("Technical window/audio capture OK; this is not a trailer take", flush=True)
    else:
        watch(args.minutes)


if __name__ == "__main__":
    main()
