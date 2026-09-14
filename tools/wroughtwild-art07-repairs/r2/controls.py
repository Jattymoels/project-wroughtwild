"""Fresh candidate art-off controls, paired with the same three candidate art-on trials."""
import argparse
from measure import BUILD, write

def main(version):
    base=BUILD/version;jobs=[]
    for trial in range(1,4):
        for renderer in ['forward_plus','gl_compatibility']:
            ident=f'benchmark-baseline-{renderer}-{trial:02d}'
            jobs.append({'id':ident,'program':str(base/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':['--rendering-method',renderer,'--path',str(base/'runtime/game'),'res://r2/benchmark.tscn','--','--benchmark','--baseline','--run-id='+ident],'log':str(base/'logs'/(ident+'.log')),'state':str(base/'users'/ident)})
    write(base/'control-benchmark-jobs.json',jobs)
    print('R2_CANDIDATE_CONTROLS',len(jobs))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
