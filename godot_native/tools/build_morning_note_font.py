#!/usr/bin/env python3
"""Build the project's editable Morning Note pixel family, without network access.

Original ASCII/key Hanzi live in a24px grid JSON. Remaining authored characters
are grid reconstructions of the existing, verified OFL font subsets; they are
explicitly derivatives. Nothing is read from personal/system font directories.
Requires fonttools[woff]==4.61.1 and Pillow==11.3.0. --check is read-only.
"""
import argparse
import hashlib
import io
import json
import unicodedata
from collections import defaultdict
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont
from fontTools.fontBuilder import FontBuilder
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "godot_native"
SOURCE = PROJECT / "art_source/fonts/morning_note_v1"
DEST = PROJECT / "ui_assets/fonts"
FAMILY = "755 Morning Note"
EM = 24
BASELINE = 20
UNIT = 64
VERSION = "0.1.1"
SOURCE_FONTS = {
    "regular": (DEST / "SelectedCoverage-Regular.otf", "b6ad88f4e3cefd19983153f1215f770fc3751028e4a98fb47107dde11741784a"),
    "bold": (DEST / "SelectedCoverage-Bold.otf", "411841a02166bbf0f8ccb6530cd0adf4aa8b110daeec8ae935ae3251e1689c71"),
    "symbols": (ROOT / "src/assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf", "a6122b69f7ba5d0951a259954fcac8bf8dcb03779bccfeabada457f945b3ae08"),
}


def sha(data):
    return hashlib.sha256(data).hexdigest()


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def authored_characters():
    characters = set(chr(cp) for cp in range(32, 127))
    # The coverage contract depends on actual characters, not code formatting or
    # whole-source hashes. New wording can require a rebuild; whitespace cannot.
    for directory in [ROOT / "src/data", PROJECT / "scripts", PROJECT / "data/native"]:
        for file in sorted(directory.rglob("*")):
            if file.is_file() and file.suffix in [".json", ".gd"]:
                text = file.read_text(encoding="utf-8")
                characters.update(c for c in text if c.isprintable() and not unicodedata.category(c).startswith("C"))
                if file.suffix == ".json":
                    decoded = json.dumps(json.loads(text), ensure_ascii=False)
                    characters.update(c for c in decoded if c.isprintable() and not unicodedata.category(c).startswith("C"))
    characters.update("晨札像素七点五十五求是校园签到成功图书馆启真湖梁祝剧场，。！？：；、（）《》“”‘’—…·↶↷←↑→↓")
    # C3.5's former wording used 舟. Retain this one derived glyph so existing
    # saved logs stay readable after the wording change; do not expand all CJK.
    characters.add("舟")
    return characters


def outline(rows):
    """Trace the binary grid boundary; every output segment stays orthogonal.

    Shared tile edges are removed and collinear vertices merged. This avoids
    hundreds of overlapping rectangles per Chinese glyph and keeps the boot
    payload substantially smaller than a per-pixel contour font.
    """
    height = len(rows)
    width = len(rows[0]) if height else 0
    edges = defaultdict(list)
    for y in range(height):
        for x in range(width):
            if rows[y][x] != "#":
                continue
            if y == 0 or rows[y - 1][x] != "#": edges[(x, y)].append((x + 1, y))
            if x == width - 1 or rows[y][x + 1] != "#": edges[(x + 1, y)].append((x + 1, y + 1))
            if y == height - 1 or rows[y + 1][x] != "#": edges[(x + 1, y + 1)].append((x, y + 1))
            if x == 0 or rows[y][x - 1] != "#": edges[(x, y + 1)].append((x, y))
    directions = {(1, 0): 0, (0, 1): 1, (-1, 0): 2, (0, -1): 3}
    priority = {1: 0, 0: 1, 3: 2, 2: 3}
    pen = TTGlyphPen(None)
    while edges:
        start = min(edges)
        current = start
        previous_direction = None
        points = []
        while True:
            points.append(current)
            options = edges[current]
            def turn(end):
                direction = directions[(end[0] - current[0], end[1] - current[1])]
                return priority[(direction - previous_direction) % 4] if previous_direction is not None else direction
            end = min(options, key=turn)
            options.remove(end)
            if not options: del edges[current]
            previous_direction = directions[(end[0] - current[0], end[1] - current[1])]
            current = end
            if current == start: break
        corners = [p for i, p in enumerate(points) if
                   (p[0] - points[i - 1][0], p[1] - points[i - 1][1]) !=
                   (points[(i + 1) % len(points)][0] - p[0], points[(i + 1) % len(points)][1] - p[1])]
        # Reverse so the y-up TrueType outer contour has its normal direction.
        corners.reverse()
        if len(corners) >= 4:
            pen.moveTo((corners[0][0] * UNIT, (BASELINE - corners[0][1]) * UNIT))
            for x, y in corners[1:]: pen.lineTo((x * UNIT, (BASELINE - y) * UNIT))
            pen.closePath()
    return pen.glyph()


def manual_grid(spec):
    rows = [["."] * EM for _ in range(EM)]
    x, y = spec["offset"]
    assert x >= 0 and y >= 0 and y + len(spec["rows"]) <= EM
    for dy, line in enumerate(spec["rows"]):
        assert x + len(line) <= EM and set(line) <= {".", "#"}
        for dx, pixel in enumerate(line): rows[y + dy][x + dx] = pixel
    return ["".join(line) for line in rows]


def raster_grid(character, raster, advance):
    image = Image.new("L", (EM, EM))
    box = raster.getbbox(character, anchor="ls")
    x = (advance - (box[2] - box[0])) // 2 - box[0]
    ImageDraw.Draw(image).text((x, BASELINE), character, font=raster, fill=255, anchor="ls")
    return image


def make_font(style, grids, advances, design):
    builder = FontBuilder(EM * UNIT, isTTF=True)
    cmap = {ord(c): f"u{ord(c):06X}" for c in sorted(grids, key=ord)}
    names = [".notdef"] + list(cmap.values())
    builder.setupGlyphOrder(names)
    builder.setupCharacterMap(cmap)
    missing = ["." * EM for _ in range(EM)]
    missing = [list(row) for row in missing]
    for y in range(3, 20):
        for x in range(3, 19):
            if x in [3, 18] or y in [3, 19]: missing[y][x] = "#"
    glyphs = {".notdef": outline(["".join(row) for row in missing])}
    metrics = {".notdef": (EM * UNIT, 0)}
    for character, name in zip(sorted(grids, key=ord), cmap.values()):
        glyph = outline(grids[character])
        glyphs[name] = glyph
        occupied_columns = [x for row in grids[character] for x, cell in enumerate(row) if cell == "#"]
        metrics[name] = (advances[character] * UNIT, min(occupied_columns, default=0) * UNIT)
    builder.setupGlyf(glyphs)
    builder.setupHorizontalMetrics(metrics)
    builder.setupHorizontalHeader(ascent=BASELINE * UNIT, descent=-(EM - BASELINE) * UNIT, lineGap=0)
    builder.setupNameTable({
        "familyName": FAMILY, "styleName": style, "uniqueFontIdentifier": f"755MorningNote-{style}-{VERSION}",
        "fullName": FAMILY + " " + style, "psName": "MorningNote-" + style,
        "version": "Version " + VERSION,
        "copyright": "Copyright2026 7:55 contributors. Contains modified OFL Noto CJK and Fusion Pixel glyphs; see accompanying OFL and provenance.",
        "manufacturer": "7:55 project", "designer": "7:55 project contributors",
        "description": "24-grid pixel family. Original ASCII/key Hanzi plus disclosed OFL-derived coverage. No system font dependency.",
        "licenseDescription": "This Font Software is licensed under the SIL Open Font License, Version1.1.",
        "licenseInfoURL": "https://openfontlicense.org/open-font-license-official-text/",
    })
    weight = 400 if style == "Regular" else 500
    builder.setupOS2(version=4, sTypoAscender=BASELINE * UNIT, sTypoDescender=-(EM - BASELINE) * UNIT,
                     sTypoLineGap=0, usWinAscent=BASELINE * UNIT, usWinDescent=(EM - BASELINE) * UNIT,
                     usWeightClass=weight, fsType=0, sxHeight=design["x_height"] * UNIT,
                     sCapHeight=design["cap_height"] * UNIT)
    builder.setupPost()
    builder.setupMaxp()
    builder.font["head"].created = 3875472000
    builder.font["head"].modified = 3875472000
    builder.font.recalcTimestamp = False
    builder.font["OS/2"].fsSelection |= 1 << 7  # use matching typo metrics
    stream = io.BytesIO()
    builder.font.save(stream)
    ttf = stream.getvalue()
    # Independent FreeType rasterization must recover the editable source grid
    # at native size; this catches contour winding, baseline and LSB mistakes.
    raster = ImageFont.truetype(io.BytesIO(ttf), EM)
    for character in grids:
        image = Image.new("L", (EM, EM))
        ImageDraw.Draw(image).text((0, BASELINE), character, font=raster, fill=255, anchor="ls")
        actual = ["".join("#" if image.getpixel((x, y)) >= 112 else "." for x in range(EM)) for y in range(EM)]
        if actual != grids[character]: raise SystemExit(f"Font/grid raster roundtrip mismatch: {style} {character!r}")
    web = TTFont(io.BytesIO(ttf), recalcTimestamp=False)
    web.flavor = "woff2"
    stream = io.BytesIO()
    web.save(stream)
    return ttf, stream.getvalue()


def build():
    source = json.loads((SOURCE / "original_glyphs.json").read_text(encoding="utf-8"))
    assert source["em"] == EM and source["baseline"] == BASELINE
    sources = {}
    for key, (file, digest) in SOURCE_FONTS.items():
        raw = file.read_bytes()
        if sha(raw) != digest: raise SystemExit("Unexpected font source hash: " + str(file))
        font = TTFont(io.BytesIO(raw), recalcTimestamp=False)
        sources[key] = {"raw": raw, "font": font, "cmap": font.getBestCmap(), "raster": ImageFont.truetype(io.BytesIO(raw), 22)}
    required = authored_characters() | set(source["glyphs"])
    grids = {"Regular": {}, "Medium": {}}
    advances = {}
    origins = {}
    unavailable = []
    for char in sorted(required, key=ord):
        if char in source["glyphs"]:
            rows = manual_grid(source["glyphs"][char])
            for style in grids: grids[style][char] = rows
            advances[char] = source["glyphs"][char]["advance"]
            origins[char] = "original-manual-grid"
            continue
        key = "regular" if ord(char) in sources["regular"]["cmap"] else "symbols"
        if ord(char) not in sources[key]["cmap"]:
            unavailable.append(char)
            continue
        font = sources[key]["font"]
        old_advance = font["hmtx"].metrics[sources[key]["cmap"][ord(char)]][0]
        advance = max(1, round(old_advance * EM / font["head"].unitsPerEm))
        if 0x2E80 <= ord(char) <= 0xA4CF or 0xFF01 <= ord(char) <= 0xFF60: advance = EM
        advance = min(EM, advance)
        regular = raster_grid(char, sources[key]["raster"], advance)
        bold = raster_grid(char, sources["bold"]["raster"], advance) if key == "regular" and ord(char) in sources["bold"]["cmap"] else regular
        medium = Image.blend(regular, bold, 0.55)
        for style, image in [("Regular", regular), ("Medium", medium)]:
            grids[style][char] = ["".join("#" if image.getpixel((x, y)) >= 112 else "." for x in range(EM)) for y in range(EM)]
        advances[char] = advance
        origins[char] = "OFL-Noto-CJK-grid-derivative" if key == "regular" else "OFL-Fusion-Pixel-grid-derivative"
    absent_hanzi = [char for char in unavailable if 0x3400 <= ord(char) <= 0x9FFF]
    if absent_hanzi: raise SystemExit("Authored Hanzi absent from all explicit font sources: " + "".join(absent_hanzi))
    outputs = {}
    font_records = []
    for style in grids:
        ttf, woff = make_font(style, grids[style], advances, source["design"])
        name = f"MorningNote-{style}"
        outputs[DEST / (name + ".ttf")] = ttf
        outputs[SOURCE / "web" / (name + ".woff2")] = woff
        font_records.append({"file": name + ".ttf", "family": FAMILY, "style": style,
                             "weight": 400 if style == "Regular" else 500,
                             "bytes": len(ttf), "sha256": sha(ttf), "woff2Bytes": len(woff), "woff2Sha256": sha(woff)})
    grid_record = {"schema": "755-morning-note-grid-v1", "em": EM, "baseline": BASELINE,
                   "advances": advances, "origins": origins, "regular": grids["Regular"], "medium": grids["Medium"]}
    outputs[SOURCE / "derived_grids.json"] = encoded(grid_record)
    charset = "".join(sorted(grids["Regular"], key=ord))
    outputs[SOURCE / "charset.txt"] = (charset + "\n").encode("utf-8")
    report = {"schema": "755-morning-note-family-v1", "family": FAMILY, "familyZh": "晨札像素", "version": VERSION,
              "emGrid": EM, "baseline": BASELINE, "unitsPerEm": EM * UNIT, "format": "TrueType orthogonal pixel contours",
              "latinMetrics": {key: source["design"][key] for key in ["cap_height", "x_height", "digit_advance"]},
              "files": font_records, "glyphCount": len(charset), "originalGridGlyphs": len(source["glyphs"]),
              "derivedGlyphs": len(charset) - len(source["glyphs"]), "charsetSha256": sha(charset.encode()),
              "requiredAuthoredHanziMissing": [], "unsupportedNonHanzi": [f"U+{ord(c):04X}" for c in unavailable],
              "originCounts": {key: sum(value == key for value in origins.values()) for key in sorted(set(origins.values()))},
              "originalSource": {"file": "art_source/fonts/morning_note_v1/original_glyphs.json", "sha256": sha((SOURCE / "original_glyphs.json").read_bytes())},
              "derivativeSources": [{"file": str(file.relative_to(ROOT)), "sha256": digest, "license": "SIL-OFL-1.1"} for file, digest in SOURCE_FONTS.values()],
              "derivativeRecipe": {"rasterPixels": 22, "threshold": 112, "mediumBoldBlend": 0.55, "systemFonts": False},
              "license": "SIL-OFL-1.1 for combined font binaries; Apache-2.0 original glyph source; upstream notices retained",
              "coverageBoundary": "Static authored game text plus original glyph source. Future wording requires coverage validation; unsupported user input uses the explicit bundled Fusion fallback, never an OS font.",
              "rendering": {"antialiasing": "none", "msdf": False, "subpixelPositioning": "disabled", "textureFilter": "nearest", "scaleAware": True},
              "builder": {"file": "tools/build_morning_note_font.py", "sha256": sha(Path(__file__).read_bytes()), "fonttools": "4.61.1", "pillow": "11.3.0"}}
    outputs[DEST / "morning_note_manifest.json"] = encoded(report)
    outputs[SOURCE / "family_manifest.json"] = encoded(report)
    return outputs, report


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()
    outputs, report = build()
    for file, data in outputs.items():
        if args.check:
            if not file.is_file() or file.read_bytes() != data: raise SystemExit("Stale font artifact: " + str(file))
        else:
            file.parent.mkdir(parents=True, exist_ok=True)
            file.write_bytes(data)
    print(json.dumps({"family": report["family"], "glyphs": report["glyphCount"], "original": report["originalGridGlyphs"],
                      "fonts": report["files"], "checkOnly": args.check}, ensure_ascii=False))


if __name__ == "__main__": main()
