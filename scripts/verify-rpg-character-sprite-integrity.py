#!/usr/bin/env python3
"""Verify runtime RPG character frames preserve complete source silhouettes."""

from __future__ import annotations

from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
ALPHA_THRESHOLD = 10
MIN_COMPONENT_AREA = 500
MIN_SHAPE_IOU = 0.44
MAX_SCALE_RATIO = 1.03
MAX_ASPECT_RATIO_ERROR = 0.03
MIN_EDGE_PADDING = 2


@dataclass(frozen=True)
class Component:
    bounds: tuple[int, int, int, int]
    mask: Image.Image

    @property
    def width(self) -> int:
        return self.bounds[2] - self.bounds[0]

    @property
    def height(self) -> int:
        return self.bounds[3] - self.bounds[1]


@dataclass(frozen=True)
class RuntimeFrame:
    label: str
    source_index: int
    image: Image.Image
    source_mirrored: bool = False
    expected_height: int | None = None


def extract_components(image: Image.Image) -> list[Component]:
    width, height = image.size
    alpha_values = list(image.getchannel("A").get_flattened_data())
    visited = bytearray(width * height)
    components: list[Component] = []

    for start, value in enumerate(alpha_values):
        if value < ALPHA_THRESHOLD or visited[start]:
            continue
        visited[start] = 1
        queue: deque[int] = deque([start])
        pixels: list[int] = []
        while queue:
            index = queue.pop()
            pixels.append(index)
            x = index % width
            y = index // width
            neighbors = (
                index - 1 if x > 0 else -1,
                index + 1 if x + 1 < width else -1,
                index - width if y > 0 else -1,
                index + width if y + 1 < height else -1,
            )
            for neighbor in neighbors:
                if (
                    neighbor >= 0
                    and not visited[neighbor]
                    and alpha_values[neighbor] >= ALPHA_THRESHOLD
                ):
                    visited[neighbor] = 1
                    queue.append(neighbor)

        if len(pixels) < MIN_COMPONENT_AREA:
            continue
        xs = [index % width for index in pixels]
        ys = [index // width for index in pixels]
        bounds = (min(xs), min(ys), max(xs) + 1, max(ys) + 1)
        mask = Image.new("L", (bounds[2] - bounds[0], bounds[3] - bounds[1]), 0)
        mask_pixels = mask.load()
        for index in pixels:
            mask_pixels[index % width - bounds[0], index // width - bounds[1]] = 255
        components.append(Component(bounds=bounds, mask=mask))
    return components


def order_components(components: list[Component], columns: int, rows: int) -> list[Component]:
    expected = columns * rows
    if len(components) != expected:
        raise AssertionError(f"expected {expected} source poses, found {len(components)}")
    by_vertical_center = sorted(
        components,
        key=lambda component: (component.bounds[1] + component.bounds[3]) / 2,
    )
    ordered: list[Component] = []
    for row in range(rows):
        row_components = by_vertical_center[row * columns:(row + 1) * columns]
        ordered.extend(sorted(
            row_components,
            key=lambda component: (component.bounds[0] + component.bounds[2]) / 2,
        ))
    return ordered


def alpha_mask(image: Image.Image) -> tuple[tuple[int, int, int, int], Image.Image]:
    alpha = image.getchannel("A")
    bounds = alpha.getbbox()
    if bounds is None:
        raise AssertionError("runtime frame is empty")
    mask = alpha.crop(bounds).point(lambda value: 255 if value >= ALPHA_THRESHOLD else 0)
    return bounds, mask


def shape_iou(first: Image.Image, second: Image.Image) -> float:
    resized = second.resize(first.size, Image.Resampling.NEAREST)
    first_values = list(first.get_flattened_data())
    second_values = list(resized.get_flattened_data())
    intersection = sum(
        bool(left) and bool(right)
        for left, right in zip(first_values, second_values, strict=True)
    )
    union = sum(
        bool(left) or bool(right)
        for left, right in zip(first_values, second_values, strict=True)
    )
    return intersection / union if union else 1.0


def split_atlas(path: Path, frame_width: int, frame_height: int, count: int) -> list[Image.Image]:
    atlas = Image.open(path).convert("RGBA")
    if atlas.size != (frame_width * count, frame_height):
        raise AssertionError(
            f"{path.name} expected {frame_width * count}x{frame_height}, got {atlas.size}"
        )
    return [
        atlas.crop((index * frame_width, 0, (index + 1) * frame_width, frame_height))
        for index in range(count)
    ]


def verify_role(
    role: str,
    source_path: Path,
    columns: int,
    rows: int,
    groups: dict[str, list[RuntimeFrame]],
    enforce_scale_ratio: bool = True,
) -> None:
    source = Image.open(source_path).convert("RGBA")
    components = order_components(extract_components(source), columns, rows)

    for group_name, frames in groups.items():
        scales: list[float] = []
        for frame in frames:
            source_component = components[frame.source_index]
            bounds, runtime_mask = alpha_mask(frame.image)
            top_padding = bounds[1]
            bottom_padding = frame.image.height - bounds[3]
            if top_padding < MIN_EDGE_PADDING or bottom_padding < MIN_EDGE_PADDING:
                raise AssertionError(
                    f"{frame.label} clips its silhouette padding: "
                    f"top={top_padding} bottom={bottom_padding}"
                )
            runtime_height = bounds[3] - bounds[1]
            if (
                frame.expected_height is not None
                and runtime_height != frame.expected_height
            ):
                raise AssertionError(
                    f"{frame.label} expected silhouette height "
                    f"{frame.expected_height}, got {runtime_height}"
                )
            source_mask = (
                source_component.mask.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
                if frame.source_mirrored
                else source_component.mask
            )
            iou = shape_iou(runtime_mask, source_mask)
            if iou < MIN_SHAPE_IOU:
                raise AssertionError(
                    f"{frame.label} lost source silhouette pixels: IoU={iou:.3f}"
                )
            source_aspect = source_component.width / source_component.height
            runtime_aspect = (
                (bounds[2] - bounds[0]) / (bounds[3] - bounds[1])
            )
            aspect_error = abs(runtime_aspect / source_aspect - 1)
            if aspect_error > MAX_ASPECT_RATIO_ERROR:
                raise AssertionError(
                    f"{frame.label} changed source silhouette proportions: "
                    f"error={aspect_error:.3f}"
                )
            scales.append((bounds[3] - bounds[1]) / source_component.height)
        scale_ratio = max(scales) / min(scales)
        if enforce_scale_ratio and scale_ratio > MAX_SCALE_RATIO:
            raise AssertionError(
                f"{role}/{group_name} changes character scale between frames: "
                f"ratio={scale_ratio:.3f}"
            )


def player_groups() -> dict[str, list[RuntimeFrame]]:
    root = ROOT / "src/assets/rpg/player"
    source_specs = {
        "down": [(index, False) for index in range(0, 8)],
        "up": [(index, False) for index in range(8, 15)] + [(12, True)],
    }
    groups: dict[str, list[RuntimeFrame]] = {}
    for direction in ("down", "up"):
        groups[direction] = [
            RuntimeFrame(
                label=f"player_{direction}_{phase}",
                source_index=source_index,
                image=Image.open(root / f"player_{direction}_{phase}.png").convert("RGBA"),
                source_mirrored=mirrored,
            )
            for phase, (source_index, mirrored) in enumerate(source_specs[direction])
        ]
    return groups


def player_side_sheet_group() -> dict[str, list[RuntimeFrame]]:
    root = ROOT / "src/assets/rpg/player"
    specs = (
        (0, 16, 104),
        (2, 17, 102),
        (3, 18, 101),
        (5, 19, 103),
        (6, 20, 104),
        (8, 21, 102),
        (9, 22, 101),
        (11, 23, 103),
    )
    return {
        "side_sheet": [
            RuntimeFrame(
                label=f"player_side_{phase}",
                source_index=source_index,
                image=Image.open(root / f"player_side_{phase}.png").convert("RGBA"),
                expected_height=expected_height,
            )
            for phase, source_index, expected_height in specs
        ]
    }


def player_side_transition_group(
    phase: int,
    expected_height: int,
) -> dict[str, list[RuntimeFrame]]:
    root = ROOT / "src/assets/rpg/player"
    return {
        f"side_transition_{phase}": [
            RuntimeFrame(
                label=f"player_side_{phase}",
                source_index=0,
                image=Image.open(root / f"player_side_{phase}.png").convert("RGBA"),
                expected_height=expected_height,
            )
        ]
    }


def npc_groups(role: str) -> dict[str, list[RuntimeFrame]]:
    root = ROOT / "src/assets/rpg/npcs/finale"
    definitions = {
        "student": [
            ("walk", "student_walk_8frame.png", 96, list(range(0, 8))),
            ("phone", "student_phone_glance_2frame.png", 96, [8, 9]),
            ("bag", "student_adjust_bag_2frame.png", 96, [10, 11]),
            ("door", "student_push_door_3frame.png", 112, [12, 13, 14]),
            ("idle", "student_idle_1frame.png", 96, [15]),
        ],
        "guard_action": [
            ("list", "guard_check_list_2frame.png", 96, [8, 9]),
            ("watch", "guard_check_watch_2frame.png", 96, [10, 11]),
            ("flashlight", "guard_flashlight_down_2frame.png", 128, [12, 13]),
            ("radio", "guard_radio_2frame.png", 96, [14, 15]),
        ],
        "guard_walk_side": [
            ("walk_side", "guard_walk_8frame.png", 96, list(range(0, 8))),
        ],
        "guard_walk_down": [
            ("walk_down", "guard_walk_down_8frame.png", 96, list(range(0, 8))),
        ],
        "guard_walk_up": [
            ("walk_up", "guard_walk_up_8frame.png", 96, list(range(0, 8))),
        ],
        "cleaner_action": [
            ("mop", "cleaner_mop_4frame.png", 144, [4, 5, 6, 7]),
            ("cart", "cleaning_cart_1frame.png", 144, [8]),
            ("sign", "cleaner_place_sign_2frame.png", 128, [9, 10]),
            ("lights", "cleaner_toggle_lights_2frame.png", 112, [11, 12]),
            ("rest", "cleaner_rest_1frame.png", 96, [13]),
        ],
        "cleaner_idle": [
            ("idle", "cleaner_idle_8frame.png", 96, list(range(0, 8))),
        ],
        "cleaner_push_side": [
            ("push_side", "cleaner_push_cart_8frame.png", 192, list(range(0, 8))),
        ],
        "cleaner_push_down": [
            ("push_down", "cleaner_push_cart_down_8frame.png", 192, list(range(0, 8))),
        ],
        "cleaner_push_up": [
            ("push_up", "cleaner_push_cart_up_8frame.png", 192, list(range(0, 8))),
        ],
    }
    groups: dict[str, list[RuntimeFrame]] = {}
    for group_name, file_name, frame_width, source_indices in definitions[role]:
        images = split_atlas(root / file_name, frame_width, 128, len(source_indices))
        groups[group_name] = [
            RuntimeFrame(
                label=f"{group_name}_{index}",
                source_index=source_index,
                image=image,
            )
            for index, (source_index, image) in enumerate(zip(source_indices, images, strict=True))
        ]
    return groups


def main() -> None:
    verify_role(
        "player",
        ROOT / "src/assets/rpg/player/source/player_walk_24pose_transparent_v2.png",
        4,
        6,
        player_groups(),
    )
    verify_role(
        "player_side_sheet",
        ROOT / "src/assets/rpg/player/source/player_walk_24pose_transparent_v2.png",
        4,
        6,
        player_side_sheet_group(),
        enforce_scale_ratio=False,
    )
    side_transition_sources = (
        (1, 103, "player_side_transition_01_v3.png"),
        (4, 102, "player_side_transition_23_v3.png"),
        (7, 103, "player_side_transition_45_v3.png"),
        (10, 102, "player_side_transition_67_v3.png"),
    )
    for phase, expected_height, source_file in side_transition_sources:
        verify_role(
            f"player_side_transition_{phase}",
            ROOT / "src/assets/rpg/player/source" / source_file,
            1,
            1,
            player_side_transition_group(phase, expected_height),
            enforce_scale_ratio=False,
        )
    npc_source_root = ROOT / "src/assets/rpg/npcs/finale/source"
    source_roles = (
        ("student", "finale_student_source_grid_v2.png", 4, 4),
        ("guard_action", "finale_guard_source_grid_v2.png", 4, 4),
        ("guard_walk_side", "finale_guard_walk_side_source_grid_v3.png", 4, 2),
        ("guard_walk_down", "finale_guard_walk_down_source_grid_v3.png", 4, 2),
        ("guard_walk_up", "finale_guard_walk_up_source_grid_v3.png", 4, 2),
        ("cleaner_action", "finale_cleaner_source_grid_v2.png", 4, 4),
        ("cleaner_idle", "finale_cleaner_idle_source_grid_v3.png", 4, 2),
        ("cleaner_push_side", "finale_cleaner_push_side_source_grid_v3.png", 4, 2),
        ("cleaner_push_down", "finale_cleaner_push_down_source_grid_v3.png", 4, 2),
        ("cleaner_push_up", "finale_cleaner_push_up_source_grid_v3.png", 4, 2),
    )
    for role, source_file, columns, rows in source_roles:
        verify_role(
            role,
            npc_source_root / source_file,
            columns,
            rows,
            npc_groups(role),
        )
    print("verified complete, padded and scale-stable runtime silhouettes for directional RPG roles")


if __name__ == "__main__":
    main()
