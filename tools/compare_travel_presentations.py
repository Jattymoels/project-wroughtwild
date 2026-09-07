"""Compare the INT-07D Godot fixtures with a preserved production snapshot."""
import argparse
import json
from pathlib import Path


def compare(baseline: Path, current: Path, filename: str, fields: tuple[str, ...]) -> int:
    before = json.loads((baseline / filename).read_text(encoding="utf-8"))
    after = json.loads((current / filename).read_text(encoding="utf-8"))
    if before["failures"] or after["failures"]:
        raise ValueError(f"{filename}: a source fixture failed")
    if before["profile"] != after["profile"]:
        raise ValueError(f"{filename}: different world profiles")
    old = {row["id"]: row for row in before["rows"]}
    new = {row["id"]: row for row in after["rows"]}
    if len(old) != len(before["rows"]) or len(new) != len(after["rows"]):
        raise ValueError(f"{filename}: duplicate source IDs")
    if old.keys() != new.keys():
        raise ValueError(f"{filename}: different source IDs")
    mismatches = [key for key in old if any(old[key][field] != new[key][field] for field in fields)]
    if mismatches:
        raise ValueError(f"{filename}: changed presentations: {mismatches}")
    return len(old)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("baseline", type=Path)
    parser.add_argument("current", type=Path)
    parser.add_argument("--kind", choices=("resources", "leylines"), required=True)
    args = parser.parse_args()
    filename, fields = ("resource-presentation.json", ("category", "states")) if args.kind == "resources" else ("leyline-meshes.json", ("sha256", "triangles"))
    count = compare(args.baseline, args.current, filename, fields)
    print(f"{args.kind}: {count} exact matching presentations; no missing, additional or changed IDs")


if __name__ == "__main__":
    main()
