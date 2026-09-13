# ART-07G1 integration tools

G1 composes the 24 sealed packages from the published G1 input index in a copy
of game/data and a newly built native extension, all pinned to
`6bb2e044dcd0bf1788896aa2c19cdf56fee93522`. It changes presentation dispatch
inside that copy. It introduces no simulation, save schema, material gate or
geography change. The receipt and evidence README record the measured result.

The scripts run from the isolated `codex/art07-g1` worktree. Existing source
packages remain read-only. Outputs must use a fresh path under this worktree's
`build/art07/g1`; the GPU runner shares `Local\Wroughtwild-Art07-GPU`, inspects
running processes and never terminates another job. It gives tests their own
APPDATA directory. A failed run stays a failed diagnostic; use a fresh log when
rerunning a corrected case.

## Reconstruct

Use the installed Python runtime and Godot 4.5-stable. No new dependencies.
Commands below use PowerShell variables only to abbreviate absolute paths.

```powershell
$g1='C:/Users/Matty/Dev/project-wroughtwild/build/art07/g1/worktree'
$py='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$godot='C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe'
Set-Location $g1
& $py tools/wroughtwild-art07/g1/verify_inputs.py build/art07/g1/NEW/inputs.json
& tools/wroughtwild-art07/g1/build-native.ps1 -Output build/art07/g1/NEW/native -Depot C:/Users/Matty/Dev/project-wroughtwild
& $py tools/wroughtwild-art07/g1/prepare.py build/art07/g1/NEW/pilot build/art07/g1/NEW/native build/art07/g1/NEW/inputs.json
& tools/wroughtwild-art07/g1/gpu-slot.ps1 -Program $godot -JobArguments @('--headless','--editor','--path',"$g1/build/art07/g1/NEW/pilot/game",'--import') -Log "$g1/build/art07/g1/NEW/import.log"
& tools/wroughtwild-art07/g1/gpu-slot.ps1 -Program $godot -JobArguments @('--headless','--fixed-fps','60','--path',"$g1/build/art07/g1/NEW/pilot/game",'res://g1/paid.tscn','--','--run-id=initial') -Log "$g1/build/art07/g1/NEW/paid.log"
```

The paid harness creates its actual `user://g1-paid.json`. Copy that checkpoint
to the reconstructed `game/g1/paid-home.json` for reviews and the standalone
play scene. Repeat the paid harness with `--baseline --run-id=baseline` and
compare its report using `fingerprints.py`. It checks the whole save at initial,
paid and final stages; only ephemeral station scene-node names are omitted.
Persistent station keys, all stock/work/progression and geography stay exact.

`checks.ps1` runs current focused, sources, devices, shapes and signals suites.
Use `-Renderer gl_compatibility` for D3 and the catalogue: Godot's headless dummy
renderer produces a shutdown-only null-material diagnostic for these complete
mesh assemblies. The strict runner rejects that diagnostic; the unchanged
assertions must pass in the supported renderer. Do not suppress the error or
weaken an assertion. `final-captures.ps1` runs labelled native fixture captures,
F4 flow/fractional/exhausted recovery, all 273 legal pairs and art-off views in
both supported backends.

`probe.gd` checks final-hook restore and read-only presentation frames;
`probe_compare.py` compares full art-on/art-off snapshots and generated-map
fingerprints. `render.ps1 -Mode benchmark` runs four matched paid cameras under
day/dusk lighting, with no captures inside timing. Run both art and `-Baseline`
for each renderer, after every compiler, Blender and Godot job has exited.
`benchmark_compare.py` refuses mismatched cameras, IDs, chunks or sample counts.

`stage_masters.py` copies the 30 original packed masters with hashes.
`reopen.py` reopens every copied master, imports six runtime GLBs into a clearly
static metric inspection assembly, binds externalized F4/F5 textures, packs and
reopens the assembly, and renders material/clay views. Blender arguments:
`--background --threads 8 --python-exit-code 1 --python <reopen.py> -- <masters> <game> <fresh-output>`.
This is not a second gameplay map.

## Integration ownership and controls

- `art.gd`: exact native resource/station/shape dispatch; C5 raised forms only
  for the original fallback. Faceted terrain retains its native thin ribbon.
- `materials.gd`: 19 published family maps, linear normal/ORM, metric tiling;
  existing glass frame and material/shape gates remain authoritative.
- `environment.gd`: existing cover transforms/counts, B2 far meshes and B4
  rooted sway; C6 changes existing ruin meshes only.
- `colours.gd`: F5 reads native source claims and device ledgers. White/Green
  follow delivered pulse counters, Blue release follows actual timer expiry,
  Red work follows paid feeder progress. Loading emits no synthetic event.
- `prepare.py`: records every literal engine hook in `integration.json` and
  copies modules from verified inputs. F4 pocket visuals refresh synchronously
  after successful native restore, before world recovery resumes.
- `settings.json`: each added tuning value has its player-facing purpose.
  Existing body fits and per-package appearance controls remain inherited.

`launch.ps1` belongs at the handoff root beside `game/` and `data/`. It supports
`-Import`, `-Smoke`, `-Baseline`, and `-Renderer gl_compatibility`. Saves go to
the sibling `<package-name>-user/ART07G1` directory, outside the sealed package.
Use the normal WASD/mouse, E, B/Tab/Q/R, LMB, I, F5/F9 and H controls. Normal
repository saves are never read. `manifest.py seal/verify` hashes deliverable
files and excludes only generated caches/UID sidecars/Blender backup files.

G1 ends with its branch commit and a local handoff. Main publication belongs to
the dedicated publisher. G2 and owner visual acceptance remain outside this work.
