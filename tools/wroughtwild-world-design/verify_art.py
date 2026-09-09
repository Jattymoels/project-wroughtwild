"""Verify ART-07 concept provenance, image integrity and new document links.

--seal initializes missing provenance fields from unchanged local originals.
It does not overwrite an existing recorded hash or bless changed image bytes.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "docs/art/concepts/environment/2026-09-09-frontier"
REFERENCE = "docs/art/references/environment/env-002-dense-frontier-original.png"


def digest(value):
    return hashlib.sha256(value).hexdigest()


def require(condition, message):
    if not condition:
        raise ValueError(message)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--seal", action="store_true")
    args = parser.parse_args()
    manifest_path = OUT / "image-manifest.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    records = manifest["images"]
    expected = {"01-world-keyframe.png", "02-habitat-kits.png", "03-building-family.png",
                "04-stations-and-home-v01.png", "04-stations-and-home.png", "05-useful-fixtures.png"}
    require(len(records) == len(expected) and {r['file'] for r in records} == expected,
            "Missing, unexpected or duplicate concept record")
    originals_checked = 0
    for record in records:
        file = OUT / record["file"]
        raw = file.read_bytes()
        with Image.open(file) as im:
            require(im.format == "PNG", f"Not PNG: {file}")
            dimensions = list(im.size)
            im.verify()
        original = Path(record["generated_original"])
        if original.exists():
            require(original.read_bytes() == raw, f"Changed generated original copy: {file}")
            originals_checked += 1
        prompt_bytes = record["prompt"].encode("utf-8")
        prompt_path = OUT / record["prompt_file"]
        if args.seal and "sha256" not in record:
            require(original.exists(), f"Cannot initialize without generated original: {file}")
            record["sha256"] = digest(raw)
            record["dimensions"] = dimensions
            record["prompt_sha256"] = digest(prompt_bytes)
            prompt_path.write_bytes(prompt_bytes)
        require(digest(raw) == record.get("sha256"), f"Image hash mismatch: {file}")
        require(dimensions == record.get("dimensions"), f"Dimensions mismatch: {file}")
        require(prompt_path.read_bytes() == prompt_bytes, f"Submitted prompt mismatch: {prompt_path}")
        require(digest(prompt_bytes) == record.get("prompt_sha256"), f"Prompt hash mismatch: {file}")
    by_file = {r["file"]: r for r in records}
    for record in records:
        if record["edit_parent"]:
            parent = by_file[record["edit_parent"]]
            if args.seal and "edit_parent_sha256" not in record:
                record["edit_parent_sha256"] = parent["sha256"]
            require(record["edit_parent_sha256"] == parent["sha256"], "Edit parent changed")
    reference_hash = digest((ROOT / REFERENCE).read_bytes())
    if args.seal and "mood_reference" not in manifest:
        manifest["mood_reference"] = {"path": REFERENCE, "sha256": reference_hash,
                                      "use": "Inspected for composition; preserved unchanged; not attached to image generation."}
    require(manifest["mood_reference"]["sha256"] == reference_hash, "Original landscape reference changed")

    docs = [OUT / "README.md", OUT / "asset-catalogue.md",
            ROOT / "docs/prototype/world-and-placeable-art-2026-09-09.md",
            Path(__file__).parent / "README.md"]
    links_checked = 0
    for doc in docs:
        content = doc.read_text(encoding="utf-8")
        for target in re.findall(r'\]\(([^)]+)\)', content):
            if target.startswith(("http:", "https:", "#")):
                continue
            path = target.split("#", 1)[0].strip("<>")
            require((doc.parent / path).resolve().exists(), f"Broken local link in {doc}: {target}")
            links_checked += 1
    if args.seal:
        manifest_path.write_bytes((json.dumps(manifest, indent=2, ensure_ascii=False) + "\n").encode("utf-8"))
    print(json.dumps({"result": "PASS", "pngs": len(records), "selected_boards": 5,
                      "superseded_framing_board": 1, "exact_prompts": len(records),
                      "generated_original_copies_checked": originals_checked,
                      "edit_parent_links": sum(bool(r['edit_parent']) for r in records),
                      "unchanged_mood_reference": 1, "local_links_checked": links_checked}, indent=2))


if __name__ == "__main__":
    main()
