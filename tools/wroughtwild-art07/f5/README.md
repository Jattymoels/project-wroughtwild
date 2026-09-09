# ART-07F5 — Four approved colours retained

Technically audited reuse of `red_source`, `white_source`, `blue_source`, `green_source`,
`white_connection`, `blue_delay`, `green_junction` and `red_heat_buffer` only.
Owner visual acceptance of this F5 comparison remains pending. No normal-world art adoption.

Measured costs are in `PERFORMANCE.md`; full per-case data is in `conformance.json`.

Open `comparison.html` in the local handoff to compare actual Blender/Godot sources,
recovered materials, devices and motion. It is an offline page with no server, downloads
or telemetry. All original full-size PNG frames remain alongside both renderer clips.

From the local handoff directory, run in PowerShell 7:

```powershell
& './Launch review.ps1' -Colour white
& './Launch review.ps1' -Colour blue -Compatibility
```

The launcher verifies all delivered hashes, creates a fresh sibling review and isolated
TEMP APPDATA, imports that copy, then opens the native study. It records both private
paths in `private-paths.json`. It checks the cooperative GPU lock and existing renderer
processes, and never stops another session. Close with Escape. Canonical handoff assets
and the owner's normal saves are not opened for writing.

Review keys: 1 source, 2 device, 3 route, 4 recovered material; D day/shade,
G emission off/on, N/M/F explicit near/middle/far detail, Space pause, A active/away,
R reset copied paid checkpoint. Colour-specific buttons and obstruction keys are in
`<colour>/original-README.md`; Green also has 5 feeder and J/K independent branches.
These copied ART-04 scenes exercise real current native state. Their compact backdrop
and controls are review context, not an integrated first-person world.

## Preserved contracts

| Family | Paid frame | Existing native behaviour |
| --- | --- | --- |
| White | 2 White Mineral + 2 wood | One immediate request; receiver owns drive and supplies. |
| Blue | 2 Blue Flakes + 2 wood | One pending request, 3 active seconds; pause/obstruction preserve progress; no reload replay. |
| Green | 2 Green Resin + 2 wood | Each distinct branch attempts once and pays its own drive/supplies; no free production. |
| Red | 4 Red Salt + 4 wood + 2 iron | 2 salt purchases 1 heat, capacity 4 including held heat. Separate feeder payment: 8 clay + 1 drive + 1 heat -> 4 bricks in 8 active seconds. |

All source bodies are 1.5 x 1.1 x 1.5 metres (Godot X/Y/Z). White/Blue/Green
bodies are 0.65 x 1.18 x 0.55 m, signal anchor (0,1.18,0). Both Green visual arms
use that existing shared native anchor. Red is 1 x 1.2 x 1 m, thermal anchor
(0,0.85,0). Ground-centred pivots and original transforms are unchanged.
Blender (x,y,z) -> Godot (x,z,-y) happens once through glTF. White's original
inspection additionally turns the imported host -90 degrees around Blender Z.
Exact source normalization and measured export bounds are in `conformance.json`.

| Family | Source triangles near / middle / far | Device triangles near / middle / far |
| --- | --- | --- |
| Red | 41,999 / 11,999 / 2,499 | 45,647 / 15,617 / 6,145 |
| White | 41,937 / 17,989 / 14,989 | 43,533 / 19,585 / 16,585 |
| Blue | 35,999 / 15,999 / 7,999 | 38,651 / 18,651 / 10,651 |
| Green | 35,999 / 15,999 / 7,999 | 1,998 / 1,998 / 1,998 |

Each family retains 19 authored PNG maps: seven 2048-square, twelve 1024-square.
RGBA8 allocation without mips would be 160 MiB per family; actual whole-review GPU
texture memory is reported separately. Base colour is sRGB; ORM, normal and scar
maps are linear. Green scar alpha stores branch identity, not transparency.
Original source base/ORM embedded bytes match exactly. Geometric cuts reach approximately
3 mm at delivered scale, measured against the identical pre-cut topology rather than
inferred from glow. No new appearance tuning is introduced. Original JSON controls
and their plain-language purpose descriptions are retained in the manifest and recipes.

## Reproduce the F5 audit

Canonical read-only depot: `C:/Users/Matty/Dev/project-wroughtwild`.
Worker: `C:/Users/Matty/Dev/project-wroughtwild-art07-f5`, branch `codex/art07-f5`.
Frozen current game/native/data: `56ce6bbe343012205690cf669491372958b80662`.
Historical native baseline: `f7253d20ed1dbeee743219190bdaccac60921c1c`.
Native DLL SHA-256: `a39a5972948cd420f56c2ca1065cf078ad41463b93af009f36b2b22dadd9993d`.

Use the existing bundled Python (NumPy/Pillow), Blender 4.5.9, Godot 4.5 and compiler.
No reinstall, model download, package installation or new generation is required.
Exact executed argument arrays, durations and exit codes are retained in logs and the
F5 receipt. Run commands from the worker; use fresh build directories and log tags.

1. `audit.py FRESH_JSON` verifies every original manifest-listed file and raw source.
2. Depot `tools/wroughtwild-workshop/build-native.ps1 -Revision 56ce6bbe343012205690cf669491372958b80662 -Output FRESH_NATIVE`
   compiles an isolated current snapshot using the existing ABI library.
3. `prepare.py NATIVE FRESH_WORKING` copies only audited dependencies and pins native/data.
4. `measurement_adapter.py WORKING` changes only copied `benchmark()` telemetry; original
   state, capture, collision and restoration assertions stay untouched.
5. `run-blender.ps1 -Package WORKING -Tag FRESH_TAG` freshly imports nine exports per
   family, proves source incision/contact, and reopens/renders each unchanged packed master.
6. For each `<colour>/review`, use `run-review.ps1 -Project REVIEW -Mode import|check|restart|capture|benchmark -Tag FRESH_TAG`.
   Capture and benchmark also run with `-Compatibility`. Coordinate GPU and CPU load;
   benchmarks must be a separate uncontended batch. Short private shader-cache paths are
   created under the worker build tree; original APPDATA is restored after every launch.
7. `check_game.py NATIVE FRESH_GAME` runs unchanged current source/work/ownership,
   crafting, material/shape, placement, drop and save-geography regressions. It creates
   required private test-output directories. `--resume` preserves successful logs and
   retains failed attempts while rerunning them under a new log name.
8. `prepare_placements.py GAME WORKING`, then `run-placement.py GAME FRESH_TAG` checks
   all four occupied-footprint refusals, one-object successes, actual E controls and
   fresh-process ownership. Two explicitly labelled kits per colour are granted only
   inside this transaction test. They do not count as paid first-hour progression.
9. `finalize_evidence.py WORKING` runs original image/state assertions and encodes both
   renderers' lossless clips, verifying every source frame and timeline duration.
10. `collect_report.py WORKING GAME` consolidates measurements and current evidence;
    `comparison.py WORKING` writes the local comparison. `package.py WORKING FRESH_HANDOFF`
    retains original recipes/cutouts and hashes every delivered file before engine import.
11. `verify_handoff.py HANDOFF FRESH_COPY` verifies/copies all files. Repeat native
    import/check/restart and Blender audit against this copy, leaving the canonical
    handoff unchanged. Record fresh evidence separately from historical ART-04 evidence.

Original reconstruction recipes, prompts, inputs, raw GLBs, retained cutouts and packed
masters are in the local handoff. Their actual raw metadata records TRELLIS.cpp v0.6.0,
CUDA, 1024, seed 42, PNG, retained BiRefNet cutout, eight threads and the pinned model.
Actual raw build commit `16f3109e82f3922033bfa62b83c42899678b7b6f` differs from the
release target recorded by the installation manifest; this historical difference is
preserved, not represented as a new generation run. Reuse is the selected outcome.

## Limits and delivery

The original exterior source meshes include non-manifold junctions. Only recovered
pieces are certified closed solids. Fresh runtime imports contain no nonfinite vertices or triangles below 1e-12 square metres;
no topology repair or smoothing was introduced. White's far source
remains 14,989 triangles. Review backdrop geometry and dense foliage affect measured
costs. RTX 5090 results do not certify low-end devices, a populated world, texture
cooking, automatic LOD switching or streaming. VSync is enabled in these studies, so the roughly 7 ms wall-frame figures include
presentation pacing and do not claim uncapped throughput. Per-case GPU/render-CPU
timings are reported separately.

The original compact reviews start from historical paid checkpoints. Current native
checks and a separate complete current-game regression establish compatibility at the
frozen revision; they do not erase historical differences or claim new player testing.
The isolated placement test attaches original near GLBs at identity for physical fit
and usability. It does not install their native-state shader adapter into the ordinary game.

Git contains only F5 tools, conformance data, curated evidence and the F5 receipt.
Large raw assets, packed masters, DLLs, full PNG sequences, isolated saves, caches and
working projects remain in ignored build outputs. A clean clone does not contain them.
Main integration and push are reserved for the dedicated publisher.
