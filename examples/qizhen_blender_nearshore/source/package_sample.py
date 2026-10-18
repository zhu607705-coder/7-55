"""Create a clean portable source bundle. Excludes caches, auth, recordings and old reports."""
from pathlib import Path
import hashlib,json,zipfile,shutil
BASE=Path(__file__).resolve().parents[1]
PREVIEW=BASE/'preview'
OLD=BASE.parent/'lake-input-camera-20261018/source/7-55_Qizhen_LargeWorld_Prototype'
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
# Keep historical audit records explicitly separated from this revision's evidence.
docs=PREVIEW/'docs';history=docs/'baseline_reports';history.mkdir(exist_ok=True)
keep={'ASSET_PROVENANCE.json','REFERENCE_AND_SCOPE.md','REFERENCE_GEOMETRY.json','BLENDER_SAMPLE_TECHNICAL.md','BASELINE_README.md'}
for p in list(docs.iterdir()):
 if p.is_file() and p.name not in keep:
  target=history/p.name
  if not target.exists():p.rename(target)
basefiles=[]
for folder in ['assets/paddling','assets/native','assets/rpg','assets/licenses']:
 for p in sorted((PREVIEW/folder).rglob('*')):
  if p.is_file() and p.suffix!='.import':
   rel=p.relative_to(PREVIEW).as_posix();original=OLD/rel
   basefiles.append({'file':rel,'source':'Approved PR147 input-camera large-world baseline / '+rel,'sha256':sha(p),'matches_source':original.exists() and sha(original)==sha(p)})
for rel in ['scripts/presentation/kayak_rig.gd','scripts/presentation/kayak_stroke_timeline.gd','scripts/presentation/qizhen_swan_swim_visual.gd','scripts/games/lake_geometry.gd']:
 p=PREVIEW/rel;basefiles.append({'file':rel,'source':'Approved PR147 input-camera large-world baseline / '+rel,'sha256':sha(p),'matches_source':sha(OLD/rel)==sha(p)})
assert all(f['matches_source'] for f in basefiles)
newfiles=[]
for p in sorted((PREVIEW/'assets/blender').glob('*')):
 if p.is_file() and p.suffix!='.import':newfiles.append({'file':p.relative_to(PREVIEW).as_posix(),'sha256':sha(p),'origin':'Authored for this sample; Blender script / shore-style bake or Godot GLB import extraction'})
provenance={'scope':'Original pixel actors/strokes/font copied unchanged from the PR147 input-camera baseline; new procedural Blender/GLB scenery and boat added in this independent sample.','unchanged_baseline_assets':basefiles,'new_authored_assets':newfiles,'editable_source':{'file':'../source/qizhen_north_bank.blend','sha256':sha(BASE/'source/qizhen_north_bank.blend'),'rebuild':['../source/build_lake_sample.py','../source/build_shore_distance.py']},'third_party_models_or_stock_textures':False,'font_license':'assets/licenses/FUSION_PIXEL_FONT_OFL.txt','reference_images_redistributed':False,'reference_links':['https://www.zju.edu.cn/2018/0410/c32747a1513553/page.psp','https://hr.zju.edu.cn/cn/2024/0517/c29598a2918345/page.htm','https://www.zju.edu.cn/2023/0324/c75118a2732446/pagem.htm'],'scope_warning':'Dock dimensions, attachment, facades, vegetation, path details and shallow-water styling are game adaptations, not measured/current reality.'}
(docs/'ASSET_PROVENANCE.json').write_text(json.dumps(provenance,ensure_ascii=False,indent=2))
# Freeze latest regression and captured-input evidence alongside portable source.
for name in ['capture-result.json']:
 p=BASE/'outputs'/name
 if p.exists():shutil.copy2(p,BASE/'verification'/name)
for name in ['test-blender-sample.log','test-sample-route.log','capture-final.log']:
 p=BASE/'outputs'/name
 if p.exists():shutil.copy2(p,BASE/'verification'/name)
for p in (BASE/'runtime/review-results').glob('*.log'):shutil.copy2(p,BASE/'verification'/('original-'+p.name))
project_files=[]
for top in ['assets','scripts','scenes']:
 project_files += [p for p in (PREVIEW/top).rglob('*') if p.is_file() and p.suffix!='.import']
project_files += [PREVIEW/'project.godot',PREVIEW/'README.md',PREVIEW/'打开说明.txt']
project_files += [docs/n for n in keep if (docs/n).exists()]
project_files += [p for p in (PREVIEW/'tests').glob('*') if p.is_file() and p.suffix in ['.gd','.uid']]
manifest={'basis':'Freshly frozen Blender nearshore sample; caches/import metadata excluded.','files':{p.relative_to(PREVIEW).as_posix():sha(p) for p in sorted(project_files)}}
(PREVIEW/'SOURCE_SHA256.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2))
files=project_files+[PREVIEW/'SOURCE_SHA256.json',BASE/'README.md',BASE/'ASSET_LICENSES.md',BASE/'render.sh',BASE/'xorg.conf']
files += [p for p in (BASE/'source').glob('*') if p.suffix in ['.py','.blend']]
files += [p for p in (BASE/'verification').glob('*') if p.is_file() and p.name!='files.json']
# Runtime directory is intentionally empty of auth/cache/history.
runtime_readme=BASE/'runtime/README.txt';runtime_readme.write_text('This directory is reserved for local generated test output. No authentication or cache files are included in the source package.\n');files.append(runtime_readme)
full={p.relative_to(BASE).as_posix():sha(p) for p in sorted(set(files))}
(BASE/'verification/files.json').write_text(json.dumps(full,ensure_ascii=False,indent=2));files.append(BASE/'verification/files.json')
zipname=BASE/'outputs/7-55_Qizhen_Blender_Nearshore_Source.zip'
with zipfile.ZipFile(zipname,'w',zipfile.ZIP_DEFLATED,compresslevel=8) as z:
 for p in sorted(set(files)):z.write(p,'7-55_Qizhen_Blender_Nearshore/'+p.relative_to(BASE).as_posix())
print(json.dumps({'zip':str(zipname),'bytes':zipname.stat().st_size,'files':len(set(files)),'unchanged_baseline_files':len(basefiles),'source_sha256':sha(PREVIEW/'SOURCE_SHA256.json')},ensure_ascii=False))
