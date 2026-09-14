"""Copy selected full frames and encode timestamped engine samples; no image synthesis."""
import hashlib,json,shutil
from pathlib import Path
from PIL import Image
ROOT=Path(__file__).resolve().parents[3];B=ROOT/'build/art07-repairs/r5';BASE=B/'v01';C=B/'v02'
OUT=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r5'
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.file_digest(p.open('rb'),'sha256').hexdigest()
def write(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
assert not OUT.exists();OUT.mkdir(parents=True);images=[];motion=[];jobs=[];costs=[]
def select(src,name):
 dst=OUT/name;shutil.copy2(src,dst);assert sha(src)==sha(dst)
 with Image.open(dst) as im:size=list(im.size)
 images.append({'file':name,'source':src.relative_to(ROOT).as_posix(),'sha256':sha(dst),'dimensions':size,'processing':'Byte-exact PNG copy; no crop, resize, retouch or compositing.'})
for name in ['wood-closed','wood-open','iron-open']:select(C/'reopen-v02'/(name+'.png'),'source-'+name+'.png')
for backend in ['forward_plus','gl_compatibility']:
 for version,label in [(BASE,'baseline06'),(C,'candidate')]:
  folder=version/'evidence'/(label+'-capture-'+backend)
  for name in ['flat-wood-closed','ordinary-slab-closed','fine-slab-closed']:
   select(folder/(name+'.png'),label+'-'+backend+'-'+name+'.png')
  if backend=='forward_plus':
   for name in ['back-wall-open','low-ceiling-open','ordinary-slab-open']:
    select(folder/(name+'.png'),label+'-'+backend+'-'+name+'.png')
 for version,label in [(BASE,'baseline05'),(C,'candidate')]:
  if backend=='forward_plus':
   for name in ['original-paid-home-closed','retained-terrain-1-closed']:
    select(version/'evidence'/(label+'-terrain-'+backend)/(name+'.png'),label+'-'+backend+'-'+name+'.png')
 folder=C/'evidence'/('candidate-capture-'+backend);report=read(folder/'report.json');records=report['motion_frames'];frames=[];durations=[]
 for i,row in enumerate(records):
  source=folder/row['image'];im=Image.open(source).convert('RGB');assert im.size==(1440,900)
  frames.append(im.convert('P',palette=Image.Palette.ADAPTIVE,colors=256))
  dt=(records[i+1]['capture_usec']-row['capture_usec'])/1000 if i+1<len(records) else (row['capture_usec']-records[i-1]['capture_usec'])/1000
  durations.append(max(10,round(dt/10)*10))
  row={**row,'source':source.relative_to(ROOT).as_posix(),'sha256':sha(source),'gif_duration_ms':durations[-1]};motion.append({'renderer':backend,**row})
 dest=OUT/('candidate-'+backend+'-opening.gif');frames[0].save(dest,save_all=True,append_images=frames[1:],duration=durations,loop=0,optimize=False,disposal=2)
 with Image.open(dest) as test:assert test.n_frames==len(records) and test.size==(1440,900)
 images.append({'file':dest.name,'sha256':sha(dest),'dimensions':[1440,900],'frames':len(records),'duration_ms':sum(durations),'processing':'Actual engine PNG samples, native panel-driven lid; full-frame GIF palette conversion only; captured wall-clock durations rounded to GIF 10 ms units; final sample held for preceding interval. Loop resets to first sample; no reverse or invented closing. Capture stalls affect wall-clock sampling. First sample is already partway open.'})
 for version,label in [(BASE,'baseline02'),(C,'candidate')]:
  r=read(version/'evidence'/(label+'-benchmark-'+backend)/'report.json');assert r['failures']==0
  costs.append({'variant':label,'renderer':backend,**r['benchmark']})
for version,label,names in [(BASE,'baseline',['import','smoke-forward_plus','smoke-gl_compatibility']+[f'{tag}-{mode}-{b}' for b in ['forward_plus','gl_compatibility'] for tag,mode in [('baseline06','capture'),('baseline02','restore'),('baseline02','benchmark'),('baseline05','terrain')]]),(C,'candidate',['blender-fit','blender-reopen-v02','import','smoke-forward_plus','smoke-gl_compatibility']+['candidate-'+mode+'-'+b for b in ['forward_plus','gl_compatibility'] for mode in ['capture','restore','benchmark','terrain']])]:
 for name in names:
  record=read(version/'logs'/(name+'.log.json'));assert record['exit_code']==0 and not record['failure']
  log=version/'logs'/(name+'.log');assert sha(log)==record['log_sha256']
  report=version/'evidence'/name/'report.json';checks=None
  if report.exists():
   r=read(report);assert r['failures']==0;checks=len(r['checks']) if isinstance(r['checks'],list) else r['checks']
  diagnostics=[line for line in log.read_text(encoding='utf-8-sig',errors='replace').splitlines() if any(s in line.lower() for s in ['warning:','error:','leaked','orphan'])]
  jobs.append({'variant':label,'id':name,'log':log.relative_to(ROOT).as_posix(),'checks':checks,'diagnostics':diagnostics,**record})
write(OUT/'provenance.json',{'images':images,'motion_frames':motion})
write(OUT/'results.json',{'jobs':jobs,'costs':costs,'audit':read(C/'audit.json'),'hardware':read(BASE/'preflight/hardware.json'),'source_reopen':read(C/'reopen-v02/reopen.json'),'fit':read(ROOT/'tools/wroughtwild-art07-repairs/r5/fit.json')})
print('R5_CURATED',len(images),'artifacts;',len(motion),'real motion samples;',len(jobs),'successful recorded jobs')
