"""Curate unaltered engine stills and actual controller frames after fresh checks."""
import argparse
import json
import shutil
from pathlib import Path
from PIL import Image
from stage import ROOT, OUT, sha, write
from package import read, compare_probes

def main():
    parser=argparse.ArgumentParser()
    for key in ['surface','c5','probe','benchmark','reopen']:parser.add_argument('--'+key,required=True)
    args=parser.parse_args()
    dest=ROOT/'docs/art/leyline-studies/2026-09-14/art07-repairs/r6'
    dest.mkdir(parents=True,exist_ok=True)
    runs={key:OUT/'runs'/getattr(args,key) for key in ['surface','c5','probe','benchmark','reopen']}
    checked=[]
    for group,run in runs.items():
        for job in read(run/'jobs.json'):
            log=Path(job['log'])
            receipt=read(Path(str(log)+'.json'))
            assert receipt['failure']=='' and receipt['exit_code']==0,(group,job['id'],receipt['failure'])
            assert receipt['log_sha256']==sha(log)
            checked.append({'group':group,'id':job['id'],'seconds':receipt['seconds'],'log':str(log),'log_sha256':sha(log),'exit_code':0})
    compare_probes(runs['probe'])
    surfaces={renderer:read(runs['surface']/('surface-'+renderer)/'report.json') for renderer in ['forward_plus','gl_compatibility']}
    assert all(row['failures']==0 and len(row['rows'])==5 for row in surfaces.values())
    c5_checks={}
    for renderer in surfaces:
        c5_checks[renderer]={}
        for mode,expected in [('flow',178),('partial',66),('final',52)]:
            row=read(runs['c5']/('c5-'+renderer+'-'+mode)/('native-'+mode+'.json'))
            assert row['checks']==expected and row['failures']==0
            c5_checks[renderer][mode]=row
    costs=[]
    for renderer in ['forward_plus','gl_compatibility']:
        baseline=read(runs['benchmark']/('baseline-'+renderer)/'report.json')
        art=read(runs['benchmark']/('art-'+renderer)/'report.json')
        assert len(baseline['samples'])==len(art['samples'])==5
        for old,new in zip(baseline['samples'],art['samples']):
            assert old['kind']==new['kind']
            assert old['samples']==new['samples']==240 and old['worst_ms']>=old['p95_ms'] and new['worst_ms']>=new['p95_ms']
            costs.append({'renderer':renderer,'kind':old['kind'],'baseline':old,'candidate':new})
    image_manifest=[]
    def copy(source,name):
        target=dest/name
        shutil.copy2(source,target)
        with Image.open(target) as im:
            im.load()
            dimensions=list(im.size)
        assert sha(source)==sha(target)
        image_manifest.append({'name':name,'source':str(source),'sha256':sha(target),'dimensions':dimensions,'kind':'unmodified native engine still'})
    for renderer,label in [('forward_plus','forward'),('gl_compatibility','compatibility')]:
        run=runs['surface']/('surface-'+renderer)
        for kind,state,view in [('iron_vein','full','player'),('iron_vein','partial','close'),('copper_vein','excavated','close'),('ember_iron_vein','full','close')]:
            name=f'{kind}-{state}-{view}-{label}.png'
            copy(run/f'{kind}-{state}-{view}.png',name)
        copy(runs['c5']/('c5-'+renderer+'-flow')/'iron_vein-full-player.png','fallback-iron-'+label+'.png')
    frames=sorted((runs['surface']/'surface-forward_plus').glob('motion-*.png'))
    assert len(frames)==30
    images=[]
    for path in frames:
        with Image.open(path) as im:images.append(im.convert('RGB'))
    motion=dest/'native-walk.gif'
    images[0].save(motion,save_all=True,append_images=images[1:],duration=83,loop=0)
    for im in images:im.close()
    image_manifest.append({'name':motion.name,'sha256':sha(motion),'kind':'Illustrative 12 fps playback of actual input/controller frames sampled every five harness iterations. Native physics also advances while screenshots are captured; playback is not a real-time clock.','frames':[{'source':str(p),'sha256':sha(p)} for p in frames]})
    result={'checked_jobs':checked,'surfaces':surfaces,'c5_checks':c5_checks,'costs':costs,'full_probe_comparison':read(runs['probe']/'comparison.json'),'hardware':read(OUT/'verification/hardware.json'),'images':image_manifest,'master_reopen':read(runs['reopen']/'reopen/report.json'),'limits':['Current RTX 5090 measurements only; no minimum-hardware clearance.','Harness-paced native acquisition and inspection sites; no continuous campaign or owner visual acceptance.','No raised ore volume or new collision/terrain seat is approved on faceted terrain.']}
    write(dest/'evidence.json',json.dumps(result,indent=2))
    print('R6_EVIDENCE',len(checked),'fresh passed jobs;',len(image_manifest),'curated media')

if __name__=='__main__':main()
