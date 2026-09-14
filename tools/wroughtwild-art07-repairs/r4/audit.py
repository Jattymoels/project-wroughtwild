"""R4 log attribution, preservation audit, exact delta seal/verification and guarded application."""
import argparse
import collections
import json
import os
import re
import shutil
import subprocess
from pathlib import Path
from work import ROOT, OUT, GAME, DEPOT, IDS, read, row, sha, write, git

def diagnostic(path):
    path=path.resolve()
    content = path.read_text(encoding="utf-8-sig")
    leaks = re.findall(r"Leaked instance: (\w+):(\d+)", content)
    result = read(Path(str(path)+".json"))
    assert sha(path) == result["log_sha256"]
    return {
        "path": str(path.relative_to(OUT)), "sha256":sha(path),
        "exit_code":result["exit_code"],"failure":result["failure"],
        "seconds":result["seconds"],"child_pid":result["child_pid"],
        "program":result["program"],"arguments":result["arguments"],"start":result["start"],
        "private_state":{k:result.get(k) for k in ["appdata","localappdata","temp"]},
        "markers":re.findall(r"^(?:B3_NATIVE_OK|C1_NATIVE_OK|C2_NATIVE_RESULT|C3_NATIVE_OK|C4_NATIVE_OK|E1_CHECKS|E1_RESTORE|F2_CHECKS|F2_RESTART|F3_CHECKS|F3_RESTART(?:-DEPLETED)?|R4_SOAK_OK).*$",content,re.M),
        "leak_types":dict(collections.Counter(kind for kind,_ in leaks)),
        "leaks":[{"class":kind,"id":ident} for kind,ident in leaks],
        "warnings":re.findall(r"^WARNING:.*$",content,re.M),
        "errors":re.findall(r"^(?:SCRIPT ERROR|ERROR):.*$",content,re.M),
        "orphan_string_names":re.findall(r"^Orphan StringName:.*$",content,re.M),
        "cleanup":[json.loads(line) for line in re.findall(r"^R4_CLEANUP (.*)$",content,re.M)]
    }

def logs():
    result = [diagnostic(path) for path in sorted((OUT/"logs").rglob("*.log"))
              if Path(str(path)+".json").exists()]
    target = OUT/"evidence/log-audit.json"
    target.write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    for item in result:
        print(item["path"],item["markers"],item["leak_types"],len(item["orphan_string_names"]),item["failure"])

def traces():
    result = []
    for path in sorted((OUT/"logs").glob("trace*/*.log")):
        ident=path.stem
        content=path.read_text(encoding="utf-8-sig")
        observations=[json.loads(line) for line in re.findall(r"^R4_AUDIO_TRACE (.*)$",content,re.M)]
        for batch in re.findall(r"^R4_AUDIO_TRACE_BATCH (.*)$",content,re.M): observations.extend(json.loads(batch))
        # Godot's ObjectID is uint64; GDScript int is signed. Keep full integer precision.
        by_id={}
        for observation in observations:
            for field in ["stream_id","playback_id"]:
                instance=str(int(observation[field]) % (1<<64))
                if instance!="0":
                    by_id.setdefault(instance,[]).append(observation)
        audit=diagnostic(path)
        mapping=[]
        for leak in audit["leaks"]:
            seen=by_id.get(leak["id"],[])
            mapping.append({**leak,"observed":bool(seen),"owners":sorted(set(o["parent"] for o in seen)),
                            "cues":sorted(set(o["cue"] for o in seen)),"events":sorted(set(o["event"] for o in seen))})
        result.append({"fixture":ident,"log":audit["path"],"records":len(observations),"leaks":mapping,
                       "matched":sum(m["observed"] for m in mapping),"total":len(mapping)})
    (OUT/"evidence/attribution.json").write_text(json.dumps(result,indent=2)+"\n",encoding="utf-8")
    for item in result: print(item["log"],item["matched"],"/",item["total"],"matched")

def preservation(record="preservation-after.json"):
    assert Path(record).name==record and record.endswith(".json")
    before=read(OUT/"evidence/preservation-before.json")
    changed=[name for name,expected in before["files"].items()
             if not Path(name).is_file() or row(Path(name))!=expected]
    names=subprocess.check_output(["git","-C",str(DEPOT),"ls-files","-z","--cached","--others",
                                   "--exclude-standard","--","game","sim","data"]).decode().split("\0")
    current={str(DEPOT/name) for name in set(names)-{""} if (DEPOT/name).is_file()}
    current.update(str(p) for p in Path(before["normal_save_root"]).rglob("*") if p.is_file())
    added=sorted(current-set(before["files"]))
    missing=sorted(set(before["files"])-current)
    original=read(OUT/"prepared.json")["original_files"]
    runtime_changes=[name for name,expected in original.items()
                     if not (OUT/"runtime"/name).is_file() or row(OUT/"runtime"/name)!=expected]
    source_changes={item["path"] for item in read(OUT/"changes.json")["files"]}
    # Original fixture evidence is an output within the mutable R4 copy, never source/gameplay.
    unexpected=[name for name in runtime_changes if name not in source_changes and "/evidence/" not in name]
    result={"owner_files":len(before["files"]),"changed":changed,"added":added,"missing":missing,
        "owner_head_before":before["owner_head"],"owner_head_after":git(DEPOT,"rev-parse","HEAD"),
        "owner_status_after":git(DEPOT,"status","--porcelain=v1"),
        "runtime_original_entries":len(original),"runtime_changed_entries":runtime_changes,
        "unexpected_runtime_source_changes":unexpected,
        "native":row(GAME/"bin/libwroughtwild_sim.windows.x86_64.dll"),
        "engine":row(OUT/"runtime/engine/Godot_v4.5-stable_win64.exe")}
    write(OUT/"evidence"/record,result)
    print(json.dumps(result,indent=2))
    assert not changed and not added and not missing and not unexpected

def verify(package):
    package=package.resolve()
    manifest=read(package/"manifest.json")
    rows=manifest["files"]
    actual={p.relative_to(package).as_posix() for p in package.rglob("*") if p.is_file()}
    assert actual==set(rows)|{"manifest.json"}, "Exact package file set differs"
    for name,expected in rows.items():
        path=(package/name).resolve()
        assert path.is_relative_to(package)
        assert row(path)==expected, name
    result={"path":package.as_posix(),"manifest_sha256":sha(package/"manifest.json"),
            "files":len(rows),"bytes":sum(v["bytes"] for v in rows.values())}
    print("R4_EXACT_PACKAGE_VERIFIED",json.dumps(result))
    return result

def seal(package):
    package=package.resolve()
    assert package.parent==OUT.resolve(), "Seal only inside this assigned version"
    assert not package.exists(), "Use a fresh absent candidate; never modify a seal"
    changes=read(OUT/"changes.json")
    for change in changes["files"]:
        assert sha(OUT/change["master"])==change["after_sha256"]
        assert sha(OUT/"runtime"/change["path"])==change["after_sha256"]
    package.mkdir()
    for directory in ["changed-source","source-before","evidence","logs","captures"]:
        source=OUT/directory
        if source.exists(): shutil.copytree(source,package/directory)
    for path in OUT.glob("*.json"):
        if path.name.startswith("sealed"): continue
        shutil.copy2(path,package/path.name)
    for path in (OUT/"users").rglob("*"):
        if path.is_file() and "ART07G1" in path.parts and path.suffix in [".json",".bak",".tmp"]:
            target=package/path.relative_to(OUT)
            target.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(path,target)
    shutil.copytree(ROOT/"tools/wroughtwild-art07-repairs/r4",package/"tools/r4",
                    ignore=shutil.ignore_patterns("__pycache__"))
    shutil.copytree(ROOT/"docs/art/leyline-studies/2026-09-14/art07-repairs/r4",package/"report")
    rows={p.relative_to(package).as_posix():row(p) for p in sorted(package.rglob("*")) if p.is_file()}
    write(package/"manifest.json",{"id":"r4","runtime_base":changes["runtime_base"],"files":rows})
    result=verify(package)
    write(OUT/("sealed-"+package.name+".json"),result)

def apply(package,target):
    verify(package)
    target=target.resolve()
    assert target.name=="runtime" and target.parts[0].upper()=="D:\\", "Use an isolated repair runtime"
    assert "project-wroughtwild-art07-r8" in target.parts, "This integration recipe is for R8's private runtime"
    changes=read(package/"changes.json")
    prepared=read(package/"prepared.json")["original_files"]
    for name,expected in prepared.items():
        if name.startswith("data/") or name in ["engine/Godot_v4.5-stable_win64.exe","game/bin/libwroughtwild_sim.windows.x86_64.dll"]:
            assert row(target/name)==expected, "Pinned runtime mismatch: "+name
    # Validate every path and before-hash before the first write; conflicts are R8 decisions.
    for change in changes["files"]:
        path=(target/change["path"]).resolve()
        assert path.is_relative_to(target)
        if change["before_sha256"] is None: assert not path.exists(),str(path)
        else: assert sha(path)==change["before_sha256"], "Overlap: "+str(path)
        assert sha(package/change["master"])==change["after_sha256"]
    for change in changes["files"]:
        path=target/change["path"]
        path.parent.mkdir(parents=True,exist_ok=True)
        shutil.copy2(package/change["master"],path)
        assert sha(path)==change["after_sha256"]
    print("R4_FIXTURE_ONLY_DELTA_APPLIED",len(changes["files"]))

if __name__=="__main__":
    parser=argparse.ArgumentParser()
    parser.add_argument("command",choices=["logs","traces","preservation","seal","verify","apply"])
    parser.add_argument("--package",type=Path,default=OUT/"handoff")
    parser.add_argument("--target",type=Path)
    parser.add_argument("--record",default="preservation-after.json")
    args=parser.parse_args()
    if args.command=="logs": logs()
    elif args.command=="traces": traces()
    elif args.command=="preservation": preservation(args.record)
    elif args.command=="seal": seal(args.package)
    elif args.command=="verify": verify(args.package)
    elif args.command=="apply": apply(args.package,args.target)
