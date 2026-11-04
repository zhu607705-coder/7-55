#!/usr/bin/env python3
"""Measure an existing verified source archive; never substitute acceptance."""
import argparse, hashlib, json, pathlib, resource, shutil, subprocess, threading, time

def digest(path):
    with path.open('rb') as f: return hashlib.file_digest(f, 'sha256').hexdigest()

def measure(bundle, output, budget=300):
    started = time.monotonic()
    archive = bundle / 'source.tar'
    manifest = json.loads((bundle / 'manifest.json').read_text())
    assert archive.stat().st_size == manifest['archiveBytes']
    expected = digest(archive)
    assert expected == manifest['archiveSha256']
    report = {'source': manifest['source'], 'sourceBytes': manifest['sourceBytes'], 'archiveBytes': archive.stat().st_size, 'archiveSha256': expected, 'results': [], 'scope': 'Measurement only; does not replace any source verification or acceptance gate.'}
    output.parent.mkdir(parents=True, exist_ok=True)
    def save():
        report['elapsedSeconds'] = round(time.monotonic()-started, 3)
        output.write_text(json.dumps(report, indent=2)+'\n')
    save()
    for name, compressor, decompressor in [
        ('gzip-1', ['gzip','-1','-n','-c'], ['gzip','-d','-c']),
        ('zstd-1', ['zstd','-1','-q','-c','-T1'], ['zstd','-d','-q','-c']),
        ('zstd-3', ['zstd','-3','-q','-c','-T1'], ['zstd','-d','-q','-c']),
        ('gzip-6', ['gzip','-6','-n','-c'], ['gzip','-d','-c'])]:
        row = {'mode': name}; report['results'].append(row)
        packed = bundle / ('measurement-'+name)
        try:
            if not shutil.which(compressor[0]):
                row['status']='unavailable'; continue
            remaining = budget-(time.monotonic()-started)
            if remaining < 20:
                row['status']='budget-exhausted'; continue
            t=time.monotonic(); cpu=resource.getrusage(resource.RUSAGE_CHILDREN)
            with packed.open('xb') as f:
                subprocess.run(compressor+[str(archive)], stdout=f, check=True, timeout=min(90,remaining-10))
            after_cpu=resource.getrusage(resource.RUSAGE_CHILDREN)
            row.update(compressCpuSeconds=round(after_cpu.ru_utime+after_cpu.ru_stime-cpu.ru_utime-cpu.ru_stime,3), compressSeconds=round(time.monotonic()-t,3), compressedBytes=packed.stat().st_size, ratio=round(packed.stat().st_size/archive.stat().st_size,6))
            # No extraction or path interpretation: write at most original bytes + 1.
            t=time.monotonic()
            process=subprocess.Popen(decompressor+[str(packed)],stdout=subprocess.PIPE)
            timer=threading.Timer(45, process.kill); timer.start()
            count=0; h=hashlib.sha256()
            try:
                while chunk:=process.stdout.read(1024*1024):
                    count+=len(chunk)
                    if count>archive.stat().st_size: raise ValueError('Roundtrip exceeds archive bound')
                    h.update(chunk)
                    if time.monotonic()-t>45: raise TimeoutError('Roundtrip time bound')
                assert process.wait(timeout=5)==0
            finally:
                timer.cancel()
                if process.poll() is None: process.kill(); process.wait()
                process.stdout.close()
            assert count==archive.stat().st_size and h.hexdigest()==expected
            row.update(decompressSeconds=round(time.monotonic()-t,3), roundtripSha256=h.hexdigest(), roundtripBytes=count, status='verified')
        except (subprocess.SubprocessError, TimeoutError) as e:
            row.update(status='measurement-timeout-or-process-error', error=type(e).__name__)
        finally:
            if packed.exists(): packed.unlink()
            save()
    return report

if __name__=='__main__':
    p=argparse.ArgumentParser(); p.add_argument('--bundle',type=pathlib.Path,required=True); p.add_argument('--output',type=pathlib.Path,required=True)
    args=p.parse_args(); print(json.dumps(measure(args.bundle,args.output),indent=2))
