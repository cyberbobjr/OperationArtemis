"""Check the mod's translations against EN (keys, placeholders, document layout, line widths).

    python source/translations/check_translations.py [LANG ...]

Rules (Build 42.21, see .claude/pz-knowledge/quest-building-blocks.md and api-42-21.md):
- same keys as EN, except CN/JP/KO which must NOT ship Print_Media/Print_Text (the printMedia
  SDF fonts have no CJK glyphs: those documents fall back to English);
- same %1..%9, %%, literal \\n in every value;
- Print_Media *_info: identical <...> layout tags in the same order; the text between tags may hold
  ',' and ':' (only tag parameters may not) but no more '<' or '>' than the EN value;
- every text line without autoWidth must fit its page: x + sum(xadvance) * scaleX <= parent width - 10,
  using the game's AngelCode metrics (media/fonts/<font>.fnt, base size 32).
Exit code 1 on any error.
"""
from pathlib import Path
import json
import re
import sys

ROOT = Path(__file__).resolve().parents[2]
TRANSLATE = ROOT / "Contents/mods/batman_OperationArtemis/42.21/media/lua/shared/Translate"
FONTS = Path("D:/SteamLibrary/steamapps/common/ProjectZomboid/media/fonts")
LANGS = ["DE", "ES", "PT", "PTBR", "RU", "TR", "CN", "JP", "KO"]
CJK = {"CN", "JP", "KO"}
PRINT_FILES = {"Print_Media.json", "Print_Text.json"}
PLACEHOLDER = re.compile(r"%\d|%%|\\n")
TAG = re.compile(r"<[^<>]*>")
_fonts = {}


def font_advances(name):
    if name not in _fonts:
        path = next((p for p in FONTS.glob("*.fnt") if p.stem.lower() == name.lower()), None)
        advances = {}
        if path:
            for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
                if line.startswith("char "):
                    fields = dict(re.findall(r"(\w+)=(-?\d+)", line))
                    advances[int(fields["id"])] = int(fields["xadvance"])
        _fonts[name] = advances
    return _fonts[name]


def params(tag):
    body = tag[1:-1]
    return {k.strip(): v.strip() for k, _, v in (p.partition(":") for p in body.split(","))}


def layout_errors(key, value):
    errors = []
    parts = TAG.split(value)
    tags = TAG.findall(value)
    width = None
    for index, tag in enumerate(tags):
        p = params(tag)
        if p.get("type") == "parent":
            width = float(p.get("width", 600))
        text = parts[index + 1]
        if not text:
            continue
        if p.get("type") != "text" or "autoWidth" in p or width is None:
            continue
        advances = font_advances(p.get("font", "SdfOldRegular"))
        scale = float(p.get("scaleX", 1))
        x = float(p.get("x", 0))
        for line in text.split("^"):
            size = x + sum(advances.get(ord(c), 16) for c in line) * scale
            if size > width - 10:
                errors.append(f"{key}: line too wide {size:.0f} > {width - 10:.0f} px « {line[:40]} »")
    return errors, tags


def check(lang):
    errors = []
    folder = TRANSLATE / lang
    if not folder.is_dir():
        return [f"{lang}: folder missing"]
    for en_file in sorted((TRANSLATE / "EN").glob("*.json")):
        target = folder / en_file.name
        if lang in CJK and en_file.name in PRINT_FILES:
            if target.exists():
                errors.append(f"{lang}/{en_file.name}: must not exist (no CJK glyphs in printMedia fonts)")
            continue
        if not target.exists():
            errors.append(f"{lang}/{en_file.name}: missing")
            continue
        raw = target.read_bytes()
        if raw.startswith(b"\xef\xbb\xbf"):
            errors.append(f"{lang}/{en_file.name}: BOM")
        try:
            data = json.loads(raw.decode("utf-8"))
        except ValueError as error:
            errors.append(f"{lang}/{en_file.name}: invalid JSON ({error})")
            continue
        en = json.loads(en_file.read_text(encoding="utf-8"))
        if list(data) != list(en):
            missing, extra = set(en) - set(data), set(data) - set(en)
            errors.append(f"{lang}/{en_file.name}: keys differ (missing {sorted(missing)[:5]}, extra {sorted(extra)[:5]}, "
                          f"order {'same' if not missing and not extra else 'n/a'})")
        for key, value in data.items():
            if key not in en:
                continue
            if not isinstance(value, str) or not value.strip():
                errors.append(f"{lang}/{en_file.name}:{key}: empty")
                continue
            if sorted(PLACEHOLDER.findall(value)) != sorted(PLACEHOLDER.findall(en[key])):
                errors.append(f"{lang}/{en_file.name}:{key}: placeholders {PLACEHOLDER.findall(value)} "
                              f"!= EN {PLACEHOLDER.findall(en[key])}")
            if en_file.name == "Print_Media.json" and key.endswith("_info"):
                layout, tags = layout_errors(key, value)
                errors += [f"{lang}/{e}" for e in layout]
                if tags != TAG.findall(en[key]):
                    errors.append(f"{lang}/{key}: layout tags differ from EN")
                for mark in "<>":
                    if TAG.sub("", value).count(mark) > TAG.sub("", en[key]).count(mark):
                        errors.append(f"{lang}/{key}: extra '{mark}' in document text")
    return errors


def main():
    for stream in (sys.stdout, sys.stderr):
        stream.reconfigure(encoding="utf-8")
    langs = [a.upper() for a in sys.argv[1:]] or LANGS
    total = 0
    for lang in langs:
        errors = check(lang)
        total += len(errors)
        print(f"{lang}: {'OK' if not errors else str(len(errors)) + ' error(s)'}")
        for error in errors:
            print("  - " + error)
    en_errors = []
    for key, value in json.loads((TRANSLATE / "EN/Print_Media.json").read_text(encoding="utf-8")).items():
        if key.endswith("_info"):
            en_errors += layout_errors(key, value)[0]
    if en_errors:
        print("EN reference warnings (already in the original):")
        for error in en_errors:
            print("  - " + error)
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
