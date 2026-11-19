"""Pack ImageGen character plates into the shared Godot walking art slots."""
import argparse
from collections import deque
from pathlib import Path
from PIL import Image


COLORS = [
    "202B35", "344452", "526B7A", "7993A1",
    "243F5A", "385B79", "547F9D", "F4CD77",
    "44332D", "70503B", "A1744E", "C79B62",
    "6F483E", "A76A4C", "D89C6A", "F0C895",
    "766E63", "A39B87", "C5C1A9", "E8E0C8",
    "9A514A", "C77964", "D8C7A0", "F4EAD5",
]
PALETTE = Image.new("P", (1, 1))
PALETTE.putpalette(list(bytes.fromhex("".join(COLORS))))
DIRECTIONS = ("side", "down", "up")
STRIDE = (1, 1, 2, 2, 3, 3, 0, 0)


def silhouette(image):
    """Remove disconnected alpha speckles and crop around the figure."""
    image = image.convert("RGBA")
    mask = image.getchannel("A").point(lambda value: 255 if value >= 150 else 0)
    extent = mask.getbbox()
    if not extent:
        raise ValueError("The source cell has no visible character")
    image = image.crop(extent)
    mask = mask.crop(extent)
    width, height = mask.size
    remaining = {(x, y) for y in range(height) for x in range(width) if mask.getpixel((x, y))}
    largest = []
    while remaining:
        todo = deque([remaining.pop()])
        component = []
        while todo:
            x, y = todo.popleft()
            component.append((x, y))
            for pixel in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if pixel in remaining:
                    remaining.remove(pixel)
                    todo.append(pixel)
        if len(component) > len(largest):
            largest = component
    clean = Image.new("L", mask.size)
    for pixel in largest:
        clean.putpixel(pixel, 255)
    image.putalpha(clean)
    return image.crop(clean.getbbox())


def pack(image, size, height, ground, max_width):
    image = silhouette(image)
    scale = min(height / image.height, max_width / image.width)
    fitted = image.resize((round(image.width * scale), round(image.height * scale)), Image.Resampling.NEAREST)
    rgb = fitted.convert("RGB").quantize(palette=PALETTE, dither=Image.Dither.NONE).convert("RGBA")
    rgb.putalpha(fitted.getchannel("A"))
    # Clear RGB outside the alpha matte for compact, repeatable PNGs.
    cell = Image.new("RGBA", size)
    cell.paste(rgb, ((size[0] - rgb.width) // 2, ground - rgb.height), rgb.getchannel("A"))
    return cell


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("sheet", type=Path)
    parser.add_argument("portrait", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--front-idle", type=Path)
    parser.add_argument("--seated", type=Path)
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    sheet = Image.open(args.sheet)
    atlas = Image.new("RGBA", (960, 480))
    for row, direction in enumerate(DIRECTIONS):
        poses = [
            sheet.crop((sheet.width * col // 4, sheet.height * row // 3,
                        sheet.width * (col + 1) // 4, sheet.height * (row + 1) // 3))
            for col in range(4)
        ]
        if direction == "down" and args.front_idle:
            poses[0] = Image.open(args.front_idle)
        cells = [pack(pose, (120, 160), 134, 159, 80) for pose in poses]
        for frame, index in enumerate(STRIDE):
            atlas.paste(cells[index], (frame * 120, row * 160))
        pack(poses[0], (96, 128), 106, 128, 64).save(args.output / f"player_{direction}_idle.png")
    atlas.save(args.output / "player_walk_full.png", optimize=True)
    pack(Image.open(args.portrait), (128, 144), 136, 144, 126).save(args.output / "portrait.png", optimize=True)
    if args.seated:
        pack(Image.open(args.seated), (96, 128), 88, 112, 60).save(args.output / "player_seated.png", optimize=True)


if __name__ == "__main__":
    main()
