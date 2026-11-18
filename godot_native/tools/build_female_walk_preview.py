"""Normalize the red-jacket preview into the shared Godot walking contract."""
from pathlib import Path
import json
import hashlib
import argparse
import subprocess
import tempfile
from statistics import median

from PIL import Image, ImageDraw

PROJECT = Path(__file__).resolve().parents[1]
DEST = PROJECT / "art_source/player_locomotion_20261116/female_preview"
CELL = (120, 160)
FOOT_BASELINE = 157
DIRECTIONS = ("side", "down", "up")
SOURCE_FRAMES = 8
INTERPOLATED_FRAMES = 24
REFERENCE_HEIGHT = 132
# Use the project's ink, paper, skin and red ramps as one fixed family.
COLORS = (
    "202B35", "344452", "526B7A", "7993A1", "A9BCC2", "243F5A",
    "385B79", "D8C7A0", "F4EAD5", "44332D", "70503B", "A1744E",
    "766E63", "A39B87", "C5C1A9", "E8E0C8", "6F483E", "A76A4C",
    "D89C6A", "F0C895", "9A514A", "C77964",
)


def digest(file):
    return hashlib.sha256(file.read_bytes()).hexdigest()


def build_comparison(atlas, destination, cycle_ms):
    male = Image.open(PROJECT / "assets/native/player_locomotion/player_walk_and_idle.png").convert("RGBA")

    def strip(male_frame, female_frame):
        result = Image.new("RGB", (720, 200), (227, 219, 199))
        labels = ImageDraw.Draw(result)
        for row in range(3):
            for column, (sheet, frame, name) in enumerate(((male, male_frame, "male"), (atlas, female_frame, "female"))):
                pose = sheet.crop((frame * 120, row * 160, (frame + 1) * 120, (row + 1) * 160))
                x = row * 240 + column * 120
                result.paste(pose, (x, 24), pose)
                labels.text((x + 36, 5), name, fill=(32, 43, 53))
        return result

    strip(16, SOURCE_FRAMES).save(destination / "male_female_scale.png")
    frames = [strip(frame, frame // 2) for frame in range(16)]
    frames[0].save(destination / "male_female_walk.webp", save_all=True,
                   append_images=frames[1:], duration=cycle_ms // 16, loop=0,
                   lossless=True, method=6)


def cut_frames(source, head_height):
    for row in range(len(DIRECTIONS)):
        for frame in range(SOURCE_FRAMES):
            image = source.crop((
                frame * source.width // SOURCE_FRAMES,
                row * source.height // len(DIRECTIONS),
                (frame + 1) * source.width // SOURCE_FRAMES,
                (row + 1) * source.height // len(DIRECTIONS),
            ))
            alpha = image.getchannel("A").point(lambda x: 255 if x >= 128 else 0)
            box = alpha.getbbox()
            assert box and 210 <= box[3] - box[1] <= 260, (row, frame, box)
            assert 0 < box[0] < box[2] < image.width and 0 < box[1] < box[3] < image.height
            # The top of the head stays in place as the lead shoe advances.
            head = alpha.crop((0, box[1], image.width, box[1] + head_height)).getbbox()
            head_center = (head[0] + head[2]) / 2 - box[0]
            image.putalpha(alpha)
            yield row, frame, image.crop(box), head_center


def interpolate_row(keyframes, row, executable, model, palette):
    with tempfile.TemporaryDirectory(prefix="755-female-rife-") as scratch:
        scratch = Path(scratch)
        inputs, outputs = scratch / "input", scratch / "output"
        inputs.mkdir()
        outputs.mkdir()
        for frame in range(SOURCE_FRAMES + 1):
            key = keyframes.crop((
                (frame % SOURCE_FRAMES) * CELL[0], row * CELL[1],
                (frame % SOURCE_FRAMES + 1) * CELL[0], (row + 1) * CELL[1],
            ))
            # Put RGB and a matching matte through the same inference. Padding
            # keeps model boundaries away from both silhouettes.
            packed = Image.new("RGB", (256, 160))
            packed.paste(key.convert("RGB"), mask=key.getchannel("A"))
            packed.paste(key.getchannel("A").convert("RGB"), (136, 0))
            packed.resize((512, 320), Image.Resampling.NEAREST).save(
                inputs / f"{frame:02}.png"
            )
        command = [
            str(executable), "-i", str(inputs), "-o", str(outputs),
            "-n", str((SOURCE_FRAMES + 1) * 3), "-m", str(model),
            "-g", "0", "-j", "1:1:1", "-f", "%08d.png",
        ]
        result = subprocess.run(command, text=True, capture_output=True, timeout=180)
        if result.returncode:
            raise RuntimeError(result.stderr[-2000:])
        frames = []
        for index in range(INTERPOLATED_FRAMES):
            if index % 3 == 0:
                original = index // 3
                frames.append(keyframes.crop((
                    original * 120, row * 160, (original + 1) * 120, (row + 1) * 160,
                )))
                continue
            generated = Image.open(outputs / f"{index + 1:08}.png").convert("RGB")
            generated = generated.resize((256, 160), Image.Resampling.NEAREST)
            color = generated.crop((0, 0, 120, 160))
            alpha = generated.crop((136, 0, 256, 160)).convert("L")
            pixels = []
            for rgb, opacity in zip(color.get_flattened_data(), alpha.get_flattened_data()):
                if opacity < 128:
                    pixels.append((0, 0, 0, 0))
                else:
                    pixels.append(tuple(min(255, round(v * 255 / opacity)) for v in rgb) + (255,))
            rgba = Image.new("RGBA", CELL)
            rgba.putdata(pixels)
            frame = rgba.convert("RGB").quantize(
                palette=palette, dither=Image.Dither.NONE,
            ).convert("RGBA")
            frame.putalpha(rgba.getchannel("A"))
            frames.append(frame)
        return frames


def build(variant, executable=None, model=None):
    original = variant != "slim-24"
    aligned = variant == "aligned"
    source_file = DEST / {"original": "red_jacket_source.png", "aligned": "red_jacket_aligned_source.png", "slim-24": "red_jacket_slim_source.png"}[variant]
    destination = DEST if aligned else DEST / ("original_8" if original else "slim_24")
    cycle_ms = 800 if aligned else 600
    destination.mkdir(parents=True, exist_ok=True)
    frame_count = SOURCE_FRAMES if original else INTERPOLATED_FRAMES
    source = Image.open(source_file).convert("RGBA")
    palette = Image.new("P", (1, 1))
    rgb = b"".join(bytes.fromhex(c) for c in COLORS)
    palette.putpalette(rgb + bytes.fromhex(COLORS[0]) * (256 - len(COLORS)))
    keyframes = Image.new("RGBA", (CELL[0] * (SOURCE_FRAMES + 1), CELL[1] * len(DIRECTIONS)))
    frames = list(cut_frames(source, 56 if variant == "original" else 40))
    scale = REFERENCE_HEIGHT / (249 if variant == "original" else median(image.height for _, _, image, _ in frames))
    for row, frame, image, head_center in frames:
        image = image.resize(
            (round(image.width * scale), round(image.height * scale)),
            Image.Resampling.NEAREST,
        )
        flattened = image.convert("RGB").quantize(
            palette=palette, dither=Image.Dither.NONE,
        ).convert("RGBA")
        flattened.putalpha(image.getchannel("A"))
        x = (68 if row == 0 else 60) - round(head_center * scale)
        y = FOOT_BASELINE - image.height
        assert x > 0 and x + image.width < CELL[0] and y > 0, (row, frame)
        keyframes.paste(flattened, (frame * CELL[0] + x, row * CELL[1] + y))
    idle_frames = (0, 2, 2) if aligned else (1, 2, 2)
    for row, idle_frame in enumerate(idle_frames):
        idle = keyframes.crop((idle_frame * 120, row * 160, (idle_frame + 1) * 120, (row + 1) * 160))
        keyframes.paste(idle, (SOURCE_FRAMES * 120, row * 160))
    key_path = destination / "walk_keyframes.png"
    keyframes.save(key_path, optimize=True)
    atlas = Image.new("RGBA", (CELL[0] * (frame_count + 1), CELL[1] * len(DIRECTIONS)))
    for row, direction in enumerate(DIRECTIONS):
        if original:
            row_frames = [keyframes.crop((i * 120, row * 160, (i + 1) * 120, (row + 1) * 160)) for i in range(SOURCE_FRAMES)]
        else:
            row_frames = interpolate_row(keyframes, row, executable, model, palette)
        for index, frame in enumerate(row_frames):
            atlas.paste(frame, (index * CELL[0], row * CELL[1]))
        atlas.paste(
            keyframes.crop((SOURCE_FRAMES * 120, row * 160, (SOURCE_FRAMES + 1) * 120, (row + 1) * 160)),
            (frame_count * 120, row * 160),
        )
        print(f"{direction}: {frame_count} walking frames")
    output = destination / "walk_and_idle.png"
    atlas.save(output, optimize=True)
    record = {
        "status": "native-preview",
        "source": source_file.name if aligned else "../" + source_file.name,
        "variant": variant,
        "method": "Built-in ImageGen, original red-jacket design with male-player proportion reference" if aligned else "Built-in ImageGen, red-jacket original" if original else "Built-in ImageGen, slim redraw and RIFE interpolation",
        "reference": "godot_native/assets/native/library_animation_20261105/player_walk_full.png" if variant == "original" else "godot_native/assets/native/player_locomotion/player_walk_and_idle.png",
        "reference_pose_columns": [0, 2, 4, 6, 8, 10, 12, 14],
        "reference_character_height": REFERENCE_HEIGHT,
        "direction_rows": list(DIRECTIONS),
        "walking_frames_per_direction": frame_count,
        "idle_source_columns": list(idle_frames),
        "cycle_ms": cycle_ms,
        "frame_size": list(CELL),
        "visual_foot_baseline": FOOT_BASELINE,
        "keyframes_sha256": digest(key_path),
        "source_sha256": digest(source_file),
        "atlas_sha256": digest(output),
    }
    if not original:
        record["interpolation"] = {
            "tool": "rife-ncnn-vulkan 20221029",
            "release": "https://github.com/nihui/rife-ncnn-vulkan/releases/tag/20221029",
            "model": model.name,
            "executable_sha256": digest(executable),
            "model_sha256": {name: digest(model / name) for name in ("flownet.param", "flownet.bin")},
            "keyframes_per_direction": SOURCE_FRAMES,
            "preserved_indices": list(range(0, frame_count, 3)),
            "fractions": ["1/3", "2/3"],
            "loop_closure": "frame 7 to frame 0 interpolated",
            "alpha": "paired RGB and grayscale matte, threshold 128, project palette",
        }
    (destination / "registration.json").write_text(json.dumps(record, indent=2) + "\n")
    preview = []
    for frame in range(frame_count):
        strip = Image.new("RGB", (360, 160), (227, 219, 199))
        for row in range(3):
            pose = atlas.crop((frame * 120, row * 160, (frame + 1) * 120, (row + 1) * 160))
            strip.paste(pose, (row * 120, 0), pose)
        preview.append(strip)
    preview[0].save(destination / "walk_preview.webp", save_all=True,
                    append_images=preview[1:], duration=cycle_ms // frame_count, loop=0,
                    lossless=True, method=6)
    preview[0].save(destination / "walk_preview.gif", save_all=True,
                    append_images=preview[1:], duration=100 if aligned else [70, 80] * 4 if original else [20, 30] * 12, loop=0, disposal=2)
    if aligned:
        build_comparison(atlas, destination, cycle_ms)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--variant", choices=("original", "aligned", "slim-24"), default="aligned")
    parser.add_argument("--rife-bin", type=Path)
    parser.add_argument("--rife-model", type=Path)
    args = parser.parse_args()
    if args.variant == "slim-24" and (args.rife_bin is None or args.rife_model is None):
        parser.error("--variant slim-24 requires --rife-bin and --rife-model")
    build(args.variant, args.rife_bin.resolve() if args.rife_bin else None,
          args.rife_model.resolve() if args.rife_model else None)
