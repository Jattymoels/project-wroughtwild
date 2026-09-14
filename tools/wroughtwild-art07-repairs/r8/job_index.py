"""Collect fresh job receipts without counting retained failures as acceptance."""
import json,re
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write

def collect():
    build=ROOT/'build/art07-repairs/r8';jobs=[]
    for version in ['v01','v02']:
        out=build/version
        for p in sorted((out/'logs').glob('*.log.json')):
            r=read(p);log=p.with_suffix('');assert sha(log)==r['log_sha256'],str(log)
            s=log.read_text(encoding='utf-8-sig');r['version']=version;r['receipt']=str(p);r['log']=str(log)
            r['diagnostics']=[line for line in s.splitlines() if re.search(r'\b(?:ERROR|WARNING|leaked|leaks|AssertionError)\b',line,re.IGNORECASE)]
            stderr=Path(str(log)+'.stderr');r['stderr_lines']=stderr.read_text(encoding='utf-8-sig',errors='replace').splitlines() if stderr.exists() else []
            r['markers']=[line for line in s.splitlines() if re.search(r'checks|assertions|passed|failures|R8_COMFORT|G1_PACKAGED|G1_REVIEW|R[134567]_.*REOPEN',line)]
            jobs.append(r)
    dest=build/'v01/evidence/job-index.json';dest.parent.mkdir(exist_ok=True,parents=True)
    dest.write_text(json.dumps({'jobs':jobs,'passed':sum(r['exit_code']==0 and not r['failure'] for r in jobs),'failed':sum(bool(r['failure']) or r['exit_code']!=0 for r in jobs),'scope':'Actual run.ps1 process receipts and freshly verified log hashes. Historical failed attempts remain separately listed.'},indent=2),encoding='utf-8')
    print('R8_JOB_INDEX',len(jobs),'passed',sum(r['exit_code']==0 and not r['failure'] for r in jobs))
    return jobs
if __name__=='__main__':collect()
