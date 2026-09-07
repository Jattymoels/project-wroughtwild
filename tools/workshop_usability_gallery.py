"""Validate actual Godot review evidence and build its local comparison page.

No image generation, network, packages, or changes to the running game. Invoke
after both rendered resolutions have finished for both preserved/current phases.
"""
from __future__ import annotations

import argparse
import html
import json
import math
from pathlib import Path
import struct


PHASES = ("baseline", "current")
HEIGHTS = (720, 1080)
VIEWS = (
    ("main", "empty-panel", "An empty workshop", "Read the immediate blocker before loading anything."),
    ("main", "fuel-only-panel", "Fuel without clay", "Ordinary fuel supplies heat; clay is still required."),
    ("main", "ready-panel", "Ready to fire", "The same exact clay, fuel and finite drive are available in both versions."),
    ("main", "firing-panel", "A firing in progress", "Inputs and drive already belong to this firing; its current work remains visible."),
    ("main", "paused-panel", "Paused by the player", "Pause preserves the existing firing without awarding offline work."),
    ("main", "completed-panel", "Completed bricks", "The tray holds sixteen bricks ready for explicit collection."),
    ("workflow", "ready-supplies", "Load or return supplies", "The new supplies page is compared with the preserved version's single list."),
    ("workflow", "ready-supplies-expanded", "Supplies, with details open", "Optional explanation stays available without hiding Close."),
    ("workflow", "ready-drive", "Drive and connections", "Stored drive, the finite pocket and hand winding have a dedicated page."),
    ("workflow", "ready-drive-expanded", "Drive, with details open", "Pressure supplies motion. Ordinary fuel still supplies heat."),
    ("world", "struck-hearth-panel", "The struck old smithy", "An older hearth was hit accidentally. It is a finite source, not a working player forge."),
    ("world", "empty-world", "Empty hopper and tray", "Normal first-person aim and HUD at the actual placed feeder."),
    ("world", "fuel-only-world", "Fuel has its own appearance", "A fuel-only hopper should not advertise a clay load."),
    ("world", "ready-world", "A supplied workshop", "Paid player-built kits stand beside the generated impact site."),
    ("world", "firing-world", "Working machinery", "The unchanged work clock drives the feeder's physical presentation."),
    ("world", "paused-world", "A held firing", "The supplies remain owned while work is paused."),
    ("world", "completed-world", "Bricks in the tray", "Finished output remains in the workshop until collected."),
    ("world", "built-brick-handoff", "Materials used in a home", "Three ordinary masonry pieces were paid for with this feeder's collected bricks."),
)


def read_report(path: Path, height: int) -> dict:
    with path.open(encoding="utf-8-sig") as source:
        report = json.load(source)
    if not isinstance(report, dict):
        raise ValueError(f"Report is not an object: {path}")
    if report.get("height") != height or report.get("profile") != "frontier_v6":
        raise ValueError(f"Wrong resolution or world profile: {path}")
    if report.get("failures") != 0 or not isinstance(report.get("checks"), int) or report["checks"] <= 0:
        raise ValueError(f"Review checks did not pass: {path}")
    if report.get("renderer") in (None, "", "headless"):
        raise ValueError(f"A rendered review is required: {path}")
    number(report.get("world_startup_ms"), "world_startup_ms", path)
    return report


def number(value: object, key: str, path: Path) -> float:
    if isinstance(value, bool) or not isinstance(value, (int, float)) or not math.isfinite(value) or value < 0:
        raise ValueError(f"Invalid {key}: {path}")
    return float(value)


def validate_timing(report: dict, path: Path) -> dict:
    timing = report.get("timing", {})
    for name in ("world", "live_panel"):
        sample = timing.get(name)
        if not isinstance(sample, dict):
            raise ValueError(f"Missing {name} timing: {path}")
        for key in ("frames", "median_ms", "p95_ms", "mean_process_ms", "mean_physics_ms", "mean_draw_calls", "warmup_ms", "sample_ms"):
            number(sample.get(key), key, path)
        if sample["frames"] <= 0 or sample["p95_ms"] < sample["median_ms"]:
            raise ValueError(f"Invalid {name} frame sample: {path}")
        if sample.get("capture_readbacks") != 0 or sample.get("active_machine_count") != 1:
            raise ValueError(f"Unmatched {name} workload: {path}")
        if sample["warmup_ms"] < 3000 or sample["sample_ms"] < 5000:
            raise ValueError(f"Incomplete {name} timing interval: {path}")
    return timing


def validate_captures(report: dict, folder: Path, height: int) -> int:
    expected = {f"{height}p-{key}.png" for _, key, _, _ in VIEWS}
    seen: set[str] = set()
    records = report.get("captures")
    if not isinstance(records, list):
        raise ValueError(f"Missing capture list: {folder}")
    for record in records:
        filename = record.get("file") if isinstance(record, dict) else None
        if not isinstance(filename, str) or Path(filename).name != filename or not filename.startswith(f"{height}p-") or not filename.endswith(".png"):
            raise ValueError(f"Invalid capture filename in {folder}: {filename!r}")
        if filename in seen:
            raise ValueError(f"Duplicate capture: {folder / filename}")
        seen.add(filename)
        path = folder / filename
        if not path.resolve().is_relative_to(folder.resolve()):
            raise ValueError(f"Capture leaves its review folder: {path}")
        with path.open("rb") as source:
            header = source.read(24)
        if len(header) != 24 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
            raise ValueError(f"Capture is not a PNG: {path}")
        width, image_height = struct.unpack(">II", header[16:24])
        if (width, image_height) != (height * 16 // 9, height):
            raise ValueError(f"Wrong capture dimensions: {path} ({width} x {image_height})")
    if not expected <= seen:
        raise ValueError(f"Missing required captures in {folder}: {sorted(expected - seen)}")
    return len(seen)


def load_evidence(root: Path) -> tuple[dict, int]:
    evidence: dict = {}
    capture_count = 0
    identity = None
    for height in HEIGHTS:
        evidence[str(height)] = {}
        for phase in PHASES:
            folder = root / "captures" / phase
            manifest = folder / f"{height}p-manifest.json"
            report = read_report(manifest, height)
            this_identity = (report["profile"], report.get("seed"))
            if identity is None:
                identity = this_identity
            if this_identity != identity:
                raise ValueError(f"Unmatched world identity: {manifest}")
            capture_count += validate_captures(report, folder, height)
            timing_report = report
            timing_path = folder / f"{height}p-performance.json"
            if timing_path.is_file():
                timing_report = read_report(timing_path, height)
                if (timing_report["profile"], timing_report.get("seed")) != identity:
                    raise ValueError(f"Unmatched timing world: {timing_path}")
            else:
                timing_path = manifest
            evidence[str(height)][phase] = {
                "checks": report["checks"], "profile": report["profile"], "seed": report["seed"],
                "startup_ms": report["world_startup_ms"],
                "timing": validate_timing(timing_report, timing_path),
                "manifest": manifest.relative_to(root).as_posix(),
                "timing_source": timing_path.relative_to(root).as_posix(),
            }
    return evidence, capture_count


def render(evidence: dict, capture_count: int) -> str:
    cards = []
    for category, key, title, description in VIEWS:
        pair = []
        for phase, label in (("baseline", "Before · preserved production"), ("current", "After · current slice")):
            path = f"captures/{phase}/720p-{key}.png"
            pair.append(f'<figure><figcaption>{label}</figcaption><a href="{path}" data-phase="{phase}" data-shot="{key}"><img src="{path}" alt="{html.escape(title)} — {label}" width="1280" height="720" loading="lazy"></a></figure>')
        cards.append(f'<section data-category="{category}"{" hidden" if category != "main" else ""}><h2>{html.escape(title)}</h2><p>{html.escape(description)}</p><div class="pair">{"".join(pair)}</div></section>')
    payload = json.dumps(evidence, ensure_ascii=False, separators=(",", ":")).replace("<", "\\u003c").replace(">", "\\u003e").replace("&", "\\u0026")
    return '''<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The pressure workshop · Wroughtwild review</title><style>
:root{color-scheme:dark;font:16px/1.55 system-ui,sans-serif;background:#171c1b;color:#e2dfd2}*{box-sizing:border-box}body{max-width:1560px;margin:0 auto;padding:30px 22px 60px}h1{font-size:clamp(28px,5vw,44px);line-height:1.12;margin:10px 0 18px}h2{font-size:23px;margin:0 0 8px}p{max-width:1020px;color:#bdc7ba;margin:0 0 18px}a{color:#ded2a4}small,.quiet{color:#9faf9f}button{font:inherit;cursor:pointer;border:1px solid #687561;background:#273129;color:#e8e5d5;border-radius:7px;padding:8px 14px}button[aria-pressed=true]{background:#b9c99b;color:#192118}button:focus-visible,a:focus-visible{outline:3px solid #ddc582;outline-offset:3px}.toolbar{display:flex;flex-wrap:wrap;gap:14px;justify-content:space-between;padding:15px 0 22px;border-bottom:1px solid #495247}.buttons{display:flex;flex-wrap:wrap;gap:7px}.pair{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:16px}figure{margin:0;min-width:0}figcaption{color:#c8cfbe;margin-bottom:7px;font-size:14px}img{display:block;width:100%;height:auto;border:1px solid #53604e;border-radius:6px;background:#101511}section{margin:32px 0 45px}section[hidden]{display:none}.facts{padding:18px 20px;margin:24px 0;background:#20281f;border:1px solid #495543;border-radius:8px}.table-wrap{overflow-x:auto}table{border-collapse:collapse;width:100%;font-size:14px}th,td{text-align:left;padding:8px 12px;border-bottom:1px solid #485140;white-space:nowrap}th{color:#c7d2bc}td.rise{color:#e3c27f}details{border-top:1px solid #495247;padding-top:14px;margin-top:20px}summary{cursor:pointer;color:#e0d5b5;margin-bottom:12px}.evidence-links{display:flex;flex-wrap:wrap;gap:6px 22px;font-size:14px}.badge{margin:8px 0 14px;color:#d1d9c4}@media(max-width:800px){body{padding:22px 14px 40px}.pair{grid-template-columns:1fr;gap:18px}.toolbar{gap:16px}th,td{padding:8px}section{margin-top:27px}}
</style></head><body>
<small>WROUGHTWILD · INT-06A · ACTUAL GODOT CAPTURES</small>
<h1>Understand the pressure workshop</h1>
<p>The same finite pocket, placed forge, paid feeder and brick recipe. Compare how the existing work, supplies and stops are presented before and after this usability slice. Click any image for its original resolution.</p>
<div class="toolbar"><nav class="buttons" aria-label="Review area"><button data-category-button="main" aria-pressed="true">Main controls</button><button data-category-button="workflow" aria-pressed="false">Supplies &amp; drive</button><button data-category-button="world" aria-pressed="false">World &amp; building</button></nav><nav class="buttons" aria-label="Capture resolution"><button data-height="720" aria-pressed="true">720p</button><button data-height="1080" aria-pressed="false">1080p</button></nav></div>
<div class="badge" id="status" role="status" aria-live="polite"></div>
''' + "".join(cards) + f'''
<div class="facts"><h2>What this review establishes</h2>
<p>{capture_count} PNG captures were validated against successful rendered manifests, including their actual pixel dimensions. Both phases use the same V6 world identity. Kits and three masonry pieces follow ordinary payment and placement; the review explicitly supplies crafting ingredients and operates actual panel callbacks.</p>
<p>Screenshot states use scripted firing ticks and held first-person poses. Timing uses live feeder physics: three seconds of warmup, then five seconds of actual frames, with no screenshot readbacks. The world sample pans from a fixed grounded approach; the panel sample keeps the active work page open. A separate performance manifest is used when present, and linked below.</p>
<p>These checks establish operation and presentation evidence. They do not measure human comprehension, discovery pace, physical walking, difficulty or enjoyment. The preserved version keeps supplies and drive controls in its original single list.</p>
<h2>Matched local measurements</h2><p class="quiet">One recorded sample per view and resolution. Frame intervals and startup costs can vary between runs; a rise above 10% is highlighted for review.</p>
<div class="table-wrap"><table><thead><tr><th>Measurement</th><th>Before</th><th>After</th><th>Change</th></tr></thead><tbody id="measurements"></tbody></table></div>
<details><summary>Source reports and measurement detail</summary><p id="sample-detail"></p><div class="evidence-links" id="reports"></div></details></div>
<script id="evidence" type="application/json">{payload}</script>
<script>
const evidence=JSON.parse(document.getElementById('evidence').textContent);
function showHeight(height){{
 document.querySelectorAll('[data-height]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.height===height)));
 document.querySelectorAll('[data-shot]').forEach(a=>{{const src='captures/'+a.dataset.phase+'/'+height+'p-'+a.dataset.shot+'.png';a.href=src;a.querySelector('img').src=src}});
 const before=evidence[height].baseline, after=evidence[height].current;
 document.getElementById('status').textContent=height+'p · '+before.profile+' · seed '+before.seed+' · Before: '+before.checks+' checks passed · After: '+after.checks+' checks passed';
 const rows=[['World startup',before.startup_ms/1000,after.startup_ms/1000,'s'],['World frame median',before.timing.world.median_ms,after.timing.world.median_ms,'ms'],['World frame p95',before.timing.world.p95_ms,after.timing.world.p95_ms,'ms'],['Live panel frame median',before.timing.live_panel.median_ms,after.timing.live_panel.median_ms,'ms'],['Live panel frame p95',before.timing.live_panel.p95_ms,after.timing.live_panel.p95_ms,'ms']];
 const body=document.getElementById('measurements');body.replaceChildren();
 rows.forEach(([title,b,a,unit])=>{{const tr=document.createElement('tr');const delta=b>0?(a/b-1)*100:null;[title,b.toFixed(3)+' '+unit,a.toFixed(3)+' '+unit,delta===null?'Unavailable':(delta>0?'+':'')+delta.toFixed(1)+'%'].forEach((text,i)=>{{const td=document.createElement('td');td.textContent=text;if(i===3&&delta>10)td.className='rise';tr.appendChild(td)}});body.appendChild(tr)}});
 document.getElementById('sample-detail').textContent='World frames: '+before.timing.world.frames+' before / '+after.timing.world.frames+' after. Live-panel frames: '+before.timing.live_panel.frames+' before / '+after.timing.live_panel.frames+' after. Each sample has one advancing feeder and zero screenshot readbacks. Startup comes from the capture manifest; timing comes from the linked timing report.';
 const links=document.getElementById('reports');links.replaceChildren();
 [['Before capture manifest',before.manifest],['After capture manifest',after.manifest],['Before timing source',before.timing_source],['After timing source',after.timing_source]].forEach(([title,href])=>{{const a=document.createElement('a');a.textContent=title;a.href=href;links.appendChild(a)}});
}}
document.querySelectorAll('[data-height]').forEach(b=>b.addEventListener('click',()=>showHeight(b.dataset.height)));
document.querySelectorAll('[data-category-button]').forEach(b=>b.addEventListener('click',()=>{{document.querySelectorAll('[data-category-button]').forEach(other=>other.setAttribute('aria-pressed',String(other===b)));document.querySelectorAll('section[data-category]').forEach(section=>section.hidden=section.dataset.category!==b.dataset.categoryButton)}}));
showHeight('720');
</script></body></html>'''


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--review-root", type=Path, default=Path(__file__).resolve().parents[1] / "build" / "workshop-usability")
    args = parser.parse_args()
    root = args.review_root.resolve()
    evidence, capture_count = load_evidence(root)
    # Validate all four reports and every PNG before replacing the last gallery.
    target = root / "index.html"
    temporary = target.with_suffix(".html.tmp")
    temporary.write_text(render(evidence, capture_count), encoding="utf-8")
    temporary.replace(target)
    print(f"Workshop usability gallery: {capture_count} verified PNG captures; {target}")


if __name__ == "__main__":
    main()
