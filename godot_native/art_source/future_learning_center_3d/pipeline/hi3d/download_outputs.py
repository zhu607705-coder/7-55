"""Preserve an existing completed task's output. Input JSON stays private (signed URLs).
Does not submit or retry any generation. Outputs contain provenance without access tokens.
"""
import argparse, base64, hashlib, json, pathlib, urllib.request
p=argparse.ArgumentParser();p.add_argument('result');p.add_argument('destination');args=p.parse_args()
r=json.loads(pathlib.Path(args.result).read_text());s=r['structuredContent']
if s.get('status')!='succeeded':raise SystemExit('Task must have succeeded')
d=pathlib.Path(args.destination);d.mkdir(parents=True,exist_ok=True)
for item in r.get('content',[]):
 if item.get('type')=='image':
  suffix={'image/webp':'.webp','image/png':'.png','image/jpeg':'.jpg'}[item['mimeType']]
  (d/('provider_preview'+suffix)).write_bytes(base64.b64decode(item['data']));break
receipt={'provider':'Hi3D','taskId':s['task_id'],'modelPage':s.get('model_page_url'),'actualPoints':s.get('actual_points'),'files':[]}
urls=[]
for a in s.get('assets',[]):
 if a.get('format','').upper()=='GLB' and a['url'] not in urls:urls.append(a['url'])
for i,url in enumerate(urls):
 dest=d/f'original_{i}.glb';part=dest.with_suffix('.glb.part')
 if not dest.exists():
  try:
   with urllib.request.urlopen(url,timeout=120) as response,part.open('wb') as f:
    size=0;last=0
    while block:=response.read(1024*1024):
     f.write(block);size+=len(block)
     if size-last>=16*1024*1024:print(dest.name,size,flush=True);last=size
   part.rename(dest)
  except Exception as e:raise SystemExit(f'Download failed for {dest.name}: {type(e).__name__}; no generation resubmitted')
 data=dest.read_bytes();receipt['files'].append({'file':dest.name,'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest()});print(dest.name,len(data),flush=True)
(d/'source_receipt.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n')
