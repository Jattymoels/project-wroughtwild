"""Create fresh guarded author/reopen/audit jobs; does not launch an engine."""
from pathlib import Path
from measure import ROOT,OUT,write
BLENDER=Path('C:/Users/Matty/Dev/project-wroughtwild/build/blender-tool/blender-4.5.9-windows-x64/blender.exe')
assert BLENDER.is_file()
def job(ident,script,extra=()):
    return {'id':ident,'program':str(BLENDER),'arguments':['--background','--threads','8','--python-exit-code','1','--python',str(ROOT/'tools/wroughtwild-art07-repairs/r1'/script),'--',str(OUT),*extra],'log':str(OUT/'logs'/(ident+'.log')),'state':str(OUT/'users'/ident)}
write(OUT/'model-jobs.json',[job('build-'+kind,'build.py',[kind]) for kind in ['broadleaf','pine']]+[job('reopen','reopen.py')])
write(OUT/'source-audit-jobs.json',[job('source-audit','source_audit.py')])
print('R1_AUTHOR_JOBS_READY',OUT)
