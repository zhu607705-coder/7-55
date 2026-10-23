"""Deterministic native-grid/palette normalization; never creates new artwork."""
from pathlib import Path
import hashlib
import json
from PIL import Image

PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / 'art_source/ending_resume_20261022/terminal_original.png'
OUTPUT = PROJECT / 'assets/native/ending_resume/terminal_signal_20261022.png'
# Existing terminal ramp plus existing campus metal/paper/ink members.
PALETTE = ['070B10','0B1219','202B35','344452','526B7A','7993A1',
           '9AD9EF','DBEDF4','F4EAD5','D8C7A0','9A514A','44332D',
           '70503B','A9BCC2','294553','809BA9']
palette = Image.new('P', (1, 1))
rgb = [tuple(bytes.fromhex(c)) for c in PALETTE]
palette.putpalette([v for color in rgb for v in color] + [7,11,16] * (256-len(rgb)))
original = Image.open(SOURCE).convert('RGB')
assert original.width * 2 == original.height * 3, 'Keep the authored 3:2 composition'
# 2 native art pixels per authored UI pixel, no unequal aspect transform.
normalized = original.resize((756,504), Image.Resampling.NEAREST).quantize(
    palette=palette, dither=Image.Dither.NONE).convert('RGB')
assert set(normalized.getdata()) <= set(rgb)
OUTPUT.parent.mkdir(parents=True, exist_ok=True)
normalized.save(OUTPUT, optimize=True)
report = {
    'source': str(SOURCE.relative_to(PROJECT)),
    'asset': str(OUTPUT.relative_to(PROJECT)),
    'mode': 'built-in image_gen; deterministic nearest-grid and palette normalization',
    'sourceSha256': hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
    'assetSha256': hashlib.sha256(OUTPUT.read_bytes()).hexdigest(),
    'sourceSize': list(original.size), 'nativeSize': list(normalized.size),
    'authoredUiSize': [378,252], 'palette': PALETTE,
    'uniqueColors': len(set(normalized.getdata())),
    'prompt': 'docs/art/prompts/ending_resume_terminal_20261022.txt',
    'normalizer': 'tools/prepare_ending_resume_art.py',
    'runtimeRole': 'non-authoritative static illustration; no baked interface text',
    'pillowVersion': Image.__version__,
}
(PROJECT / 'docs/art/ENDING_RESUME_ART_20261022.json').write_text(
    json.dumps(report, ensure_ascii=False, indent=2)+'\n')
print(json.dumps(report, ensure_ascii=False))
