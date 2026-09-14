"""Retain original R1 comparisons and rejected R7 evidence with exact provenance."""
import shutil
from common import *
guard()
old=ROOT/'build/art07-repairs/r7/v01'
rows=[]
def copy(src,dst):
    dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
    assert sha(src)==sha(dst)
    rows.append({'source':str(src),'copy':dst.relative_to(OUT).as_posix(),'bytes':src.stat().st_size,'sha256':sha(src),'operation':'byte-identical copy'})
for renderer in ['forward_plus','gl_compatibility']:
    source=old/'runtime/evidence'/('r7-views-before-'+renderer)
    for p in source.rglob('*'):
        if p.is_file():copy(p,OUT/'evidence/r1-comparison'/source.name/p.relative_to(source))
    reject=old/'runtime/evidence'/('r7-views-after-'+renderer)
    for name in ['report.json','home-player-height-day.png','habitat-player-height-day.png','distance-2.5.png']:
        copy(reject/name,OUT/'evidence/rejected-v01'/reject.name/name)
for p in (old/'logs').iterdir():
    if p.is_file():copy(p,OUT/'evidence/v01-logs'/p.name)
for p in old.glob('*.json'):
    if p.name!='prepared.json':copy(p,OUT/'evidence/v01-job-specs'/p.name)
for name in ['cover.gd','settings.json','surface.gdshader','views.gd']:
    copy(old/'runtime/game/r7'/name,OUT/'evidence/rejected-v01/runtime-fixture'/name)
write(OUT/'evidence/comparison-provenance.json',{'scope':'The BEFORE comparison images/reports were executed in fresh V01 jobs against the verified R1 parent using --r7-before. They are reused without modification for the V02 after comparison. They are not represented as new V02 baseline executions. V01 after was rejected visually; selected original renders, complete reports, original candidate settings and logs remain here. Full originals remain at the named source paths.','files':rows})
parse=read(OUT/'parse-jobs-01.json')[:3]+read(OUT/'parse-fix-02.json')
write(OUT/'accepted-parse-jobs.json',parse)
route=[job('route-motion-forward_plus','route',['--capture','--run-id=r7-route-motion'],'forward_plus')]
write(OUT/'route-motion-only.json',route)
write(OUT/'route-capture-jobs-01.json',route+read(OUT/'cost-jobs-01.json'))
print('R7_PROVENANCE',len(rows))
