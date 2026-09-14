import shutil
from common import *
guard()
for name in ['audit.gd','views.gd']:
    shutil.copy2(TOOLS/name,GAME/'r7'/name)
(GAME/'r7/views.tscn').write_text((GAME/'g1/review.tscn').read_text().replace('res://g1/review.gd','res://r7/views.gd'))
# Retain R1's paid fixture fixes and every original native assertion; redirect only disposable output.
paid=(GAME/'r1/paid.gd').read_text().replace('res://r1/replayed-paid-home.json','res://r7/replayed-paid-home.json')
(GAME/'r7/paid.gd').write_text(paid)
(GAME/'r7/paid.tscn').write_text((GAME/'g1/paid.tscn').read_text().replace('res://g1/paid.gd','res://r7/paid.gd'))
route=(GAME/'r1/route.gd').read_text().replace('res://r1/paid.gd','res://r7/paid.gd')
(GAME/'r7/route.gd').write_text(route)
(GAME/'r7/route.tscn').write_text((GAME/'g1/walk_review.tscn').read_text().replace('res://g1/walk_review.gd','res://r7/route.gd'))
write(OUT/'view-jobs-01.json',[job('views-'+mode+'-'+r,'views',['--r7-before'] if mode=='before' else [],r) for r in ['forward_plus','gl_compatibility'] for mode in ['before','after']])
write(OUT/'cost-jobs-01.json',[job('cost-'+mode+'-'+r,'views',['--benchmark']+(['--r7-before'] if mode=='before' else []),r) for r in ['forward_plus','gl_compatibility'] for mode in ['before','after']])
core=[]
for mode in ['before','after']:
    flags=['--r7-before'] if mode=='before' else []
    j=job('paid-'+mode,'paid',flags+['--run-id=r7-'+mode]);core.append(j)
    restart=job('paid-restart-'+mode,'paid',flags+['--restart','--run-id=r7-restart-'+mode]);restart['state']=j['state'];core.append(restart)
write(OUT/'paid-jobs-01.json',core)
print('R7_EVIDENCE_PREPARED')
