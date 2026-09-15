# RF-06: fen and lakeside atmosphere

## Original-plan outcome

Return to the original [Reclaimed Frontier direction](reclaimed-frontier-intensive-2026-09-14.md):
established life reclaiming old terrain, with distinct biome character and places
that make the player want to build a home. This slice delivers the wetland part:
fen ground and lake margins should feel planted, settled and connected to their
surroundings, with quiet open water, readable routes and useful dry building space.

The owner approved this sequence and then explicitly asked us to stay with the
original plan. Complete this slice, record incidental additions/bugs for the
end-of-wave cleanup, and stop. Next is highland recovery, then remaining impact/
scar composition. Compass/coordinates are parked. Do not launch another lag,
general polish or art-review wave in response to a non-blocking finding.

Workspace: `D:/Wroughtwild/work/rf06-fen-lakeside`.
Branch: `codex/rf06-fen-lakeside`.
Read `build/rf06/SETUP.md` for the exact base and native runtime. Read current
`C:/Users/Matty/Dev/project-wroughtwild/AGENTS.md` and follow its required reading
order. Then read this owner-depot prompt; copied worktree guidance can be older.
The coordinator has integrated PLAY-07 and all earlier art/creature/lake work.
The owner starts this worker; no parallel workers or automatic next task.

## Reference and compatibility boundary

Read the [annotated original gallery](../art/references/environment/2026-09-14-reclaimed-frontier/README.md)
and [owner wording](../art/references/environment/2026-09-14-reclaimed-frontier/owner-intent.md),
and inspect the actual supplied images relevant to composition. Their old R9/
review sequencing is superseded by current AGENTS.md. Carry forward rooted
foreground vegetation, layered living surroundings, quiet openings and growth
over old damage. Do not copy the exact imagery, HUD, crater repetition, style or
watercourses. This should look like Wroughtwild years after the event.

This is **presentation and placement**, not new geography or mechanics:

- Dress actual existing `fen` biome/marsh surfaces in V6/V7/V8 and existing LF
  profiles, and the actual shore of RF-05 lakes in V8. Use the current native map
  and water records. Fen is not permission to flood dry ground. Profiles without
  a lake gain no water; V1–V5 keep their existing presentation.
- Existing eligible Continue worlds receive derived cosmetic composition without
  reseeding/migration. Do not change native heights, voxels, collisions, water
  level/footprint/bed, biome boundaries, world identity or campaign transformations.
- No extra lake, sea, river, drainage, erosion, ecology simulation, resource yield,
  creature, recipe, building rule or progression change. No new save fields/profile.
- Preserve lake swimming/wading/exits and recovery, all paid ownership, finite
  sources, native approach reservations and octagonal building support.

## Small complete visual treatment

1. **Fen character:** compose irregular reed/sedge groups and low wet-ground
   growth around open passages. Use restrained damp earth/litter transitions and
   occasional rooted/deadfall accents from the adopted kit. Give the fen its own
   recognizable rhythm instead of simply increasing meadow-grass density.
2. **Lakeside character:** compose a broken planted bank with taller accents in
   suitable sheltered pockets and lower growth toward dry ground. Leave stretches
   of shore/open water visible. Keep the existing lake-home clearing and its
   approach inviting: a framed outlook and room for ordinary player-built layouts,
   not a prescribed/free house, hard plot boundary or bonus.
3. **Connected transitions:** blend new low cover with the existing meadow/forest
   finish using actual surface and water context. Avoid a uniform ring of reeds,
   repeated fence-like rows, bright plastic mud or every shoreline becoming dense.
   Fen without a lake should still read as recovered wetland through its existing
   marsh ground; do not imply new traversable water where none exists.

Reuse approved resources and their visual language first. If the existing reed/
bank forms cannot express the treatment, author a small original Blender reed/
sedge kit or local surface treatment within this slice. Retain editable source,
recipe and selected game exports; no third-party assets or large new catalogue.
Keep new production proportionate to these two environments. Do not reopen all
approved masters or run the old end-to-end art pipeline for every reused asset.

Implementation leads already inspected, not a prescribed architecture:

- `game/scripts/ground_cover.gd` already has a fen reed role;
  `game/scripts/habitat_cover.gd` / `game/art/habitat_look.gd` already place shrubs,
  fern beds, deadfall and stumps. Keep resource/work clearances and avoid stacking
  duplicate old/new cover at the same roots.
- `game/rf01/cover.gd` has deterministic meadow/forest placement, actual supported
  footprints and native approach reservations. Its current eligibility excludes
  fen. Reuse the applicable support/paid-building behavior without broadening
  other biomes by accident. R7/B2 and RF-02 supply adopted vegetation/materials.
- `game/rf02/ground.gd` scopes the existing surface treatment through transient
  biome data. Local damp transitions must remain cosmetic and constrained to this
  slice, retaining existing texture scales and the RF-04 surface continuity.
- `game/scripts/lake_water.gd` exposes generated columns and actual water contact.
  Shore eligibility must respect actual supported terrain and changed ground,
  not decorate every low point or leave plants floating over excavation/caves.

Prefer a scoped `game/rf06/` presentation module/resources using current chunk
refresh and building-clearance hooks. Derive/cache bounded placement data rather
than scanning the whole world or all assets every frame. Prepare/reuse any new
heavy resources at the existing loading boundary; preserve the recent creature
and scenery preparation fixes. Describe tunable density, width, height, shore
distance and transition controls in terms of their player-visible effect.

## Gameplay preservation and focused evidence

The risks to check are blocked/obscured lake access, plants over holes or paid
buildings, cross-biome spill, and cosmetic refresh changing saved ownership.
Presentation must be deterministic for the saved seed/profile and repeat correctly
after chunk retirement, Continue and local edits. Roots use real support; shallow
plants, if used, must be anchored to the actual bank/bed within a bounded suitable
depth. Do not cover deep water, cave floors or create cosmetic collision.
Honor paid floors/stations/paths, all legal building shapes including octagonal
footprints, resource/site approaches and both LF terrain publication boundaries.
Reuse unchanged campaign evidence; no full LF replay is requested.

Default to at most three focused jobs, one renderer (Forward+):

1. A focused placement/use check for eligibility/support, dry approach/open shore,
   an affected paid building/station footprint and local excavation/refresh. Test
   the changed behavior; do not sweep every seed, building family or material.
2. One fresh-process Continue check of an affected existing world, with native
   identity, paid ownership, partial source work and lake behavior preserved.
   Reuse RF-05/PLAY-07 evidence for unchanged rules. A small non-lake fen case can
   establish that no water or new geography is invented.
3. A short ordinary player-height Forward+ presentation/use pass: one existing fen
   setting and the V8 lake/home approach. A few selected views and a brief walk/
   wade/shore return are enough to show placement and atmosphere. It need not be
   one continuous cross-world journey. Disclose any initial staging; keep ordinary
   runtime systems enabled and provide exact seed/profile/location for replay.

Use existing import caches after one necessary first import. No before/after
benchmark gate, 24-camera live matrix, second renderer, exhaustive source reopen,
long soak, native rebuild or new package. Additional checking is only for a
concrete changed behavior/failure. Fix blockers within this scope; note incidental
polish/performance issues for the cleanup backlog and keep moving. No hard ten-
minute cutoff, but do not turn this prototype composition into a review intensive.

Use headless/background jobs where possible. Rendered runs must reuse verified
mouse opt-out, BOM-free UTF-8 no-focus override, retained process handles and the
render mutex. Never move the desktop pointer, seize the mouse, stop owner/peer
processes or leave tests running. Never automatically launch owner interactive play.

## Delivery and stop

Make the result available in ordinary New World/Continue, not only a showcase.
Use `build/rf06/` on D: for large outputs, private user/local/temp state and checks.
Keep selected compact screenshots/one short clip, the useful result and new source;
do not copy a parent playable package. Reuse the inherited RF-05 DLL unchanged.

Write `docs/prototype/rf06-fen-lakeside-result-2026-09-16.md`: achieved atmosphere
and gameplay, exact compatibility/tuning, checks actually run, actual media paths,
remaining original-plan work versus deferred cleanup notes, and checked commit
SHA(s). Include a simple private playtest launcher/visible directions using
process-scoped PowerShell Bypass; name the private save slot and preserve owner
and existing private progress. Do not rely on the parked compass UI.

Commit checked source and selected small evidence to this branch. The coordinator
will integrate and push main under standing approval. Stop after RF-06; do not
implement highlands, new impact/scar treatment, compass or another performance fix.
