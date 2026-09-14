"""Collect only proven fresh native captures and recheck normal files after engine work."""
import json
import shutil
import struct
import subprocess
from datetime import datetime
from pathlib import Path
from work import ROOT, OUT, GAME, DEPOT, read, row, write
from audit import diagnostic

def collect():
    result=diagnostic(OUT/"logs/render-after/c3.log")
    assert result["markers"]==["C3_NATIVE_OK 68"] and result["exit_code"]==0
    assert not any(result[k] for k in ["failure","leaks","errors","orphan_string_names"])
    start=datetime.fromisoformat(read(OUT/"logs/render-after/c3.log.json")["start"]).timestamp()
    names=["full","partial","bark-six-remain","cork-depleting","amber-stump"]+[f"fall-{i:03}" for i in range(42)]
    captures=[]
    for name in names:
        source=GAME/"c3/evidence/gl_compatibility"/(name+".png")
        assert source.stat().st_mtime>=start, "Historical capture: "+str(source)
        data=source.read_bytes()
        assert data[:8]==b"\x89PNG\r\n\x1a\n"
        width,height=struct.unpack(">II",data[16:24])
        assert (width,height)==(1280,720)
        target=OUT/"captures/c3"/source.name
        target.parent.mkdir(parents=True,exist_ok=True)
        assert not target.exists()
        shutil.copy2(source,target)
        captures.append({"file":target.relative_to(OUT).as_posix(),"source":str(source),"width":width,"height":height,"modified":source.stat().st_mtime,**row(target)})
    write(OUT/"evidence/capture-provenance.json",{"log":result,"captures":captures,"motion":[f"captures/c3/fall-{i:03}.png" for i in range(42)],"scope":"Original native C3 posed work and fall frames at fixed 60 FPS; no model or geography change; not human playtime."})
    docs=ROOT/"docs/art/leyline-studies/2026-09-14/art07-repairs/r4"
    for source_name,name in [("full.png","native-full.png"),("fall-006.png","native-fall.png")]:
        target=docs/name
        assert not target.exists()
        shutil.copy2(OUT/"captures/c3"/source_name,target)
    diagnostics=OUT/"evidence/diagnostic-source"
    diagnostics.mkdir()
    for source in (GAME/"r4").iterdir():
        if source.suffix in [".gd",".tscn"]: shutil.copy2(source,diagnostics/source.name)
    before=read(OUT/"evidence/preservation-before.json")
    changed=[name for name,expected in before["files"].items() if not Path(name).is_file() or row(Path(name))!=expected]
    names=subprocess.check_output(["git","-C",str(DEPOT),"ls-files","-z","--cached","--others","--exclude-standard","--","game","sim","data"]).decode().split("\0")
    current={str(DEPOT/name) for name in set(names)-{""} if (DEPOT/name).is_file()}
    current.update(str(p) for p in Path(before["normal_save_root"]).rglob("*") if p.is_file())
    preserved={"files":len(before["files"]),"changed":changed,"added":sorted(current-set(before["files"])),"missing":sorted(set(before["files"])-current),"checked_at":datetime.now().astimezone().isoformat()}
    write(OUT/"evidence/preservation-final.json",preserved)
    assert not any(preserved[k] for k in ["changed","added","missing"])
    print("R4_FRESH_CAPTURES",len(captures),"normal files preserved",preserved["files"])

if __name__=="__main__": collect()
