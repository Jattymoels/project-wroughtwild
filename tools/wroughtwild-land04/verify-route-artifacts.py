"""Verify only the retained route correction artifacts; never launch a game.

Godot JSON.parse_string represents JSON numbers as float, while hash() produces
an int. Deep Variant equality therefore rejected an otherwise exact persisted
journey hash. Decimal JSON decoding below retains exact numeric values while
normalizing int/float spelling. Original game/checkpoint evidence is read-only.
"""
from decimal import Decimal
from hashlib import sha256
from pathlib import Path
import json
import sys

root = Path(__file__).resolve().parents[2]
out = root / "build" / "land04"
paths = {name: out / name for name in (
    "expected-before-routefix.json", "expected.json",
    "corrected_route-checks.json", "private-world.json",
)}
raw = {name: path.read_bytes() for name, path in paths.items()}
def decode(name):
    return json.loads(raw[name], parse_int=Decimal, parse_float=Decimal)
old = decode("expected-before-routefix.json")
current = decode("expected.json")
route = decode("corrected_route-checks.json")
checks = []
def check(ok, label):
    checks.append({"passed": bool(ok), "label": label})
    if not ok:
        print("FAIL LAND04 route artifacts:", label)

check(old.keys() == current.keys(), "expected field set remains exact")
old_other = {k: v for k, v in old.items() if k != "journey_hash"}
current_other = {k: v for k, v in current.items() if k != "journey_hash"}
check(old_other == current_other,
      "decoded expectation differs from original backup only in journey_hash")
check(old["journey_hash"] == route["prior_journey_hash"] and
      current["journey_hash"] == route["final_journey_hash"] and
      old["journey_hash"] != current["journey_hash"],
      "old and new journey hashes exactly match the retained route report")
checkpoint_hash = sha256(raw["private-world.json"]).hexdigest()
check(checkpoint_hash == route["checkpoint_sha256"],
      "paid checkpoint SHA-256 exactly matches the completed corrected-route run")
check(route["checks"] == 34 and route["failures"] == 1,
      "original 33/34 rendered result remains explicitly recorded")
check(all(path.read_bytes() == raw[name] for name, path in paths.items()),
      "all four input evidence artifacts remain byte-for-byte unchanged")
failures = sum(not item["passed"] for item in checks)
report = {
    "checks": len(checks), "failures": failures, "details": checks,
    "prior_journey_hash": int(old["journey_hash"]),
    "final_journey_hash": int(current["journey_hash"]),
    "checkpoint_sha256": checkpoint_hash,
    "original_route_report_sha256": sha256(raw["corrected_route-checks.json"]).hexdigest(),
    "original_expectation_sha256": sha256(raw["expected-before-routefix.json"]).hexdigest(),
    "diagnosis": "Final engine artifact assertion compared JSON-parsed float to newly inserted int hash in deep Variant equality. Exact Decimal decoding confirms only journey_hash value changed; prior dug/height numeric spellings changed from integer to .0 without value changes. corrected_route.gd now JSON-normalizes both assertion operands.",
    "scope": "Standalone artifact verification only. Original 33/34 renderer result and 183/184 use result retained; no game, source work, native build or renderer rerun.",
}
(out / "route-artifact-checks.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
print(f"LAND04_ROUTE_ARTIFACTS {len(checks)} checks / {failures} failures")
print(json.dumps({k: report[k] for k in ("prior_journey_hash", "final_journey_hash", "checkpoint_sha256")}))
sys.exit(1 if failures else 0)