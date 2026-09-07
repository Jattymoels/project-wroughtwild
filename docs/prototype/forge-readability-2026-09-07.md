# INT-05A — Read the Forge, choose a route, see the danger

Status: **Implemented, owner review pending.** Baseline: `f8e2a08`.

The owner's "Yep let's do it" authorises the queued INT-05 dungeon presentation
and traversal pass. The existing D-028 Forge arc supplies rooms, route choices,
secrets, floor boundaries and bosses. This slice improves their readability and
verifies physical use under D-010's rules/space separation and D-013's weathered
frontier direction. Combat numbers and final difficulty remain separate.

## Audit and outcome

Route plaques currently sit partly inside the solid corridor side wall. Their
depth-tested labels and glow can therefore disappear from a normal approach.
All fixtures share a plain block silhouette, and route details expose long raw
reward/monster strings. Make existing choices physically readable before entry,
keep the passage clear, and give reward/boundary interactions concise truthful
names and recognisable presentation. Optional secrets remain discoveries.

Boss and furnace tells currently rely on translucent orange fills that overlap
other effects. Give their unchanged footprints a readable perimeter and show
the existing warning clock. Warden physical sweeps should not say "INHALING";
existing recovery windows should have a short accurate cue. The adjacent burning
ground visual shrinks while its affected radius stays fixed: preserve that
footprint until expiry while fading its appearance, without changing its rules.

## Small implementation plan

1. Preserve production and isolated user data in `build/forge-readability/`.
   Establish matched first-person route and boss/effect captures and a bounded
   active-encounter timing fixture.
2. Expose route plaques on a readable approach, distinguish fixture roles and
   states using restrained forms/short text, and verify real capsule interaction
   and navigation. Retain existing topology, gates, rewards and secret ownership.
3. Add clear depth-tested borders/progress to existing hostile footprints,
   accurate boss phase labels and fixed-radius burning-ground fade. All attack
   damage, extents, clocks, guard rules and player effects remain authoritative.
4. Test physical routes, phase/footprint truth, once-only rewards and saved floor
   restoration. Compare matched captures and performance, investigate any
   regression over 10%, update specifications/queue and push the checked slice
   through the owner's standing main workflow.

## Systems, assumptions and boundaries

Godot Forge geometry, fixtures, boss/hazard presentation and review resources are
affected. Native `trial.json`/boon/item rules, world generation, save schemas,
enemy populations and combat calibration are not selected for change. Any
necessary presentation dimensions, colours and distances receive a plain-language
purpose in a Resource. No external assets/packages or new authoring service is
needed. Existing authored Forge dressing and eight module treatments remain.

Assume a readable approach plaque, distinct but restrained fixture shapes and
exact danger edges fit the approved mood. Owner visual judgement and route
comprehension remain pending while away. Automated forced clears can verify
progression, never human enjoyment, difficulty or the 20/10-minute targets.
The D-018 timber-demolition conflict and broader graphical redesign stay outside
this slice. No new room, boss, reward gate, map economy or automation is implied.

## Reproduced traversal correction

The initial conduit probe uses the capsule shared by Forge bosses. It starts
7.02 m from the player and after eight seconds remains 3.39 m away, outside
its existing 2.6 m claw reach, stopped
against a solid conduit. Its navigation path passes through the conduit centre.
Runtime fixture collision was absent from the floor's navigation cells.

The selected correction updates the existing floor mesh when fixture bodies
are added or removed, coalescing each batch and retaining the map/region. It
uses the actual collider poses, leaves authored cover/topology intact and clears
stale walk cells. No per-frame rebake, changed body dimensions, enemy attack
range or general navigation framework is introduced. A physical chase and
fixture-add/remove checks verify the result below.

The corrected probe reaches 2.252 m, inside the unchanged 2.6 m claw range.
Sixteen checks cover real chase, coalesced conduit addition, reward placement,
replacement/removal, reclaimed cells, map/region reuse and floor teardown.
The final one-room event refresh takes 1.278 ms for conduits and 1.637 ms for a
reward; the 4.859 ms peak includes initial creation. Full-floor timing is
recorded below.

The first full-floor implementation took 20.930–28.319 ms at reward events
during concurrent headless verification. Investigation found it was rescanning
unchanged walls and floor-union clearance on every fixture update. The final
implementation caches that fixed ordered candidate set once per floor and
filters only the live fixture footprints on later updates. It retains the same
polygon assembly, map, region and clearance. The regression compares its ordered
cells with the original raster algorithm on both full floors, including fixture
addition/removal, before walking those routes.

Final full-floor reward updates take 3.922–5.088 ms. The complete cached route
retains 814.8 m of actual walking, covers all eight module treatments and passes
122 checks, including both-floor ordered-cell equivalence. These event timings
were collected alongside independent headless regressions, separately from
the exclusive rendered-frame comparison below. No continual rescan is retained.

## Presentation resources

`forge_look.gd` places the route plaque 0.8 m inside the gallery edge and 8 m
forward of the room centre so the existing corridor wall no longer hides it.
`trial_fixture_look.gd/.tres` holds text height/front offset, measured width,
font size, reach/distance fades, restrained state colours/emission and the
bounded shared kit cache. Geometry fits the original 1.2 × 2.1 × 0.7 m collider.

`forge_tell_look.gd/.tres` holds 32-segment arc detail, the 0.16 m inward dark
edge and 0.055 m warm stroke inset by 0.035 m, depth-tested floor lift, colours,
fill opacity and bounded shared geometry cache. The existing burning-ground
initial alpha stays 0.85. Each exported value documents its player-facing
purpose; no damage, attack duration, enemy-count or reward tuning is added.

## Evidence and remaining review

The isolated review gallery is `build/forge-readability/index.html`. Production
baseline `f8e2a08` stays in `build/forge-readability/baseline`; normal owner saves
were not used. Both phases render the same seed-77 native story progression,
first-person camera poses and actual Foundry/hostile effects. The final captures
refresh the existing HUD before each image because fixture-driven state jumps
can complete before its ordinary 0.1-second update. No gameplay HUD cadence
was changed. Reward/lift/conduit faces point toward the normal approach via a
180-degree rotation, retaining the same rectangular collider footprint.

| Check | Result |
| --- | --- |
| `forge_fixtures` | 200 checks; exact retained collision, shared role kit, compact current/native text, secret states and bounded material/mesh caches. |
| `forge_tells` | 163 checks; all three boss identities, exact danger extents, warning/recovery clocks, real damage/cover, stagger/freeze/death cleanup, furnace phases and late full-radius burning ground. |
| `forge_readability_review` | 90 checks each baseline/current; three story runs, physical reward progression, first-floor options and matching active-effect captures. Both former branch-label obstructions are clear in the current build. |
| `forge_traversal --fixture-nav-audit` | 16 checks; the reproduced boss/conduit obstruction is resolved, fixture navigation has exact add/remove ownership and cached cells match the original algorithm. |
| `forge_traversal` | 122 checks; 814.8 m actual movement through all eight treatments, both branch approaches, physical secret/rewards/lift, exact boundary restore and final extraction. Both full floors match the original ordered raster with fixtures present/removed. |
| `trial_intensive` | 6,218 checks; all native story/repeatable/condition/reward paths, existing navigation and exact suspension/deposit/restore regression pass. |
| `grammar` / `integration` | 72 / 273 checks; actual status/freeze lifecycle, original trial/boss, world burning ground and economy integration remain intact. |

The first art assertion compared a float renderer property with a double
Resource value using exact equality. It now permits only representation error
and additionally requires actual restrained emission. No art tuning was changed
to satisfy that assertion. The original warning/active damage checks remain.

The existing lifecycle suite initially failed only its secret-path assertion:
it required the endpoint to be less than 2 m from the centre of the solid
fixture, which navigation now correctly excludes. That incidental threshold
is replaced by a connected route plus the actual player's interaction ray from
the clear endpoint. The real capsule walking/E/once-only secret checks also
remain. This verifies use within existing reach instead of demanding navigation
inside a blocked body; no fixture, reach or clearance is changed for the test.

### Matched performance

Final baseline/current manifests use Forward+ at 1280 × 720, VSync off and Dummy
audio. Both complete the same inspected story arc before an identical dense
cohort: 24 enemies, eight ignites, four real Foundry fields and two fixed furnace
warnings. The invulnerable player and surrounding world updates are held for
the fixed view; the trial cohort and field physics continue. These measurements
isolate Forge changes rather than wide-world streaming. A three-second warmup precedes five seconds
of sampling; no screenshot readbacks occur during timing. No other review engine
runs concurrently with these measurements.

| Measurement | Baseline | Current | Assessment |
| --- | --- | --- | --- |
| Median frame | 1.162 ms | 1.180 ms | +1.5%. |
| p95 frame | 2.969 ms | 3.009 ms | +1.3%. |
| Mean physics monitor | 2.747 ms | 2.705 ms | −1.5%. |
| World instantiate/ready | 8,357 ms | 8,338 ms | −0.2%; this fixture measures startup, not every travel/loading path. |

No final matched measurement exceeds the 10% investigation threshold. The
initial 120-frame warmup was too short at uncapped speed and left Godot's
one-second monitors reporting prior capture/startup work; it is superseded by
the elapsed-time warmup above. The separate early `performance.json` probe
starts before the story arc and is retained as raw evidence only; the final
comparison uses both complete `manifest.json` runs at the same progression.

Owner judgement of route clarity, visual finish and tell recognition during
ordinary combat remains pending. Forced clears and held attack poses do not
calibrate difficulty or establish the 20/10-minute run targets. No population,
damage, reward or build-power tuning was performed. Broader graphical finish
and combat calibration remain their separate work items.

The source-workspace Godot import and whitespace checks pass. New stable script
IDs are retained; imported engine caches and review builds stay untracked.
The owner's standing non-force `origin/main` workflow applies to this slice.
INT-06 remains next: demonstrate and diagnose the existing finite pressure
feeder's input, output, source-exhaustion and blocked states. No broader factory
or renewed supply is selected by this completion.
