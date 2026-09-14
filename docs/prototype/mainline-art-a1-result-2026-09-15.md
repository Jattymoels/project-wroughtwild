# A1 — R8 art in the ordinary game

The normal game now uses the owner-approved R8 environment, resources,
construction materials, stations and devices through new-world and Continue
entry. The existing octagonal/chamfered vocabulary and door poses remain usable.
Worker delivery is on `codex/mainline-art-a1`, based on
`026a2c4a43ccb869ca157c7139f6158e50919073`; coordinator integration and push remain
separate. Owner approval is recorded in [the adoption direction](art-mainline-adoption-2026-09-14.md).

## Scope and retained limits

The selected source is R8's final `handoff-final/runtime/game`, including repaired
R1 trees, R2 shared external textures/aliases, R3 construction shading, R5 source/
station restoration repairs, R6 ore shading and R7 vegetation. The G1 recipe was
used only as the hook map. Required assets live below `game/`; there are no D:
or ignored build dependencies in the adopted presentation. Existing actor art
is retained: the older wolf, boar, stag and moth set. Latest finished ART-01/03
fauna/native adapter adoption is A2; the six ART-06C rigs remain separate work.

PLAY-01 stuttering, PLAY-02 incomplete-looking canopies, PLAY-03 unintended
underground access/worse lag and PLAY-04 untried stations remain open. The
ordinary smoke image still shows the reported sparse/incomplete tree crowns.
No performance, hardware, all-profile, material or seed matrix was run. R9 stays
stopped. The LF check uses an existing published synthetic paid workshop; it
does not establish a fresh human campaign or owner station usability.

The port changes presentation hooks only. Native simulation, data/tuning,
campaign eligibility, both terrain events, save schemas, costs and rewards are
unchanged. Ordinary entry remains `res://scenes/sandpit.tscn`; no paid-home
bootstrap, fixed production seed, private save override or baseline switch is
required. C6 tolerates older profiles without a Cataclysm scenery root. R3 reads
construction sizes through the existing tuning-directory resolver.

## Art settings

No gameplay tuning is introduced. Delivered values remain in their runtime JSON:

| Settings | Purpose |
| --- | --- |
| `game/g1/settings.json`: `colour_lod = mid` | F5 source/device mesh detail. Removed inactive G1 fallback settings; R1/R3/R7 own their repaired presentation. |
| `game/r1/settings.json` | Tree burial and lower-trunk fit; the adapter uses the delivered LOD2 meshes and native bodies. |
| `game/r3/settings.json`, `game/d4`–`d6/materials.json` | Metric grain/edge projection, board and frame widths, normal relief, seam shading and glass opacity for all 19 delivered families. |
| `game/r7/settings.json` | Existing cover envelopes, LOD2 source groupings, rooted 0.018 m/m sway, 5.5 s wind and leaf lighting; no new scatter positions. |
| `game/c1`, `c3`, `c5`, `c6` JSON | Resource surface/state presentation, ore maps, ruin detail distances and ambient scar pulses. |
| `game/e1`–`e3`, `f1`, `f4`, `f5` JSON | Station material relief, forge/fire response and device/source light driven by already-owned native work, stock, heat or requests. |

## Focused verification

At most three jobs were used; Forward+ was the sole rendered backend:

1. Actual production import/load: completed, no reported import/script errors.
   Fresh import log ran approximately 29 seconds. One runtime shader dependency
   was exposed by job 2 and repaired there.
2. Ordinary chooser → finite gathering → paid workbench placement/use → chamfer
   block/triangular slab/door → save → normal Continue: **70 checks, 0 failures**.
   Verified restored native inventory, blocks, stations, machines and sources;
   reopened/closed restored door and confirmed adopted trees/workbench. Forward+
   final run: **68.99 seconds**, no reported shader/script errors. The first
   attempt (**69.46 seconds**) reported a missing R3 `surface.gdshaderinc`;
   the final source include was added and the same job repeated. Original failure
   log is retained; the initial attempt is not counted as a clean pass.
3. Published LF2 paused thermal workshop load/use: **12 checks, 0 failures**,
   **63.83 seconds**, headless. Exact source, inventory, machine/escrow/stock
   restoration; pause gives no offline credit; Resume completes the held firing
   once, and an unfunded continuation pays no additional rewards.

Private logs, fixture, harnesses and one ordinary screenshot are in the worker's
ignored `build/a1/`. The test-only `--r8-no-mouse-capture` branch reaches the
player's sole capture setter; the rendered check asserted visible mouse mode
and an unfocusable window. Disposable `override.cfg` is removed for manual play.
No tests, imports, DLLs, engines, private saves or captures belong to the commit.

Historical timing: setup consumed 17 seconds; preflight/dependency selection
and copy were charged an additional conservative 60 seconds. The prior worker
verification window ran from 21:53:00 to 22:01:43 UTC on 14 September
(15 September Adelaide), when delivery stopped under the former ten-minute rule.
The owner subsequently removed that hard cutoff in current AGENTS.md (main
`41420ff`). Routine completion resumed using the existing passing evidence;
no additional import, gameplay, renderer or package review was run.

The final staged check exposed one blank line at EOF and binary glTF buffers
misclassified as text. Their raw diagnostic bytes also broke the delivery
script's text decoder. The EOF was fixed; `game/.gitattributes` now declares
`.bin` mesh buffers binary, preserving bytes and preventing text conversion.
All 126 staged buffers were byte-identical to the tested working files before
this correction. The resumed staged diff/attribute check passes. This is a Git
classification fix, not a change to mesh geometry or a disabled text assertion.

Only the A1 production allowlist and related documentation are committed.
Coordinator integration into current main and the ordinary origin/main push
remain pending. Keep current main's owner guidance and unrelated work intact;
reuse the passed gameplay checks during integration.

## Play after coordinator integration

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game'
```

Continue an existing world, inspect trees/resources, place and use one workbench
or forge, then build a chamfered/octagonal section and use its door. Save and
Continue to inspect the same owned work. A fresh normal world uses the same art.

Colour sources/devices keep their existing LF eligibility. For a compatible
saved LF campaign, use the separate established launch:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game' -- --living-frontier-wave7
```

Use Continue for the existing LF campaign. This art port does not unlock colour
devices in every historical ordinary world. No portable rebuild is required.
