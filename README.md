# Project Wroughtwild

Project Wroughtwild is an early single-player sandbox ARPG prototype built around one core loop:

> See an ambition → identify the missing capability → explore, fight, craft or build toward it → realise the ambition → choose the next one.

The intended game combines self-directed construction, persistent ARPG buildcraft, repeatable variable trials, useful craft-skill progression and gradual production automation. The repository holds the design, an engine-neutral rules library with a playable text slice, and the **Godot 4.5-stable** engine project in `game/` (accepted in [ADR-0001](docs/decisions/ADR-0001-engine-selection.md) on 31 August 2026).

## Run it

- **Engine project:** download Godot 4.5-stable (single executable) and open `game/project.godot`, or `godot --path game`. Headless checks: `GODOT=/path/to/godot game/run_headless_checks.sh`. See [game/README.md](game/README.md).
- **Rules tests (no engine, needs g++ and make):** `cd tests/sim && make`.
- **Text playtest of the whole slice:** `cd tools && make build/playtest && ./build/playtest ../data/tuning`.

## Start here

1. Read [docs/DESIGN.md](docs/DESIGN.md) for the game vision and current boundaries.
2. Read [docs/prototype/vertical-slice.md](docs/prototype/vertical-slice.md) for the first playable target.
3. Check [docs/decisions/registry.md](docs/decisions/registry.md) before making design assumptions.
4. Read the relevant file under [docs/systems](docs/systems) before implementing a system.
5. AI coding agents must follow [AGENTS.md](AGENTS.md).

For visual and Blender work, begin with the [visual reference library](docs/art/references/README.md):
owner-supplied environment references, the qualities to preserve, and versioned
creature concept sheets with modelling notes.

## Current phase

The [current intensive queue](docs/prototype/intensive-queue.md) tracks seven
focused passes that can progress between playtests. First is
[INT-01: first-hour clarity](docs/prototype/first-hour-clarity-plan-2026-09-07.md):
accurate recipe pins, useful material explanations and an optional route into
a first home and workshop. INT-01 is implemented with shorter panel text,
optional supporting detail and a verified gathering-to-home journey; owner
review of clarity remains pending. The follow-up
[INT-07A save fix](docs/prototype/loose-drop-persistence-2026-09-07.md) preserves
uncollected materials, gear, pages and death packs and replaces stale drops on
load. [INT-02A exploration](docs/prototype/exploration-storytelling-2026-09-07.md)
now adds old craft and damage remains to the existing smithy, distinguishes rare
clues from intact finds, and exposes their existing work stages and uses.
Matched captures, interface checks and save/building regressions pass; owner
discovery review remains pending. [INT-03A home/workshop usability](docs/prototype/home-workshop-usability-2026-09-07.md)
adds accurate station ghosts and fit, material-correct joins and tight-ceiling
step handling, verified with two complete homes and actual first-home entry.
[INT-03B placement/save reliability](docs/prototype/home-placement-persistence-2026-09-07.md)
checks complete piece footprints against terrain, keeps stations clear of built
walls and ceilings, and restores open doors in their saved physical pose.
Existing buildings remain loadable; owner comfort review is still pending.
[INT-03C placement reliability](docs/prototype/placement-reliability-2026-09-07.md)
restricts costly scenery refresh to changed building areas and seats unchanged
station bodies clear of corner walls. All seven fixture kits have actual-control
and restart checks; the owner's original disappearance remains unreproduced.
[INT-04A interaction feedback](docs/prototype/interaction-feedback-2026-09-07.md)
adds distinct local work, release and material-collection sounds, plus one
confirmation at the station completing a manual craft. Save/visual refreshes
and failed actions stay quiet. Functional checks and local listening samples
are ready; human listening and repetition comfort remain pending.
[INT-04B footsteps and ambience](docs/prototype/footsteps-ambience-2026-09-07.md)
adds contacts from actual walking/support and quiet existing-biome beds that
soften in shelter. World, save and trial boundaries clear cosmetic audio;
mob hearing, generation and rare discovery rules remain unchanged.

[INT-05A Forge readability](docs/prototype/forge-readability-2026-09-07.md)
exposes route previews, distinguishes physical fixtures and outlines existing
boss/furnace danger under overlapping effects. Enemies navigate around live
conduits and offerings. Existing combat numbers, rewards and suspension rules
remain; matched captures and physical traversal evidence accompany the slice.

[INT-06A workshop usability](docs/prototype/workshop-usability-2026-09-07.md)
shows exact reasons a feeder cannot start, separates supplies and drive controls,
and keeps completed bricks easy to collect. Live pages retain focus and expanded
details, and the hopper distinguishes actual clay from fuel. The finite source,
existing recipe and exact saved firing remain the same; owner review is pending.

[INT-07B world preparation](docs/prototype/world-performance-2026-09-07.md)
reduces repeated cave, route and terrain-collision work and avoids rebuilding
unchanged leyline tiles. Preserved-world, streamed geometry, excavation and save
checks accompany matched timing. World size, geography, rendering detail and
finite resources retain their existing definitions.

[INT-07C session reliability](docs/prototype/session-reliability-2026-09-07.md)
checks repeated expeditions, built-home returns and fresh-process restoration.
Damaged saves now recover a validated previous checkpoint explicitly, reject
invalid building sets before live changes, and retain the good backup when play
saves again. World profiles and ordinary inventory/workshop rules stay the same.

[INT-07D travel optimisation](docs/prototype/travel-performance-2026-09-07.md)
prepares resource-highlight shaders before interaction, retains the resource
scene between arrivals and batches equivalent leyline geometry. Matched travel
measurements and exact presentation comparisons accompany streaming, harvesting
and save checks; existing scenery detail and world identities remain the same.

[INT-07E loading schedule](docs/prototype/stream-scheduling-2026-09-07.md)
separates collision preparation from publication and gives queued leyline tiles
their own terrain work slots. Resource creation also stops at an elapsed-work
budget. Exact output, interruption, paced coverage and fresh-process home/save
checks accompany matched travel measurements; synchronous safety remains intact.

[INT-07F nearby-world refresh](docs/prototype/focus-scheduling-2026-09-07.md)
gives terrain scanning, resource scanning and new preparation separate turns.
Overdue scans still allow loading to progress, and teleport/restore safety stays
synchronous. Matched worst walking frames improve 24–37%; exact scenery,
historical worlds and home/save checks pass. An intermittent settled pause
remains recorded for follow-up; owner review is pending.

[INT-07G frame pacing and slow-frame safety](docs/prototype/frame-pacing-2026-09-07.md)
protects completed ground when terrain preparation falls behind. Sparse-cadence
regional travel, older worlds and corrected home/save checks pass. Detailed
stationary traces and actual Radeon integrated-GPU measurements now cover the
previous evidence gaps; the earlier intermittent pause did not recur and remains
unattributed. Normal RTX travel p95 stays effectively unchanged.

The owner-approved [Foundry completion pass](docs/prototype/foundry-all-inputs-2026-09-06.md)
finishes the remaining 72 Kind–ingot identities alongside the 24 existing Ember,
Frost and Preserving roles. Footwork, sequences, defence, recovery, passage and
impact now have individual conditions and explanations. Existing pieces and
saves retain their identities; final combat balance remains player-tested.

**Playable prototype:** the open sandpit established by D-011 now includes the bounded expansions below. The [original wave roadmap](docs/prototype/roadmap-waves.md) records its development history. The game opens on a seed-generated open world: biome terrain, scattered resources, roaming mob packs with loot, and a start-with-nothing opening (hand-craft a workbench, assemble and fuel a forge). The vertical-slice loop — mine order, armour, trial, catalyst tempering, construction unlock — sits on top and remains completable; `tools/playtest` stays the headless economy oracle. See `docs/prototype/acceptance-criteria.md` for what is ticked and what awaits playtesting.

The owner-approved [world intensive](docs/prototype/world-intensive-2026-09-06.md) and [Forge intensive](docs/prototype/trial-intensive-2026-09-06.md) add three resource habitats, eight finished building families, two wall forms and one complete Forge arc followed by selectable repeatable tiers. D-027/D-028 explicitly expand the earlier material and endgame boundaries. Existing saves retain their original generation profile; the first two Forge curios still activate their existing world landmarks.

The [Strange Frontier intensive](docs/prototype/rare-world-intensive-2026-09-06.md), D-029, introduced the finite 512 × 512 m world with three broad discovery regions, five finite rare finds and useful lamps, a hand-wound cargo winch, a signal lever, a sorter and bellows. Fixture recipes use the workbench; rare cores survive dismantling. A small connected winch experiment introduces signals and stored energy while powered production lines remain future work.

The owner's [art refinement](docs/prototype/frontier-art-refinement-2026-09-06.md) develops those regions into clustered woodland, planted wet margins and weathered rock shelves. Matched gameplay captures and walking reviews document the current finish; the owner accepts this visual finish for now, with a later graphical pass deferred.

The [Cataclysm intensive](docs/prototype/cataclysm-world-intensive-2026-09-06.md) connects extreme augmentation to impacts, traces, ruins, creatures and craft. The [pressure workshop](docs/prototype/pressure-workshop-2026-09-06.md), D-031, introduced one accidental asteroid strike through an old pre-cataclysm smithy in `frontier_v5`. Build your own forge and feeder there: finite pressure provides motion, ordinary clay and fuel make existing bricks. Its small buffers, exact cycle saves and hand-winding fallback introduce one useful production loop.

**New worlds now use `frontier_v6`: 1,024 × 1,024 m with larger rolling biomes, four home clearings and a quieter starter valley.** The [Wide Frontier intensive](docs/prototype/wide-frontier-intensive-2026-09-06.md), D-032, preserves every older world's geography. The initial class chooser offers a random seed, a chosen seed, or Continue for the saved world/suspended trial. Help (`H`) shows the current seed and generation version. The same pair recreates the same geography; loading also restores buildings, excavation and finite resource state. Existing V5 worlds remain 512 m; V4 and earlier receive no pressure retrofit. Wider automation and a later graphical pass remain future work.

The prototype excludes co-op, raids, an infinite world, extensive automation and a trading economy. Its purpose is to prove that returning from a trial makes the player excited to improve their build, base or production capability—and that those improvements make them want to venture out again.

## Repository map

```text
docs/DESIGN.md                 Master design and system relationships
docs/GLOSSARY.md               Shared vocabulary
docs/SYSTEM_SPEC_TEMPLATE.md   Template for new system specifications
docs/prototype/                Vertical-slice scope and acceptance criteria
docs/systems/                  Focused gameplay system specifications
docs/decisions/                Decision registry and architecture records
docs/research/                 Time-stamped external research notes
data/tuning/                   Engine-neutral tuning placeholders
sim/                           Engine-neutral C++ simulation core (rules layer)
tools/                         Text playtest of the vertical slice + balance simulator
third_party/godot-cpp          Submodule: Godot's GDExtension C++ bindings (pinned godot-4.5-stable)
game/                          Godot 4.5-stable engine project (presentation layer)
tests/                         Automated and simulation tests (tests/sim runs headless)
```

## Development principles

- Keep game rules data-driven where practical.
- Separate permanent progression from run-specific dungeon effects.
- Prefer useful friction over arbitrary grind.
- Treat building, combat and crafting as one economy.
- Prototype one complete return loop before adding content breadth.
- Record meaningful design decisions rather than silently embedding them in code.

## Licence

No licence has been selected. All rights are reserved until one is added explicitly.
