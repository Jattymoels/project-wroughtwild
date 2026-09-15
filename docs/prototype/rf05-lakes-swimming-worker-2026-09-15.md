# RF-05 — a lake worth making a home beside

Status: prepared for the owner to start after RF-04 adoption, 15 September 2026.
Worktree: `D:/Wroughtwild/work/rf05-lakes-swimming`.
Branch: `codex/rf05-lakes-swimming`. Exact base, inherited DLL and existing native
build inputs are in `build/rf05/SETUP.md`. The coordinator integrates the finished
source and matching DLL into main and pushes. Do not start another slice.

## Player outcome and authority

The owner now requires water and selected **"Lakes with simple swimming fine"**.
Deliver a lake in ordinary fresh worlds that makes exploration and base building
more appealing: an inviting shore, a view across water, a useful dry place for a
house/workshop and room to extend it. Walk into the shallows, swim across deeper
water with normal movement input, and walk out naturally. Early look, feel and
atmosphere matter more than exhaustive proof or small cosmetic imperfections.

Read the current owner depot's `AGENTS.md` and follow its required reading order.
Then read [the selected water scope](rf05-lakes-swimming-scope-2026-09-15.md),
[RF-04 result](rf04-ground-continuity-result-2026-09-15.md), the current coordination
sheet, and relevant world-generation, construction, combat and loot/save contracts.
Keep the reclaimed-landscape references and owner home-building sentiment in view.
Historical no-swimming exclusions are superseded only for this selected feature.

The choices below settle the earlier scope's open details under standing approval.
They are ordinary prototype implementation decisions, not additional owner quotes.

## One complete lake, composed into the landscape

- Generate **one guaranteed lake per fresh normal world** initially. Use seed-driven
  position, orientation and restrained shoreline variation. Start around 50–90 m
  across, with a roughly 4 m deepest area and 6–10 m gentle shallow margins.
  These are tuning starting points, not a camera or numerical beauty gate.
  Keep count, size/depth, shore width and siting controls together in the separate
  V8 tuning file, explaining the player experience each controls.
- Carve a real native basin and shape its dry surroundings before final finite
  resources and route guarantees. Give at least one of the four useful home
  settings a lakeside outlook and dry expansion space. Keep the four radius-14 m
  level cores, opening/supply guarantees and existing paid construction kit.
  No free dock/home, plot bonus, new building material or forced base location.
- Keep spawn, guaranteed supply/discovery/cave routes and home access usable on
  land; swimming is a new option, not a new progression gate. Keep terrestrial
  resource/patrol placements out of deep water and existing ground-only roaming
  ashore through bounded eligibility/contact rules. No aquatic enemy production
  or general AI rewrite. Preserve finite stock and content identities.
- Use a bounded candidate search and deterministic fallback for a safe basin.
  Do not erase cave entrances, rare/progression sites or protected home cores to
  force it. Preserve legitimate caves beneath/outside the basin. Adapt only the
  new profile's composition as needed, not old generation inputs.
- Retain broad hills, woodland enclosure and the RF-04 upward-face correction.
  Gentle shore grading should avoid introducing a fresh rim of small humps or an
  inaccessible one-metre lip. Do not turn this into an all-biome terrain remake.
- Use existing art/shader ingredients or small original project-authored visuals:
  restrained surface motion, readable shallows and coherent shore colour. Existing
  fen discs in `strange_sites.gd::_pools` are decorative, not a basin/swim system.
  Lake water should not draw through raised ground or paid buildings. Keep grass
  out of submerged ground and preserve paid-footprint clearance. No downloaded
  asset, reflection framework, boats, diving or fluid simulation is needed.

## Small shared water contract

Add a compact native lake record to the new profile's WorldMap: stable local ID,
surface elevation and bounded footprint/depth information (including original
bed limits). Expose this with the runtime map. It is deterministic generated
geography, not another inventory owner or a per-frame world scan. Old profiles
have no gameplay lake records and retain their decorative pools unchanged.

Use one consistent bounded water query for visuals/contact, player movement and
loose-drop landing. Fixed extents and levels are the first-pass edit policy:
digging does not drain or spread a lake, or flood an entire underground column.
Limit water to its generated basin volume; reject occupied solid volume and
refresh affected shore/cover/contacts through existing local edit hooks. A newly
dug tunnel beyond/below that original volume stays dry. Record the visible static
boundary as a prototype limitation; do not add a protected no-dig zone or change
ordinary build payment/support rules to simplify it. Raised paid floors provide
dry support above water, with actual collision and placement still authoritative.

## Movement, recovery and ownership

- Integrate with `WroughtwildPlayer._physics_process`, existing movement/step
  handling and terrain contact. Wade using grounded movement until water is deep
  enough to swim; surface swimming supports the body with the camera above water.
  Normal horizontal input steers. Start swimming around 1.1 m depth and around
  70% of normal walking speed; document/tune the actual transition hysteresis,
  support offset and speed for comfortable entry/exit. Avoid repeated state
  toggling, landing dips or walking footsteps while afloat.
- No oxygen/drowning/stamina meter or swim skill. Keep collision with banks and
  buildings, existing combat roots/haste/dash rules and pause/panel behavior.
  Water support must not grant invulnerability, change skill costs or bypass
  walls. Do not add special underwater combat or change ordinary land controls.
  Stop upward jump buffering from repeatedly popping the player out of deep
  water; ordinary grounded exit/jump behavior remains available at the shore.
- Derive transient wet/swim state from the loaded world and actual pose. Reset it
  on New World, teleport, death/respawn, trial boundaries and Continue. Ensure
  world water/contact exists before releasing restored movement. Saving while
  afloat and continuing should return to a valid surface pose, not the lake bed.
- **Drops and open-world death packs float at the lake surface**, at their same
  horizontal location, when released into its water volume. Use the current
  `Pickup` and `DroppedBundle` ownership; no new container or bank teleport.
  Ordinary pickup attraction/interact remains reachable from a swimmer. Retain
  material lifetimes/capacities, gear/page identity and exact death-pack contents.
  Do not lift underground loot through solid ground just because a lake is above.
- `WorldDrops.capture/restore` already stores position, landing height, flight,
  age and exact contents; reuse that contract. Restore one set, settle its water
  contact without awarding/re-rolling anything, and preserve its age. Do not
  reset expiry on water contact or copy a death pack while moving it. Off-water
  drops, open-world death categories and trial deposit/rewards stay unchanged.

## Version and integration boundary

Add **`frontier_v8`** for normal fresh random/chosen-seed worlds at the existing
1,024 x 1,024 x 96 extent and one-metre editable cells. Use separate V8 tuning and
composition; `worldgen.json`, V7 inputs and published V1–V7/LF algorithms stay
frozen. Continue restores the saved profile/seed before generation. No retroactive
lake carving through player homes, new LF geography or campaign-event changes.

Explicitly include V8 in applicable adopted art, RF ground/grass, the RF-04 native
continuous-surface condition, streamers, resource/pack/site paths, native bindings,
pressure identity and strict save validation. Do not broaden LF-only mechanics.
New lake metadata is regenerated from immutable identity; persist only additional
state actually required. Keep existing save validation and ownership boundaries.

## Focused verification and handoff

Name risks first; default to three focused jobs on one renderer, Forward+:

1. **Generation/identity:** one primary seed and one variation, checking repeatable
   lake geometry, safe shores, dry home/supply/progression guarantees and sensible
   content placement. Use focused guards for untouched V7/LF inputs/routing and
   one retained old-save load; reuse RF-03/RF-04 evidence instead of a legacy matrix.
2. **Water behavior/ownership:** a small connected entry → swim → shore-exit use
   fixture, one lake-edge edit/paid-support case, save afloat and fresh-process
   Continue, plus exact pickup/death-pack recovery. Exercise off-water reset and
   the selected basin-volume boundary. Reuse unchanged cost/build/campaign checks.
3. **Ordinary Forward+ play:** one short real shore/wade/swim/exit route and dry
   home view, with a few actual screenshots and an eight-second motion clip.
   Keep active physics/world work; do not pass a teleport tour off as traversal.
   Show the building possibilities as well as water. No seed/camera matrix.

Use the established test-only mouse-capture opt-out, BOM-free no-focus override
and render mutex; no desktop pointer automation. Imports, build and private saves
stay on D:. Reuse the existing Godot ABI and incremental objects. Do not replace
the owner depot DLL or touch remote access/app settings. End owned jobs.

Write `docs/prototype/rf05-lakes-swimming-result-2026-09-15.md`, update the affected
specifications and commit checked source/tuning/selected evidence on the worker
branch. Report achieved gameplay, remaining limits, actual checks, tuning, source
commit and matching DLL hash/path/provenance. Show pictures/clip inline with
absolute paths and exact ordinary New World/Continue playtest instructions.
The coordinator adopts and pushes. Stop after RF-05; R9 and PLAY-03 stay parked.
