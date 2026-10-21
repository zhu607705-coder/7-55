#!/usr/bin/env python3
"""Rebuild licensed, true-weight coverage companions; never replace locked preview faces."""
import argparse, hashlib, io, json
from pathlib import Path
import fontTools
from fontTools import subset
from fontTools.ttLib import TTFont
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'godot_native/ui_assets/fonts'
SHAS = {'Regular':'b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a', 'Bold':'faa5f3656a78b2e2d450d27fe8382c778bc2b6bb5ea29c986664a6a435056ceb'}
def digest(b): return hashlib.sha256(b).hexdigest()
def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--source-dir',type=Path,required=True);p.add_argument('--check',action='store_true');a=p.parse_args()
    assert fontTools.__version__ == '4.61.1'
    # Keep exact preview primaries untouched; companions cover their union with
    # the old game subset and current authored native CJK, including JSON escapes.
    inputs=['CampusUISans-Regular.otf','SelectedSans-Regular.otf','SelectedSans-Bold.otf']
    cps=set(); hashes={}
    for name in inputs:
        raw=(OUT/name).read_bytes();hashes[name]=digest(raw);cps.update(TTFont(io.BytesIO(raw)).getBestCmap())
    runtime_cjk=set()
    for root in ['godot_native/scripts','godot_native/data/native']:
        for source in sorted((ROOT/root).rglob('*')):
            if not source.is_file() or source.suffix not in {'.gd','.json'}:continue
            text=source.read_text()
            if source.suffix=='.json':text=json.dumps(json.loads(text),ensure_ascii=False)
            runtime_cjk.update(ord(c) for c in text if 0x3400<=ord(c)<=0x9fff or 0x20000<=ord(c)<=0x3134f)
    cps.update(runtime_cjk)
    report={'tool':'fonttools '+fontTools.__version__,'coverage_inputs':hashes,
            'runtime_cjk_count':len(runtime_cjk),'runtime_cjk_sha256':digest(','.join(map(str,sorted(runtime_cjk))).encode()),'faces':[]}
    for weight,expected in SHAS.items():
        src=a.source_dir/('NotoSansCJK-'+weight+'.ttc');raw=src.read_bytes();assert digest(raw)==expected
        f=TTFont(src,fontNumber=2,recalcTimestamp=False);assert f['name'].getDebugName(1)=='Noto Sans CJK SC'
        assert f['OS/2'].usWeightClass==(400 if weight=='Regular' else 700)
        present=cps & f.getBestCmap().keys();assert len(present)==len(cps)
        o=subset.Options();o.recalc_timestamp=False;o.canonical_order=True;o.name_IDs=['*'];o.name_legacy=True;o.name_languages=['*'];o.layout_features=['*']
        worker=subset.Subsetter(options=o);worker.populate(unicodes=sorted(present));worker.subset(f)
        family='Selected UI Coverage';ps='SelectedUICoverage-'+weight
        names={1:family,2:weight,3:ps+'-1.0',4:family+' '+weight,6:ps,16:family,17:weight,18:family+' '+weight,21:family,22:weight}
        for entry in f['name'].names:
            if entry.nameID in names:entry.string=names[entry.nameID].encode(entry.getEncoding())
        for key,val in names.items():f['name'].setName(val,key,3,1,0x409)
        cff=f['CFF '].cff;cff.fontNames=[ps];top=cff.topDictIndex[0];top.FamilyName=family;top.FullName=family+' '+weight
        if hasattr(top,'FDArray'):
            for i,fd in enumerate(top.FDArray):fd.FontName=f'{ps}-FD{i}'
        b=io.BytesIO();f.save(b,reorderTables=True);data=b.getvalue();name='SelectedCoverage-'+weight+'.otf'
        assert set(present).issubset(TTFont(io.BytesIO(data)).getBestCmap())
        report['faces'].append({'file':name,'sha256':digest(data),'source':src.name,'source_sha256':expected,'source_face':2,'weight':f['OS/2'].usWeightClass,'codepoints':len(present)})
        if a.check:assert (OUT/name).read_bytes()==data,name
        else:(OUT/name).write_bytes(data)
    data=(json.dumps(report,indent=2)+'\n').encode();name='selected_coverage_manifest.json'
    if a.check:assert (OUT/name).read_bytes()==data,name
    else:(OUT/name).write_bytes(data)
    print('Selected coverage companions: true 400/700, source hashes and '+str(len(cps))+' glyph mappings verified')
if __name__=='__main__':main()
