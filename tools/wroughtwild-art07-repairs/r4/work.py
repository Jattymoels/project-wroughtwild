"""R4-only reproduction, preservation and candidate tools; no engine launch here."""
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
OUT = ROOT / "build/art07-repairs/r4/v01"
GAME = OUT / "runtime/game"
DEPOT = Path("C:/Users/Matty/Dev/project-wroughtwild")
IDS = ["b3", "c1", "c2", "c3", "c4", "e1", "f2", "f3"]

def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))

def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()

def row(path):
    return {"bytes": path.stat().st_size, "sha256": sha(path)}

def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("x", encoding="utf-8", newline="\n") as stream:
        json.dump(value, stream, indent=2)
        stream.write("\n")

def git(root, *args):
    return subprocess.check_output(["git", "-C", str(root), *args], text=True).strip()

def source_files():
    return [f"{ident}/{'native_review' if ident in IDS[:5] else 'review'}.gd" for ident in IDS]

def snapshot():
    assert ROOT == Path("D:/project-wroughtwild-art07-r4")
    assert git(ROOT, "branch", "--show-current") == "codex/art07-r4"
    preserved = {}
    names = subprocess.check_output(["git", "-C", str(DEPOT), "ls-files", "-z",
        "--cached", "--others", "--exclude-standard", "--", "game", "sim", "data"]).decode().split("\0")
    for name in sorted(set(names) - {""}):
        path = DEPOT / name
        if path.is_file():
            preserved[str(path)] = row(path)
    normal_saves = Path(os.environ["APPDATA"]) / "Godot/app_userdata/Wroughtwild"
    for path in sorted(normal_saves.rglob("*")):
        if path.is_file():
            preserved[str(path)] = row(path)
    write(OUT / "evidence/preservation-before.json", {
        "owner_head": git(DEPOT, "rev-parse", "HEAD"),
        "owner_status": git(DEPOT, "status", "--porcelain=v1"),
        "normal_save_root": str(normal_saves), "files": preserved})
    original = read(OUT / "prepared.json")["original_files"]
    mismatches = []
    for name, expected in original.items():
        if row(OUT / "runtime" / name) != expected:
            mismatches.append(name)
    write(OUT / "evidence/prepared-runtime-check.json", {
        "files": len(original), "bytes": sum(r["bytes"] for r in original.values()),
        "mismatches": mismatches, "scope": "Original prepared entries; engine caches are not inputs."})
    assert not mismatches, mismatches
    source = Path(read(ROOT / "docs/prototype/art07-repairs/2026-09-14/inputs.json")["runtime_source"]["path"])
    for name in source_files():
        target = OUT / "source-before/game" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        assert not target.exists()
        shutil.copy2(source / "game" / name, target)
        assert sha(GAME / name) == sha(target)
    print("R4_PRESERVATION_BASELINE", len(preserved), "runtime", len(original))

def jobs(phase):
    jobs = []
    for ident in IDS:
        scene = f"res://{ident}/{'native_review' if ident in IDS[:5] else 'review'}.tscn"
        cases = [("", ["--check"] if ident in ["e1", "f2"] else [])]
        if ident in IDS[:5]:
            cases += [("-partial", ["--restore-partial"]), ("-final", ["--restore-final"])]
        else:
            cases += [("-restart", ["--restore" if ident == "e1" else "--restart"])]
        if ident == "f3": cases += [("-depleted", ["--restart-depleted"])]
        for suffix, flags in cases:
            name = ident + suffix
            args = ["--verbose", "--headless", "--fixed-fps", "60", "--path", str(GAME), scene]
            if flags:
                args += ["--", *flags]
            jobs.append({"id": name, "program": str(OUT / "runtime/engine/Godot_v4.5-stable_win64.exe"),
                         "arguments": args, "log": str(OUT / "logs" / phase / (name + ".log")),
                         "state": str(OUT / "users" / phase / ident)})
    write(OUT / (phase + "-jobs.json"), jobs)
    print("R4_JOBS", phase, len(jobs))


def patch():
    """Apply only terminal fixture disposal to the mutable R4 runtime copy."""
    changes = []
    for name in source_files():
        origin = OUT / "source-before/game" / name
        target = GAME / name
        assert sha(target) == sha(origin), "Not the unmodified pinned fixture: " + name
        source = origin.read_bytes().decode("utf-8")
        newline = "\r\n" if "\r\n" in source else "\n"
        function = "finish_e1" if name.startswith("e1/") else ("_done" if name.startswith("f2/") else "finish")
        start = source.index("func " + function + "(")
        end = source.find("\nfunc ", start + 1)
        if end < 0: end = len(source)
        body = source[start:end]
        if name.startswith("e1/"):
            old = "\tfor child in get_children():child.queue_free()" + newline + "\tawait get_tree().process_frame" + newline + "\tawait get_tree().process_frame"
            assert old in body
            body = body.replace(old, '\tawait preload("res://r4/fixture_cleanup.gd").dispose(self)')
            body = body.replace("get_tree().quit(", "get_tree().quit.call_deferred(")
        else:
            calls = list(re.finditer(r"get_tree\(\)\.quit\(([^\n]*?)\)", body))
            assert calls
            call = calls[-1]
            code = call.group(1) or "0"
            body = body[:call.start()] + 'preload("res://r4/fixture_cleanup.gd").finish.call_deferred(self, ' + code + ')' + body[call.end():]
        updated = (source[:start] + body + source[end:]).encode("utf-8")
        assert updated != origin.read_bytes()
        master = OUT / "changed-source/game" / name
        master.parent.mkdir(parents=True, exist_ok=True)
        assert not master.exists()
        master.write_bytes(updated)
        target.write_bytes(updated)
        changes.append({"path": "game/"+name, "classification":"fixture_only",
            "before_sha256":sha(origin),"after_sha256":sha(master),
            "before_bytes":origin.stat().st_size,"after_bytes":len(updated),
            "functions":[function], "purpose":"Dispose completed fixture descendants and retire owned audio before normal quit; existing checks and work/restore logic unchanged.",
            "master":"changed-source/game/"+name,"overlaps":[]})
    for name in ["fixture_cleanup.gd","cleanup_options.gd"]:
        origin = ROOT / "tools/wroughtwild-art07-repairs/r4" / name
        target = OUT / "changed-source/game/r4" / name
        target.parent.mkdir(parents=True, exist_ok=True)
        assert not target.exists()
        shutil.copy2(origin,target)
        shutil.copy2(origin,GAME/"r4"/name)
        changes.append({"path":"game/r4/"+name,"classification":"fixture_only",
            "before_sha256":None,"after_sha256":sha(target),"before_bytes":0,
            "after_bytes":target.stat().st_size,
            "functions":["dispose","finish","counts","_alive"] if name=="fixture_cleanup.gd" else ["PREDISPOSE_FRAMES","MIX_PASSES","MAIN_FRAMES","POLL_SLEEP_MS","TIMEOUT_SECONDS","SOAK_ITERATIONS"],
            "purpose":"Owned test-scene teardown and diagnostic controls only.",
            "master":"changed-source/game/r4/"+name,"overlaps":[]})
    settings = [{'name': 'PREDISPOSE_FRAMES', 'before': None, 'after': 3, 'purpose': 'Let queued two-frame UI layout callbacks finish while their owned controls exist.'}, {'name': 'MIX_PASSES', 'before': None, 'after': 2, 'purpose': 'Observe two real mixer progress events after stopping owned voices.'}, {'name': 'MAIN_FRAMES', 'before': None, 'after': 2, 'purpose': 'Allow deferred node frees and main-thread audio retirement; also the final release sample delay.'}, {'name': 'POLL_SLEEP_MS', 'before': None, 'after': 1, 'purpose': 'Yield CPU so accelerated headless frames do not starve the mixer.'}, {'name': 'TIMEOUT_SECONDS', 'before': None, 'after': 2.0, 'purpose': 'Fail visibly if owned playback cannot retire; a timeout is never success.'}, {'name': 'SOAK_ITERATIONS', 'before': None, 'after': 12, 'purpose': 'Bound the diagnostic create/work/restore/dispose exercise; no long-session claim.'}]
    for change in changes:
        change["settings"]=settings if change["path"]=="game/r4/cleanup_options.gd" else []
    write(OUT/"changes.json",{"id":"r4","runtime_base":"6bb2e044dcd0bf1788896aa2c19cdf56fee93522",
        "baseline_manifest_sha256":"fd5c592ef52185cc7d0737840e41af09dbb5bcea36b719539931e156f42865cd",
        "parent_candidates":[],"reusable_runtime_changes":[],"files":changes,
        "overlap_policy":"Merge only listed finish-function changes if a peer repair changes the same review file; before-hash mismatch requires R8 reconciliation.",
        "overlap_review":"Only the common baseline was consumed; peer candidate files were not inspected or applied. R8 must reconcile any before-hash mismatch at the listed finish functions.",
        "scope":"Eight fixture exit paths plus their shared fixture-only helper. No audio palette/cache, rendering, resource owner, simulation, gameplay, save or G1 hook changes."})
    print("R4_PATCHED",len(changes),"fixture-only files")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("command", choices=["snapshot", "jobs", "patch"])
    parser.add_argument("--phase", default="before")
    args = parser.parse_args()
    if args.command == "snapshot": snapshot()
    if args.command == "jobs": jobs(args.phase)
    if args.command == "patch": patch()
