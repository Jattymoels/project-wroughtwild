"""Summarise bounded INT-07G traces without treating frame gaps as CPU/GPU attribution.

The threshold selects long intervals for inspection; it is review-only, not a
game performance target. Individual callback and monitor timings overlap the
three complete event intervals and must not be added to them.
"""
import argparse
import json
import math
from pathlib import Path


def stats(values: list[float]) -> dict:
    ordered = sorted(values)
    if not ordered:
        return {"samples": 0}
    return {"samples": len(ordered), "median_ms": ordered[len(ordered) // 2],
            "p95_ms": ordered[min(len(ordered) - 1, int(len(ordered) * .95))],
            "max_ms": ordered[-1]}


def summarise(rows: list[dict], threshold_ms: float) -> dict:
    # The first interval can cross untimed setup/capture work. Keep it in the
    # raw evidence but exclude it from event-interval comparisons.
    measured = rows[1:]
    errors = []
    for row in measured:
        parts = [row[name] for name in ("cpu_to_draw_ms", "draw_observation_ms", "post_draw_to_process_ms")]
        complete = row["process_to_process_ms"]
        if not all(math.isfinite(v) and v >= 0 for v in parts + [complete, row["frame_ms"]]):
            raise ValueError("Non-finite or negative frame timing")
        errors.append(abs(complete - sum(parts)))
    if errors and max(errors) > .01:
        raise ValueError("Process/draw/gap intervals do not describe the same frame")
    outliers = []
    for index, row in enumerate(measured):
        if row["frame_ms"] < threshold_ms:
            continue
        previous = rows[index]
        changes = {name: row[name] - previous[name] for name in
                   ("pipeline_mesh", "pipeline_surface", "pipeline_draw", "pipeline_specialization")}
        outliers.append({"frame": row["frame"], "frame_ms": row["frame_ms"],
                         "metres": row.get("metres"), "window": row.get("window", "travel"),
                         "terrain_ms": row["terrain_callback_ms"], "stage": row["executed_stage"],
                         "cpu_to_draw_ms": row["cpu_to_draw_ms"], "draw_wall_ms": row["draw_observation_ms"],
                         "post_draw_to_process_ms": row["post_draw_to_process_ms"],
                         "physics_callbacks_ms": row["physics_callbacks_ms"],
                         "post_draw_to_first_physics_ms": row["post_draw_to_first_physics_ms"],
                         "last_physics_to_process_ms": row["last_physics_to_process_ms"],
                         "pipeline_changes": changes})
    return {"frames": stats([r["frame_ms"] for r in measured]),
            "max_partition_error_ms": max(errors, default=0.0),
            "safety_refills": sum(r.get("safety_refills", 0) for r in measured),
            "terrain_ms": stats([r["terrain_callback_ms"] for r in measured]),
            "cpu_to_draw_ms": stats([r["cpu_to_draw_ms"] for r in measured]),
            "draw_wall_ms": stats([r["draw_observation_ms"] for r in measured]),
            "post_draw_to_process_ms": stats([r["post_draw_to_process_ms"] for r in measured]),
            "long_intervals": outliers}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("directory", type=Path)
    parser.add_argument("--threshold-ms", type=float, default=100.0,
                        help="Inspection threshold for rare long intervals, default 100 ms.")
    parser.add_argument("--output", type=Path, help="Optional report outside timed measurement.")
    args = parser.parse_args()
    if not math.isfinite(args.threshold_ms) or args.threshold_ms <= 0:
        parser.error("--threshold-ms must be finite and positive")
    manifest = json.loads((args.directory / "manifest.json").read_text(encoding="utf-8"))
    if manifest["failures"]:
        raise ValueError("Source review failed")
    settled = json.loads((args.directory / "settled-frames.json").read_text(encoding="utf-8"))
    travel = json.loads((args.directory / "travel-frames.json").read_text(encoding="utf-8"))
    report = {"hardware": manifest["hardware"], "profile": manifest["profile"], "seed": manifest["seed"],
              "resolution": manifest["resolution"], "fps_cap": manifest["fps_cap"],
              "setup_ms": manifest["world_setup_ms"], "inspection_threshold_ms": args.threshold_ms,
              "scope": "First interval excluded per window. Event intervals partition elapsed time; draw wall time may include GPU waits, and post-draw time includes engine/OS/frame waiting. Neither establishes a root cause alone.",
              "warmup": summarise([r for r in settled if r["window"] == "warmup"], args.threshold_ms),
              "settled": summarise([r for r in settled if r["window"] == "settled"], args.threshold_ms),
              "travel": summarise(travel, args.threshold_ms)}
    encoded = json.dumps(report, indent=2)
    if args.output:
        args.output.write_text(encoded + "\n", encoding="utf-8")
    print(encoded)


if __name__ == "__main__":
    main()
