"""Build local Steam copy and a review page. Never uploads files or invents image URLs."""
from pathlib import Path
import html
import json
import re

ROOT = Path(__file__).resolve().parent
PROJECT = ROOT.parents[1]
SLOTS = {"signal": "01_notebook", "investigation": "04_archives", "escape": "06_pursuit", "exfiltration": "09_extraction"}


def description(data, images):
    parts = ["[h1]Operation Artemis[/h1]", "[b]" + data["tagline"] + "[/b]", data["intro"]]
    for section, slot in (("signal", "signal"), ("investigate", "investigation"), ("escape", "escape")):
        parts.append("[h2]" + data[section] + "[/h2]")
        if images.get(slot):
            parts.append("[img]" + images[slot] + "[/img]")
        parts.append(data[section + "Text"])
    if images.get("exfiltration"):
        parts.append("[img]" + images["exfiltration"] + "[/img]")
    parts += ["[h2]" + data["features"] + "[/h2]", "[list]\n" + "\n".join("[*]" + v for v in data["list"]) + "\n[/list]"]
    for section in ("start", "status", "support"):
        parts += ["[h2]" + data[section] + "[/h2]", data[section + "Text"]]
    parts += ["[url=https://ko-fi.com/Z8Z8QJV31][img]https://storage.ko-fi.com/cdn/kofi6.png?v=6[/img][/url]",
              "[h2]" + data["credits"] + "[/h2]",
              "Ferry engine: Work With Sounds / Werstas, [url=https://creativecommons.org/licenses/by/4.0/]CC BY 4.0[/url], "
              "[url=https://commons.wikimedia.org/wiki/File:WWS_MSThtistart.ogg]Wikimedia Commons[/url]; edited (loop, mono, normalized)."]
    return "\n\n".join(parts) + "\n"


def preview(locales):
    d = locales["fr"]
    blocks = []
    for section, slot in (("signal", "signal"), ("investigate", "investigation"), ("escape", "escape")):
        path = ROOT / "captures" / (SLOTS[slot] + ".png")
        visual = '<img src="captures/' + path.name + '" alt="Capture réelle du jeu">' if path.exists() else '<div class="pending">CAPTURE EN JEU À TOURNER</div>'
        blocks.append('<section><h2>' + html.escape(d[section]) + '</h2>' + visual + '<p>' + html.escape(d[section + "Text"]) + '</p></section>')
    page = '''<!doctype html><html lang="fr"><meta charset="utf-8"><title>Operation Artemis — maquette Steam</title>
<style>body{margin:0;background:#0b1015;color:#e9e2d3;font:17px/1.65 system-ui}main{max-width:920px;margin:auto;padding:40px 24px}h1{font-size:48px;line-height:1.05}h2{font-size:25px;color:#b0df96;letter-spacing:.08em}section{margin:40px 0;padding-top:15px;border-top:1px solid #3a454a}img{max-width:100%;display:block;border-radius:5px}.hero{width:460px;margin:auto}.label{font-size:13px;color:#caaa6c}.pending{background:repeating-linear-gradient(135deg,#192228,#192228 18px,#1d2930 18px,#1d2930 36px);padding:75px 15px;text-align:center;color:#caaa6c;border:1px solid #46565a}li{margin:9px 0}</style><main>'''
    page += '<img class="hero" src="../art/20261004-cinematic/poster-source.png"><p class="label">Illustration promotionnelle générée · maquette locale, aucune publication Steam</p>'
    page += '<h1>Operation Artemis</h1><p><strong>' + html.escape(d["tagline"]) + '</strong></p><p>' + html.escape(d["intro"]) + '</p>' + ''.join(blocks)
    page += '<section><h2>' + html.escape(d["features"]) + '</h2><ul>' + ''.join('<li>' + html.escape(v) + '</li>' for v in d["list"]) + '</ul></section>'
    page += '<section><h2>' + html.escape(d["status"]) + '</h2><p>' + html.escape(d["statusText"]) + '</p></section></main></html>'
    (ROOT / "page-preview.html").write_text(page, encoding="utf-8")


def main():
    locales = json.loads((ROOT / "descriptions.json").read_text(encoding="utf-8"))
    images = json.loads((ROOT / "steam-images.json").read_text(encoding="utf-8"))
    for key, url in images.items():
        assert key in SLOTS and (not url or url.startswith("https://")), key
    drafts = ROOT / "illustrated-drafts"
    drafts.mkdir(exist_ok=True)
    for suffix, data in locales.items():
        filename = "README.steam" + ("." + suffix if suffix else "")
        text = description(data, images)
        # Reserve space for Workshop/Mod IDs added by the publication tool.
        assert len(text.encode("utf-8")) + 160 <= 8000, filename
        tags = []
        for closing, tag in re.findall(r"\[(/?)(h1|h2|b|url|img|list)(?:=[^\]]*)?\]", text):
            if closing:
                assert tags and tags.pop() == tag, filename
            else:
                tags.append(tag)
        assert not tags, filename
        (PROJECT / filename).write_text(text, encoding="utf-8")
        draft = description(data, {key: images.get(key) or "{{" + key + "}}" for key in SLOTS})
        (drafts / (filename + ".bbcode")).write_text(draft, encoding="utf-8")
    workshop = PROJECT / "workshop.txt"
    lines = [line for line in workshop.read_text(encoding="utf-8").splitlines() if not line.startswith("description=")]
    english = (PROJECT / "README.steam").read_text(encoding="utf-8")
    index = next(i for i, line in enumerate(lines) if line.startswith("title=")) + 1
    lines[index:index] = ["description=" + line for line in english.splitlines()]
    workshop.write_text("\n".join(lines) + "\n", encoding="utf-8")
    preview(locales)
    print(f"{len(locales)} Steam descriptions prepared; illustration slots filled: {sum(bool(v) for v in images.values())}/4. No upload.")


if __name__ == "__main__":
    import sys
    # Superseded on 2026-10-04: README.steam* are now written by hand with the cinematic banners
    # (source/art/20261004-steam-banners). Running this would overwrite them and workshop.txt.
    if "--force" not in sys.argv:
        sys.exit("prepare_page.py is superseded (README.steam* written by hand since 2026-10-04); "
                 "use --force only to regenerate the old layout from descriptions.json.")
    main()
