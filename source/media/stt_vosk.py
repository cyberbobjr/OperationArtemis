"""Transcription horodatée hors ligne (Vosk) de la voix brute de V, au format lu par `artemis_media.py align`
(out/stt_<langue>.json : {"words": [{"text", "start", "end", "type": "word"}]}). Remplace la transcription
d'ElevenLabs, que la clé du projet n'a pas le droit d'utiliser.

Usage (Python où `vosk` est installé, par exemple un environnement isolé) :
  python stt_vosk.py <FR|EN> <dossier du modèle Vosk>
Modèles : https://alphacephei.com/vosk/models (vosk-model-small-fr-0.22, vosk-model-small-en-us-0.15).
"""
import json
import pathlib
import subprocess
import sys

from vosk import KaldiRecognizer, Model, SetLogLevel

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE / "out"
RATE = 16000


def transcribe(language, model_dir):
    source = OUT / f"voice_{language}_raw.mp3"
    pcm = subprocess.run(["ffmpeg", "-v", "error", "-i", str(source), "-ac", "1", "-ar", str(RATE), "-f", "s16le", "-"],
                         capture_output=True, check=True).stdout
    SetLogLevel(-1)
    recognizer = KaldiRecognizer(Model(str(model_dir)), RATE)
    recognizer.SetWords(True)
    words = []
    chunk = 8000
    for offset in range(0, len(pcm), chunk):
        if recognizer.AcceptWaveform(pcm[offset:offset + chunk]):
            words += json.loads(recognizer.Result()).get("result", [])
    words += json.loads(recognizer.FinalResult()).get("result", [])
    data = {"words": [{"text": w["word"], "start": w["start"], "end": w["end"], "type": "word"} for w in words]}
    target = OUT / f"stt_{language}.json"
    target.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
    print("transcription :", target, len(words), "mots")


if __name__ == "__main__":
    transcribe(sys.argv[1].upper(), pathlib.Path(sys.argv[2]))
