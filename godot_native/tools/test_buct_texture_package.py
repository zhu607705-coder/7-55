#!/usr/bin/env python3
"""Build and execute a tiny source-less texture PCK, never a full game export.

Requires Python3 and an installed official Godot4 executable. Outputs are written
only to a fresh subdirectory of the explicitly supplied --output-root. No CI
workflow or export preset is changed. The two deliberately invalid .ctex fixtures
emit expected ResourceLoader ERROR diagnostics; read the case-level JSON result.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-root', type=Path, required=True)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN', 'godot'))
    parser.add_argument('--prepare-only', action='store_true',
                        help='Prepare and validate file paths without launching Godot; requires an existing tiny ctex cache.')
    args = parser.parse_args()
    project = Path(__file__).resolve().parents[1]
    output = args.output_root.expanduser().resolve()
    output.mkdir(parents=True, exist_ok=True)
    run = Path(tempfile.mkdtemp(prefix='buct-texture-package-', dir=output))
    mini, inputs, runtime = run/'project', run/'inputs', run/'runtime'
    for folder in [mini, inputs, *(runtime/x for x in ['tmp', 'data', 'config', 'cache', 'state', 'runtime'])]:
        folder.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    env.update({key: str(runtime/'tmp') for key in ['TMPDIR', 'TEMP', 'TMP']})
    for key, directory in [('XDG_DATA_HOME', 'data'), ('XDG_CONFIG_HOME', 'config'),
                           ('XDG_CACHE_HOME', 'cache'), ('XDG_STATE_HOME', 'state'),
                           ('XDG_RUNTIME_DIR', 'runtime')]:
        env[key] = str(runtime/directory)
    campus = project/'campuses/buct_haidian'
    source = campus/'rongmao/assets/south-ground-mask.png'
    profile = json.loads((campus/'rongmao/data/library-profile.json').read_text())
    expected = profile['asset_sha256']['assets/south-ground-mask.png']
    if hashlib.sha256(source.read_bytes()).hexdigest() != expected:
        raise RuntimeError('Source fixture hash differs from the production contract')
    helper = campus/'scripts/imported_texture_validator.gd'
    builder = project/'tests/build_buct_texture_package.gd'
    test = project/'tests/fixtures/buct_texture_package.gd'
    for required in [helper, builder, test]:
        if not required.is_file():
            raise RuntimeError(f'Missing regression source: {required.relative_to(project)}')
    (mini/'project.godot').write_text('[application]\nconfig/name="Tiny imported texture regression"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n')

    def invoke(arguments, log_name, project_dir=mini):
        with (run/log_name).open('w') as log:
            result = subprocess.run([args.godot, '--headless', '--audio-driver', 'Dummy',
                                     '--path', str(project_dir), *arguments], env=env,
                                    stdout=log, stderr=subprocess.STDOUT, timeout=60)
        if result.returncode:
            raise RuntimeError(f'Godot exit {result.returncode}; retained log: {run/log_name}')

    def cached_texture(png, project_root):
        mapping = png.with_suffix('.png.import')
        if not mapping.is_file():
            return None
        match = re.search(r'^path="res://([^"]+\.ctex)"', mapping.read_text(), re.M)
        target = project_root/match[1] if match else None
        return target if target and target.is_file() else None

    texture = cached_texture(source, project)
    reused_cache = texture is not None
    if texture is None:
        if args.prepare_only:
            raise RuntimeError('No existing54x58ctex cache; prepare-only did not launch an importer')
        # Cold checkout: import ONE tiny54x58 PNG in an isolated project only.
        import_project = run/'tiny-import'
        import_project.mkdir()
        shutil.copy2(mini/'project.godot', import_project/'project.godot')
        shutil.copy2(source, import_project/'valid.png')
        invoke(['--editor', '--import'], 'tiny-import.log', import_project)
        texture = cached_texture(import_project/'valid.png', import_project)
        if texture is None:
            raise RuntimeError('Tiny isolated import did not produce a ctex')
    shutil.copy2(texture, inputs/'valid.ctex')
    shutil.copy2(source, inputs/'valid.png')
    (inputs/'corrupt-source.png').write_bytes(b'CORRUPT SOURCE WHILE IMPORT IS VALID\n')
    (inputs/'bad.ctex').write_bytes(b'NOT A GODOT COMPRESSED TEXTURE\n')
    (inputs/'wrong-type.tres').write_text('[gd_resource type="Resource" format=3]\n[resource]\n')
    files = {'project.godot': mini/'project.godot', 'packaged_validation.gd': test,
             'campuses/buct_haidian/scripts/imported_texture_validator.gd': helper,
             '.godot/imported/valid.ctex': inputs/'valid.ctex',
             '.godot/imported/bad.ctex': inputs/'bad.ctex',
             'with-source.png': inputs/'valid.png',
             'corrupt-source.png': inputs/'corrupt-source.png',
             'wrong-type.tres': inputs/'wrong-type.tres'}
    for name, cache in [('valid', 'valid'), ('with-source', 'valid'),
                        ('corrupt-source', 'valid'), ('missing-data', 'absent'), ('bad-data', 'bad')]:
        mapping = inputs/f'{name}.png.import'
        mapping.write_text(f'[remap]\nimporter="texture"\ntype="CompressedTexture2D"\npath="res://.godot/imported/{cache}.ctex"\n[deps]\nsource_file="res://{name}.png"\ndest_files=["res://.godot/imported/{cache}.ctex"]\n')
        files[mapping.name] = mapping
    manifest = inputs/'files.json'
    manifest.write_text(json.dumps({k: str(v) for k, v in files.items()}, indent=2)+'\n')
    env.update(BUCT_PACKAGE_FILES=str(manifest), BUCT_PACKAGE_PCK=str(run/'texture-validation.pck'),
               BUCT_PACKAGE_REPORT=str(run/'result.json'), BUCT_PACKAGE_EXPECTED_SHA=expected)
    shutil.copy2(builder, mini/'build_pack.gd')
    setup = {'reused_existing_ctex': reused_cache, 'file_count': len(files),
             'input_bytes': sum(p.stat().st_size for p in files.values()),
             'source_png_absent_from_valid_case': 'valid.png' not in files,
             'production_validator_sha256': hashlib.sha256(helper.read_bytes()).hexdigest()}
    (run/'setup.json').write_text(json.dumps(setup, indent=2)+'\n')
    if args.prepare_only:
        print(f'PREPARED_ONLY, no Godot run: {run}')
        return
    invoke(['--script', 'build_pack.gd'], 'build.log')
    invoke(['--main-pack', env['BUCT_PACKAGE_PCK'], '--script', 'res://packaged_validation.gd'], 'validation.log')
    result = json.loads((run/'result.json').read_text())
    if result['errors'] or result['checks'] != 20:
        raise RuntimeError(f'Unexpected test result: {run/"result.json"}')
    print(f'PASS20/20 packaged checks across9cases; deliberate missing/corrupt resources emit expected errors. Results: {run}')


if __name__ == '__main__':
    main()
