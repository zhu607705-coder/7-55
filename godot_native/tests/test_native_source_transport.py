#!/usr/bin/env python3
"""Executable synthetic transport tests; no hosted speed or gameplay claims."""
import hashlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location('transport', Path(__file__).parents[1] / 'tools/native_source_transport.py')
t = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(t)


class Transport(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='native-source-test-')
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.src = self.base / 'source'; self.src.mkdir()
        self.files = {'plain.txt': b'original\n', '.hidden': b'hidden\n', 'art_source/.gdignore': b'',
                      'art_source/model.bin': bytes(range(256)) * 4096,
                      'script.sh': b'#!/bin/sh\nexit 0\n', t.HELPER: Path(t.__file__).read_bytes(),
                      'space name.txt': b'space\n', '"quoted".txt': b'quote\n',
                      '中文/é "quoted" file.txt': b'unicode\n', '-leading-option': b'option\n',
                      'long/' + 'directory/' * 14 + 'file.txt': b'long path\n'}
        for name, data in self.files.items():
            p = self.src / name; p.parent.mkdir(parents=True, exist_ok=True); p.write_bytes(data)
            p.chmod(0o755 if name == 'script.sh' else 0o644)
        t.git(self.src, 'init', '-q')
        t.git(self.src, 'config', 'user.name', 'Fixture')
        t.git(self.src, 'config', 'user.email', 'fixture@example.invalid')
        t.git(self.src, 'add', '.')
        t.git(self.src, 'commit', '-qm', 'fixture')
        self.context = dict(repository='fixture/repo', workflow='Native validation', event='pull_request', run='123', attempt='1',
                            head='a'*40, base='b'*40, commit=t.git(self.src, 'rev-parse', 'HEAD').decode().strip())
        self.bundle = self.base / 'bundle'
        self.receipt = t.capture(self.src, self.bundle, self.context)
        self.dst = self.base / 'consumer'; self.dst.mkdir()
        t.git(self.dst, 'init', '-q')
        ids = t.git(self.src, 'rev-list', '--objects', '--filter=blob:none', 'HEAD')
        ids = b'\n'.join(row.split(b' ')[0] for row in ids.splitlines()) + b'\n'
        t.git(self.dst, 'unpack-objects', '-q', data=t.git(self.src, 'pack-objects', '--stdout', data=ids))
        t.git(self.dst, 'update-ref', '--no-deref', 'HEAD', self.context['commit'])
        t.git(self.dst, 'read-tree', 'HEAD')
        # Model non-cone sparse bootstrap with only the exact helper blob.
        p = self.dst / t.HELPER; p.parent.mkdir(parents=True); p.write_bytes(self.files[t.HELPER])
        t.git(self.dst, 'hash-object', '-w', '--no-filters', str(p))
        t.git(self.dst, 'config', 'core.sparseCheckout', 'true')
        (self.dst / '.git/info/sparse-checkout').write_text('/' + t.HELPER + '\n')
        names = b'\0'.join(name.encode() for name in self.files if name != t.HELPER) + b'\0'
        t.git(self.dst, 'update-index', '--skip-worktree', '-z', '--stdin', data=names)

    def restore(self, context=None, producer_attempt='1'):
        return t.restore(self.dst, self.bundle, context or self.context, self.receipt['manifest_sha'], self.receipt['archive_sha'], producer_attempt)

    def resign(self, mutate=None):
        p = self.bundle / 'manifest.json'; m = json.loads(p.read_text())
        if mutate:
            mutate(m)
        m['archiveSha256'] = t.sha256(self.bundle / 'source.tar')
        p.write_text(json.dumps(m))
        self.receipt['manifest_sha'] = t.sha256(p)
        self.receipt['archive_sha'] = m['archiveSha256']

    def assertRejected(self):
        before = (self.dst / t.HELPER).read_bytes()
        with self.assertRaises((ValueError, KeyError, TypeError)):
            self.restore()
        self.assertEqual((self.dst / t.HELPER).read_bytes(), before)
        self.assertFalse((self.dst / 'plain.txt').exists())
        self.assertFalse(list(self.base.glob('.native-source-stage-*')))

    def test_roundtrip_full_git_semantics_no_network(self):
        # No remote is configured; all Git reads after restore must be local.
        result = self.restore()
        self.assertEqual(result['files'], len(self.files))
        self.assertFalse((self.bundle / 'source.tar').exists())
        for name, data in self.files.items():
            self.assertEqual((self.dst / name).read_bytes(), data)
            self.assertEqual(t.git(self.dst, 'show', 'HEAD:' + name), data)
        for command in [('rev-parse', 'HEAD', 'HEAD^{tree}'), ('ls-files', '--stage', '-z'), ('ls-files', '-z'),
                        ('status', '--porcelain'), ('diff', 'HEAD')]:
            self.assertEqual(t.git(self.src, *command), t.git(self.dst, *command))
        self.assertEqual((self.dst / 'script.sh').stat().st_mode & 0o777, 0o755)
        (self.dst / 'generated.bin').write_text('generated')
        self.assertNotIn(b'generated.bin', t.git(self.dst, 'ls-files', '-z'))
        (self.dst / 'plain.txt').write_text('changed')
        self.assertIn(b'changed', t.git(self.dst, 'diff', 'HEAD'))

    def test_rerun_restores_exact_explicit_producer(self):
        result = self.restore(dict(self.context, attempt='2'))
        self.assertEqual(result['source'], t.identity(self.src, self.context))
        self.assertEqual((self.dst / 'plain.txt').read_bytes(), self.files['plain.txt'])

    def test_rerun_rejects_unbound_wrong_and_future_producer(self):
        for producer in ['', None, '0', '-1', '01', 'wrong', '2', '3']:
            with self.subTest(producer=producer), self.assertRaises(ValueError):
                self.restore(dict(self.context, attempt='2'), producer)
        self.assertFalse((self.dst / 'plain.txt').exists())

    def test_rerun_keeps_run_source_and_hash_binding(self):
        retry = dict(self.context, attempt='2')
        for field, value in [('run', '124'), ('head', 'c'*40), ('base', 'c'*40),
                             ('commit', 'c'*40), ('repository', 'other/repo'),
                             ('workflow', 'other'), ('event', 'push')]:
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.restore(dict(retry, **{field: value}))
        for field in ['manifest_sha', 'archive_sha']:
            saved = self.receipt[field]
            self.receipt[field] = '0'*64
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.restore(retry)
            self.receipt[field] = saved
        self.resign(lambda m: m['source'].update(tree='c'*40))
        with self.assertRaises(ValueError):
            self.restore(retry)
        self.assertFalse((self.dst / 'plain.txt').exists())

    def test_wrong_provenance_all_fields(self):
        for field in self.context:
            with self.subTest(field=field):
                context = dict(self.context); context[field] = ('c'*40 if field in ('head', 'base', 'commit') else 'wrong')
                with self.assertRaises(ValueError):
                    self.restore(context)
        self.resign(lambda m: m['source'].update(tree='c'*40))
        self.assertRejected()

    def test_blob_population_uses_one_batch_with_exact_ordered_oids(self):
        original = t.git
        with patch.object(t, 'git', wraps=original) as calls:
            self.restore()
        writes = [call for call in calls.call_args_list if call.args[1:3] == ('hash-object', '-w')]
        self.assertEqual(len(writes), 1)
        self.assertEqual(writes[0].args[1:], ('hash-object', '-w', '--no-filters', '--stdin-paths'))
        paths = [json.loads(line) for line in writes[0].kwargs['data'].decode('utf-8').splitlines()]
        entries = t.tree_entries(self.dst)
        self.assertEqual(len(paths), len(entries))
        staged = Path(paths[0]).parents[len(Path(entries[0]['path']).parts) - 1]
        self.assertEqual([str(Path(p).relative_to(staged)) for p in paths],
                         [e['path'] for e in entries])

    def test_blob_batch_rejects_missing_extra_reordered_and_wrong_oids(self):
        original = t.git
        entries = t.tree_entries(self.dst)
        expected = b''.join(e['oid'].encode() + b'\n' for e in entries)
        rows = expected.splitlines(keepends=True)
        for bad in [b'', b''.join(rows[:-1]), expected + rows[0],
                    b''.join(reversed(rows)), b'0'*40 + b'\n' + b''.join(rows[1:])]:
            def changed(root, *args, **kwargs):
                if args[:2] == ('hash-object', '-w'):
                    return bad
                return original(root, *args, **kwargs)
            with self.subTest(output=bad[:41]), patch.object(t, 'git', side_effect=changed):
                self.assertRejected()

    def test_manifest_digest_mismatch(self):
        self.receipt['manifest_sha'] = '0'*64
        self.assertRejected()

    def test_archive_digest_mismatch(self):
        self.receipt['archive_sha'] = '0'*64
        self.assertRejected()

    def test_manifest_tree_disagreement(self):
        self.resign(lambda m: m['entries'][0].update(oid='0'*40))
        self.assertRejected()

    def test_size_bomb(self):
        self.resign(lambda m: m['entries'][0].update(size=t.MAX_BYTES+1))
        self.assertRejected()

    def test_tampered_content_even_with_resigned_archive(self):
        archive = self.bundle / 'source.tar'
        with archive.open('r+b') as f:
            f.seek(512); f.write(b'X')
        self.resign()
        self.assertRejected()

    def test_missing_extra_truncated_duplicate_records(self):
        archive = self.bundle / 'source.tar'; original = archive.read_bytes()
        for bad in [original[:-1], original + b'\0'*512, original[1024:], original[:1024] + original]:
            with self.subTest(bytes=len(bad)):
                archive.write_bytes(bad); self.resign(); self.assertRejected()

    def test_reject_every_unsafe_tar_header(self):
        archive = self.bundle / 'source.tar'; original = archive.read_bytes()
        m = json.loads((self.bundle / 'manifest.json').read_text()); e = m['entries'][0]
        for label, name, typ in [('traversal','../outside',tarfile.REGTYPE),('absolute','/outside',tarfile.REGTYPE),
                                ('git','.git/config',tarfile.REGTYPE),('backslash','a\\b',tarfile.REGTYPE),
                                ('dot','a/./b',tarfile.REGTYPE),('control','a\nb',tarfile.REGTYPE),
                                ('symlink',e['path'],tarfile.SYMTYPE),('hardlink',e['path'],tarfile.LNKTYPE),
                                ('device',e['path'],tarfile.CHRTYPE),('fifo',e['path'],tarfile.FIFOTYPE),
                                ('sparse',e['path'],tarfile.GNUTYPE_SPARSE),('pax',e['path'],tarfile.XHDTYPE),
                                ('mode',e['path'],tarfile.REGTYPE),('extra','not-tracked',tarfile.REGTYPE)]:
            with self.subTest(label=label):
                info = tarfile.TarInfo(name); info.type=typ; info.size=e['size']; info.mode=0o755
                header = info.tobuf(format=tarfile.USTAR_FORMAT)
                archive.write_bytes(header + original[512:]); self.resign(); self.assertRejected()

    def test_bad_padding_and_trailer(self):
        archive = self.bundle / 'source.tar'; original = archive.read_bytes()
        for offset in [512+len(self.files['.hidden']), len(original)-1]:
            data = bytearray(original); data[offset] = 1
            archive.write_bytes(data); self.resign(); self.assertRejected()

    def test_disk_checks_fail_closed_without_materialization(self):
        with patch.object(t.shutil, 'disk_usage', return_value=shutil._ntuple_diskusage(1,1,0)):
            self.assertRejected()

    def test_interruption_keeps_bootstrap_and_cleans_staging(self):
        original_git=t.git
        def interrupted(root, *args, **kw):
            if args[:2] == ('hash-object', '-w'):
                raise KeyboardInterrupt('synthetic interruption')
            return original_git(root, *args, **kw)
        with patch.object(t, 'git', side_effect=interrupted):
            with self.assertRaises(KeyboardInterrupt):
                self.restore()
        self.assertEqual((self.dst / t.HELPER).read_bytes(), self.files[t.HELPER])
        self.assertFalse((self.dst / 'plain.txt').exists())
        self.assertFalse(list(self.base.glob('.native-source-stage-*')))

    def test_capture_rejects_dirty_content_and_executable_mode(self):
        for path in ['plain.txt', 'script.sh']:
            with self.subTest(path=path):
                file=self.src/path
                if path=='plain.txt': file.write_text('bad')
                else: file.chmod(0o644)
                with self.assertRaises(ValueError): t.capture(self.src,self.base/'bad',self.context)
                file.write_bytes(self.files[path]); file.chmod(0o755 if path=='script.sh' else 0o644)

    def test_capture_change_during_read_rejected(self):
        original_header=t.tar_header
        def changed(e):
            if e['path']=='plain.txt': (self.src/'plain.txt').write_bytes(b'different')
            return original_header(e)
        with patch.object(t,'tar_header',side_effect=changed):
            with self.assertRaises(ValueError): t.capture(self.src,self.base/'bad',self.context)
        self.assertFalse((self.base/'bad').exists())

    def test_capture_excludes_untracked_secrets_and_git(self):
        (self.src / 'untracked-secret').write_text('not a real credential')
        bundle=self.base/'second';t.capture(self.src,bundle,self.context)
        with tarfile.open(bundle/'source.tar') as archive:
            self.assertEqual(set(archive.getnames()),set(self.files))
        self.assertNotIn(b'not a real credential',(bundle/'source.tar').read_bytes())

    def test_bootstrap_mismatch_and_nonfresh_checkout(self):
        (self.dst/t.HELPER).write_text('tampered')
        self.assertRejected()
        (self.dst/t.HELPER).write_bytes(self.files[t.HELPER])
        (self.dst/'unexpected').write_text('do not overwrite')
        self.assertRejected()

    def test_symlink_ancestor_rejected(self):
        link=self.base/'link';link.symlink_to(self.dst, target_is_directory=True)
        with self.assertRaises(ValueError): t.restore(link,self.bundle,self.context,self.receipt['manifest_sha'],self.receipt['archive_sha'],'1')

    def test_tree_rejects_symlinks_gitlinks_and_case_collision(self):
        original=t.git
        for rows in [b'120000 blob '+b'a'*40+b'\tlink\0',b'160000 commit '+b'a'*40+b'\tsubmodule\0',
                     b'100644 blob '+b'a'*40+b'\tName\0'+b'100644 blob '+b'b'*40+b'\tname\0']:
            with patch.object(t,'git',return_value=rows):
                with self.assertRaises(ValueError): t.tree_entries(self.dst)


if __name__=='__main__':
    unittest.main(verbosity=2)

