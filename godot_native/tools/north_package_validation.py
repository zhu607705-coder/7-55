#!/usr/bin/env python3
"""Probe north HD production resource methods in tiny source-less main PCKs.

No export, importer, editor, GUI, source PNG, or full campus is involved. Reuses
existing real imported body, ground and shared-strip Texture2Ds, their unchanged
.import mappings, production profiles, ownership and one crown R8 field.
The production scripts are unchanged. Four separate processes prevent
ResourceLoader's cache from masking the missing-import negative case.

Use --prepare-only to inspect package inputs without launching Godot. Every
output, temporary file and XDG directory stays under the supplied --output-root.
This is resource-method QA, NOT scene, gameplay, rendering, or GPU acceptance.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import struct
import subprocess
import tempfile


CASES = ("valid", "missing_ctex", "missing_surface", "corrupt_surface")
PREFIX = "campuses/buct_changping/"


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def resource_path(project: Path, value: str) -> tuple[str, Path]:
    if not value.startswith("res://"):
        raise RuntimeError(f"Not a project resource: {value}")
    relative = value.removeprefix("res://")
    target = (project / relative).resolve()
    if not target.is_relative_to(project) or not target.is_file():
        raise RuntimeError(f"Required existing production resource is missing: {value}")
    return relative, target


def imported_texture(project: Path, source: Path) -> tuple[Path, str]:
    mapping = source.with_suffix(source.suffix + ".import")
    if not mapping.is_file():
        raise RuntimeError("Existing production .import is required; importing is forbidden")
    match = re.search(r'^path="(res://[^"\n]+\.ctex)"$', mapping.read_text(), re.M)
    if not match:
        raise RuntimeError("Production .import has no unambiguous .ctex remap")
    relative, _ = resource_path(project, match.group(1))
    return mapping, relative


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", type=Path, required=True)
    parser.add_argument("--godot", default=os.environ.get("GODOT_BIN", "godot"))
    parser.add_argument("--prepare-only", action="store_true")
    parser.add_argument("--body-id", choices=("north_sports_hall", "teaching_2"), default="north_sports_hall")
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    output = args.output_root.expanduser().resolve()
    if output.is_relative_to(project):
        raise RuntimeError("--output-root must be outside the production project")
    output.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix="north-package-", dir=output))
    inputs = run / "inputs"
    mini = run / "builder-project"
    inputs.mkdir()
    mini.mkdir()
    profile_relative = PREFIX + f"data/{args.body_id}_registration.json"
    profile = json.loads((project / profile_relative).read_text())
    body_relative, source = resource_path(project, profile["body_asset"])
    surface_relative, surface = resource_path(project, profile["surface_id_path"])
    _, ctex_relative = imported_texture(project, source)
    region_profile_relative = PREFIX + ("data/west_north_hd_region.json" if args.body_id == "teaching_2" else "data/north_hd_region.json")
    region_profile = json.loads((project / region_profile_relative).read_text())
    region_profile_relatives = [region_profile_relative]
    if args.body_id == "teaching_2": region_profile_relatives.append(PREFIX + "data/west_south_hd_region.json")
    region_files = list(region_profile_relatives)
    region_ctex = {}
    for region_path in region_profile_relatives:
        region = json.loads((project / region_path).read_text())
        seam = region.get("shared_overlap") or next(edge for edge in region["shared_edges"] if edge["edge"] == "east")
        for image_path in [region["ground_asset"], seam["unfeathered_strip_asset"]]:
            image_relative, image_source = resource_path(project, image_path)
            _, imported_relative = imported_texture(project, image_source)
            region_files.extend([image_relative + ".import", imported_relative])
            region_ctex[image_path] = "res://" + imported_relative
        masks = [region["source_body_ownership"]]
        if region.get("water_complement"): masks.append(region["water_complement"])
        for crown in region["foreground"]:
            masks.append({"asset":crown["alpha_asset"],"sha256":crown["alpha_sha256"],"size":[int(crown["rect"][2]*5),int(crown["rect"][3]*5)]})
        for mask in masks:
            relative, path = resource_path(project, mask["asset"])
            raw = path.read_bytes(); expected_size = tuple(map(int,mask["size"]))
            if len(raw) != expected_size[0] * expected_size[1] or digest(raw) != mask["sha256"]:
                raise RuntimeError(f"Production region R8 differs from its profile: {mask['asset']}")
            region_files.append(relative)
    source_sha = digest(source.read_bytes())
    if source_sha != profile["body_sha256"]:
        raise RuntimeError("Production source SHA differs from the registration")
    surface_bytes = surface.read_bytes()
    width, height = map(int, profile["body_image_to_world"]["raw_size"])
    if len(surface_bytes) != width * height or digest(surface_bytes) != profile["surface_id_sha256"]:
        raise RuntimeError("Production R8 field differs from the registration")
    rows = profile["depth_rows_raw_y"]
    if len(rows) != profile["surface_count"] or any(len(row) != width for row in rows):
        raise RuntimeError("Production depth rows have invalid dimensions")
    depth_values = [float(value) for row in rows for value in row]
    depth_bytes = struct.pack("<" + "f" * len(depth_values), *depth_values)
    project_text = ('[application]\nconfig/name="North resource-method package probe"\n'
                    '[rendering]\nrenderer/rendering_method="gl_compatibility"\n')
    (mini / "project.godot").write_text(project_text)
    builder = project / "tests/build_buct_texture_package.gd"
    shutil.copy2(builder, mini / "north_package_build.gd")
    # Snapshot only this dependency closure. Never copy production project.godot,
    # source PNGs, scenes, whole .godot cache, UID cache or export presets.
    production_files = [
        PREFIX + "scripts/registered_hd_building.gd",
        PREFIX + "scripts/registered_hd_region.gd",
        PREFIX + "shaders/wenli_depth.gdshader",
        PREFIX + "shaders/registered_hd_ground.gdshader",
        PREFIX + "shaders/registered_hd_west_ground.gdshader",
        profile_relative,
        body_relative + ".import",
        ctex_relative,
        surface_relative,
    ] + region_files
    files: dict[str, Path] = {"project.godot": mini / "project.godot"}
    hashes: dict[str, str] = {}
    for relative in production_files:
        _, path = resource_path(project, "res://" + relative)
        target = inputs / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, target)
        files[relative] = target
        hashes[relative] = digest(target.read_bytes())
    probe = inputs / "north_package_validation.gd"
    shutil.copy2(project / "tests/north_package_validation.gd", probe)
    files[probe.name] = probe
    expected_depth = inputs / "expected_depth.rf.bin"
    expected_depth.write_bytes(depth_bytes)
    files[expected_depth.name] = expected_depth
    corrupted = bytearray(surface_bytes)
    corrupted[len(corrupted) // 2] ^= 0xFF
    corrupt_surface = inputs / "corrupt_surface.r8.bin"
    corrupt_surface.write_bytes(corrupted)
    if digest(corrupted) == profile["surface_id_sha256"]:
        raise RuntimeError("Negative fixture must differ at the same byte length")
    setup = {
        "scope": "Production resource helpers and building configure only; no scene/gameplay/GPU proof",
        "run": str(run), "source_png_packaged": False, "reused_existing_ctex": True,
        "production_snapshot_sha256": hashes,
        "computed_depth_sha256": digest(depth_bytes),
        "cases": [],
    }
    environments = []
    for case in CASES:
        case_dir = run / case
        case_dir.mkdir()
        runtime = case_dir / "runtime"
        for name in ("tmp", "data", "config", "cache", "state", "runtime", "home"):
            (runtime / name).mkdir(parents=True)
        (runtime / "runtime").chmod(0o700)
        env = dict(os.environ)
        env.update({name: str(runtime / "tmp") for name in ("TMPDIR", "TEMP", "TMP")})
        for key, name in (("XDG_DATA_HOME", "data"), ("XDG_CONFIG_HOME", "config"),
                          ("XDG_CACHE_HOME", "cache"), ("XDG_STATE_HOME", "state"),
                          ("XDG_RUNTIME_DIR", "runtime"), ("HOME", "home")):
            env[key] = str(runtime / name)
        selected = dict(files)
        if case == "missing_ctex":
            del selected[ctex_relative]
        elif case == "missing_surface":
            del selected[surface_relative]
        elif case == "corrupt_surface":
            selected[surface_relative] = corrupt_surface
        if any(name.endswith(".png") for name in selected):
            raise RuntimeError("Unexpected source PNG in package")
        expectation = case_dir / "expectation.json"
        expectation.write_text(json.dumps({
            "case": case, "profile": "res://" + profile_relative,
            "region_profile": "res://" + region_profile_relative,
            "region_profiles": ["res://"+value for value in region_profile_relatives],
            "region_ctex": region_ctex,
            "ctex": "res://" + ctex_relative,
            "depth_sha256": digest(depth_bytes),
            "script_sha256": {"res://" + key: value for key, value in hashes.items() if key.endswith(".gd")},
        }, indent=2) + "\n")
        selected["expectation.json"] = expectation
        manifest = case_dir / "files.json"
        manifest.write_text(json.dumps({key: str(value) for key, value in selected.items()}, indent=2) + "\n")
        env.update(BUCT_PACKAGE_FILES=str(manifest), BUCT_PACKAGE_PCK=str(case_dir / "north.pck"),
                   NORTH_PACKAGE_REPORT=str(case_dir / "result.json"))
        setup["cases"].append({"case": case, "file_count": len(selected),
                               "input_bytes": sum(path.stat().st_size for path in selected.values()),
                               "files": list(selected), "ctex_present": ctex_relative in selected,
                               "surface_present": surface_relative in selected})
        environments.append((case, case_dir, env))
    (run / "setup.json").write_text(json.dumps(setup, indent=2) + "\n")
    print(f"Prepared four source-less north resource cases: {run}", flush=True)
    if args.prepare_only:
        print("PREPARED ONLY: no Godot process, import, export or gameplay test ran")
        return

    def invoke(arguments: list[str], env: dict[str, str], log_path: Path) -> int:
        with log_path.open("w") as log:
            result = subprocess.run([args.godot, "--headless", "--audio-driver", "Dummy",
                                     "--path", str(mini), *arguments], env=env,
                                    stdout=log, stderr=subprocess.STDOUT, timeout=90, cwd=mini)
        return result.returncode

    results = []
    for case, case_dir, env in environments:
        code = invoke(["--script", "north_package_build.gd"], env, case_dir / "build.log")
        if code:
            raise RuntimeError(f"PCK builder exited {code}; see {case_dir / 'build.log'}")
        code = invoke(["--main-pack", env["BUCT_PACKAGE_PCK"], "--script", "res://north_package_validation.gd"],
                      env, case_dir / "validation.log")
        result_path = case_dir / "result.json"
        result = json.loads(result_path.read_text()) if result_path.is_file() else {"failures": ["No probe report"]}
        result["exit_code"] = code
        result["case"] = case
        result["pck_bytes"] = (case_dir / "north.pck").stat().st_size
        results.append(result)
        # Continue all independent negative cases; preserve every case report.
        print(f"{case}: exit={code}, checks={result.get('checks', 0)}, failures={result['failures']}", flush=True)
    report = {"scope": setup["scope"], "cases": results,
              "checks": sum(item.get("checks", 0) for item in results),
              "passed": all(item["exit_code"] == 0 and not item["failures"] and item.get("checks", 0) >= 15
                            for item in results)}
    (run / "summary.json").write_text(json.dumps(report, indent=2) + "\n")
    if not report["passed"]:
        raise RuntimeError(f"North resource package probe failed; retained evidence: {run}")
    print(f"PASS {report['checks']} resource-method checks across 4 actual PCKs: {run}")


if __name__ == "__main__":
    main()
