# INT-02B — struck-smithy environment target

Status: **Implemented, owner review pending.** 8 September 2026.
The owner continued after INT-02C. Baseline: `a7c3854` on clean `main`.
This completes the last bounded slice of the
[7 September queue](playtest-iterations-2026-09-07.md#int-02b-one-finished-place-then-its-reusable-surroundings).
It is an implementation record, not owner acceptance of the final art quality.

## Observed baseline and selected change

Seed 77's actual fen smithy, approach and linked Ventlung supplied the target;
seed 1 supplied a second generated composition. The original barren screenshot
does not identify its seed or position, so these are controlled comparisons,
not a reconstruction of that exact view. Both original owner images remain intact.

The baseline has thin broadleaf sprays and a particularly abrupt empty middle
distance. Inspection found authored trees capped at **75 m**, despite a 120 m
resource stream with a further 32 m retirement margin. The shared weathered
tree setting already specified 200 m, but the authored path overrode it.
Screenshots and native signatures were captured before changing production art.

The local Blender recipes now produce broader overlapping folded leaves, fuller
fern fronds, broader shrub leaves, leaning/twisted mineral ledges with patchy
moss, and curved Ventlung pleats. Tree, shrub, fern and membrane meshes are fitted
to their old envelopes; the boulder retains its original dimensions and burial.
Nine existing fen/rootvault/upland ruin assets receive stronger embedded grain
and patchy lower-surface darkening. Their **triangle geometry is identical to
the baseline**, including apertures and the bounds that form runtime bodies.

The complete seed-77 scene was rendered and inspected with the fen treatment
before extending the same surface treatment to the existing rootvault/upland
variants. This did not create new regional structures or add placement points.
The existing ground-material transitions, contact occlusion, source/work strip,
impact, craft remnants, discovery route and restrained leyline light remain part
of the reviewed composition. Lighting and terrain geometry were not retuned.

The near authored-tree limit now matches 200 m. Render-only 32 m batches show
surviving meadow/fen broadleaf resource records out to 320 m, using a separate
**1,436-triangle** mesh instead of the near tree's 10,264 triangles. These batches
have no physics bodies, resource nodes, inventory, yields or saved state. They
use the same record position/yaw; the existing horizon mask selects the matching
coarse terrain triangle height where exact terrain is absent. Batch culling bounds
include both ground representations. Landmark canopy-clearance exclusions remain.

Materialising a normal resource immediately collapses its distant instance.
Retirement restores that picture only while the record survives. Depletion and
normal save reload derive the layer from the saved survivor ledger. The checks
caught and corrected an attempted heightfield lookup during terrain teardown;
the layer also tolerates depleted IDs left in the spatial index and uses weak
ownership so an old stream can be released.

## Matched visual evidence

1440×900, Forward+, FOV 75, ground-sampled 1.65 m eye. Daylight and a repeatable
warm, reduced-sun dusk comparison use the same camera/target positions per seed.
This dusk fixture is not a complete simulation of the ordinary day/night cycle.

| View | Baseline | Implemented |
| --- | --- | --- |
| Seed 77 woodland, day | [Before](references/environment-target-2026-09-08/baseline/seed-77/smithy_woodland-day.png) | [After](references/environment-target-2026-09-08/current/seed-77/smithy_woodland-day.png) |
| Seed 77 woodland, dusk | [Before](references/environment-target-2026-09-08/baseline/seed-77/smithy_woodland-dusk.png) | [After](references/environment-target-2026-09-08/current/seed-77/smithy_woodland-dusk.png) |
| Smithy arrival, day | [Before](references/environment-target-2026-09-08/baseline/seed-77/smithy_arrival-day.png) | [After](references/environment-target-2026-09-08/current/seed-77/smithy_arrival-day.png) |
| Impact/work area, dusk | [Before](references/environment-target-2026-09-08/baseline/seed-77/smithy_breach-dusk.png) | [After](references/environment-target-2026-09-08/current/seed-77/smithy_breach-dusk.png) |
| Ventlung, day | [Before](references/environment-target-2026-09-08/baseline/seed-77/ventlung_host-day.png) | [After](references/environment-target-2026-09-08/current/seed-77/ventlung_host-day.png) |
| Ventlung, dusk | [Before](references/environment-target-2026-09-08/baseline/seed-77/ventlung_host-dusk.png) | [After](references/environment-target-2026-09-08/current/seed-77/ventlung_host-dusk.png) |
| Seed 1 woodland, day | [Before](references/environment-target-2026-09-08/baseline/seed-1/smithy_woodland-day.png) | [After](references/environment-target-2026-09-08/current/seed-1/smithy_woodland-day.png) |
| Seed 1 arrival, dusk | [Before](references/environment-target-2026-09-08/baseline/seed-1/smithy_arrival-dusk.png) | [After](references/environment-target-2026-09-08/current/seed-1/smithy_arrival-dusk.png) |

[Raw manifests and selected walk frames](references/environment-target-2026-09-08/README.md)
retain camera positions, native signatures, samples and individual checks.
The scripted traverses cover 76 m / 913 frames in seed 77 and 74 m / 889 frames
in seed 1, by daylight and dusk. They advance 5 m/s at 60 simulation ticks/s
through production streaming. Ground and actual capsule samples along the native
discovery route pass. These are accelerated camera walks, not human input,
controller traversal or combat playtests.

## Cost and checks

Each static timed view uses 90 warmup frames then 600 uncapped wall-frame samples;
PNG readback is excluded. Processes ran sequentially, hidden, with dummy audio
and copied projects/APPDATA under `build/environment-target`. The owner's normal
save and independent playtest were not used or stopped.

| Measurement | Baseline → implemented |
| --- | --- |
| Seed 77 woodland day p95 | 1.030 → 1.138 ms (+10.5%) |
| Seed 1 woodland day p95 | 1.087 → 1.133 ms (+4.2%) |
| Seed 77 day walk p95 / maximum | 5.021 / 11.018 → 4.799 / 9.039 ms |
| Seed 1 day walk p95 / maximum | 4.661 / 9.128 → 4.640 / 9.669 ms |
| Seed 77 dusk walk p95 / maximum | 4.237 / 7.780 → 4.237 / 8.882 ms |
| Seed 1 dusk walk p95 / maximum | 4.003 / 9.821 → 4.212 / 9.174 ms |
| Seed 77 complete world setup | 4,908 → 4,933 ms |
| Seed 1 complete world setup | 5,059 → 5,079 ms |

More trees cost more rendering: the woodland day view rises from 796 to 911 draw
calls and 1.81 to 2.64 million submitted primitives in seed 77, and 943 to 1,107
calls / 2.00 to 3.21 million primitives in seed 1. Much of this is the full near
trees that previously vanished at 75 m. A first full-mesh distant candidate was
reduced before final measurement. The distant ledger contains 1,426 slots / 446
batches in seed 77 and 1,186 / 394 in seed 1; frustum/distance culling bounds their
draws. Active resource counts and the 120 m stream radius are unchanged. These
local, hidden-window measurements are not a portable FPS promise or evidence of
a general speedup; cold import, ordinary play and other GPU load can differ.

**1,960 current automated checks pass**, plus 232 baseline scene/walk checks:

- Export contracts: 71; all 15 curated meshes stay within retained envelopes,
  all nine ruin triangle hashes match the baseline, and habitat radii/budgets hold.
- Headless: environment lifecycle 19, smithy story 122, discovery sites 183,
  discovery clarity 249, pressure workshop 60, ecology/buildings 102,
  weathered save 21, wide terrain streaming 75.
- Rendered: environment lifecycle 23, ruin import/material/aperture checks 455,
  ecology/buildings 113, generated fixture ownership/visibility 44, and the
  existing rare/leyline visual, normal interaction, partial-save and depletion
  suite 169. Dummy rendering cannot return real MultiMesh transforms; the rendered
  run separately asserts the actual submitted poses, including hidden instances.
- Final matched V6 scene/walk checks: seed 77 **129**, seed 1 **125**, including
  identical native geography/stock signatures and exact before/after cameras.

Reproduce using `tools/home_review.ps1 -ReviewSet environment-target` with
`-Phase baseline/current`, `-Prepare`, `-Import`, `-Rendered` and the named scenes.
For `environment_target_review`, also pass
`-ExtraArguments '--story-seed=77 --story-phase=current --weathered-look'` (or seed
1 / baseline). A baseline must be copied from the pre-change revision, not current
source. `environment_target_checks` also runs headless. Export validation is
`python tools/check_environment_target.py`. Existing rule/native code is unchanged;
the complete repository test suite was not rerun.

## Sources, tuning and remaining limits

[Editable Blender masters and rebuild commands](../../art/blender/README.md#int-02b-environment-target-8-september-2026)
and the existing three JSON recipes are checked in. The durable
`environment_target_manifest.json` retains baseline bounds/ruin triangle hashes.
This uses the already approved local Blender pipeline and original geometry,
vertex colours and embedded grain; no external assets or services were added.

Changed controls and their plain-language purposes are also recorded beside the
recipes: leaf length **0.34 m**, leaf width fraction **0.34**, shrub leaf half-width
**0.07 m**, fern **15 fronds / 12 leaf pairs**, boulder bedding twist **0.24** and
lean **0.22**, moss coverage **0.40**, distant triangle fraction **0.14**, ruin
grain **0.13**, base weathering **0.32**, and Ventlung curve steps **4**. Saved
envelope coordinates are compatibility constants. Runtime presentation controls
in `material_library.gd` are the **200 m** near cap, **320 m** distant range and
**24 m** far fade margin. Resource creation/retirement budgets are unchanged.

The result remains visibly faceted prototype art. Distant silhouettes currently
cover meadow/fen broadleaves; forest/ember-specific silhouettes retain their
existing treatment. Hills with no surviving generated resources remain open,
and the frozen sparse population distribution identified in INT-02C is unchanged.
The new LOD can change silhouette at the stream handoff. The coarse horizon is
still a heightfield, and no terrain resculpt, new canopy footprint or collision
change was approved by this work. Owner judgement of fullness, weathering and
the ordinary-play dusk read remains pending. No new generator, enemy cap,
progression rule or next intensive is introduced by this completion.

Local commit and ordinary push results are reported separately at publication;
technical verification does not substitute for the owner's art review.
