"""Validate and collect INT-18A receipts; no engine or gameplay mutations."""
import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CASES = ("baseline", "crossfire", "relentless_boss")


def read(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    receipts = ROOT / "build/int18-a"
    names = list(CASES) + ["control-" + case for case in CASES]
    names += ["sound-crossfire", "ember-crossfire"]
    rows = {name: read(receipts / (name + ".json")) for name in names}
    checks = 0

    def require(condition, message):
        nonlocal checks
        assert condition, message
        checks += 1

    for prefix in ("", "control-"):
        baseline = rows[prefix + "baseline"]
        for case in CASES:
            row = rows[prefix + case]
            require(row["preparation"]["native_sha256"] == baseline["preparation"]["native_sha256"], prefix + case + " has identical prepared native state")
            for field in ("id", "seed", "slot", "tier", "module_order", "material_target", "boss_id", "equipment_rewards", "completion_components", "reward_multiplier"):
                require(row["offer"][field] == baseline["offer"][field], prefix + case + " preserves " + field)
            rolled = [condition for condition in row["offer"]["conditions"] if condition["id"] not in ("crossfire", "relentless_boss")]
            require(rolled == baseline["offer"]["conditions"], prefix + case + " preserves rolled risks")
            expected_pressure = "" if case == "baseline" else case
            require(row["offer"]["pressure"] == expected_pressure, "exact selected pressure")
            require(row["settlement"]["gate"]["last_pressure"] == expected_pressure, "saved remembered pressure")
            require(row["settlement"]["gate"]["last_tier"] == 1, "saved remembered tier")
            require(row["offer"]["cache_materials"]["raw_clay"] == (28 if case == "baseline" else 36), "exact targeted cache rounding")
            require(row["offer"]["secret_materials"]["raw_clay"] == (28 if case == "baseline" else 36), "exact targeted secret rounding")
            for kind in ("iron_ingot", "marrow", "quicksilver", "vanguard"):
                require(row["offer"]["cache_materials"][kind] == baseline["offer"]["cache_materials"][kind], "no unrelated reward bonus")

    for name, row in rows.items():
        require(row["failures"] == 0, name + " has no failed assertions")
        require(row["outcome"] in ("victory", "death"), name + " is an honestly completed attempt")
        require(isinstance(row["offer"]["seed"], str), name + " retains exact seed text")
        require(all(room["casts"] > 0 for room in row["rooms"]), name + " fights each entered room")
        require(all(room.get("floor_rescue_frames", 0) == 0 for room in row["rooms"]), name + " never needs a floor rescue")
        require(all(room["max_live_enemies"] <= 24 and room["max_major_hazards"] <= 2 for room in row["rooms"]), name + " respects live caps")
        require(sum(room["damage_taken"] for room in row["rooms"]) > 0, name + " has live incoming damage")
        if row["outcome"] == "victory":
            require(len(row["rooms"]) == 5 and all(room["cleared"] for room in row["rooms"]), name + " earns all five clears")
            require(sum(room["kills"] for room in row["rooms"]) == 49, name + " earns every native encounter death")
        else:
            require(row["rooms"][-1]["died"] and row["rooms"][-1]["life_after_combat"] == 0, name + " ends in real death")
        for mode in ("restart", "preentry"):
            recovery = read(receipts / (name + "-" + mode + ".json"))
            require(recovery["failures"] == 0, name + " fresh " + mode + " passes")
            row[mode] = recovery
        for payment in row["preparation"]["payments"]:
            require(payment["result"]["crafted"], name + " pays " + payment["recipe"])
            for cost in payment["costs"]:
                before = payment["before_inventory"].get(cost["id"], payment["before_purse"].get(cost["id"], 0))
                after = payment["after_inventory"].get(cost["id"], payment["after_purse"].get(cost["id"], 0))
                require(before - after >= cost["need"], name + " consumes " + cost["id"])

    compact = {}
    for name, row in rows.items():
        prepared = row["preparation"]
        payments = []
        for payment in prepared["payments"]:
            delta = {}
            for field in ("inventory", "purse"):
                before, after = payment["before_" + field], payment["after_" + field]
                delta[field] = {key: after.get(key, 0) - before.get(key, 0) for key in sorted(before.keys() | after.keys()) if after.get(key, 0) != before.get(key, 0)}
            payments.append({key: payment[key] for key in ("recipe", "quality", "fuel_heat", "result")} | {"delta": delta})
        compact[name] = {key: row[key] for key in ("case", "outcome", "checks", "failures", "offer", "rooms", "run_seconds", "combat_and_gallery_metres", "approach_and_gallery_metres", "combat_seed", "restart", "preentry")}
        compact[name]["preparation"] = {key: prepared[key] for key in ("native_sha256", "kit", "stats", "bar", "plate", "equipment")}
        compact[name]["preparation"]["payments"] = payments
        compact[name]["settlement"] = {key: row["settlement"][key] for key in ("native_sha256", "inventory", "currency", "gate", "offers", "checkpoint_ms")}
        compact[name]["damage_by_source"] = {}
        for event in row["damage_events"]:
            source = event["source"].split("  ·  ")[0]
            result = compact[name]["damage_by_source"].setdefault(source, {"hits": 0, "damage": 0})
            result["hits"] += 1
            result["damage"] += event["damage"]
        compact[name]["raw_receipt_sha256"] = hashlib.sha256((receipts / (name + ".json")).read_bytes()).hexdigest()
    output = {
        "purpose": "INT-18A matched live five-room attempts, including natural deaths; not human balance acceptance.",
        "source_commit_before_slice": "4f0886b",
        "engine": "4.5.stable.official.876b29033",
        "physics_hz": 60,
        "matched_cohorts": [list(CASES), ["control-" + case for case in CASES]],
        "diagnostic_preparations": ["sound-crossfire", "ember-crossfire"],
        "receipt_checks": checks,
        "files_sha256": {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in (
            "game/tests/fixtures/lf6-published-ending.json.gz",
            "game/tests/laboratory_pressure_runs.gd",
            "data/tuning/trial.json", "data/tuning/crafting.json", "data/tuning/foundry.json",
        )},
        "attempts": compact,
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"INT18_RECEIPTS {checks} checks, 0 failures; {len(rows)} attempts")
    for name, row in rows.items():
        rooms = row["rooms"]
        print(f"{name}: {row['outcome']}, rooms={len(rooms)}, combat={sum(r['elapsed_seconds'] for r in rooms):.2f}s, damage={sum(r['damage_taken'] for r in rooms):.2f}, casts={sum(r['casts'] for r in rooms)}, kills={sum(r['kills'] for r in rooms)}, minimum={min(r['minimum_life_fraction'] for r in rooms):.2%}")


if __name__ == "__main__":
    main()
