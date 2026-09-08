"""Verify an exported package after relocating it outside the checkout.

All game processes use separate APPDATA/LOCALAPPDATA and Dummy audio. Retains
logs, copied checkpoints and captures in the printed temporary evidence folder.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import tempfile

from export_windows import ROOT, run, sha


def check_missing_tuning(package, evidence, working):
    # A complete checkout exists on this machine. Removing only the packaged
    # tuning in a separate copy proves the export cannot silently fall back to it.
    broken = evidence / "Incomplete package"
    broken.mkdir()
    for child in package.iterdir():
        if child.is_file():
            shutil.copy2(child, broken / child.name)
    env = os.environ.copy()
    env["APPDATA"] = str(broken / "appdata")
    env["LOCALAPPDATA"] = str(broken / "localappdata")
    run([broken / "Wroughtwild.exe", "--headless", "--audio-driver", "Dummy", "--quit-after", "3"],
        working, env, broken / "game.log", timeout=120)
    missing = (broken / "game.log").read_text(encoding="utf-8")
    if "WROUGHTWILD - INCOMPLETE PLAYTEST BUILD" not in missing or "Sim tuning loaded:" in missing:
        raise RuntimeError("Incomplete package did not refuse missing tuning with package instructions")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", type=Path, required=True)
    parser.add_argument("--baseline", action="store_true")
    parser.add_argument("--world-save", type=Path)
    parser.add_argument("--trial-save", type=Path)
    parser.add_argument("--prepare-project", type=Path, help="Pre-change editor project for a generated suspended-trial fixture")
    parser.add_argument("--godot", type=Path)
    parser.add_argument("--headless", action="store_true")
    args = parser.parse_args()
    origin = args.package.resolve()
    manifest = json.loads((origin / "build-manifest.json").read_text())
    for name, expected in manifest["files"].items():
        if sha(origin / name) != expected:
            raise RuntimeError("Package checksum mismatch: " + name)
    evidence = Path(tempfile.mkdtemp(prefix="Wroughtwild-export-check-"))
    package = evidence / "Relocated game with spaces"
    shutil.copytree(origin, package)
    working = evidence / "Unrelated working directory"
    working.mkdir()
    driver = evidence / "portable_build.gd"
    shutil.copy2(ROOT / "game/tests/portable_build.gd", driver)
    print("Evidence: " + str(evidence), flush=True)
    if ROOT in evidence.parents or (package.parent / "data").exists():
        raise RuntimeError("Verification must be outside checkout and without parent data")
    assets = ["res://" + p.relative_to(ROOT / "game").as_posix()
              for p in (ROOT / "game/assets").rglob("*.glb") if ".godot" not in p.parts]

    def case(mode, appdata=None, fixture=None, editor=None):
        output = evidence / mode
        output.mkdir()
        (output / "assets.json").write_text(json.dumps(assets))
        env = os.environ.copy()
        env["APPDATA"] = str(appdata or output / "appdata")
        env["LOCALAPPDATA"] = str(output / "localappdata")
        env["WW_CHECK_MODE"] = mode
        env["WW_CHECK_OUTPUT"] = str(output)
        save_dir = Path(env["APPDATA"]) / "Godot/app_userdata/Wroughtwild"
        save_dir.mkdir(parents=True, exist_ok=True)
        if fixture:
            shutil.copy2(fixture, save_dir / "wroughtwild_save.json")
        flags = ["--audio-driver", "Dummy", "--resolution", "1280x720", "--position", "-9999,-9999"]
        if args.headless or editor:
            flags += ["--headless"]
        command = [package / "Wroughtwild.exe", *flags, "--script", driver, "--", "--world-seed=77"]
        if editor:
            command = [args.godot.resolve(), "--path", editor.resolve(), *flags, "--script", driver, "--", "--world-seed=77"]
        run(command, working, env, output / "game.log", timeout=300)
        log = (output / "game.log").read_text(encoding="utf-8")
        if "SCRIPT ERROR:" in log or "ERROR:" in log or "FAIL PORTABLE:" in log:
            raise RuntimeError(f"Runtime errors: {output / 'game.log'}\n{log[-6000:]}")
        result = json.loads((output / "result.json").read_text())
        if result["failures"]:
            raise RuntimeError(str(result))
        print(f"{mode}: {result['checks']} checks passed", flush=True)
        return save_dir / "wroughtwild_save.json"

    if args.baseline:
        output = evidence / "baseline"
        output.mkdir()
        env = os.environ.copy()
        env["APPDATA"] = str(output / "appdata")
        env["LOCALAPPDATA"] = str(output / "localappdata")
        run([package / "Wroughtwild.exe", "--headless", "--audio-driver", "Dummy", "--quit-after", "3"],
            working, env, output / "game.log", timeout=120)
        log = (output / "game.log").read_text(encoding="utf-8")
        if "Sim tuning failed to load:" not in log:
            raise RuntimeError("Expected baseline tuning failure did not reproduce")
        print("Reproduced baseline: exported native tuning cannot load", flush=True)
        return
    trial = args.trial_save
    if args.prepare_project:
        if not args.godot:
            parser.error("--prepare-project requires --godot")
        trial = case("prepare-trial", editor=args.prepare_project)
    fresh = case("fresh")
    case("restart", appdata=fresh.parents[3])
    if args.world_save:
        case("existing", fixture=args.world_save)
    if trial:
        case("trial", fixture=trial)
    results = {p.parent.name: json.loads(p.read_text()) for p in evidence.glob("*/result.json")}
    check_missing_tuning(package, evidence, working)
    results["missing-tuning"] = {"checks": 1, "failures": 0}
    (evidence / "verification.json").write_text(json.dumps({"package": manifest, "runs": results}, indent=2))
    print("Verified unchanged package: " + str(package), flush=True)


if __name__ == "__main__":
    main()
