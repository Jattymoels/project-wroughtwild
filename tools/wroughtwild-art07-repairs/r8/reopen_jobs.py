"""Fresh source reopen job specifications; original package masters stay read-only."""
import json
from pathlib import Path
from inspect_inputs import ROOT,read
from compose import write
out=ROOT/'build/art07-repairs/r8/v01';scripts=ROOT/'tools/wroughtwild-art07-repairs';blender=read(ROOT/'docs/prototype/art07-repairs/2026-09-14/inputs.json')['tools']['blender'];jobs=[]
for ident,script,args in [
 ('r1',scripts/'r1/reopen.py',[out/'sources/r1']),
 ('r3',scripts/'r3/reopen.py',[out/'sources/r3/masters',out/'evidence/reopens/r3']),
 ('r5',scripts/'r5/blender_fit.py',['reopen',out/'sources/r5/source-candidate/r5_chest.blend',out/'evidence/reopens/r5']),
 ('r6',scripts/'r6/reopen.py',[out/'sources/r6/evidence/sources/r6-surface-master-v03.blend',out/'evidence/reopens/r6.json']),
 ('r7',scripts/'r7/reopen.py',[out/'sources/r7/sources/b2',out/'evidence/reopens/r7.json'])]:
    (out/'evidence/reopens').mkdir(parents=True,exist_ok=True)
    if ident=='r1':(out/'sources/r1/evidence').mkdir(parents=True,exist_ok=True)
    jobs.append({'id':'reopen-'+ident,'program':blender,'arguments':['--background','--threads','8','--python-exit-code','1','--python',str(script),'--',*[str(v) for v in args]],'log':str(out/'logs'/('reopen-'+ident+'.log')),'state':str(out/'users'/('reopen-'+ident))})
write(out/'jobs-reopen-01.json',jobs)
print('R8_PACKED_REOPEN_JOBS',len(jobs))
