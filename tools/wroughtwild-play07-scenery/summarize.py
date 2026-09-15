"""Summarize retained opt-in captures; no game runs or baseline reconstruction."""
import json
import math
import statistics
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
BUILD = ROOT / "build/play07-scenery"

def read(path):
    return json.loads(Path(path).read_text(encoding="utf-8-sig"))

def stats(rows):
    values = sorted(row["frame_ms"] for row in rows)
    return {"intervals": len(values), "median_ms": statistics.median(values),
            "p95_ms": values[math.ceil(len(values) * .95) - 1], "max_ms": max(values)}

result = {"scope": "One retained V8 seed-77 route. Cold process, existing OS/driver/import caches. Nested spans are not additive.",
          "boundaries": "Walking excludes the horn frame; recovery and first-view end indices are exclusive. The explicit final stop row contains fixture serialization/source probes, not travel.",
          "native_dll_sha256": "fbf7067477d63693e35b5d15ccff0bbad86be7586d679e284a44c843b0404e2b"}
for job in ("before", "after"):
    report = read(BUILD / job / "report.json")
    trace = read(report["trace"])
    rows = trace["frames"]
    events = [event for row in rows for event in row.get("arrivals", [])]
    selected = {"report": report, "process_result": read(BUILD / (job + "-result.json")),
                "preparation": [e for e in events if e["phase"].startswith("scenery_prep")],
                "pullstone_frame": next(row for row in rows if row.get("resource_arrival_visual") == "pullstone"),
                "group_frame": next(row for row in rows if row["frame"] == report["trigger_frame"] + 1),
                "relocation_frame": next(row for row in rows if row["frame"] == 2),
                "arrival_events_dropped": sum(row.get("arrival_events_dropped", 0) for row in rows),
                "overwritten_frames": trace["metadata"]["overwritten_frames"]}
    for name, start, end in (("settling", 3, report["walk_start_frame"]+1),
                            ("walking", report["walk_start_frame"]+1, report["trigger_frame"]+1),
                            ("recovery", report["trigger_frame"]+2, report["recovery_end_frame"]),
                            ("first_view", report.get("first_view_frame",0)+1, report.get("first_view_end_frame",0))):
        window = [row for row in rows if start <= row["frame"] < end]
        if window:
            selected[name] = stats(window)
            if name == "first_view": selected["first_view_interval"] = window[0]
    # Preserve all measured stages of rare-source attachment in the coverage probe.
    selected["source_events"] = [e for e in events if e["phase"].startswith("scenery_") and not e["phase"].startswith("scenery_prep")]
    result[job] = selected
assert result["before"]["report"]["group"] == result["after"]["report"]["group"]
assert result["before"]["report"]["initial_position"] == result["after"]["report"]["initial_position"]
for job in ("lifecycle", "device", "retire"):
    result[job] = {"process_result": read(BUILD / (job+"-result.json"))}
    if job != "retire":
        report = read(BUILD / job / "report.json")
        result[job]["report"] = report
        result[job]["preparation"] = [e for row in read(report["trace"])["frames"] for e in row.get("arrivals",[]) if e["phase"].startswith("scenery_prep")]
result["check_corrections"] = [
    "Two initial diagnostic launches stopped at a duplicate local-variable parse error before entry; corrected before valid before capture.",
    "Two intermediate after runs reported renderer null-material errors on stormglass retirement. Tiny retire probe isolated the issue; retaining immutable F1 bore finishes fixed it. Final after and retire have zero engine errors.",
    "Lifecycle recorded 97/99: its only two failures used wind instead of the bellows' existing prime action. Corrected device-only subcheck passes 6/6. Continue/source checks were reused, not relabelled as a clean 99/99 run."
]
# Keep evidence small: full source event lists and synthetic fixture frames remain in raw local traces.
for job in ("before", "after"):
    del result[job]["source_events"]
    for name in ("group_frame", "relocation_frame", "first_view_interval"):
        if name in result[job]:
            row = result[job][name]
            result[job][name] = {key: value for key, value in row.items() if key != "arrivals"}
output = Path(__file__).parent / "evidence/summary.json"
output.parent.mkdir(exist_ok=True)
output.write_text(json.dumps(result, indent=2)+"\n", encoding="utf-8")
print(output)
