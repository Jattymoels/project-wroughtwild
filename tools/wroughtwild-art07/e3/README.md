# ART-07E3 — chest and fire-setting source

This branch owns eight legal chest families and five legal campfire fuels only.
It substitutes presentation in a copied, frozen game. Ordinary `game/`, `sim/`,
`data/`, source packages, owner saves and the shared queue are untouched.
The receipt records the selected versions, absolute handoff and verified hashes.

## Rules and presentation

Chest: 1 × .7 × .8 m native body, bottom at local Y −.5, top at .2.
The native lattice pose is the origin. Closed parts stay inside this envelope.
The rear pin is `(0,.09,−.354)` in Godot; Blender uses `(0,.354,.09)`.
The existing grid also lowers the chest pose .15 m: on the flat review floor
the lower .15 m intersects ground. This inherited seating remains unchanged;
any ordinary-world correction needs its own integration decision.
The lid opens 78 degrees when that chest's actual storage panel is open, and
closes when the panel closes. Its sweep is cosmetic above the unchanged solid
body. It creates no traversable space, extra collider, save field or inventory.
Hinges, straps and grips are included presentation, with no additional iron cost.
Native cost is six units of the chosen family's source; capacity is 960 shared.

Five ordinary timbers plus iron, bronze and steel accept chests. Reed, cork,
stone, silver and glazing keep their existing restrictions. Invalid intermediate
catalogue selections use the original preview proxy and remain native-refused.

Fire: original .8 × .25 × .8 m low body and original offset Y −.125. Crossed
split billets or angular charcoal fit inside it. Real 22 mm-deep cuts in the
billets hold narrow combustion surfaces 12 mm below their upper shoulders.
These are fuel splits, not magical scars. Ordinary chests have no emission.
Existing fuel clocks own charring, ember phase and pre-expiry ash: timber
45 seconds/heat 1, charcoal 60 seconds/heat 2. Ash appears during the final
30% of that same lifetime. The native expiry deletes everything without refund;
the existing save policy omits fire. There is no persistent ash, stone cost,
cooking ingredient, output item or replacement fuel owner.

`appearance.json` explains every art control. No gameplay tuning is introduced.
Shaders sample native remaining seconds rather than wall-clock `TIME`, and freeze
with pause. The original one small fire light remains the game's own light.
The studio combustion is deliberately low and ember-led, without a flame card
or added smoke system. Full-world placement and owner visual acceptance remain
separate from this source handoff.

## Materials and geometry

D4 supplies the five timber face/end sets; D5 the charcoal face set; D6 iron,
bronze and steel. All 42 PNGs remain byte-identical to their verified packages.
Albedo is sRGB; OpenGL +Y normal and ORM are linear. ORM G owns roughness;
metals use the D6 metallic-one contract. One shared binding per role prevents
per-chest texture clones. Fuel parameters are per-instance because burn ages differ.
Exported GLBs also retain embedded source maps; this handoff does not claim a
minimal streaming footprint. The receipt separates map arithmetic from measured
engine texture residency.
Timber repeats U .5 m/V 2 m along the member, cut ends .5² m; metal .5² m.
The supplied timber end maps appear on the actual sawn ends. Native biome tint
is not applied twice. Explicit import settings retain mipmaps/anisotropic filters.

The master separates native envelope references, editable finished parts,
runtime inspection copies and review metadata. Exact source triangle/surface,
texture and native bounds are in `geometry.json` and the audit. Runtime GLBs
contain only the finished parts, never reference envelopes or extra bodies.
Godot imports their articulated parts through the existing AuthoredAssets path;
the closed preview combines the same body and lid. The explicit mesh set is
unchanged at near/middle/far; no arbitrary decimation budget is approved here.

Compared with the concept board, the surfaces and billet arrangement are more
regular and the fuel pile is lower to fit its existing body. The chest keeps
the supported lid/cavity/strap language. The review is an authored test floor,
not a completed furnished landscape. Renderer colour parity is not assumed.

## Reproduction

Run from the isolated E3 worktree, using fresh output paths under
`build/art07/e3/`. Existing dependencies live in the canonical depot at
`C:/Users/Matty/Dev/project-wroughtwild`; a clone does not include them.
`inputs.py` checks all four published prerequisite manifests and every listed
file before copying the selected maps. No imagegen/TRELLIS job is needed for
these exact directly modelled mechanisms. No download or new package is used.

1. Run `inputs.py <fresh-inputs>` with the installed Python runtime.
2. Run `build-native.ps1 -Depot <depot> -Revision
   bbcb3a7dfd235e8f803141ccb57c38e03d6c1708 -Output <fresh-native>`.
3. Run Blender 4.5.9 with `--background --threads 8 --python-exit-code 1
   --python tools/wroughtwild-art07/e3/blender_home.py -- <inputs>/textures
   <fresh-models>/source`, inside `gpu-slot.ps1`.
4. Run `prepare_game.py <fresh-review> <models> <native> <inputs>`.
5. `run.ps1 -Game <review>/game -Log <fresh-log> -Mode import`, then
   `configure_imports.py <review>/game`, then another fresh import log.
6. Use `run.ps1` modes `check`, `restore`, `capture` and `benchmark`, each with
   a fresh log; both renderer names are `forward_plus` and `gl_compatibility`.
   Capture and benchmarks are separate processes. Native core: `native_checks.py`.
7. Reopen the packed master in another Blender process with
   `blender_home.py -- --reopen <models>/source/e3_home.blend <fresh-inspection>`.
   This renders all families plus six-angle clay views and independently imports
   all 31 GLBs. Source solids must be closed/outward; imported UV seams are not
   treated as topological boundaries. All imports must have finite, nondegenerate
   triangles and positive signed volume.
8. `audit.py <models> <review> <inputs> <fresh-audit.json>` rechecks all source
   hashes and material/native contracts. `package.py` and `verify_handoff.py`
   seal and verify a fresh copy, never importing into the canonical package.

Task-local process/native wrappers derive minimally from the inspected E2
recipes; the Blender material/export convention derives from E2/D4/D6 examples.
Original recipes remain read-only. The ordinary home fixture supplies the native
catalogue/payment/E helper used by the new review. Test grants and stepped
burn time are explicit, not first-hour gathering or natural-duration captures.

Standalone review: `Launch-review.ps1 -Visible` in the sealed package, optionally
`-Renderer gl_compatibility`. It verifies and copies before import. Keys 1–8 choose
a chest; O operates its native panel with the canvas hidden for model inspection;
F grants three inspection wood and pays for one naturally timed fire. Esc quits.
Only this launcher user action requests a visible window. Automated runs stay hidden.
`-Smoke` checks every selection/open/close key and a naturally advancing paid
fire, then exits. It is suitable for a bounded hidden launcher verification.
