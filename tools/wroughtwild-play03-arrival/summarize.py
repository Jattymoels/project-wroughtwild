"""Summarize retained arrival traces after sampling, with no engine work."""
import json
import statistics
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUTPUT = ROOT / "build/play03-arrival"

def stats(rows):
    values = sorted(row["frame_ms"] for row in rows)
    return {"frames": len(values), "median_ms": statistics.median(values),
            "p95_ms": values[min(len(values)-1, int(len(values)*.95))], "max_ms": max(values)}

def summarize(job):
    report = json.loads((OUTPUT / job / "report.json").read_text())
    trace = json.loads(Path(report["trace"]).read_text())
    rows = trace["frames"]
    indices = [i for i, row in enumerate(rows) if any(
        e.get("enemy_id") == "ember_whelp" and e["phase"] == "configure"
        for e in row.get("arrivals", []))]
    assert len(indices) == 1, "This fixture must capture the selected role's first and only setup"
    i = indices[0]
    row = rows[i]
    assert any(e["phase"] == "pack" and e["pack"] == 176 and e["count"] == 1
               for e in row["arrivals"])
    assert row["frame"] >= report["walk_start_frame"]
    settled = [q for q in rows[i+2:] if q["elapsed_s"] <= row["elapsed_s"]+2]
    keys = ["frame", "frame_ms", "position", "draw_wall_ms", "render_setup_cpu_ms",
            "physics_callbacks_ms", "chunk_tick_ms", "resource_tick_ms", "pipeline_mesh",
            "pipeline_surface", "pipeline_specialization", "arrivals"]
    return {"fixture": report, "metadata": trace["metadata"],
            "causal_frame_ms": row["frame_ms"], "arrival_events": row["arrivals"],
            "first_draw_interval": {k: rows[i+1].get(k) for k in keys},
            "recovered_two_seconds": stats(settled),
            "slowest_recovered_interval": max(settled, key=lambda q: q["frame_ms"]),
            "adjacent_intervals": [{k: q.get(k) for k in keys} for q in rows[i-1:i+4]],
            "selected_setup_events_in_whole_trace": len(indices)}

before, after = summarize("before"), summarize("after")
assert before["fixture"]["pack"] == after["fixture"]["pack"]
assert before["fixture"]["initial_position"] == after["fixture"]["initial_position"]
assert before["fixture"]["members"] == after["fixture"]["members"]
result = {"before": before, "after": after,
          "frame_reduction_percent": (1-after["causal_frame_ms"]/before["causal_frame_ms"])*100,
          "lifecycle": json.loads((OUTPUT/"lifecycle/report.json").read_text()),
          "limitations": ["One instrumented V8 seed-77 boar arrival per process; no OS/driver-cold claim.",
              "First before fixture returned 1 for an overbroad empty-all-species-cache assertion: ordinary spawn-area grazers already existed. Retained whole-session events prove no earlier boar setup; corrected assertions check the selected boar in the after run.",
              "The row closing the activation physics contains the preceding draw. First rendering of the new actor is observed in the NEXT interval; wall-time render counters are not direct GPU measurements.",
              "Remaining finished presentation setup exceeds 300 ms. Other arrivals and the underground connection remain unresolved."]}
out = ROOT/"tools/wroughtwild-play03-arrival/evidence/summary.json"
out.parent.mkdir(exist_ok=True)
out.write_text(json.dumps(result,indent=2)+"\n")
print(json.dumps({"reduction_percent": result["frame_reduction_percent"],
                  "before_recovered": before["recovered_two_seconds"],
                  "after_recovered": after["recovered_two_seconds"], "output": str(out)},indent=2))
