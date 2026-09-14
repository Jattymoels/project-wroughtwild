"""Replay original source assertions with unique evidence paths and 1440x900 views."""
import argparse
import hashlib
from measure import BUILD, read, write


def main(version):
    base=BUILD/version;game=base/'runtime/game';proof=[];mapping={}
    specs=[(i,'native_review') for i in ['b1','b3','c1','c2','c3','c4','c5']]+[(i,'review') for i in ['e1','e2','e3','f1','f2','f3','f4']]
    for ident,name in specs:
        path=game/ident/(name+'.gd');original=path.read_text(encoding='utf-8-sig');text=original
        substitutions=[('res://../evidence/','res://../evidence/replays/'+ident+'/'),('res://'+ident+'/evidence','res://../evidence/replays/'+ident),('Vector2i(1600,900)','Vector2i(1440,900)')]
        if ident=="f2":substitutions.append(("func _run() -> void:\n","func _run() -> void:\n\tDirAccess.make_dir_recursive_absolute(OUT)\n"))
        used=[]
        for old,new in substitutions:
            if old in text:text=text.replace(old,new);used.append((old,new))
        reverse=text
        for old,new in reversed(used):reverse=reverse.replace(new,old)
        assert reverse==original,'Only paths and inspection viewport may differ'
        new_name='r2/replay_'+ident
        write(game/(new_name+'.gd'),text)
        write(game/(new_name+'.tscn'),(game/ident/(name+'.tscn')).read_text().replace('res://'+ident+'/'+name+'.gd','res://'+new_name+'.gd'))
        mapping['res://'+ident+'/'+name+'.tscn']='res://'+new_name+'.tscn'
        proof.append({'source':path.relative_to(game).as_posix(),'source_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'derivative':new_name+'.gd','substitutions':used,'inverse_substitutions_restore_all_original_assertions_and_logic':True})
        if ident=='b3':
            write(game/'r2/projection_base.gd',text.replace('res://../evidence/replays/b3/','res://../evidence/replays/projection/'))
    projection=game/'r2/projection_checks.gd';s=projection.read_text();old='extends "res://b3/native_review.gd"';assert s.count(old)==1
    projection.write_text(s.replace(old,'extends "res://r2/projection_base.gd"'),encoding='utf-8',newline='\n')
    for name in ['native','render']:
        jobs=read(base/(name+'-jobs.json'))
        for job in jobs:job['arguments']=[mapping.get(a,a) for a in job['arguments']]
        write(base/(name+'-replay-jobs.json'),jobs)
    write(base/'source-replay-derivatives.json',proof)
    print('R2_ORIGINAL_ASSERTIONS_ISOLATED',len(proof))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
