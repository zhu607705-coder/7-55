#!/usr/bin/env python3
"""Same-run full tracked source transport. No Git directory is ever transported.

Only canonical USTAR regular files are accepted. Git independently supplies the
commit/tree; archive metadata is never used as authority for paths or modes.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import tarfile
import tempfile
import time
import unicodedata

SCHEMA = '755-native-source-v1'
HELPER = 'godot_native/tools/native_source_transport.py'
MAX_BYTES = 3 * 1024**3
MAX_FILES = 20000
RESERVE = 1024**3
CHUNK = 1024**2


def require(ok, message):
    if not ok:
        raise ValueError(message)


def git(root, *args, data=None):
    env = dict(os.environ, GIT_NO_LAZY_FETCH='1', GIT_TERMINAL_PROMPT='0')
    return subprocess.check_output(['git', '-C', str(root), *args], input=data, env=env)


def safe_absolute(path):
    path = Path(os.path.abspath(path))
    for part in [path, *path.parents]:
        require(not part.is_symlink(), f'Symlink ancestor: {part}')
    return path


def safe_name(name):
    require(isinstance(name, str) and name and not name.startswith('/')
            and not re.search(r'[\\\x00-\x1f\x7f]', name)
            and all(p and p not in ('.', '..') and p.casefold() != '.git' for p in name.split('/')),
            f'Unsafe tracked path: {name!r}')
    return name


def tree_entries(root):
    entries, seen = [], set()
    for row in git(root, 'ls-tree', '-rz', '--full-tree', 'HEAD').split(b'\0'):
        if not row:
            continue
        header, path = row.split(b'\t', 1)
        mode, kind, oid = header.decode('ascii').split()
        name = safe_name(path.decode('utf8', errors='strict'))
        canonical = unicodedata.normalize('NFC', name).casefold()
        require(canonical not in seen, f'Case/normalization collision: {name}')
        seen.add(canonical)
        require(kind == 'blob' and mode in ('100644', '100755'), 'Only regular tracked files are supported')
        entries.append(dict(path=name, mode=mode, oid=oid))
    require(0 < len(entries) <= MAX_FILES, 'Source file count outside bound')
    names = {e['path'] for e in entries}
    for name in names:
        require(not any(str(p) in names for p in Path(name).parents if str(p) != '.'), 'File/directory collision')
    return entries


def identity(root, context):
    require(re.fullmatch('[0-9a-f]{40}', context['commit']) is not None, 'Invalid expected commit')
    require(re.fullmatch('[0-9a-f]{40}', context['head']) is not None, 'Invalid expected head')
    require(context['base'] == '' or re.fullmatch('[0-9a-f]{40}', context['base']), 'Invalid expected base')
    require(all(context[k] for k in ('repository', 'workflow', 'event', 'run', 'attempt')), 'Incomplete source provenance')
    require(all(re.fullmatch('[1-9][0-9]*', context[k]) for k in ('run', 'attempt')), 'Invalid run/attempt')
    require(Path(git(root, 'rev-parse', '--show-toplevel').decode().strip()).resolve() == root.resolve(), 'Not checkout root')
    require(git(root, 'rev-parse', 'HEAD').decode().strip() == context['commit'], 'Wrong checked-out commit')
    return dict(context, tree=git(root, 'rev-parse', 'HEAD^{tree}').decode().strip())


def disk(path, needed, phase):
    free = shutil.disk_usage(path).free
    print(json.dumps(dict(phase=phase, freeBytes=free, requiredBytes=needed)), flush=True)
    require(free >= needed, f'Insufficient disk for {phase}: need {needed}, free {free}')


def sha256(path):
    with open(path, 'rb') as f:
        return hashlib.file_digest(f, 'sha256').hexdigest()


def clean(root):
    require(git(root, 'status', '--porcelain', '--untracked-files=no') == b'', 'Tracked source is dirty')


def tar_header(entry):
    info = tarfile.TarInfo(entry['path'])
    info.size = entry['size']
    info.mode = int(entry['mode'][-3:], 8)
    info.uid = info.gid = info.mtime = 0
    return info.tobuf(format=tarfile.USTAR_FORMAT, encoding='utf-8', errors='strict')


def location(root, bundle):
    root, bundle = safe_absolute(root), safe_absolute(bundle)
    require(root != bundle and root not in bundle.parents and bundle not in root.parents, 'Transport must be outside source root')
    return root, bundle


def capture(root, bundle, context):
    started = time.monotonic()
    root, bundle = location(root, bundle)
    provenance = identity(root, context)
    clean(root)
    entries = tree_entries(root)
    total = 0
    for entry in entries:
        path = safe_absolute(root / entry['path'])
        st = path.lstat()
        require(stat.S_ISREG(st.st_mode), 'Nonregular source')
        require(bool(st.st_mode & 0o111) == (entry['mode'] == '100755'), 'Source executable mode mismatch')
        entry['size'] = st.st_size
        total += st.st_size
    require(total <= MAX_BYTES, 'Source bytes exceed trial bound')
    require(not bundle.exists(), 'Output bundle must be fresh')
    bundle.parent.mkdir(parents=True, exist_ok=True)
    disk(bundle.parent, total + len(entries) * 1024 + 2 * RESERVE, 'capture')
    bundle.mkdir()
    archive = bundle / 'source.tar'
    try:
        with archive.open('xb') as out:
            for entry in entries:
                path = safe_absolute(root / entry['path'])
                before = path.stat()
                out.write(tar_header(entry))
                digest = hashlib.sha256()
                blob = hashlib.sha1(f"blob {entry['size']}\0".encode())
                size = 0
                with path.open('rb') as f:
                    while chunk := f.read(CHUNK):
                        size += len(chunk)
                        require(size <= entry['size'], 'Source grew during capture')
                        digest.update(chunk); blob.update(chunk); out.write(chunk)
                after = path.stat()
                require((before.st_ino, before.st_size, before.st_mtime_ns, before.st_mode) ==
                        (after.st_ino, after.st_size, after.st_mtime_ns, after.st_mode), 'Source changed during capture')
                require(size == entry['size'] and blob.hexdigest() == entry['oid'], 'Source differs from exact Git blob')
                entry['sha256'] = digest.hexdigest()
                out.write(b'\0' * ((-size) % 512))
            out.write(b'\0' * 1024)
        clean(root)
        require(identity(root, context) == provenance and tree_entries(root) ==
                [{k: e[k] for k in ('path', 'mode', 'oid')} for e in entries], 'Source identity changed during capture')
        manifest = dict(schema=SCHEMA, source=provenance, entries=entries, sourceBytes=total,
                        archiveBytes=archive.stat().st_size, archiveSha256=sha256(archive))
        (bundle / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, sort_keys=True) + '\n')
        result = dict(manifest_sha=sha256(bundle / 'manifest.json'), archive_sha=manifest['archiveSha256'],
                      source_bytes=total, archive_bytes=manifest['archiveBytes'], tree=provenance['tree'],
                      capture_seconds=round(time.monotonic() - started, 3))
        print(json.dumps(result), flush=True)
        if os.environ.get('GITHUB_OUTPUT'):
            with open(os.environ['GITHUB_OUTPUT'], 'a') as f:
                for key, value in result.items():
                    f.write(f'{key}={value}\n')
        return result
    except BaseException:
        shutil.rmtree(bundle)
        raise


def load_manifest(root, bundle, context, manifest_sha, archive_sha):
    path = bundle / 'manifest.json'
    require(path.is_file() and not path.is_symlink() and path.stat().st_size <= 16 * 1024**2, 'Invalid manifest file')
    require(sha256(path) == manifest_sha, 'Manifest digest mismatch')
    m = json.loads(path.read_text())
    require(m['schema'] == SCHEMA and m['source'] == identity(root, context), 'Source provenance mismatch')
    entries = m['entries']
    require(isinstance(entries, list) and len(entries) <= MAX_FILES, 'Invalid source inventory')
    require([{k: e[k] for k in ('path', 'mode', 'oid')} for e in entries] == tree_entries(root), 'Manifest differs from authentic Git tree')
    for e in entries:
        require(type(e['size']) is int and 0 <= e['size'] <= MAX_BYTES, 'Invalid source size')
        require(re.fullmatch('[0-9a-f]{64}', e['sha256']), 'Invalid file digest')
    total = sum(e['size'] for e in entries)
    expected_length = sum(512 + ((e['size'] + 511) // 512) * 512 for e in entries) + 1024
    require(total == m['sourceBytes'] and total <= MAX_BYTES, 'Invalid total source size')
    archive = bundle / 'source.tar'
    require(archive.is_file() and not archive.is_symlink(), 'Invalid archive')
    require(archive.stat().st_size == expected_length == m['archiveBytes'], 'Archive byte bound mismatch')
    require(sha256(archive) == m['archiveSha256'] == archive_sha, 'Archive digest mismatch')
    return m


def restore(root, bundle, context, manifest_sha, archive_sha):
    started = time.monotonic()
    root, bundle = location(root, bundle)
    m = load_manifest(root, bundle, context, manifest_sha, archive_sha)
    # A new checkout may contain ONLY the independently fetched bootstrap helper.
    existing = []
    for current, directories, files in os.walk(root, followlinks=False):
        if Path(current) == root and '.git' in directories:
            directories.remove('.git')
        for name in directories + files:
            path = Path(current) / name
            require(not path.is_symlink(), 'Unexpected symlink in bootstrap checkout')
        existing.extend(str((Path(current) / name).relative_to(root)) for name in files)
    require(set(existing) <= {HELPER}, 'Consumer checkout is not bootstrap-only')
    if existing:
        helper = next(e for e in m['entries'] if e['path'] == HELPER)
        require(git(root, 'hash-object', '--no-filters', str(root / HELPER)).decode().strip() == helper['oid'], 'Bootstrap helper differs from Git tree')
    disk(root, 2 * m['sourceBytes'] + 2 * RESERVE, 'restore-and-blob-population')
    # Inspect every canonical header/padding before any file is materialized.
    # Matching bytes, not tarfile's decoded view, rejects PAX, sparse, links,
    # duplicate names, unsafe paths, devices, and hidden trailing records.
    archive = bundle / 'source.tar'
    with archive.open('rb') as f:
        for e in m['entries']:
            require(f.read(512) == tar_header(e), 'Noncanonical or unexpected tar entry')
            f.seek(e['size'], 1)
            require(f.read((-e['size']) % 512) == b'\0' * ((-e['size']) % 512), 'Invalid tar padding')
        require(f.read() == b'\0' * 1024, 'Invalid tar trailer')
    staged = Path(tempfile.mkdtemp(prefix='.native-source-stage-', dir=root.parent))
    try:
        with archive.open('rb') as f:
            for e in m['entries']:
                require(f.read(512) == tar_header(e), 'Archive changed after inspection')
                path = staged / e['path']
                path.parent.mkdir(parents=True, exist_ok=True)
                digest = hashlib.sha256()
                blob = hashlib.sha1(f"blob {e['size']}\0".encode())
                remaining = e['size']
                with path.open('xb') as out:
                    while remaining:
                        chunk = f.read(min(CHUNK, remaining))
                        require(chunk, 'Truncated source bytes')
                        remaining -= len(chunk)
                        digest.update(chunk); blob.update(chunk); out.write(chunk)
                require(digest.hexdigest() == e['sha256'] and blob.hexdigest() == e['oid'], 'Source content hash mismatch')
                path.chmod(int(e['mode'][-3:], 8))
                require(f.read((-e['size']) % 512) == b'\0' * ((-e['size']) % 512), 'Archive padding changed')
            require(f.read() == b'\0' * 1024, 'Archive trailer changed')
        verified_seconds = time.monotonic() - started
        # Blobs are populated from verified staged bytes without filters/network.
        for e in m['entries']:
            require(git(root, 'hash-object', '-w', '--no-filters', str(staged / e['path'])).decode().strip() == e['oid'], 'Blob population mismatch')
        blob_seconds = time.monotonic() - started - verified_seconds
        require(identity(root, context) == m['source'], 'Checkout identity changed')
        git(root, 'config', 'core.sparseCheckout', 'false')
        git(root, 'config', 'core.sparseCheckoutCone', 'false')
        git(root, 'read-tree', '--reset', 'HEAD')
        names = b''.join(e['path'].encode() + b'\0' for e in m['entries'])
        git(root, 'update-index', '--no-skip-worktree', '-z', '--stdin', data=names)
        git(root, 'update-index', '--no-assume-unchanged', '-z', '--stdin', data=names)
        expected_index = b''.join(f"{e['mode']} {e['oid']} 0\t{e['path']}\0".encode() for e in m['entries'])
        # Git tree traversal and index order differ for a directory vs dotted file.
        require(sorted(git(root, 'ls-files', '--stage', '-z').split(b'\0')) == sorted(expected_index.split(b'\0')), 'Restored index mismatch')
        for name in existing:
            (root / name).unlink()
        # Only empty bootstrap ancestor directories remain, so file moves cannot overwrite inputs.
        for e in m['entries']:
            destination = root / e['path']
            destination.parent.mkdir(parents=True, exist_ok=True)
            require(not destination.exists(), 'Destination unexpectedly exists')
            os.rename(staged / e['path'], destination)
        git(root, 'update-index', '--refresh')
        clean(root)
        require(all(row[:1] == b'H' for row in git(root, 'ls-files', '-v', '-z').split(b'\0') if row), 'Sparse index flags remain')
        require(identity(root, context) == m['source'], 'Final source identity mismatch')
        # Required before prepared-project staging: do not retain a second 2GB copy.
        archive.unlink()
        result = dict(sourceBytes=m['sourceBytes'], archiveBytes=m['archiveBytes'], files=len(m['entries']),
                      verifySeconds=round(verified_seconds, 3), blobSeconds=round(blob_seconds, 3),
                      restoreSeconds=round(time.monotonic() - started, 3), freeBytes=shutil.disk_usage(root).free,
                      source=m['source'], archiveDeleted=True)
        print(json.dumps(result), flush=True)
        (bundle / 'restore-metrics.json').write_text(json.dumps(result, indent=2) + '\n')
        return result
    finally:
        shutil.rmtree(staged)


def prepared_disk(root, bundle):
    # Prepared transport contains individual uncompressed files. Existing restore
    # stages another full native project; reserve its checkout + payload plus 1GiB.
    def bytes_in(directory):
        total = 0
        for current, directories, files in os.walk(directory, followlinks=False):
            for name in directories + files:
                p = Path(current) / name
                require(not p.is_symlink(), 'Symlink in prepared disk inventory')
            total += sum((Path(current) / name).stat().st_size for name in files)
        return total
    disk(root, bytes_in(root / 'godot_native') + bytes_in(bundle) + RESERVE, 'prepared-project-staging')


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('command', choices=['capture', 'restore', 'download-disk', 'prepared-disk'])
    p.add_argument('--root', type=Path, required=True)
    p.add_argument('--bundle-dir', type=Path, required=True)
    p.add_argument('--head', default=os.environ.get('GITHUB_SHA', ''))
    p.add_argument('--base', default='')
    p.add_argument('--manifest-sha', default='')
    p.add_argument('--archive-sha', default='')
    p.add_argument('--source-bytes', type=int, default=0)
    args = p.parse_args()
    context = dict(repository=os.environ.get('GITHUB_REPOSITORY', ''), workflow=os.environ.get('GITHUB_WORKFLOW', ''),
                   event=os.environ.get('GITHUB_EVENT_NAME', ''), run=os.environ.get('GITHUB_RUN_ID', ''),
                   attempt=os.environ.get('GITHUB_RUN_ATTEMPT', ''), commit=os.environ.get('GITHUB_SHA', ''), head=args.head, base=args.base)
    if args.command == 'capture':
        capture(args.root, args.bundle_dir, context)
    elif args.command == 'restore':
        restore(args.root, args.bundle_dir, context, args.manifest_sha, args.archive_sha)
    elif args.command == 'download-disk':
        identity(args.root, context)
        require(0 < args.source_bytes <= MAX_BYTES, 'Invalid producer source byte bound')
        disk(args.root, 3 * args.source_bytes + 2 * RESERVE, 'source-download-and-restore')
    else:
        prepared_disk(safe_absolute(args.root), safe_absolute(args.bundle_dir))


if __name__ == '__main__':
    main()
