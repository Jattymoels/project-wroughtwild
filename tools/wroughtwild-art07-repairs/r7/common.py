import hashlib, json, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
OUT=ROOT/'build/art07-repairs/r7/v02'
GAME=OUT/'runtime/game'
TOOLS=ROOT/'tools/wroughtwild-art07-repairs/r7'
def sha(p):
    with Path(p).open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def write(p,value):
    p=Path(p);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(value,indent=2)+'\n',encoding='utf-8')
def guard():
    assert ROOT.resolve()==Path('D:/project-wroughtwild-art07-r7').resolve()
    assert subprocess.check_output(['git','branch','--show-current'],cwd=ROOT,text=True).strip()=='codex/art07-r7'
def job(ident,scene=None,flags=(),renderer=None):
    args=(['--rendering-method',renderer] if renderer else ['--headless'])+['--path',str(GAME)]
    if scene:args+=['res://r7/'+scene+'.tscn']
    if flags:args+=['--',*flags]
    return {'id':ident,'program':str(OUT/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':args,'log':str(OUT/'logs'/(ident+'.log')),'state':str(OUT/'users'/ident)}
