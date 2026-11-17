"""Register and color-match the approved player cels for the native game."""

import hashlib
import json
from functools import lru_cache
from pathlib import Path
from statistics import median

from PIL import Image, ImageFilter, __version__ as pillow_version


PROJECT = Path(__file__).resolve().parents[1]
SOURCE = PROJECT / 'art_source/player_locomotion_20261116'
OUTPUT = PROJECT / 'assets/native/player_locomotion/player_walk_and_idle.png'
DIRECTIONS = ('side', 'down', 'up')
STANDING_COLUMNS = {'down': 0, 'side': 1, 'up': 2}
SIDE_START = 5
CEL = (120, 160)
SIDE_FRAMES = 16
VERTICAL_FRAMES = 16
# Both vertical loops retain their approved preview's common registration.
VERTICAL_LAYOUTS = {
    'down': ((1254, 1254), (132 / 254, 132 / 254), (-22, 8)),
    'up': ((1536, 2048), (110 / 384, 147 / 512), (4, 19)),
}
HEIGHT = 132
SOLE = 157
# Offsets from the walking palette to the stationary reference. The coat,
# warm colors and neutral tones blend by color, with the same grade for
# every cel of a direction. No material masks or palette quantization.
COAT_RGB = (-14, -7, 0)
WARM_RGB = (.76, 11, 0)
NEUTRAL_TONES = (-11, -7)


def hash_file(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def split(image, columns, rows):
    for index in range(columns * rows):
        row, col = divmod(index, columns)
        yield image.crop((image.width * col // columns, image.height * row // rows,
                          image.width * (col + 1) // columns, image.height * (row + 1) // rows))


def measure(image):
    alpha = image.getchannel('A')
    solid = alpha.point(lambda value: 255 if value >= 128 else 0)
    left, top, right, bottom = solid.getbbox()
    height = bottom - top
    assert height > 0.65 * image.height, (image.size, solid.getbbox())
    head = solid.crop((0, top, image.width, top + round(height * .30))).getbbox()
    center = (head[0] + head[2]) / 2
    waist = solid.crop((0, top + round(.52 * height), image.width, top + round(.57 * height))).getbbox()
    waist_x = (waist[0] + waist[2]) / 2
    crop = (max(0, left - 3), max(0, top - 3), min(image.width, right + 3), min(image.height, bottom + 3))
    return {'crop': crop, 'pose': image.crop(crop), 'center': center, 'waist_x': waist_x,
            'top': top, 'bottom': bottom, 'height': height}


def blend(start, end, value):
    fraction = max(0.0, min(1.0, (value - start) / (end - start)))
    return fraction * fraction * (3 - 2 * fraction)


@lru_cache(maxsize=65536)
def grade_pixel(r, g, b, lower_body):
    light = .2126 * r + .7152 * g + .0722 * b
    cool = blend(5, 15, g - r) * blend(4, 13, b - g) * (1 - blend(128, 190, light))
    warm = blend(9, 26, r - g) * blend(6, 18, g - b) * blend(78, 135, r)
    neutral = (1 - cool - warm) * blend(15, 39, light) * (1 - blend(92, 155, light))
    coat_r, coat_g, coat_b = COAT_RGB
    warm_r, warm_g, warm_b = WARM_RGB
    upper, lower = NEUTRAL_TONES
    shade = (upper + (lower - upper) * lower_body) * neutral
    return tuple(round(max(0, min(255, value))) for value in (
        r + shade + coat_r * cool + (255 - r) * warm_r * warm,
        g + shade + coat_g * cool + warm_g * warm,
        b + shade + coat_b * cool + warm_b * warm,
    ))


def grade_side_walk(tile):
    colors = []
    for index, (r, g, b, alpha) in enumerate(tile.get_flattened_data()):
        if alpha:
            lower_body = round(blend(96, 111, index // tile.width) * 8) / 8
            r, g, b = grade_pixel(r, g, b, lower_body)
        colors.append((r, g, b, alpha))
    tile.putdata(colors)


def grade_down_walk(tile):
    # Match the front standing pose by material while keeping the existing ink and alpha.
    colors = []
    for index, (r, g, b, alpha) in enumerate(tile.get_flattened_data()):
        if alpha <= 128:
            colors.append((r, g, b, alpha))
            continue
        y = index // tile.width
        light = .2126 * r + .7152 * g + .0722 * b
        strength = blend(128, 245, alpha) * blend(20, 38, light)
        skin = blend(10, 25, r - g) * blend(8, 21, g - b) * blend(95, 150, r)
        coat = blend(5, 14, g - r) * blend(4, 12, b - g) * (1 - blend(113, 151, light))
        neutral = (1 - skin) * (1 - coat)
        dark_neutral = neutral * (1 - blend(100, 143, light))
        hair = (1 - blend(48, 66, y)) * dark_neutral
        trousers = blend(102, 112, y) * dark_neutral * (1 + .4 * blend(61, 83, light))
        corrected = (
            r + round(strength * (-9 * hair - 4 * coat - 8 * trousers)),
            g + round(strength * (-9 * hair + 2 * coat - 6 * trousers)),
            b + round(strength * (-6 * hair + 8 * coat - trousers - 6 * skin)),
        )
        colors.append(tuple(max(0, min(255, channel)) for channel in corrected) + (alpha,))
    tile.putdata(colors)


def fit_side_head(tile):
    # Match the standing crown width and collar height with a continuous
    # sampling map. The map returns to the original cel before the hips.
    width, height = tile.size
    crown_center = 65
    crown_y, collar_y, waist_y = 26, 68, 103
    head_height_scale = .92
    collar_shift = (collar_y - crown_y) * (1 / head_height_scale - 1)

    def source_row(y):
        if y <= collar_y:
            sy = crown_y + (y - crown_y) / head_height_scale
        else:
            sy = y + collar_shift * (1 - blend(collar_y, waist_y, y))
        sx = .94 + .06 * blend(62, 93, y)
        return crown_center - crown_center / sx, sy, crown_center + (width - crown_center) / sx

    mesh = []
    top = source_row(0)
    for y in range(waist_y):
        bottom = source_row(y + 1)
        mesh.append(((0, y, width, y + 1), (
            top[0], top[1], bottom[0], bottom[1], bottom[2], bottom[1], top[2], top[1]
        )))
        top = bottom
    mesh.append(((0, waist_y, width, height), (0, waist_y, 0, height, width, height, width, waist_y)))
    return tile.transform(tile.size, Image.Transform.MESH, mesh, Image.Resampling.NEAREST)


def fit_pose(pose, scale, center, x_shift=0):
    local_x, local_y = pose['crop'][:2]
    x = round(CEL[0] / 2 - (center - local_x) * scale) + x_shift
    y = round(SOLE - (pose['bottom'] - local_y) * scale)
    original = pose['pose']
    scaled = original.resize(tuple(round(value * scale) for value in original.size), Image.Resampling.NEAREST)
    return scaled, x, y


def place_pose(image, x, y):
    assert 0 <= x <= CEL[0] - image.width and 0 <= y <= CEL[1] - image.height, (x, y, image.size)
    tile = Image.new('RGBA', CEL)
    tile.paste(image, (x, y))
    return tile


def pose_record(tile, source_crop, scale, x, y, source_cel):
    return {'source_crop': source_crop, 'offset': [x, y], 'scale': round(scale, 8),
            'visible_rect': tile.getbbox(), 'source_cel': source_cel}


def prepare_side(path):
    rows = [measure(image) for image in split(Image.open(path).convert('RGBA'), 4, 4)]
    rows = rows[SIDE_START:] + rows[:SIDE_START]
    scale = HEIGHT * .985 / median(move['height'] for move in rows)
    bias = median(move['center'] - move['waist_x'] for move in rows)
    prepared = [fit_pose(move, scale, move['center'] - bias, x_shift=-1) for move in rows]
    shift_y = min(0, CEL[1] - max(y + im.height for im, x, y in prepared))
    output = []
    records = []
    for i, (image, x, y) in enumerate(prepared):
        y += shift_y
        tile = place_pose(image, x, y)
        grade_side_walk(tile)
        tile = fit_side_head(tile)
        output.append(tile)
        records.append(pose_record(tile, rows[i]['crop'], scale, x, y,
                                   (SIDE_START + i) % SIDE_FRAMES + 1))
    return output, records


def clean_up_outline(tile):
    alpha = tile.getchannel('A')
    solid = alpha.point(lambda value: 255 if value >= 128 else 0)
    near_solid = solid.filter(ImageFilter.MaxFilter(3))
    interior = solid.filter(ImageFilter.MinFilter(5))
    colors = []
    for pixel, nearby, inside in zip(tile.get_flattened_data(), near_solid.get_flattened_data(),
                                     interior.get_flattened_data()):
        if not nearby:
            colors.append((0, 0, 0, 0))
        elif inside or not pixel[3]:
            colors.append(pixel)
        else:
            r, g, b, a = pixel
            # Lift near-black ink in the outer two pixels, leaving interior shading intact.
            light = .2126 * r + .7152 * g + .0722 * b
            strength = 1 - blend(4, 28, light)
            colors.append((r + round(17 * strength), g + round(21 * strength), b + round(27 * strength), a))
    tile.putdata(colors)


def prepare_vertical(direction, path):
    output, records = [], []
    sheet_size, (scale_x, scale_y), (x, y) = VERTICAL_LAYOUTS[direction]
    with Image.open(path) as source:
        assert source.size == sheet_size, (path.name, source.size)
        for index, cel in enumerate(split(source.convert('RGBA'), 4, 4), 1):
            size = (round(cel.width * scale_x), round(cel.height * scale_y))
            scaled = cel.resize(size, Image.Resampling.NEAREST)
            left, top, right, bottom = scaled.getchannel('A').point(lambda value: 255 if value >= 128 else 0).getbbox()
            assert 0 <= left + x < right + x <= CEL[0], (direction, index, left, right)
            assert 0 <= top + y < bottom + y <= CEL[1], (direction, index, top, bottom)
            tile = Image.new('RGBA', CEL)
            tile.paste(scaled, (x, y))
            if direction == 'up':
                clean_up_outline(tile)
            else:
                grade_down_walk(tile)
            output.append(tile)
            record = pose_record(tile, (0, 0, cel.width, cel.height), scaled.width / cel.width, x, y, index)
            record['scale_y'] = round(scaled.height / cel.height, 8)
            records.append(record)
    return output, records


def main():
    side_path = SOURCE / 'walk_side.png'
    standing_path = SOURCE / 'standing.png'
    vertical = {'down': SOURCE / 'walk_down_thin_rim_16.png', 'up': SOURCE / 'walk_up_approved_16.png'}
    standing = list(split(Image.open(standing_path).convert('RGBA'), 3, 1))
    atlas = Image.new('RGBA', (CEL[0] * (SIDE_FRAMES + 1), CEL[1] * len(DIRECTIONS)))
    receipt = {'source': {'side': hash_file(side_path), 'standing': hash_file(standing_path),
                          'vertical': {path.name: hash_file(path) for path in vertical.values()}},
               'pillow': pillow_version, 'cell': list(CEL), 'directions': list(DIRECTIONS),
               'walk_frames': dict(side=SIDE_FRAMES, down=VERTICAL_FRAMES, up=VERTICAL_FRAMES),
               'idle_column': SIDE_FRAMES,
               'idle_sole_y': SOLE, 'nominal_actor_height': HEIGHT,
               'walk_color_grade': {'coat_rgb': {'side': COAT_RGB}, 'warm_rgb': {'side': WARM_RGB},
                                    'neutral_tones': {'side': NEUTRAL_TONES},
                                    'down': 'front idle material match'}, 'frames': {}}
    for row, direction in enumerate(DIRECTIONS):
        if direction == 'side':
            frames, records = prepare_side(side_path)
        else:
            frames, records = prepare_vertical(direction, vertical[direction])
        idle = measure(standing[STANDING_COLUMNS[direction]])
        scale = HEIGHT / idle['height']
        image, x, y = fit_pose(idle, scale, idle['waist_x'] if direction == 'side' else idle['center'])
        tile = place_pose(image, x, y)
        assert len({frame.tobytes() for frame in frames + [tile]}) == len(frames) + 1
        atlas.paste(tile, (SIDE_FRAMES * CEL[0], row * CEL[1]))
        receipt['frames'][direction] = records + [pose_record(tile, idle['crop'], scale, x, y,
                                                              STANDING_COLUMNS[direction] + 1)]
        for col, frame in enumerate(frames):
            atlas.paste(frame, (col * CEL[0], row * CEL[1]))
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    atlas.save(OUTPUT)
    receipt['atlas_sha256'] = hash_file(OUTPUT)
    (SOURCE / 'registration.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
