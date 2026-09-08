"""Export the pinned Windows prototype from a fresh, isolated source snapshot.

Python stdlib only. See docs/prototype/portable-build-2026-09-08.md.
Never replaces game/bin or uses the owner's Godot settings/save directory.
"""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time
import zipfile

ROOT = Path(__file__).resolve().parents[1]
ENGINE = "4.5.stable.official.876b29033"


def git(*args, cwd=ROOT):
    return subprocess.check_output(["git", *args], cwd=cwd).decode().strip()


def sha(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def run(args, cwd, env, log, timeout=1800):
    print(f"Running {log.name}", flush=True)
    with log.open("w", encoding="utf-8") as stream:
        process = subprocess.Popen([str(a) for a in args], cwd=cwd, env=env,
                                   stdout=stream, stderr=subprocess.STDOUT,
                                   creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            code = process.wait(timeout)
        except subprocess.TimeoutExpired:
            # Only terminate the process tree started by this invocation.
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                           capture_output=True, creationflags=subprocess.CREATE_NO_WINDOW)
            raise RuntimeError(f"Timed out: {log}")
    if code:
        raise RuntimeError(f"Exit {code}: {log}\n{log.read_text(encoding='utf-8')[-5000:]}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True, type=Path)
    parser.add_argument("--templates", required=True, type=Path,
                        help="Official 4.5 TPZ, or folder containing windows_release_x86_64.exe")
    parser.add_argument("--compiler-bin", type=Path, help="MinGW-w64 bin folder if absent from PATH")
    parser.add_argument("--jobs", type=int, default=8)
    parser.add_argument("--allow-dirty", action="store_true",
                        help="Review only: include current source edits; label by content digest")
    parser.add_argument("--label", default="playtest", help="A simple local artifact label")
    args = parser.parse_args()
    if not args.label.replace("-", "").replace("_", "").isalnum():
        parser.error("label must contain only letters, numbers, hyphens and underscores")
    status = git("status", "--porcelain")
    if status and not args.allow_dirty:
        raise RuntimeError("Commit/check source changes first, or use --allow-dirty for a labelled review build")
    submodule = ROOT / "third_party/godot-cpp"
    pinned = git("ls-tree", "HEAD", "third_party/godot-cpp").split()[2]
    if git("rev-parse", "HEAD", cwd=submodule) != pinned or git("status", "--porcelain", cwd=submodule):
        raise RuntimeError("godot-cpp must be clean at the tracked submodule revision")
    files = git("ls-files", "--cached", "--others", "--exclude-standard", "-z").split("\0")
    files = sorted(set(f for f in files if (f.startswith(("game/", "sim/", "data/tuning/")) or
                       f in ("tools/export_windows.py", "tools/windows-playtest-README.txt")) and (ROOT / f).is_file()))
    inputs = {f: sha(ROOT / f) for f in files}
    digest = hashlib.sha256(json.dumps(inputs, sort_keys=True).encode()).hexdigest()
    revision = git("rev-parse", "HEAD")
    version = revision[:12] + ("-review-" + digest[:8] if status else "")
    folder = ROOT / "build/windows" / (args.label + "-" + time.strftime("%Y%m%d-%H%M%S"))
    folder.mkdir(parents=True, exist_ok=False)
    source = folder / "source"
    for name in files:
        destination = source / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, destination)
    for name in git("ls-files", "-z", cwd=submodule).split("\0"):
        if not name:
            continue
        destination = source / "third_party/godot-cpp" / name
        destination.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(submodule / name, destination)
    logs = folder / "logs"
    logs.mkdir()
    env = os.environ.copy()
    env["APPDATA"] = str(folder / "appdata")
    env["LOCALAPPDATA"] = str(folder / "localappdata")
    Path(env["APPDATA"]).mkdir()
    Path(env["LOCALAPPDATA"]).mkdir()
    if args.compiler_bin:
        env["PATH"] = str(args.compiler_bin.resolve()) + os.pathsep + env["PATH"]
    godot = args.godot.resolve()
    run([godot, "--version"], source, env, logs / "version.log")
    if ENGINE != (logs / "version.log").read_text().strip():
        raise RuntimeError(f"Requires pinned Godot {ENGINE}")
    template = args.templates.resolve()
    if template.is_file():
        with template.open("rb") as stream:
            archive_sha512 = hashlib.file_digest(stream, "sha512").hexdigest()
        if archive_sha512 != "1643140ac56ba8e6d18be34eb27788ec6a216e4a3f45dbcc3e01caf2b28ae9c8229832061e30200e296a1be46cec61e2b54c6d9df190b921ea1d0ad5f3f25ed1":
            raise RuntimeError("Archive differs from the official pinned Godot 4.5 SHA-512")
        templates = folder / "templates"
        templates.mkdir()
        with zipfile.ZipFile(template) as archive:
            if archive.read("templates/version.txt").decode().strip() != "4.5.stable":
                raise RuntimeError("Export templates must be 4.5.stable")
            # Extract only the two known names, never arbitrary archive paths.
            for name in ("windows_release_x86_64.exe", "windows_debug_x86_64.exe"):
                with archive.open("templates/" + name) as src, (templates / name).open("wb") as dest:
                    shutil.copyfileobj(src, dest)
    else:
        templates = template
    run([templates / "windows_release_x86_64.exe", "--version"], source, env, logs / "template-version.log")
    if (logs / "template-version.log").read_text().strip() != ENGINE:
        raise RuntimeError("Export template engine/version does not match the editor")
    game = source / "game"
    preset = game / "export_presets.cfg"
    config = preset.read_text(encoding="utf-8")
    for kind in ("release", "debug"):
        binary = templates / ("windows_" + kind + "_x86_64.exe")
        if not binary.is_file():
            raise RuntimeError(f"Missing template: {binary}")
        config = config.replace(f'custom_template/{kind}=""', f'custom_template/{kind}="{binary.as_posix()}"')
    preset.write_text(config, encoding="utf-8")
    project = game / "project.godot"
    project.write_text(project.read_text(encoding="utf-8").replace('[application]',
                       '[application]\n\nconfig/version="' + version + '"'), encoding="utf-8")
    package = folder / ("Wroughtwild-" + version)
    package.mkdir()
    manifest = {"version": version, "revision": revision, "dirty": bool(status),
                "source_sha256": digest, "godot": ENGINE, "godot_cpp": pinned,
                "template_sha256": sha(templates / "windows_release_x86_64.exe"),
                "inputs": inputs}
    (folder / "source-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    run(["cmake", "-S", game / "extensions/wroughtwild_sim", "-B", folder / "native", "-G", "MinGW Makefiles",
         "-DCMAKE_BUILD_TYPE=Release", "-DGODOTCPP_TARGET=template_release",
         "-DWW_RUNTIME_OUTPUT_DIRECTORY=" + (game / "bin").as_posix()], source, env, logs / "configure.log")
    run(["cmake", "--build", folder / "native", "--parallel", str(args.jobs)], source, env, logs / "native.log")
    run([godot, "--headless", "--path", game, "--import"], source, env, logs / "import.log")
    license_script = game / "tests/export_license.gd"
    license_script.write_text('extends SceneTree\nfunc _initialize():\n'
        '\tvar file = FileAccess.open(OS.get_environment("WW_LICENSE_OUTPUT"), FileAccess.WRITE)\n'
        '\tfile.store_string(JSON.stringify({"godot": Engine.get_license_text(), '
        '"components": Engine.get_copyright_info(), "licenses": Engine.get_license_info()}, "  "))\n'
        '\tquit()\n', encoding="utf-8")
    env["WW_LICENSE_OUTPUT"] = str(package / "Godot-NOTICES.json")
    run([godot, "--headless", "--path", game, "--script", license_script], source, env, logs / "licenses.log")
    license_script.unlink()
    run([godot, "--headless", "--path", game, "--export-release", "Windows Playtest", package / "Wroughtwild.exe"],
        source, env, logs / "export.log")
    for log in (logs / "import.log", logs / "export.log"):
        if any(line.startswith(("ERROR:", "SCRIPT ERROR:")) for line in log.read_text(encoding="utf-8").splitlines()):
            raise RuntimeError(f"Engine errors: {log}")
    shutil.copytree(source / "data/tuning", package / "data/tuning")
    shutil.copy2(source / "tools/windows-playtest-README.txt", package / "README.txt")
    # Godot publishes the engine's complete license notices through its API;
    # the repository retains the extension dependency's license alongside it.
    shutil.copy2(submodule / "LICENSE.md", package / "godot-cpp-LICENSE.md")
    manifest.pop("inputs")
    manifest["files"] = {p.relative_to(package).as_posix(): sha(p) for p in sorted(package.rglob("*")) if p.is_file()}
    (package / "build-manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    archive = Path(shutil.make_archive(str(package), "zip", package.parent, package.name))
    print(json.dumps({"folder": str(folder), "package": str(package), "zip": str(archive),
                      "zip_sha256": sha(archive), "version": version}, indent=2), flush=True)


if __name__ == "__main__":
    main()
