#!/usr/bin/env python3
"""Rasterize bundled OFL lettering into presentation-only ASCII sampling masks."""
import argparse, hashlib, json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
FONT = ROOT / 'ui_assets/fonts/MorningNote-Medium.ttf'
CONTENT = ROOT / 'data/native/prologue-interception.content.json'
ATMOSPHERE = ROOT / 'data/native/prologue-flow-atmosphere.json'
OUT = ROOT / 'data/native/prologue-ascii-masks.json'
GRID = 20
SYMBOLS = '.:,;+=*%#@|/'
ATLAS = ROOT / 'assets/native/prologue_terminal_20261022/ascii_glyph_atlas.png'
FINE_ATLAS = ROOT / 'assets/native/prologue_terminal_20261022/ascii_fine_glyph_atlas.png'

def build():
    content = json.loads(CONTENT.read_text())
    words = {w for s in content['stages'] for w in s['targets'] + s['distractors'] + s['fragments']} | {'话'}
    words.update(json.loads(ATMOSPHERE.read_text())['fragments'])
    font = ImageFont.truetype(str(FONT), GRID)
    masks = {}
    for char in sorted(c for c in set(''.join(words)) if '一' <= c <= '鿿'):
        canvas = Image.new('L', (GRID, GRID), 0)
        box = font.getbbox(char)
        x = (GRID - (box[2] - box[0])) // 2 - box[0]
        y = (GRID - (box[3] - box[1])) // 2 - box[1]
        ImageDraw.Draw(canvas).text((x, y), char, font=font, fill=255)
        masks[char] = [''.join('1' if canvas.getpixel((col, row)) >= 96 else '0' for col in range(GRID)) for row in range(GRID)]
        assert any('1' in row for row in masks[char]), char
    return {'schema': '755-prologue-ascii-masks-v1', 'grid': GRID, 'font': 'res://' + FONT.relative_to(ROOT).as_posix(), 'fontSha256': hashlib.sha256(FONT.read_bytes()).hexdigest(), 'sourceContentSha256': hashlib.sha256(CONTENT.read_bytes()).hexdigest(), 'ambientContentSha256': hashlib.sha256(ATMOSPHERE.read_bytes()).hexdigest(), 'rasterPixels': GRID, 'threshold': 96, 'masks': masks}

def main():
    parser = argparse.ArgumentParser(); parser.add_argument('--check', action='store_true'); args = parser.parse_args()
    result = build(); text = json.dumps(result, ensure_ascii=False, indent=2) + '\n'
    atlas = Image.new('RGBA', (6 * len(SYMBOLS), 8), (255,255,255,0))
    micro = ImageFont.truetype(str(FONT), 8)
    for index,char in enumerate(SYMBOLS):
        ink = Image.new('L', (6,8), 0); box = micro.getbbox(char)
        ImageDraw.Draw(ink).text(((6-(box[2]-box[0]))//2-box[0],(8-(box[3]-box[1]))//2-box[1]),char,font=micro,fill=255)
        for y in range(8):
            for x in range(6):
                if ink.getpixel((x,y))>=96:atlas.putpixel((index*6+x,y),(255,255,255,255))
    fine = Image.new('RGBA',(3*len(SYMBOLS),4),(255,255,255,0))
    for index in range(len(SYMBOLS)):
        for y in range(4):
            for x in range(3):
                if any(atlas.getpixel((index*6+x*2+dx,y*2+dy))[3]>0 for dy in range(2) for dx in range(2)):
                    fine.putpixel((index*3+x,y),(255,255,255,255))
    if args.check:
        assert OUT.read_text() == text, 'ASCII masks differ from their bundled font/source; regenerate.'
        assert ATLAS.exists() and Image.open(ATLAS).convert('RGBA').tobytes()==atlas.tobytes(), 'ASCII micro glyph atlas differs from its source font.'
        assert FINE_ATLAS.exists() and Image.open(FINE_ATLAS).convert('RGBA').tobytes()==fine.tobytes(), 'Fine glyphs lost source strokes.'
    else:
        OUT.write_text(text)
        ATLAS.parent.mkdir(parents=True,exist_ok=True);atlas.save(ATLAS);fine.save(FINE_ATLAS)
    print(f'ASCII Hanzi masks: {len(result["masks"])} characters, {GRID}x{GRID}, source hash verified')

if __name__ == '__main__': main()
