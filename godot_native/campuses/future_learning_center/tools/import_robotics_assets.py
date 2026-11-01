"""Preserve generated PNG bytes; calibrate independent regions without editing art."""
import hashlib
import json
from pathlib import Path
import shutil
import sys
from PIL import Image

root = Path(__file__).resolve().parents[1]
sources = [Path(value) for value in sys.argv[1:]]
if len(sources) != 2:
    raise SystemExit('Pass the final table PNG and the 8-part atlas PNG')
manifest_path = root / 'data/object_assets.json'
manifest = json.loads(manifest_path.read_text())
records = []
for source, filename in zip(sources, ['robotics_assembly_table.png', 'robotics_components_atlas.png']):
    original = Image.open(source)
    if original.mode != 'RGBA' or original.getchannel('A').getextrema() != (0, 255):
        raise ValueError('Expected original RGBA cutout with genuine transparency')
    destination = root / 'assets/objects' / filename
    if destination.exists() and destination.read_bytes() != source.read_bytes():
        raise ValueError('Use a versioned name instead of overwriting another master')
    shutil.copyfile(source, destination)
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    alpha = original.getchannel('A').point(lambda value: 255 if value >= 127 else 0)
    if filename.startswith('robotics_assembly'):
        regions = [('robotics_assembly_table', (0, 0, original.width, original.height))]
    else:
        if original.size != (1740, 904):
            raise ValueError('Atlas cuts are calibrated to the reviewed 1740 x 904 master')
        xs, ys = [0, 455, 920, 1310, 1740], [0, 490, 904]
        names = ['hardware', 'wheels', 'motors', 'wires', 'controller', 'chassis', 'tools', 'brackets']
        regions = [('robotics_' + name, (xs[index % 4], ys[index // 4], xs[index % 4 + 1], ys[index // 4 + 1])) for index, name in enumerate(names)]
    for key, region in regions:
        silhouette = alpha.crop(region).getbbox()
        if not silhouette:
            raise ValueError('Empty component: ' + key)
        bounds = [silhouette[0]+region[0], silhouette[1]+region[1], silhouette[2]+region[0], silhouette[3]+region[1]]
        if filename.endswith('atlas.png') and (bounds[0] <= region[0] or bounds[1] <= region[1] or bounds[2] >= region[2] or bounds[3] >= region[3]):
            raise ValueError('A component crosses its calibrated cell: ' + key)
        manifest[key] = dict(path='res://campuses/future_learning_center/assets/objects/'+filename,
            size=list(original.size), opaqueBounds=bounds, sha256=digest,
            production='Builtin imagegen original RGBA; source bytes unchanged; independent runtime crop; visual review required')
        print(key, bounds)
    records.append(dict(file=filename, sourceFile=source.name, sha256=digest, size=list(original.size), regions=[key for key, _ in regions]))
manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
(root/'data/robotics_asset_receipt_20261031.json').write_text(json.dumps(dict(tool='builtin image_gen',
    normalization='No bitmap edits. Original PNG bytes retained; alpha-bounds and atlas-region metadata only.',
    records=records), ensure_ascii=False, indent=2)+'\n')
