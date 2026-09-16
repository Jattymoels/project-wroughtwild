# RF-09: clearer weathered stone and connected ground

RF-09 makes existing highland outcrops read as weathered mineral against green
recovery pockets, carries turf/litter through low-growth edges and protected open
ground, and improves the local leaf response in highland, fen/bank and impact
planting. It is installed in ordinary eligible New World/Continue presentation on
`codex/rf09-wave-cleanup`; coordinator adoption and main publication remain pending.

The strongest delivered change is the highland rock/ground separation. This is a
material cleanup of the existing environment, not the later dramatic-landscape
result. Broad native terraces, simple outcrop shapes, repeated trees and sparse
protected openings remain conspicuous. Deep bank/impact shadow still limits the
whole scene; local leaf readability is improved without making the environment
uniformly bright. The large fragment and deep fissure artwork remain unfinished
visual goals. Owner playtesting is deferred, not recorded as aesthetic acceptance.

## Actual game pictures and assessment

The retained PNGs are unretouched 1280 x 720 engine viewport captures on Forward+,
with ordinary HUD, daylight, camera height, mobs and world systems. Each setting
uses a disclosed staging pose in an existing seed-77 V8 test save; runtime
materials have no capture-coordinate branches. The 11.895 m highland route uses
the ordinary controller and existing paid construction.

- [Highland](rf09-evidence-2026-09-16/01-highland.png): cool/warm mineral variation,
  readable weathering and darker ground stone frame the paid floor and living
  turf pockets. The big outcrop's faceting remains visible.
- [Shaded lake bank](rf09-evidence-2026-09-16/02-shaded-bank.png): low leaves/rushes
  keep distinct forms and green colour against the dark bank. The water/sky
  remain much brighter; broad tree shade is intentionally retained.
- [Impact growth](rf09-evidence-2026-09-16/03-impact-growth.png): the shared creeping
  leaves remain legible around the untouched exposed scar. The central fragment
  is still dark and the scar is still a shallow angular surface treatment.

The early highland view showed smooth olive-grey rock blending into the ground.
The first revision established mineral contrast and texture-backed pockets. The
first shared-material capture then exposed insufficient shaded-leaf improvement;
the final local reflectance/normal adjustment addresses that observation. No
camera search, baseline gallery, time/seed/renderer matrix or global exposure
change was used. The worker inspected the actual final PNGs.

## Causes and bounded implementation

The dominant rock binding was already correct: `StrangeSites._publish` overrides
both large regional ribs/outcrops with the RF-07 material. Its narrow grey-green
palette and periodic sine bands supplied weak mineral definition. RF-09 replaces
that shader with irregular world-space mineral variation and analytic surface
relief, shared by existing shingle and eligible highland ground. Authored sRGB
uniform colours convert once; imported GLTF vertex colours remain linear. No
colour-space defect is claimed for the previous implementation.

Highland ground previously replaced textured surfaces with a largely flat
stone/olive-soil palette. Its existing pocket mask now blends the retained RF-02
turf, litter and detail maps. Exact biome/original-top eligibility remains. Fen
uses interpolated patch colour while retaining exact eligibility and support
height gating. Existing reservations include real finite-source work, ruins and
approaches; full-footprint probes also reject narrow/uneven native terraces.
Those openings remain protected. Materials connect their margins without
increasing scatter density or shrinking reservations.

The shared RF-06B plant shader uses wrapped diffuse, lifted local reflectance
and sky-facing normals. Fen/impact normal blend is .64; highland uses .52.
Leaf gain is 1.90; existing root/tip colours and backlight remain. No emission,
global exposure/ambient change, artificial fill light or day/night override.
See [source/tuning notes](../../game/rf07/SOURCE.md#rf-09-material-cleanup-16-september-2026)
for the palette, .045 apparent mineral relief, .76 ground mineral gain, .10
pocket fringe and 2.4 m texture scale. These control appearance, never terrain.

Existing mesh forms, seeded transforms, wind displacement, full moving footprints,
paid clearance, V1-V5 exclusions and V6/V7/V8/LF eligibility remain. No native
DLL, source stock, progression, lake/swim rule, save field, collider or terrain
input changed. RF-08 exposure/digging rejection and both mob/scenery entry fixes
are untouched. Existing textures prepare through world construction; no new
movement/spawn resource load or unbounded search was added.

## Focused checks actually run

Risks named before checking: shared shaders degrading another adopted setting;
restored worlds losing identity/presentation; paid access becoming unusable.

- Necessary hidden headless import: exit 0, zero reported errors, 39.54 seconds.
- Visual job: two early highland looks (2/2 each), then ordinary Forward+ route
  and three shared-material views. Initial route passed 22/22 in 80.76 seconds;
  shade inspection prompted the bounded material correction and final capture.
  Final **22/22**, 80.20 seconds, exit 0, zero reported errors.
  The receipt is [walk-result.json](rf09-evidence-2026-09-16/walk-result.json)
  with [assertions and view poses](rf09-evidence-2026-09-16/walk-checks.json).
- Fresh-process Continue: **16/16**, 50.17 seconds, exit 0, zero reported errors.
  Exact seed/profile, native possessions/progression, blocks, paid stations,
  contraptions, leylines, finite resource records, drops and excavation match.
  Native height/lake hashes and the predecessor cover/paid-hidden digest match
  exactly. Ordinary support, movement and private resave pass.
- The final leaf reflectance/normal change does not change the Continue inputs
  asserted above; reuse that evidence. Final rendered Continue also exercises it.
- No new placement/support algorithm: reused RF-06B/07/08 full-footprint,
  excavation/rebuild and paid-placement evidence. No predecessor suite replay,
  native lake/LF/campaign run, performance benchmark or hardware clearance.
- PowerShell parse, scoped whitespace/diff and documentation link checks accompany
  the checked commit. The private launcher is syntax checked, not auto-launched.

Rendered runs assert visible/free mouse and no-focus flags. Owned processes ended
and their BOM-free temporary override was removed. Raw logs, private state and
imports stay in `build/rf09/` on D:. Import-generated unrelated sidecars are not
part of the commit. The SETUP-verified native runtime is reused without rebuilding
or rehashing parent packages. No new asset/master archive is needed.

## Private play commands

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:/Wroughtwild/work/rf09-wave-cleanup/tools/wroughtwild-rf09/play.ps1" -View Highland
```

Choose **Continue saved world**. Start at `(846.5, 68.96, 708.5)`, facing west toward
the highland outcrop and paid floor. Walk onto the floor or southwest toward the
paid workbench; aim at its body and press **E**. WASD/mouse move/look, **F5** saves,
**H** shows controls. Normal enemies remain active.

Use the same command with `-View Bank` for the shaded lake bank or `-View Impact`
for the retained impact margin. `-View Fresh` opens a separate ordinary seed-77
New World slot (or preserves its Continue once played).

Each view uses `build/rf09/playtest-<view>/` and copies its retained starting state
only if neither the private save nor its previous checkpoint exists. Rerunning
the launcher never resets progress. The source RF-09 fixture copies and all owner/
previous-worker saves stay untouched. Process environment is restored on exit.

## Handoff and stop

This completes the original wave's selected material cleanup. The worker commit
SHA is returned in chat for coordinator adoption and ordinary push to main; this
worker neither merges nor pushes main. There is no sealed package or new review
wave. No other worker or subagent was launched.

Carry forward: dramatic terrain/landmark composition; varied biome forms and
linked colour influences on areas, growth and fauna; deeper coloured fissures;
large tree silhouettes; repeated small plant forms; bare steep/reserved margins;
physical shoreline/water glare and swim animation; minor floor-joint cosmetics.
Existing group/Thrumroot/long-entry costs and the underground correlation remain
open. These functional checks do not establish hitch-free play. Compass stays
parked, historical ART R9 stays stopped, and the next landscape effort needs its
own scope. Stop after RF-09.
