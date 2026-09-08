# INT-08B — portable Windows playtest build

8 September 2026. Owner: Matty. Implementation: Codex.
**Status: implemented; other-machine and owner review pending.** The owner's “Continue” selects this bounded next slice
after INT-08A, from the [independent-work proposal](away-work-review-2026-09-07.md).
Baseline: `c4f7fa1`; checkout clean before work.

## Outcome and scope

Export a Windows x86-64 folder/ZIP containing the pinned Godot 4.5 runtime,
fresh native extension, unchanged tuning and required imported assets/settings.
Show its source version and verify operation outside the repository layout.
Preserve existing world, resource, inventory, progression and trial contracts.
This is a local unsigned playtest package, without a store, installer, updater,
new dependency or distribution service.

Relevant authority: D-009/[ADR-0001](../decisions/ADR-0001-engine-selection.md),
D-006 ownership, D-028 suspended trials, and INT-08A's independent preferences.
Affected implementation: Sim's disk-tuning path, extension failure guidance,
HUD/window version, export preset and isolated local build/check helpers.
No gameplay tuning or save schema change is intended.

## Assumptions and steps

“Portable” means the extracted game folder runs without the editor/checkout;
the existing Windows user save/preferences location remains authoritative.
The package carries no owner save. Other-machine compatibility and ordinary
play comfort remain unverified until tested there.

1. Inspect tools and reproduce export/runtime failures in an isolated baseline.
2. Add the smallest complete export, packaged tuning and source identification.
3. Verify fresh launch, finite gathering/crafting, existing world and suspended
   trial restoration from isolated copies; repeat from tracked sources.
4. Record evidence/limitations and publish checked source changes to main.

## Tooling and package contract

`tools/export_windows.py` stages source and the clean pinned godot-cpp submodule
under ignored `build/windows/`. It rebuilds the DLL there, uses isolated APPDATA
and LOCALAPPDATA, imports assets and exports a separate EXE/PCK. Tests,
experiments and extension source are excluded; non-resource JSON is included.
The external `data/tuning` tree is copied unchanged beside the executable.
The package includes source identity, file hashes, launch/save instructions and
engine/dependency notices. Generated builds and template archives stay ignored.

The exact engine is `4.5.stable.official.876b29033`; the official non-Mono template
archive was downloaded locally and checked against its published SHA-512:
`1643140ac56ba8e6d18be34eb27788ec6a216e4a3f45dbcc3e01caf2b28ae9c8229832061e30200e296a1be46cec61e2b54c6d9df190b921ea1d0ad5f3f25ed1`.
Only its Windows x86-64 templates are extracted to each isolated build.
Godot's [4.5 export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_projects.html)
documents presets, templates and explicit non-resource filters;
its [Windows guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html)
supports the separate PCK layout used here.

## Reproduction and corrections

The first isolated export of the baseline runtime loaded its DLL but failed
to load tuning: `../data/tuning` resolved above the package. Exported Sim now
uses `OS.get_executable_path()` plus `data/tuning`; editor runs retain the
repository path. There is no fallback into a nearby checkout. The independent
extension guard gives full-ZIP extraction instructions for incomplete packages.

Normal rendered startup also reproduced a pre-existing null-column error in
`WorldSeedControls.configure`: class choices now have an intervening scroll
container. Seed/Continue controls now attach to its actual introduction column.
The class choices, permanent decisions and selected world identity are unchanged.

The full headless suite found `strange_frontier.gd` assumed its ignored output
folder existed. That fixture now explicitly creates/checks the directory before
its unchanged atomic write/read assertions. No save implementation changed.

## Repeat the build

Requirements: Python 3.11+, CMake 3.22+, MinGW-w64 C++17 compiler/make, the clean
pinned godot-cpp submodule and Godot 4.5-stable. No new packages are required by
the helpers. Download the official
[4.5 export templates](https://github.com/godotengine/godot-builds/releases/download/4.5-stable/Godot_v4.5-stable_export_templates.tpz)
to ignored local storage. The helper verifies the TPZ against the pinned checksum
above and checks the extracted release executable's exact engine version.

From the repository root (substitute your existing tool paths):

```powershell
python tools/export_windows.py `
  --godot C:/Tools/Godot/Godot_v4.5-stable_win64_console.exe `
  --templates build/windows-tools/Godot_v4.5-stable_export_templates.tpz `
  --compiler-bin C:/Tools/mingw64/bin
```

The default refuses uncommitted work and a changed/mismatched submodule.
`--allow-dirty` is for local review: the package is clearly labelled with both
the base revision and a content digest. Each invocation stages a new source
copy, rebuilds its native DLL and imports assets from scratch. Source inputs,
template hash and build logs remain beside the resulting folder/ZIP under
`build/windows/`. The package manifest records all shipped file hashes and the
exact source revision. Repeated export means repeatable checked construction;
byte-identical ZIP/PE timestamps are not promised.

Copy the entire ZIP to a local folder and extract it. Open `Wroughtwild.exe`.
The package README explains controls, saves and source identification. Existing
saves remain at `%APPDATA%/Godot/app_userdata/Wroughtwild/`; the ZIP contains
none. Do not have two game instances writing that same save.

To verify an export with **isolated test fixture copies**:

```powershell
python tools/check_windows.py --package build/windows/<run>/<package> `
  --world-save <isolated-built-home.json> --trial-save <isolated-trial.json>
```

The helper checks package hashes, copies the game and external test driver into
a new Windows temporary folder with spaces, uses an unrelated working directory,
and creates separate APPDATA/LOCALAPPDATA per case. It renders offscreen with
Dummy audio; it never reads/writes the owner's normal save. `--headless` is also
available. `--prepare-project <pre-change-game-copy> --godot <editor>` prepares
a generated seed-77 trial fixture using that earlier runtime. Forced kills
prepare its cleared boundary; they establish no difficulty/pacing result.
The helper prints the retained evidence location and fails on script/runtime
errors, failed assertions or mismatched files.

## Verification and evidence

[Original logs, screenshots and manifest](references/portable-build-2026-09-08/README.md)
record review build `c4f7fa1843f8-review-cc98bf27`. Its unchanged extracted folder
has 113,519,336 bytes, including 18 tuning files and 73 authored GLBs in its PCK.
The source tree/extension source, experiments and test scenes are excluded from
the shipped pack. The new test driver runs externally against that same pack.

| Case | Passing checks | What the evidence establishes |
| --- | ---: | --- |
| Pre-change generated trial preparation, headless | 93 | Existing native story reaches a cleared lift and saves non-full life, cooldowns, owned choices/loot and elapsed time. |
| Rendered first launch | 116 | Seed/class UI completes; 73 authored GLBs and runtime JSON load; finite work releases real pickups; exact paid crafting creates one kit and one usable visible bench. |
| Fresh-process restart | 95 | Built scene, finite work, inventory, loose drops and independent FOV persist. |
| Previous generated built-home save | 94 | Seed 77 V6, 182 paid pieces, three stations, finite resource records, storage/possessions and loose owners survive Continue and save. |
| Pre-change generated suspended trial | 98 | Continue retains exact build/deposit, checkpoint, loot/choices and combat values; resuspension does not heal/duplicate; lift enters floor two. |
| Missing packaged tuning | 1 | Separate incomplete copy refuses startup tuning and shows package extraction guidance, despite a checkout existing on this computer. |

That is **497 focused checks**, including fixture preparation. Original baseline
errors and interim comparison findings are retained separately. Comparisons use
the same full-precision JSON representation as SaveManager, with no numerical
tolerance. Exact decoded trial combat values are compared independently: the
engine changes equivalent String cooldown keys to StringName on restore, so
Variant encoder bytes alone are not a state comparison. Return positions are
compared as the exact binary32 Vector3 used by the engine.

The rules DLL imports Windows system/UCRT libraries only; no MinGW libstdc++,
libgcc or winpthread DLL is needed beside it. Local native release compilation,
clean asset import and export pass. The complete headless suite passes
**111,703 assertions** in two recorded segments after the fixture-directory
correction, including native unit/integration, historical worlds, streaming,
ownership, trials, Foundry identities, controls and the main-scene smoke run.

No gameplay tuning value, resource budget, progression rule, save schema or
generator input changed. World/trial saves and device preferences retain their
existing locations and ownership. No normal playtest process was running at
the initial inspection; all verification owns separate process handles/saves.

Limits: tested on this Windows machine with RTX 5090 Forward+ rendering,
1280×720 and Dummy audio. Other computers/drivers, signing/security prompts,
fullscreen/multi-monitor transitions and listening comfort remain unverified.
This exports the current prototype art and combat; it does not certify owner
acceptance or resolve the timber-demolition/item-roll design questions.
Generated build files remain local and ignored; ordinary Git publication covers
the helper, runtime changes, docs and evidence, without a binary release upload.
