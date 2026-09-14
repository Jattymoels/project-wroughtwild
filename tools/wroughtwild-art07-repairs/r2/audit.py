"""Exact baseline-relative source audit; generated caches are never source inputs."""
import argparse
from measure import BUILD, read, write
from source import sha

def audit(version):
    base=BUILD/version;runtime=base/'runtime';prepared=read(base/'prepared.json')
    changes={r['path']:r for r in read(base/'changes.json')['files']}
    actual=[];unexpected=[];mismatched=[]
    for name,row in prepared['original_files'].items():
        now=sha(runtime/name)
        if now!=row['sha256']:
            actual.append({'path':name,'before_sha256':row['sha256'],'after_sha256':now})
            if name not in changes:unexpected.append(name)
        if name in changes and now!=changes[name]['after_sha256']:mismatched.append(name)
    return {'original_files':len(prepared['original_files']),'changed_original_files':len(actual),'actual_changes':actual,'unexpected_changes':unexpected,'change_record_mismatches':mismatched}

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);p.add_argument('--out',required=True);a=p.parse_args();r=audit(a.version);write(BUILD/a.version/a.out,r);print({k:v for k,v in r.items() if k!='actual_changes'});assert not r['unexpected_changes'] and not r['change_record_mismatches']
