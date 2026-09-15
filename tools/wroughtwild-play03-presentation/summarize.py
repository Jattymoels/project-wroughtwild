"""Read completed scoped traces; never launches Godot or changes the game."""
import json
import statistics
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "build/play03-presentation"

def stats(rows):
    times = sorted(r["frame_ms"] for r in rows)
    return {"frames":len(times),"median_ms":statistics.median(times),
            "p95_ms":times[min(int(len(times)*.95),len(times)-1)],"max_ms":max(times)}

def read(job):
    report=json.loads((OUTPUT/job/"report.json").read_text())
    trace=json.loads(Path(report["trace"]).read_text())
    rows=trace["frames"]
    i=next(i for i,r in enumerate(rows) if any(e.get("enemy_id")=="ember_whelp" and e["phase"]=="configure" for e in r.get("arrivals",[])))
    approach=[r for r in rows if report["walk_start_frame"]<=r["frame"]<rows[i]["frame"]]
    preparation=[e for r in rows for e in r.get("arrivals",[]) if e["phase"].startswith("fauna_prepare") or e["phase"]=="fauna_world_preparation"]
    first=[r for r in rows if any(e["phase"]=="fixture_position" for e in r.get("arrivals",[]))]
    marker_dropped=not first
    # In the before trace startup grazers overflow the bounded interval. The
    # fixture pose is already in row 0; row 1 retains its following refill/draw.
    if marker_dropped:
        assert rows[0].get("arrival_events_dropped",0)>0
        assert abs(rows[0]["position"][0]-report["initial_position"][0])<.001
        first=[rows[1]]
    settled=[r for r in rows if first[0]["frame"]<r["frame"]<report["walk_start_frame"]]
    return {"report":report,"hardware":trace["metadata"],"preparation":preparation,
            "arrival":rows[i],"first_draw":rows[i+1],"approach":stats(approach),
            "worst_approach":max(approach,key=lambda r:r["frame_ms"]),
            "recovery":stats(rows[i+2:-1]),"worst_recovery":max(rows[i+2:-1],key=lambda r:r["frame_ms"]),
            "fixture_marker_dropped":marker_dropped,"fixture_relocation_interval":first[0],"settling_before_walk":stats(settled)}

before,after=read("before"),read("after")
assert before["report"]["pack"]==after["report"]["pack"]
assert before["report"]["members"]==after["report"]["members"]
assert before["report"]["initial_position"]==after["report"]["initial_position"]
assert not any(e["phase"].startswith("fauna_prepare") for r in [after["arrival"],after["first_draw"]] for e in r.get("arrivals",[]))
life=json.loads((OUTPUT/"lifecycle/report.json").read_text())
lt=json.loads(Path(life["trace"]).read_text())
life["preparation"]=[e for r in lt["frames"] for e in r.get("arrivals",[]) if e["phase"]=="fauna_world_preparation"]
summary={"before":before,"after":after,"continue":life,
         "previous_slice":"de0125f2062d9cd628b44bd23e76094676336d11",
         "native_dll_sha256":"fbf7067477d63693e35b5d15ccff0bbad86be7586d679e284a44c843b0404e2b",
         "limits":["One selected normal boar arrival per process; resource preparation is production startup work, with no hidden actors.",
                   "The relocation frame is fixture setup, retained separately. No preload occurs in the 90-frame settling wait.",
                   "Nested spans overlap. Arrival row contains preceding draw; first draw is the following row. No GPU-only or OS-cold claim.",
                   "Historical 114.660 ms non-arrival event and underground connection remain open; six newer replacement presentations are unchanged."]}
path=ROOT/"tools/wroughtwild-play03-presentation/evidence/summary.json"
path.parent.mkdir(exist_ok=True)
path.write_text(json.dumps(summary,indent=2)+"\n")
print(json.dumps({"arrival_before_ms":before["arrival"]["frame_ms"],"arrival_after_ms":after["arrival"]["frame_ms"],"continue":life,"summary":str(path)},indent=2))
