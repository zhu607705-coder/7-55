"""Import original generated PNGs, preserving alpha and recording provenance."""
import hashlib
import json
from pathlib import Path
import shutil
import sys
from PIL import Image

root = Path(__file__).resolve().parent.parent
entries = json.loads(Path(sys.argv[1]).read_text())
manifest_path = root / 'data/object_assets.json'
receipt_path = root / 'data/generation_20261028.json'
manifest = json.loads(manifest_path.read_text())
receipts = json.loads(receipt_path.read_text())
for entry in entries:
    source = Path(entry['path'])
    original = Image.open(source)
    if original.mode != 'RGBA' or original.getextrema()[3][0] != 0:
        raise ValueError(f"{entry['id']}: a genuine alpha channel is required")
    bounds = original.getchannel('A').point(lambda value: 255 if value >= 127 else 0).getbbox()
    if not bounds:
        raise ValueError(f"{entry['id']}: empty silhouette")
    destination = root / 'assets/objects' / (entry['id'] + '.png')
    if destination.exists() and destination.read_bytes() != source.read_bytes():
        raise ValueError(f"{entry['id']}: choose a new versioned filename")
    shutil.copyfile(source, destination)
    digest = hashlib.sha256(destination.read_bytes()).hexdigest()
    manifest[entry['id']] = {
        'path': 'res://campuses/future_learning_center/assets/objects/' + destination.name,
        'size': list(original.size), 'opaqueBounds': list(bounds), 'sha256': digest,
        'production': 'builtin imagegen; independent transparent master; original bytes preserved; review draft',
    }
    if not any(row['sha256'] == digest for row in receipts):
        receipts.append({'id': entry['id'], 'sourceFile': source.name, 'prompt': entry['prompt'], 'sha256': digest})
    print(entry['id'], original.size, bounds, digest[:12])
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n')
receipt_path.write_text(json.dumps(receipts, ensure_ascii=False, indent=2) + '\n')
