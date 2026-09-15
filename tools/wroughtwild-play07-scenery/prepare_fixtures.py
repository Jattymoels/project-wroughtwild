"""Create only missing private check inputs from the retained RF05 fixture.
Never touches owner saves or playtest progress. Run before checks in this worktree.
The rendered after check writes scenery-start.json from a native supported pose.
"""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[2]
output = root / "build/play07-scenery"
source = root / "build/play03-group/arrival-start.json"
original = json.loads(source.read_text(encoding="utf-8"))
output.mkdir(exist_ok=True)
def keep(name, value):
    path = output / name
    if not path.exists(): path.write_text(json.dumps(value), encoding="utf-8")
keep("arrival-start.json", original)
saved = json.loads(json.dumps(original))
selected = {}
for kind in ("lanternheart", "thrumroot", "stormglass", "pullstone", "ventlung"):
    row = next(r for r in saved["resource_nodes"] if r.get("visual") == kind)
    row["drive_progress"] = 1
    row["remaining_units"] -= 1
    selected[kind] = row["resource_id"]
depleted = next(r["resource_id"] for r in saved["resource_nodes"]
                if r.get("visual") == "pullstone" and r["resource_id"] != selected["pullstone"])
saved["resource_nodes"] = [r for r in saved["resource_nodes"] if r["resource_id"] != depleted]
saved["player"] = {"position": [837.5, 63.0999984741211, 635.5], "yaw": 3.141592653589793, "pitch": -.08}
keep("lifecycle-start.json", saved)
keep("lifecycle-selection.json", {"sources": selected, "depleted": depleted})
