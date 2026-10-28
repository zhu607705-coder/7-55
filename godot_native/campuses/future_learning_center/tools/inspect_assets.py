"""Read-only PNG inspection; updates metadata only, never edits room artwork."""
from pathlib import Path
import argparse
import hashlib
import json
from PIL import Image

parser = argparse.ArgumentParser()
parser.add_argument('--check', action='store_true')
args = parser.parse_args()
root = Path(__file__).resolve().parents[1]
project = root.parents[1]
manifest = root / 'data/room_assets.json'
assets = json.loads(manifest.read_text(encoding='utf-8'))
errors = []
for name, entry in assets.items():
    file = project / entry['path'].removeprefix('res://')
    image = Image.open(file).convert('RGBA')
    alpha = image.getchannel('A')
    bounds = alpha.point(lambda value: 255 if value >= 127 else 0).getbbox()
    if bounds is None or alpha.getextrema()[0] != 0:
        raise ValueError(f'{name}: missing architectural cutout alpha')
    strips = []
    for y in range(bounds[1], bounds[3], 16):
        end = min(y + 16, bounds[3])
        box = alpha.crop((0, y, image.width, end)).point(lambda value: 255 if value >= 127 else 0).getbbox()
        if box:
            strips.append([y, end, box[0], box[2]])
    measured = dict(size=list(image.size), opaqueBounds=list(bounds),
                    sha256=hashlib.sha256(file.read_bytes()).hexdigest(), outerWallStrips=strips)
    for key, value in measured.items():
        if args.check and entry.get(key) != value:
            errors.append(f'{name}.{key}')
        elif not args.check:
            entry[key] = value
if errors:
    raise SystemExit('Stale asset metadata: ' + ', '.join(errors))
if not args.check:
    manifest.write_text(json.dumps(assets, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
print(f'{len(assets)} independent room masters: dimensions, alpha, SHA-256 and outer contours verified')
