#!/usr/bin/env python3
"""Build FLC-only Noto SC coverage; preserve historical fonts and Morning Note inputs."""
import argparse, hashlib, io, json
from pathlib import Path
import fontTools
from fontTools import subset
from fontTools.ttLib import TTFont
ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / 'godot_native'
FLC = PROJECT / 'campuses/future_learning_center'
FONT = FLC / 'assets/fonts/flc_coverage_regular.otf'
MANIFEST = FONT.with_suffix('.json')
SOURCE_SHA = 'b76b0433203017ca80401b2ee0dd69350349871c4b19d504c34dbdd80541690a'
BASE_SHA = 'b6ad88f4e3cefd19983153f1215f770fc3751028e4a98fb47107dde11741784a'
def digest(data): return hashlib.sha256(data).hexdigest()
def characters():
    result = set()
    for directory in [FLC / 'scripts', FLC / 'data']:
        for file in sorted(directory.rglob('*')):
            if not file.is_file() or file.suffix not in {'.gd', '.json'}: continue
            text = file.read_text()
            if file.suffix == '.json': text = json.dumps(json.loads(text), ensure_ascii=False)
            result.update(ord(c) for c in text if 0x3400 <= ord(c) <= 0x9fff or 0x20000 <= ord(c) <= 0x3134f)
    return result

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', type=Path, required=True)
    parser.add_argument('--check', action='store_true')
    args = parser.parse_args()
    assert fontTools.__version__ == '4.61.1'
    assert digest(args.source.read_bytes()) == SOURCE_SHA
    baseline = (PROJECT / 'ui_assets/fonts/SelectedCoverage-Regular.otf').read_bytes()
    assert digest(baseline) == BASE_SHA, 'Historical Morning Note source must stay unchanged'
    prior = set(TTFont(io.BytesIO(baseline)).getBestCmap())
    authored = characters(); required = prior | authored
    face = TTFont(args.source, fontNumber=2, recalcTimestamp=False)
    assert face['name'].getDebugName(1) == 'Noto Sans CJK SC' and face['OS/2'].usWeightClass == 400
    assert required <= face.getBestCmap().keys()
    options = subset.Options(); options.recalc_timestamp=False; options.canonical_order=True
    options.name_IDs=['*']; options.name_legacy=True; options.name_languages=['*']; options.layout_features=['*']
    worker=subset.Subsetter(options=options);worker.populate(unicodes=sorted(required));worker.subset(face)
    family='FLC UI Coverage'; ps='FLCUICoverage-Regular'
    names={1:family,2:'Regular',3:ps+'-1.0',4:family+' Regular',6:ps,16:family,17:'Regular',18:family+' Regular',21:family,22:'Regular'}
    for entry in face['name'].names:
        if entry.nameID in names: entry.string=names[entry.nameID].encode(entry.getEncoding())
    for key,value in names.items():face['name'].setName(value,key,3,1,0x409)
    cff=face['CFF '].cff;cff.fontNames=[ps];top=cff.topDictIndex[0];top.FamilyName=family;top.FullName=family+' Regular'
    if hasattr(top,'FDArray'):
        for i,fd in enumerate(top.FDArray):fd.FontName=f'{ps}-FD{i}'
    output=io.BytesIO();face.save(output,reorderTables=True);data=output.getvalue()
    assert required <= TTFont(io.BytesIO(data)).getBestCmap().keys()
    report={'tool':'fonttools '+fontTools.__version__,'source':args.source.name,'source_sha256':SOURCE_SHA,'source_face':2,'weight':400,'historical_coverage_sha256':BASE_SHA,'authored_cjk_sha256':digest(','.join(map(str,sorted(authored))).encode()),'added_characters':''.join(map(chr,sorted(required-prior))),'codepoints':len(required),'sha256':digest(data),'license':'res://ui_assets/fonts/SELECTED_NOTO_LICENSE.txt'}
    metadata=(json.dumps(report,ensure_ascii=False,indent=2)+'\n').encode()
    if args.check: assert FONT.read_bytes()==data and MANIFEST.read_bytes()==metadata
    else: FONT.parent.mkdir(parents=True,exist_ok=True);FONT.write_bytes(data);MANIFEST.write_bytes(metadata)
    print(f'PASS FLC coverage: {len(required)} mappings, {len(required-prior)} additions; historical font unchanged')
if __name__=='__main__':main()
