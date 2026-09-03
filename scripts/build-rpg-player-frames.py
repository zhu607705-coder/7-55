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
SIDE_TRANSITION_PATHS = {
    "near_acceptance": PLAYER_DIR / "source/player_side_transition_01_v3.png",
    "near_toe_off": PLAYER_DIR / "source/player_side_transition_23_v3.png",
    "far_acceptance": PLAYER_DIR / "source/player_side_transition_45_v3.png",
    "far_toe_off": PLAYER_DIR / "source/player_side_transition_67_v3.png",
    "passing_close": PLAYER_DIR / "source/player_side_passing_close_v1.png",
}

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

# The side cycle keeps seven original authored poses and inserts five genuinely
# drawn transition poses. The two six-phase half strides explicitly
# swap the near/far support leg. Target silhouette heights encode a restrained,
# symmetric gait bob instead of inheriting source-resolution drift.
SIDE_CYCLE_SPECS = (
    ("sheet", 16, 104),
    ("transition", "near_acceptance", 103),
    ("sheet", 17, 102),
    ("transition", "passing_close", 101),
    ("transition", "near_toe_off", 102),
    ("sheet", 19, 103),
    ("sheet", 20, 104),
    ("transition", "far_acceptance", 103),
    ("sheet", 21, 102),
    ("sheet", 22, 101),
    ("transition", "far_toe_off", 102),
    ("sheet", 23, 103),
)


@dataclass(frozen=True)
class SourcePose:
    image: Image.Image
    bounds: tuple[int, int, int, int]


def extract_source_poses(sheet: Image.Image) -> list[SourcePose]:
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
        if len(component) < MIN_COMPONENT_AREA:
            continue
        xs = [index % width for index in component]
        ys = [index // width for index in component]
        components.append((
            component,
            (min(xs), min(ys), max(xs) + 1, max(ys) + 1),
        ))

    expected = GRID_COLUMNS * GRID_ROWS
    if len(components) != expected:
        raise ValueError(
            f"Expected {expected} complete player silhouettes, found {len(components)}"
        )

    components.sort(key=lambda entry: (entry[1][1] + entry[1][3]) / 2)
    ordered: list[tuple[list[int], tuple[int, int, int, int]]] = []
    for row in range(GRID_ROWS):
        row_components = components[row * GRID_COLUMNS:(row + 1) * GRID_COLUMNS]
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


def extract_standalone_pose(path: Path) -> SourcePose:
    image = Image.open(path).convert("RGBA")
    alpha = image.getchannel("A")
    visible_alpha = alpha.point(
        lambda value: 255 if value >= ALPHA_THRESHOLD else 0
    )
    bounds = visible_alpha.getbbox()
    if bounds is None:
        raise ValueError(f"Standalone player pose is empty: {path}")
    crop = image.crop(bounds)
    crop.putalpha(crop.getchannel("A").point(
        lambda value: value if value >= ALPHA_THRESHOLD else 0
    ))
    return SourcePose(image=crop, bounds=bounds)


def render_pose_at_height(pose: SourcePose, target_height: int) -> Image.Image:
    scale = min(
        target_height / pose.image.height,
        CONTENT_WIDTH / pose.image.width,
    )
    frame = render_pose(pose, scale, False)
    bounds = frame.getchannel("A").getbbox()
    if bounds is None:
        raise ValueError(f"Rendered side pose is empty: {pose.bounds}")
    rendered_height = bounds[3] - bounds[1]
    if rendered_height != target_height:
        raise ValueError(
            f"Side pose {pose.bounds} must render at {target_height}px, "
            f"received {rendered_height}px"
        )
    return frame


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
            frame.save(output, format="PNG", optimize=True)
            print(f"built {output.relative_to(ROOT)} {FRAME_WIDTH}x{FRAME_HEIGHT}")

    standalone_side_poses = {
        name: extract_standalone_pose(path)
        for name, path in SIDE_TRANSITION_PATHS.items()
    }
    for index, (source_type, source_ref, target_height) in enumerate(SIDE_CYCLE_SPECS):
        pose = (
            poses[source_ref]
            if source_type == "sheet"
            else standalone_side_poses[source_ref]
        )
        frame = render_pose_at_height(pose, target_height)
        output = PLAYER_DIR / f"player_side_{index}.png"
        frame.save(output, format="PNG", optimize=True)
        print(f"built {output.relative_to(ROOT)} {FRAME_WIDTH}x{FRAME_HEIGHT}")


if __name__ == "__main__":
    main()
