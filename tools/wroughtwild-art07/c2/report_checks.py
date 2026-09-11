"""Summarize only executed current suites and selected job records, preserving failures."""
import sys,json,re,hashlib
from pathlib import Path
root,out=[Path(p).resolve() for p in sys.argv[1:]];report={}
for folder in ['current-checks','adapter-current-checks']:
 rows=[]
 for p in sorted((root/folder).glob('*.log.job.json')):
  job=json.loads(p.read_text());log=Path(str(p)[:-9]);text=log.read_text();matches=re.findall(r'(\d+) checks, (\d+) failures',text)
  assert job['exit']==0 and len(matches)==1 and int(matches[0][1])==0,(p,matches)
  rows.append({'suite':log.stem,'checks':int(matches[0][0]),'failures':0,'pid':job['pid'],'seconds':job['seconds'],'job':str(p.relative_to(root))})
 assert len(rows)==14;report[folder]={'checks':sum(r['checks'] for r in rows),'jobs':rows}
lineage={}
for p in [root/'shellstone-generation-v01/source.glb',root/'shellstone-generation-v01/source_cutout.png',root/'shellstone-generation-v01/source_base.png',root/'kit-v05/c2-master.blend']:
 with p.open('rb') as f:h=hashlib.file_digest(f,'sha256').hexdigest()
 lineage[str(p.relative_to(root))]={'sha256':h,'bytes':p.stat().st_size}
report['selected_hashes']=lineage
out.write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:v['checks'] for k,v in report.items() if 'checks' in v}))
