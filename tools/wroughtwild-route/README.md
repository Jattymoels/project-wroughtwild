# ART-05 — playable Red route pilot

This is an actual isolated Wroughtwild game, starting from a paid LF-3 seed-77
workshop. Follow the existing Red trail from its source to the native boar
habitat. The approved boar, trees/rocks, Red source, source-owned fragments and
heat buffer follow real game actors, stock, interaction and construction.

The local package is `build/art05/red-route-handoff/`. Run `Launch route.ps1`.
It imports its own game and uses `user-data/` for APPDATA. **WASD/mouse** move and
look; **E** interacts; ordinary building/combat controls are unchanged. **F5/F9**
save/load only this package's world. Later launches resume that saved pilot.
The first launch starts at the paid workshop, before the boar hunt. Closing
without saving returns to that initial checkpoint on the next launch.

One heat is stored in the fitted buffer; ten Red Salt remain carried after its
four-salt frame and two-salt heat charge. The bench, mason yard, forge and buffer
were made through actual finite gathering, crafting and paid camera/click
placement. No materials, kits, stations, unlocks, regeneration or invulnerability
were granted. There is no pressure feeder at this small new workshop. The
separate native component regression uses the unchanged ART-04 paid firing
checkpoint to check pause, blockage, completion and visual work-clock mapping.

## Reproduce

Use the already approved local Python/Pillow, Godot 4.5, MinGW/CMake and the
existing godot-cpp ABI build. No TRELLIS generation or new dependency is required.
Original editable/source handoffs remain in `build/boar-art01/boar-handoff/`,
`build/grove-art02/emberroot-handoff/` and `build/workshop-art04/red-handoff/`.
All source hashes and cooked roles are in `game/art05/assets/asset-index.json`.

1. From the repository, `tools/wroughtwild-route/prepare.ps1 -Output build/NEW`
   archives committed game/data at `8aec10ef3b1df190e23fc4f32bc910877e8ded86`
   and builds the matching native DLL separately. It does not copy concurrent
   working-tree gameplay or replace the live DLL. Use a fresh output directory.
2. `run.ps1 -Project build/NEW/game -Scene probe` inspects the native footprint.
   `verify_assets.py build/NEW/game/art05/assets` validates input hashes and every
   retained mesh/skin/animation buffer. The cook externalizes shared images,
   limits them to 2k and keeps the approved 100 Hz animation import. Automatic
   mesh LODs are disabled for these explicit art roles.
3. `run.ps1 -Project build/NEW/game -Scene check_route -Rendered` performs the
   paid journey, real input/controller walk, native combat, freeze, harvesting,
   collision refusal, streaming and same-process save restoration. Its setup
   helpers pace gathering/travel; only the measured walk is uninterrupted
   controller movement. Captures are evidence, not frame-rate measurements.
4. Copy the resulting isolated APPDATA
   `Godot/app_userdata/Wroughtwild/art05-before-hunt.json` to
   `game/art05/route-checkpoint.json`. Then run `check_route -Restart`,
   `native_component`, and `check_route -Baseline`. Baseline uses the same game,
   native code, finite setup and route with the art adapter disabled.
5. Run `benchmark -Rendered -Baseline`, then `benchmark -Rendered`, separately.
   They use identical cameras, resource IDs and terrain chunks; finish arrivals
   before timing and hold terrain streaming stationary. Live streaming is
   covered by the walking/retirement tests. The 24-actor case is a labelled
   stress fixture at the existing approved trial cap; it changes no spawn rule.
6. `review -Rendered -Baseline` then `review -Rendered` capture actual day/dusk
   source, trail, boar and paid buffer views. `play -Rendered -Smoke` checks the
   usable launch with ordinary controllers and the unspent native boar.
7. Run `make_preview.py build/NEW`. `package_handoff.py build/NEW
   build/NEW_HANDOFF` creates the standalone game/data/evidence and SHA manifest.
   Reimport and smoke-check that fresh package. In the package, `Check route.ps1`
   defaults to its own game and another isolated test APPDATA directory.

Use `-Scene` before each scene name with `run.ps1`; switches above are abbreviated
for readability. All test errors fail, except the exact logged Windows sandbox
root-certificate-store startup warning; this offline game makes no TLS calls.
The runner records its process ID and stops only the process it launched.

## Fit and presentation

The route is the existing Red source-to-habitat trail, not the distant old
smithy. Only surviving tree/boulder records within 24 m are fitted. Their native
trunk/rock bodies, ground anchors, yaw, depletion and fall/shrink transforms stay
in charge. Existing trees constrain these forms to roughly 4.08 m tall. Quiet
hosts have a blank scar mask. Near the native source/host cues, the approved Red
scars use stable independent phases derived from existing identities.

The actual boar keeps its collider, AI, health, attack radius/timing, warning,
status effects and loot. In-place walk clips follow measured body travel; native
windup/release fractions drive those poses. The old procedural rig is hidden and
stopped, avoiding a second gait/torso motion. Freeze holds the fitted pose and
retains status priority. The initial pose is valid even if frozen immediately.

Source readiness follows support, native work, lots and claims. Raw fragments
vanish when raw material is collected; the existing native rare-claim marker can
remain independently. Buffer storage is steady. Native firing progress and
completed-cycle changes drive travel, including the completion wrap; importing a
paused fractional firing cannot flash a false work event.

`route.json` explains the small pilot settings. Scar colours, periods, brightness
and source/work/storage gains come from the approved handoff configurations.
All presentation clocks stop with scene-tree pause. There are no per-scar lights,
new game rules or changes to normal-world renderer defaults.

## Limits

This package proves one actual route on the current desktop, not a global art
rollout or a finished landscape. Older ground cover, distant canopies, scenery,
fixtures and terrain shading remain visible. No extra tree, plant, bank, source
or resource placement was introduced. The composed grove's 52-tree/834-understory
layout was not transplanted. Root banks/understory need a separate matching
existing footprint before reuse.

This first pilot uses the mid boar/source and the approved far canopy geometry;
its 2k PNG textures are deduplicated but not GPU-compressed. Near-source tree
geometry is still expensive. The handoff includes far candidates for later
measured adoption; automatic distance switching and wider budget reduction are
not implemented here. Lower-spec hardware, Compatibility in the full world and
later concurrent Wave 7 gameplay are not certified by this frozen Forward+ pilot.
Frame medians are display-sync limited; use the reported GPU/render-CPU figures
and scene counts when comparing cost. Broader reuse follows visual review and
these documented integration/performance limits.
