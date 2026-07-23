#!/usr/bin/env python3
"""Build the shared high-resolution four-phase RPG player walk cycle."""

from __future__ import annotations

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PLAYER_DIR = ROOT / "src/assets/rpg/player"
SOURCE_PATH = PLAYER_DIR / "source/student_walk_transparent.png"

FRAME_WIDTH = 96
FRAME_HEIGHT = 128
CONTENT_HEIGHT = 108
SIDE_LEG_SPLIT_Y = 94

# Tight alpha bounds measured from the approved source sheet.
POSE_BOUNDS = {
    "down": {
        "idle": (390, 66, 532, 371),
        "step": (715, 66, 859, 374),
    },
    "up": {
        "idle": (390, 468, 526, 760),
        "step": (717, 468, 853, 770),
    },
    "side": {
        "idle": (403, 851, 510, 1146),
        "step": (732, 851, 849, 1142),
    },
}


def render_pose(sheet: Image.Image, bounds: tuple[int, int, int, int], *, rise: int = 0) -> Image.Image:
    crop = sheet.crop(bounds)
    target_width = max(1, round(crop.width * CONTENT_HEIGHT / crop.height))
    resized = crop.resize((target_width, CONTENT_HEIGHT), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    frame.alpha_composite(
        resized,
        dest=((FRAME_WIDTH - target_width) // 2, FRAME_HEIGHT - CONTENT_HEIGHT - rise),
    )
    return frame


def alternate_step(frame: Image.Image, facing: str) -> Image.Image:
    if facing != "side":
        return frame.transpose(Image.Transpose.FLIP_LEFT_RIGHT)

    # Preserve the right-facing head and torso while exchanging the two legs.
    # This supplies a genuine second stride without changing horizontal facing.
    alternate = frame.copy()
    alternate.paste((0, 0, 0, 0), (0, SIDE_LEG_SPLIT_Y, FRAME_WIDTH, FRAME_HEIGHT))
    lower = frame.crop((0, SIDE_LEG_SPLIT_Y, FRAME_WIDTH, FRAME_HEIGHT)).transpose(
        Image.Transpose.FLIP_LEFT_RIGHT
    )
    alternate.alpha_composite(lower, dest=(0, SIDE_LEG_SPLIT_Y))
    return alternate


def main() -> None:
    sheet = Image.open(SOURCE_PATH).convert("RGBA")
    for facing, bounds in POSE_BOUNDS.items():
        idle = render_pose(sheet, bounds["idle"])
        step = render_pose(sheet, bounds["step"], rise=1)
        frames = (
            idle,
            step,
            render_pose(sheet, bounds["idle"], rise=2),
            alternate_step(step, facing),
        )
        for index, frame in enumerate(frames):
            output = PLAYER_DIR / f"player_{facing}_{index}.png"
            frame.save(output, format="PNG", optimize=True)
            print(f"built {output.relative_to(ROOT)} {FRAME_WIDTH}x{FRAME_HEIGHT}")


if __name__ == "__main__":
    main()
