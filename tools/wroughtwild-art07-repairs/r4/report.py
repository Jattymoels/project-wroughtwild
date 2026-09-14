"""Produce R4's measured report only after the required native and preservation gates."""
import collections
import difflib
import json
import re
import statistics
import shutil
from pathlib import Path
from work import ROOT, OUT, GAME, IDS, read, row, sha, write
from audit import diagnostic, logs, traces

DOCS=ROOT/"docs/art/leyline-studies/2026-09-14/art07-repairs/r4"

def build():
    logs()
    traces()
    audits=read(OUT/"evidence/log-audit.json")
    mapped=read(OUT/"evidence/attribution.json")
    matrix=[]
    diff=[]
    changes=read(OUT/"changes.json")
    source_checks=[]
    for change in changes["files"]:
        if change["before_sha256"] is None: continue
        name=change["path"]
        before=(OUT/"source-before"/name).read_bytes()
        after=(OUT/"changed-source"/name).read_bytes()
        function=change["functions"][0]
        def outside(body):
            start=body.index(("func "+function+"(").encode())
            end=body.find(b"\nfunc ",start+1)
            if end<0: end=len(body)
            return body[:start],body[end:]
        assert outside(before)==outside(after),name
        # All original assertions and failure diagnostics, including finish checks, remain verbatim.
        asserted=lambda b:[line for line in b.splitlines() if b"check(" in line or b"assert(" in line or b"push_error(" in line]
        assert asserted(before)==asserted(after),name
        assert sha(GAME/name.removeprefix("game/"))==change["after_sha256"]
        source_checks.append({"path":name,"outside_finish_identical":True,"assertions_identical":True,
                              "before_sha256":sha(OUT/"source-before"/name),"after_sha256":change["after_sha256"],
                              "original_crlf":b"\r\n" in before,"candidate_crlf":b"\r\n" in after})
        diff.extend(difflib.unified_diff(before.decode("utf-8-sig").splitlines(True),
                    after.decode("utf-8-sig").splitlines(True),fromfile="before/"+name,tofile="after/"+name))
    (OUT/"evidence/source-checks.json").write_text(json.dumps(source_checks,indent=2)+"\n",encoding="utf-8")
    (OUT/"evidence/fixture-delta.patch").write_text("".join(diff),encoding="utf-8",newline="")
    for ident in IDS:
        originals=[a for a in audits if Path(a["path"]).parent.name.startswith("before") and Path(a["path"]).stem==ident and a["leaks"]]
        assert originals,ident
        attributed=[a for a in mapped if a["fixture"]==ident and a["total"]>0 and a["matched"]==a["total"]]
        assert attributed,"No exact-ID leaking trace: "+ident
        before=originals[0]
        after=diagnostic(OUT/"logs/after-final"/(ident+".log"))
        assert after["markers"]==before["markers"]
        assert not any(after[k] for k in ["failure","leaks","warnings","errors","orphan_string_names"])
        matrix.append({"fixture":ident,"before":before,"after":after,"attribution":attributed[0]})
    after_runs=[diagnostic(p) for p in sorted((OUT/"logs/after-final").glob("*.log"))]
    assert len(after_runs)==22
    for a in after_runs:
        b=diagnostic(OUT/"logs/before"/Path(a["path"]).name)
        assert a["markers"]==b["markers"] and a["exit_code"]==0 and len(a["cleanup"])==1
        assert not any(a[k] for k in ["failure","leaks","warnings","errors","orphan_string_names"])
        assert a["child_pid"]!=b["child_pid"]
    for name in ["fixture_cleanup.gd","cleanup_options.gd"]:
        tested=(OUT/"evidence/diagnostic-source"/name).read_bytes()
        final=(OUT/"changed-source/game/r4"/name).read_bytes()
        assert tested.rstrip(b"\r\n")==final.rstrip(b"\r\n")
    e1_restart=diagnostic(OUT/"logs/after-final/e1-restart.log")
    assert e1_restart["cleanup"][0]["frame_waiters_before_free"]==0
    soak_before=read(OUT/"users/soak-before/ART07G1/r4-soak.json")
    soak_after=read(OUT/"users/soak-after-final/ART07G1/r4-soak.json")
    assert soak_before["checks"]==soak_after["checks"]==156
    assert soak_after["iterations"]==12 and soak_after["observed_playbacks_alive"]==0
    assert all(s["observed_playbacks_alive"]==0 for s in soak_after["samples"])
    preservation=read(OUT/"evidence/preservation-final-runtime.json")
    assert not any(preservation[k] for k in ["changed","added","missing","unexpected_runtime_source_changes"])
    verify=(OUT/"evidence/verify-after.txt").read_text(encoding="utf-8-sig")
    assert verify.count("REPAIR_FULL_INPUT_VERIFIED")==10
    renders=[diagnostic(p) for p in sorted((OUT/"logs/render-after").glob("*.log"))]
    assert len(renders)==3
    for a in renders:
        assert a["exit_code"]==0 and not any(a[k] for k in ["failure","leaks","errors","orphan_string_names"])
    environment_diagnostics={a["path"]:[line for line in (OUT/a["path"]).read_text(encoding="utf-8-sig").splitlines() if line.startswith("NVAPI: Error")] for a in renders}
    seconds=[a["cleanup"][0]["seconds"] for a in after_runs]
    summary={"id":"r4","finding":"G2-T01","matrix":matrix,"native_runs":after_runs,
        "source_checks":source_checks,"soak_before":soak_before,"soak_after":soak_after,
        "cleanup_seconds":{"samples":len(seconds),"min":min(seconds),"median":statistics.median(seconds),"max":max(seconds)},
        "render_runs":renders,"render_environment_diagnostics":environment_diagnostics,"preservation":preservation,
        "classification":{"fixture_only_files":len(changes["files"]),"reusable_runtime_changes":[]},
        "expected_invalid_input_warnings":{"affected_native_matrix":[],"scope":"G2's unrelated invalid-input/save-recovery diagnostics were not replayed or reclassified; original reports remain preserved."}}
    (OUT/"evidence/result.json").write_text(json.dumps(summary,indent=2)+"\n",encoding="utf-8")
    DOCS.mkdir(parents=True,exist_ok=True)
    compact={k:v for k,v in summary.items() if k not in ["matrix","soak_before","soak_after","preservation"]}
    compact["before_after"]=[{"fixture":m["fixture"],"before_log":m["before"]["path"],"before_leaks":m["before"]["leak_types"],
                              "after_log":m["after"]["path"],"after_leaks":m["after"]["leak_types"],
                              "attribution_log":m["attribution"]["log"],"matched_ids":m["attribution"]["matched"]} for m in matrix]
    compact["soak"]={mode:{"seconds":d["seconds"],"checks":d["checks"],"after_release":d["after_release"],
                   "observed_playbacks_alive":d["observed_playbacks_alive"],
                   "iterations":[{"iteration":s["iteration"],"before_create":s["before_create"],"before_dispose":s["before_dispose"],
                                  "after_release":s["after_release"],"observed_playbacks_alive":s["observed_playbacks_alive"]} for s in d["samples"]]}
                    for mode,d in [("reference",soak_before),("repaired",soak_after)]}
    compact["normal_preserved_files"]=preservation["owner_files"]
    (DOCS/"checks.json").write_text(json.dumps(compact,indent=2)+"\n",encoding="utf-8")
    table="\n".join("| "+m["fixture"].upper()+" | "+str(m["before"]["leak_types"].get("AudioStreamWAV",0))+" / "+str(m["before"]["leak_types"].get("AudioStreamPlaybackWAV",0))+" | 0 / 0 | "+str(m["attribution"]["matched"])+" / "+str(m["attribution"]["total"])+" |" for m in matrix)
    trials="\n".join("| "+str(s["iteration"]+1)+" | "+str(s["after_release"]["objects"])+" | "+str(s["after_release"]["resources"])+" | "+str(s["after_release"]["nodes"])+" | "+str(s["after_release"]["orphans"])+" | "+str(s["observed_playbacks_alive"])+" |" for s in soak_after["samples"])
    text=f"""# ART-07R4 â€” fixture shutdown cleanup

G2-T01 has a fixture-only candidate repair. All eight unchanged original cases
reproduced AudioStreamWAV / AudioStreamPlaybackWAV shutdown leaks. Exact-ID
observer runs attribute them to action-sound players below the completed fixture.
All 22 repaired native runs, including fresh-process partial/final/depleted
restores, pass the unchanged assertions and finish without ObjectDB, leaked
instance, orphan StringName, warning or fatal-error diagnostics.

Owner visual acceptance remains pending. Ordinary-world rollout is outside scope.

## Evidence

Counts below show a selected fresh unchanged baseline, followed by its repaired
flow. Leaks are intermittent; every repeat, including clean baseline runs, is
retained. The exact-ID attribution column refers to a separate observed run of
the same unchanged fixture, not cross-process ID matching.

| Fixture | Before WAV / playback | After WAV / playback | Trace IDs matched |
|---|---:|---:|---:|
{table}

See checks.json for exact log paths/hashes, native assertion markers, process
IDs, private state locations and the complete restart matrix. Full verbose
stdout/stderr, runner metadata, JSON saves and ID-to-cue/owner records are sealed.
No assertion or diagnostic was removed or whitelisted. The three verbose render
logs retain NVAPI's application-profile message
`NVAPI_EXECUTABLE_ALREADY_IN_USE(code -167)`; it is separate from ObjectDB
shutdown and native assertion results. The prepared Compatibility smoke retains
its SSAO/Forward+ feature warning. These diagnostics were not suppressed or
classified as expected invalid input. The affected matrix
produces no expected invalid-input warning. G2's separate invalid-input and
save-recovery warnings remain in the preserved original report; they are not
cleanup successes.

## Repeated lifecycle

Twelve cycles use the original B3 native presentation adapter and Wroughtwild
work/SaveManager path: create a player and finite boulder, work to partial stock,
write/read and compare identity/work/ownership, deplete once, collect exactly nine
units, write/read exhausted state, then dispose that cycle's descendants.

Both reference and repaired exercises pass 156 checks. Reference exercise:
{soak_before['seconds']:.6f} seconds, {soak_before['observed_playbacks_alive']}
observed playback references still alive at its last release measurement.
Repaired exercise: {soak_after['seconds']:.6f} seconds, zero observed playback
references after each disposal. Expired weak observers are removed before the
object sample. Shared PCM clips remain cached and usable by the next cycle.

| Cycle | Objects after release | Resources | Nodes | Orphans | Observed playback alive |
|---:|---:|---:|---:|---:|---:|
{trials}

checks.json records counts before player/resource creation (with the empty cycle
scope already added), before disposal and after release in both exercises,
including static-byte samples. Counts are Godot Performance/ObjectDB monitors,
not process RSS. Both reference and repaired release counts are stable over these
12 cycles. The reference count includes seven live WeakRef observer objects in
addition to the seven still-observed playbacks, so the 14-object difference must
not be described as 14 leaked runtime objects. The reference also exits without
an ObjectDB warning in this run: a pending playback at a sample is not proof of
permanent growth. Static memory includes the
intentionally retained measurement dictionaries and shared caches. These short,
accelerated samples do not establish a long-session, process-RSS, VRAM or
minimum-hardware memory bound.

## Patch and cost

Only finish in B3/C1/C2/C3/C4/F3, finish_e1 in E1 and _done in F2 change. They
release completed fixture descendants, wait for observable audio retirement,
then allow the completion coroutine to unwind before normal deferred quit.
fixture_cleanup.gd and cleanup_options.gd are shared by these test fixtures.
There is **no reusable runtime patch**: InteractionSound, its PCM palette/cache,
native simulation, resource adapters, ordinary game, data and save code remain unchanged.
Source checks prove that every original assertion and every byte outside the
eight finish functions is identical. After engine verification, the two helper
masters had one terminal blank line removed for the staged whitespace check.
Their executable bytes are identical to evidence/diagnostic-source/ after
trimming terminal CR/LF; no extra engine run is claimed for this formatting-only
change. evidence/final-formatting.json retains the earlier hashes and seal.

Teardown elapsed time across 22 headless native jobs: minimum
{min(seconds):.6f} s, median {statistics.median(seconds):.6f} s, maximum
{max(seconds):.6f} s. These are diagnostic teardown timings, not frame benchmarks.
Automatic fixture completion is the measured path; manual Escape exits and
ordinary-game shutdown are unchanged and outside this evidence.
Native tests use the pinned Godot 4.5 engine, headless, fixed 60 FPS; the 12-cycle
exercise has the same settings. The machine is Ryzen 9 9950X3D (16 cores / 32
threads), 33,446,744,064 bytes RAM, Windows 11 Home 26200. Render evidence uses
Compatibility, RTX 5090, 1280Ã—720, fixed 60 FPS. Actual settings/device and all
wrapper durations are in hardware.json and the engine logs. No benchmark was
mixed with import, generation or capture.

## Controls and limits

No player-facing tuning changed. Fixture controls are three pre-disposal frames for queued two-frame UI layout callbacks; two observed mixer
progress events after stop; two main-thread frames for deferred deletion;
one millisecond CPU yield per poll; a two-second failure deadline; twelve
lifecycle cycles. The fixed exercise seed is 7704. Its nine stock units,
three-unit harvest, three drive presses and four initial work calls establish
six units plus one partial press after the first three-unit release. Eight
setup physics frames initialize the native fixture; 48 settle frames allow its
existing depletion animation to finish. Two release frames sample deferred
cleanup. The Warden class and posed player position (0, 1.1, 5) are test inputs,
not a movement or balance change. All values and purposes are retained in the
owned source.

Fresh C3 captures include 42 native fall frames and full/partial/depletion/
aftermath images. They are the existing original models and LOD selection, with
posed native work; no mesh, map, body or animation asset changed. No Blender
generation/reopen was needed. This is not human playtime or owner art acceptance.
All 273 legal pairs and native rules are preserved by unchanged game/data/DLL
hashes; no new shape, recipe, scatter, geography, rig or ordinary rollout occurs.

## R8 application

changes.json names exactly ten fixture-only baseline-relative files and hashes.
No peer repair was consumed. R8 must merge these finish-function changes if
another repair touches the same review file; a hash mismatch is an overlap,
not permission for last-file-wins copying. Shared runtime source edits from R2
are outside this delta. The guarded apply command rejects a changed before-hash.

The original runtime source, G2 review and eight source packages were fully
rehashed before consumption and after repair. {preservation['owner_files']} normal
game/sim/data/save files were preserved with no added, missing or changed file.
The pinned runtime is 6bb2e044dcd0bf1788896aa2c19cdf56fee93522, regardless of the
newer documentation checkout. All engine processes used the unchanged shared
runner, one GPU mutex, existing-process checks and private APPDATA/local/temp/
Blender paths. Busy jobs were deferred without interruption.

See the receipt for package identity and commit SHAs. The worker does not push
main or update the shared delivery index.
"""
    (DOCS/"README.md").write_text(text,encoding="utf-8")
    owner=(DOCS/"ownership.md").read_text(encoding="utf-8-sig")
    owner=owner.replace("Status: attribution and candidate verification in progress.","Status: attribution and candidate verification complete; owner review pending.")
    owner=owner.replace("The intended delta is eight fixture finish functions", "The checked delta is eight fixture finish functions")
    (DOCS/"ownership.md").write_text(owner,encoding="utf-8")
    print("R4_REPORT_VERIFIED",len(after_runs),"native",len(renders),"render",len(matrix),"attributed fixtures")

if __name__=="__main__": build()
