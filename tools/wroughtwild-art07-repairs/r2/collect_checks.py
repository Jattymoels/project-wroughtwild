"""Retain every actual engine job outcome and diagnostic, including failed attempts."""
import argparse
import re
from measure import BUILD, read, write
from source import sha


def main(out):
    rows=[]
    for version in ['v01','v02','v03']:
        for path in sorted((BUILD/version/'logs').glob('*.log.json')):
            r=read(path);log=path.with_suffix('')
            assert sha(log)==r['log_sha256'],str(path)
            stderr=path.with_name(path.name.removesuffix('.json')+'.stderr')
            diagnostics=stderr.read_text(encoding='utf-8-sig',errors='replace').splitlines() if stderr.exists() else []
            if r.get('exit_code')==0 and not r.get('failure'):
                assert not r.get('benchmark_competitors') and not r.get('processes_before'),str(path)
            rows.append({'version':version,'id':r['id'],'log':str(log),'log_sha256':r['log_sha256'],'exit_code':r.get('exit_code'),'failure':r.get('failure'),'seconds':r['seconds'],'start':r['start'],'program':r['program'],'arguments':r['arguments'],'appdata':r['appdata'],'localappdata':r['localappdata'],'temp':r['temp'],'processes_before':r.get('processes_before'),'benchmark_competitors':r.get('benchmark_competitors'),'results':r.get('results',[]),'stderr':diagnostics})
    result={'jobs':rows,'successful':sum(r['exit_code']==0 and not r['failure'] for r in rows),'failed_attempts':sum(r['exit_code']!=0 or bool(r['failure']) for r in rows),'scope':'Actual fresh engine process log records. Failed attempts stay visible; only successful specific replays support evidence. This is an index, not a fresh engine run.'}
    write(BUILD/'v03'/out,result)
    print('R2_ACTUAL_JOB_INDEX',result['successful'],'passed;',result['failed_attempts'],'failed attempts retained')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--out',required=True);a=p.parse_args();main(a.out)
