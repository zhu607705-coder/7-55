#!/usr/bin/env python3
"""Build the shared high-resolution RPG player walk cycles."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
PLAYER_DIR = ROOT / "src/assets/rpg/player"
SOURCE_PATH = PLAYER_DIR / "source/player_walk_24pose_transparent_v2.png"
SIDE_WALK_SOURCE_PATH = (
    PLAYER_DIR / "source/player_side_walk_8frame_generated_v4.png"
)
SIDE_MODEL_SOURCE_PATH = (
    PLAYER_DIR / "source/player_side_model_9pose_generated_v4.png"
)
FRAME_WIDTH = 96
FRAME_HEIGHT = 128
CONTENT_HEIGHT = 108
CONTENT_WIDTH = 90
BOTTOM_PADDING = 2
ALPHA_THRESHOLD = 10
MIN_COMPONENT_AREA = 500
GRID_COLUMNS = 4
GRID_ROWS = 6
POSE_SPECS = {
    "down": tuple((index, False) for index in range(0, 8)),
    # The generated source contains seven back-facing poses and nine side poses.
    # Complete the back cycle deterministically with a mirrored back-facing step.
    "up": tuple((index, False) for index in range(8, 15)) + ((12, True),),
}

# Every side-view runtime frame comes from one complete generated character.
# The walk sheet provides contacts, recoils, and the two opposite passing
# poses. Two compact whole-body recovery poses come from the matching model
# sheet. Nothing below cuts or recombines the character at the waist.
SIDE_WALK_POSE_SPECS = (
    ("walk", 0),
    ("walk", 1),
    ("walk", 2),
    ("walk", 7),
    ("walk", 4),
    ("walk", 5),
    ("walk", 6),
    ("model", 7),
)
SIDE_IDLE_SOURCE_INDEX = 0
SIDE_TARGET_HEIGHT = 104
SIDE_HEAD_REGION_RATIO = 0.48


@dataclass(frozen=True)
class SourcePose:
    image: Image.Image
    bounds: tuple[int, int, int, int]


def extract_source_poses(
    sheet: Image.Image,
    columns: int = GRID_COLUMNS,
    rows: int = GRID_ROWS,
    min_component_area: int = MIN_COMPONENT_AREA,
) -> list[SourcePose]:
    width, height = sheet.size
    alpha_values = list(sheet.getchannel("A").get_flattened_data())
    visited = bytearray(width * height)
    components: list[tuple[list[int], tuple[int, int, int, int]]] = []

    for start, value in enumerate(alpha_values):
        if value < ALPHA_THRESHOLD or visited[start]:
            continue
        visited[start] = 1
        component: list[int] = []
        queue: deque[int] = deque([start])
        while queue:
            index = queue.pop()
            component.append(index)
            x = index % width
            y = index // width
            if x > 0:
                neighbor = index - 1
                if not visited[neighbor] and alpha_values[neighbor] >= ALPHA_THRESHOLD:
                    visited[neighbor] = 1
                    queue.append(neighbor)
            if x + 1 < width:
                neighbor = index + 1
                if not visited[neighbor] and alpha_values[neighbor] >= ALPHA_THRESHOLD:
                    visited[neighbor] = 1
                    queue.append(neighbor)
            if y > 0:
                neighbor = index - width
                if not visited[neighbor] and alpha_values[neighbor] >= ALPHA_THRESHOLD:
                    visited[neighbor] = 1
                    queue.append(neighbor)
            if y + 1 < height:
                neighbor = index + width
                if not visited[neighbor] and alpha_values[neighbor] >= ALPHA_THRESHOLD:
                    visited[neighbor] = 1
                    queue.append(neighbor)
        if len(component) < min_component_area:
            continue
        xs = [index % width for index in component]
        ys = [index // width for index in component]
        components.append((
            component,
            (min(xs), min(ys), max(xs) + 1, max(ys) + 1),
        ))

    expected = columns * rows
    if len(components) != expected:
        raise ValueError(
            f"Expected {expected} complete player silhouettes, found {len(components)}"
        )

    components.sort(key=lambda entry: (entry[1][1] + entry[1][3]) / 2)
    ordered: list[tuple[list[int], tuple[int, int, int, int]]] = []
    for row in range(rows):
        row_components = components[row * columns:(row + 1) * columns]
        ordered.extend(sorted(
            row_components,
            key=lambda entry: (entry[1][0] + entry[1][2]) / 2,
        ))

    poses: list[SourcePose] = []
    for component, bounds in ordered:
        crop = sheet.crop(bounds)
        component_alpha = Image.new("L", crop.size, 0)
        component_alpha_pixels = component_alpha.load()
        for index in component:
            x = index % width
            y = index // width
            component_alpha_pixels[x - bounds[0], y - bounds[1]] = alpha_values[index]
        crop.putalpha(component_alpha)
        poses.append(SourcePose(image=crop, bounds=bounds))
    return poses


def key_magenta_background(source: Image.Image) -> Image.Image:
    """Turn the generated sheet's magenta-only background into true alpha."""
    image = source.convert("RGBA")
    keyed_pixels: list[tuple[int, int, int, int]] = []
    for red, green, blue, _alpha in image.get_flattened_data():
        magenta_dominance = min(red - green, blue - green)
        if magenta_dominance > 24:
            keyed_pixels.append((0, 0, 0, 0))
        else:
            keyed_pixels.append((red, green, blue, 255))
    image.putdata(keyed_pixels)
    return image


def render_pose(pose: SourcePose, scale: float, mirror: bool) -> Image.Image:
    source_image = (
        pose.image.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        if mirror
        else pose.image
    )
    target_width = max(1, round(source_image.width * scale))
    target_height = max(1, round(source_image.height * scale))
    if target_width > CONTENT_WIDTH or target_height > CONTENT_HEIGHT:
        raise ValueError(
            f"Player pose {pose.bounds} exceeds content box after fixed scaling: "
            f"{target_width}x{target_height}"
        )
    resized = source_image.resize((target_width, target_height), Image.Resampling.LANCZOS)
    frame = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    frame.alpha_composite(
        resized,
        dest=(
            (FRAME_WIDTH - target_width) // 2,
            FRAME_HEIGHT - BOTTOM_PADDING - target_height,
        ),
    )
    return frame


def render_aligned_side_pose(pose: SourcePose, scale: float) -> Image.Image:
    """Render one intact pose while locking its head anchor and foot baseline."""
    target_width = max(1, round(pose.image.width * scale))
    target_height = max(1, round(pose.image.height * scale))
    resized = pose.image.resize(
        (target_width, target_height),
        Image.Resampling.LANCZOS,
    )

    head_region_height = max(1, round(pose.image.height * SIDE_HEAD_REGION_RATIO))
    head_bounds = pose.image.getchannel("A").crop(
        (0, 0, pose.image.width, head_region_height)
    ).getbbox()
    if head_bounds is None:
        raise ValueError(f"Generated side pose has no head pixels: {pose.bounds}")
    source_head_center_x = (head_bounds[0] + head_bounds[2]) / 2
    resized_head_center_x = source_head_center_x * target_width / pose.image.width
    destination_x = round(FRAME_WIDTH / 2 - resized_head_center_x)
    destination_y = FRAME_HEIGHT - BOTTOM_PADDING - target_height
    if (
        destination_x < 0
        or destination_x + target_width > FRAME_WIDTH
        or destination_y < 0
    ):
        raise ValueError(
            f"Generated side pose {pose.bounds} does not fit runtime frame: "
            f"dest=({destination_x},{destination_y}) size={target_width}x{target_height}"
        )

    frame = Image.new("RGBA", (FRAME_WIDTH, FRAME_HEIGHT), (0, 0, 0, 0))
    frame.alpha_composite(resized, dest=(destination_x, destination_y))
    frame.putdata([
        (0, 0, 0, 0) if alpha < 16 else (red, green, blue, alpha)
        for red, green, blue, alpha in frame.get_flattened_data()
    ])
    return frame


def save_frame(frame: Image.Image, output: Path) -> None:
    """Avoid rewriting a checked-in PNG when its decoded pixels are unchanged."""
    if output.exists():
        with Image.open(output) as existing_source:
            existing = existing_source.convert("RGBA")
            if existing.size == frame.size and existing.tobytes() == frame.tobytes():
                print(f"kept {output.relative_to(ROOT)} {FRAME_WIDTH}x{FRAME_HEIGHT}")
                return
    frame.save(output, format="PNG", optimize=True)
    print(f"built {output.relative_to(ROOT)} {FRAME_WIDTH}x{FRAME_HEIGHT}")


def main() -> None:
    sheet = Image.open(SOURCE_PATH).convert("RGBA")
    poses = extract_source_poses(sheet)

    for facing, pose_specs in POSE_SPECS.items():
        direction_poses = [poses[pose_index] for pose_index, _mirror in pose_specs]
        fixed_scale = min(
            CONTENT_WIDTH / max(pose.image.width for pose in direction_poses),
            CONTENT_HEIGHT / max(pose.image.height for pose in direction_poses),
        )
        for index, (pose_index, mirror) in enumerate(pose_specs):
            frame = render_pose(poses[pose_index], fixed_scale, mirror)
            output = PLAYER_DIR / f"player_{facing}_{index}.png"
            save_frame(frame, output)

    side_walk_poses = extract_source_poses(
        key_magenta_background(Image.open(SIDE_WALK_SOURCE_PATH)),
        columns=4,
        rows=2,
        min_component_area=5_000,
    )
    side_model_poses = extract_source_poses(
        key_magenta_background(Image.open(SIDE_MODEL_SOURCE_PATH)),
        columns=3,
        rows=3,
        min_component_area=5_000,
    )
    side_pose_sources = {
        "walk": side_walk_poses,
        "model": side_model_poses,
    }
    side_poses = [
        side_pose_sources[source_name][source_index]
        for source_name, source_index in SIDE_WALK_POSE_SPECS
    ]
    idle_pose = side_model_poses[SIDE_IDLE_SOURCE_INDEX]
    def side_pose_scale(pose: SourcePose) -> float:
        return min(
            CONTENT_WIDTH / pose.image.width,
            SIDE_TARGET_HEIGHT / pose.image.height,
        )

    idle_frame = render_aligned_side_pose(idle_pose, side_pose_scale(idle_pose))
    idle_output = PLAYER_DIR / "player_side_idle.png"
    save_frame(idle_frame, idle_output)

    for index, pose in enumerate(side_poses):
        frame = render_aligned_side_pose(pose, side_pose_scale(pose))
        output = PLAYER_DIR / f"player_side_{index}.png"
        save_frame(frame, output)


if __name__ == "__main__":
    main()
