# LAND-01: landscape, biome and influence plan

## Selected next task

RF-01–09 and RF-06B are adopted. The owner wants the next visual effort to "go big
and graphically awe", suspects world generation contributes to the current
shortfall, requests more biome types, and wants the technology/magic colours to
affect generated areas, growth and fauna together. They endorsed the larger
landscape/art sequence, then completed its preceding cleanup. This task makes
that next effort concrete and ready to implement.

Workspace: `D:/Wroughtwild/work/land01-landscape-plan`.
Branch: `codex/land01-landscape-plan`. Exact base in `build/land01/SETUP.md`.
The owner starts the task. Do not start other workers, subagents or an independent
review. This is a design/scoping delivery; no game implementation is requested
yet. It must end with a recommended plan and the first implementable worker brief,
not another instruction to scope the scope.

Read current `C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and its required
reading order. Then read this prompt, SETUP, [world premise](../world-premise.md),
the current adoption/next-sequence entries in [the coordination sheet](coordinator-status-2026-09-15.md),
and [RF-09's actual result](rf09-wave-cleanup-result-2026-09-16.md).
Use the intended-result/reference sections of [Reclaimed Frontier](reclaimed-frontier-intensive-2026-09-14.md)
and the [owner reference gallery and wording](../art/references/environment/2026-09-14-reclaimed-frontier/README.md).
Inspect the retained actual highland/bank/impact PNGs and the most relevant
original landscape references. No new camera campaign is needed.

Consult [world generation](../systems/world-generation.md) and the current
implemented sections of [Living Frontier](living-frontier-roadmap-2026-09-08.md)
only where needed to distinguish existing systems from new design. The historical
[influence record](meteorite-influences-2026-09-08.md) explains intent; its old
implementation status and superseded proposals are not the current code contract.
Do not reread every campaign report, reopen every Blender master or revive R9.

## Start with the world the player should experience

Lead with one compelling, walkable place, described from player height. The
coordinator's recommended starting composition is a **weathered fractured
highland above a recovered green valley**, with a distinctive skyline, a partly
concealed approach that opens into a view, substantial old impact/rock forms,
coloured energy deep within selected fractures, and sheltered ground that makes
the player want to build a base. Improve this recommendation if the references
and source suggest a stronger achievable first region; explain that choice.

Large forms, spatial relationships, depth, useful empty space and scale come
first. Plants, surfaces and light support them. The desired landscape is years
after the catastrophe: mature recovery over old damage, quiet places and useful
routes, with concentrated surviving augmentation. Do not turn every metre into
a cliff, glowing crater, visual effect or obstruction. Keep the existing earthy
art direction; graphical impact does not require a new engine or photorealism.

Show how foreground, middle distance and skyline work together, where the main
landmark sits, how the player reaches it, and why a nearby home would be exciting.
Include one annotated composition sketch/layout using existing references or a
simple diagram. One concept image is optional if it resolves a major shape/art
question; follow the imagegen skill if used, and label it as a target rather than
gameplay evidence. Avoid a catalogue of aspirational images with no implementation
path. The eventual delivery must be ordinary playable seeded worlds.

## Resolve these linked design questions in one recommendation

### 1. Large terrain and surface presentation

Use a bounded source inspection to distinguish native height/landform generation,
surface meshing/collision, art silhouettes, material/lighting and placement causes.
RF-03/V8 already supplies real landforms and lakes; RF-06–09 mostly dress those
surfaces. Do not assume larger noise amplitudes or additional plant density will
create the desired composition. Explain which layer each proposed change needs.

Recommend the smallest technical approach that can produce the ambitious first
region and extend naturally across seeds. Describe large-scale siting, coherent
ridge/valley/impact shapes, biome transitions, water relationships and useful home
ground. Preserve editable terrain, legitimate caves/digging and normal traversal.
Resolve how an apparently deep fissure meets real terrain without floating above
it, disappearing beneath an opaque surface or implying collision it does not have.
Identify a concrete feasibility question if needed; do not launch a generic
terrain-framework rewrite or broad benchmarking exercise.

### 2. A genuinely broader biome vocabulary

Recommend a small coherent candidate set of additional biome types, roughly
three or four rather than a production-scale catalogue. Names and exact selection
are proposals. Distinguish a new biome from an existing biome's influenced variant.
For each, give its silhouette/landform, vegetation structure, ground/water character,
fauna ancestry or existing roster fit, exploration/building appeal and art needs.
Explain its relationship to the existing meadow, forest, fen, rocky hills and
ember wastes, and recommend which additions enter the first implementation wave.
Do not fulfil the request with renamed or recoloured copies of current biomes.

### 3. Colours as causes with recognisable host expressions

Build on the established **White/Impulse, Red/Excitation, Blue/Retention and
Green/Propagation** identities. Treat biome, local host, influence and era/history
as related but distinct dimensions. Colour alone is neither damage type, rarity
nor proof of available resource stock. Use current implemented contracts before
proposing changes; no automatic fire/ice palette substitutions or duplicate systems.

Give a concise table linking each influence to plausible land/rock form, growth
pattern and fauna expression. Use a few strong host examples rather than every
animal multiplied by every colour. Distinguish visible world identity from
proposed new combat, harvesting or progression effects. Existing ordinary/LF
attacks, stock, sources, Kinds and campaign rules remain authoritative until a
specific follow-up changes them.

Recommend how impacts and the existing network seed local influence: placement,
spatial reach, quiet/recovered areas, biome relationships and any carefully bounded
overlap. Identify what should be guaranteed versus variable in random/chosen-seed
worlds. Reuse current native records when suitable. Do not assume the shared
cool-white cosmetic trace material means every trace is a White source. A colour
must not promise a resource, enemy ability or player interaction absent in game.

### 4. A practical art-to-game pipeline

Define the minimum substantial kit needed for the first composition: large rock
and tree forms, usable transitions, fracture walls/lips and recessed light, plus
supporting ground/growth. Use reference/concept, direct Blender modelling or
selective existing image-to-3D, material work, game export and ordinary player-
height composition. Identify what can be reused and where its shape is inadequate.
Better texture or scatter alone cannot close a silhouette/landform deficit.

Plan shared resource preparation/reuse at normal entry, not first encounter.
Treat the dark bank/impact evidence as a real scene-readability gap to address
alongside form/material; do not prescribe uniform brightness or universal emission.
No new paid service, dependency, engine migration or all-asset replacement is
selected. The existing tools and approved masters are available on C:/D: as noted
in SETUP; heavy new art remains on D: when actual production is selected.

### 5. Compatible delivery in a few playable slices

Recommend a short sequence with a visible result from each slice: landscape
structure, substantial landmark art, then seeded biome/influence composition can
be combined or adjusted where dependencies make a better player-facing result.
Do not put every biome, shader, reference image or remaining polish note into a
separate task. Avoid a long chain of infrastructure-only slices. Work on one
representative ordinary region early, then demonstrate reusable seed rules.

Specify the proposed entry/profile boundary. Normal fresh play currently uses V8;
Living Frontier has its own existing profile/campaign and influence systems. Be
explicit about how the first new work reaches ordinary play, what is reused from
LF and what stays unchanged. Recommend a fresh-world successor for changed
native geography while retaining all existing Continue worlds, paid octagonal
construction, finite ownership, progression and campaign terrain events. No
automatic migration or silent new-world default switch happens in this task.

Keep the finite-world boundary unless proposing a clearly justified later choice.
Do not bundle new combat rosters, biome-wide resource economies, extraction
machinery, dynamic ecological simulation, world-size expansion, old performance
reviews or the parked compass into this visual/generation effort by implication.

## Inspected source leads, not a full-project audit

- `sim/src/worldgen_frontier_v7.inc` and `worldgen_frontier_v8*.inc`,
  `data/tuning/worldgen-frontier-v8.json`: land/home/lake composition and inputs.
- `sim/src/worldgen_frontier_v6_landscape.inc`, `worldgen_living_frontier_wave3.inc`
  and `sim/include/wroughtwild/worldgen.h`: existing regional/network/host records.
- `sim/src/leyline.cpp`, `sim/include/wroughtwild/leyline.h`,
  `data/tuning/leyline.json`, `living_frontier.json`: typed influence foundation.
- `game/scripts/terrain.gd`, `game/art/wildland_terrain.gdshader`,
  `game/scripts/strange_sites.gd`, `cataclysm_sites.gd`, `leyline_fissures.gd`:
  generation/presentation boundaries and existing masks, landmarks and scars.
- `game/scripts/save_manager.gd` and the actual normal/LF entry dispatch:
  profile validation and save/ownership boundary. Follow relevant native meshing
  or actor links only to resolve a concrete question above.

## Deliverables and stop boundary

Commit these concise, reviewable planning outputs on the worker branch:

1. `docs/prototype/landscape-biomes-influences-plan-2026-09-16.md`: lead with the
   recommended player experience, visual composition and small biome/influence
   tables. Follow with source-backed implementation choices, art kit, bounded
   sequence, compatibility and the few consequential decisions still needed.
   Separate accepted owner intent, implemented facts and new proposals. Make a
   recommendation for missing details; do not stop at a list of open questions.
2. `docs/prototype/land02-landscape-foundation-worker-2026-09-16.md`: a concrete
   **proposed** first implementation brief, ready for coordinator/owner selection.
   Include visible outcome, affected files, assumptions, world-entry/save boundary,
   art needs and at most three focused checks on one renderer. This must advance
   the landscape, not prescribe another planning task. Do not create its worktree
   or start it yet.
3. One useful annotated visual/layout and a short coordination-sheet update with
   the recommendation and unresolved decisions. Show any visual directly in chat
   with an absolute path, labelled concept/layout if it is not a runtime capture.

Planning verification is links, factual source references and scoped diff/syntax.
Reuse retained game evidence. No game import, renderer, native build, new
benchmark, save fixture, fresh runtime package or independent review is required.
Do not edit runtime code/tuning or mark proposals as accepted decisions. Current
prototype limits supersede every historical review or hard ten-minute rule.

Return the checked commit SHA, brief owner-facing recommendation, visual and
first implementation prompt. Coordinator adopts/pushes the planning work. Stop
after LAND-01; do not implement LAND-02, expand the task into all-asset production
or resume historical ART R9.
