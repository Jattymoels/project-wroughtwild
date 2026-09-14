"""Compare actual final-hook fingerprints with each other and the pinned G1 evidence."""
import argparse
from pathlib import Path
from measure import BUILD, read, write
from source import sha


def main(version):
    base=BUILD/version;prepared=read(base/'prepared.json');source=Path(prepared['source']['path']);manifest=read(source/'manifest.json')['files']
    current={mode:read(base/'runtime/evidence'/('probe-'+mode+'.json')) for mode in ['art','baseline']}
    references={}
    for mode in current:
        path=source/'evidence'/('probe-'+mode+'.json')
        assert sha(path)==manifest[path.relative_to(source).as_posix()]['sha256']
        references[mode]=read(path)
        assert current[mode]['failures']==0 and references[mode]['failures']==0
    fields=['sim','leylines','contraptions','blocks','stations','resource_nodes']
    for field in fields:
        assert current['art']['snapshot'][field]==current['baseline']['snapshot'][field],field
        for mode in current:assert current[mode]['snapshot'][field]==references[mode]['snapshot'][field],(mode,field)
    geography={r['geography_sha256'] for r in [*current.values(),*references.values()]};assert len(geography)==1
    write(base/'analysis/native-ownership.json',{'fields':fields,'art_on_equals_art_off':True,'matches_original_pinned_g1_fingerprints':True,'geography_sha256':geography.pop(),'reports':{m:{'current':str((base/'runtime/evidence'/('probe-'+m+'.json')).resolve()),'current_sha256':sha(base/'runtime/evidence'/('probe-'+m+'.json')),'original':str(source/'evidence'/('probe-'+m+'.json')),'original_sha256':sha(source/'evidence'/('probe-'+m+'.json')),'current_checks':current[m]['checks']} for m in current},'scope':'Fresh candidate final-hook processes compared exactly with each other and pinned original G1 evidence. Historical original evidence is identified as historical; it is not relabelled a new engine run.'})
    print('R2_EXACT_FINAL_HOOK_OWNERSHIP_AND_GEOGRAPHY_PRESERVED')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
