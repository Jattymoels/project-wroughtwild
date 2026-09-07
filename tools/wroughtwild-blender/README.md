# Wroughtwild Blender bridge

Local, dependency-free Python MCP server for repeatable Blender building, nature, furnishing and mob studies.
The selected wolf/boar/stag/moth adoption has a separate local authoring recipe:
[editable master and regeneration](../../art/blender/README.md). Its script is
`scripts/build_augmented_beasts.py` and its data is `augmented_beasts.json`.
The older `--mobs` study remains the legacy comparison; it does not replace the
selected animals or their articulated manifest automatically.
The owner requested Blender tooling and selected building meshes/collision fit on
6 September 2026, then approved an official portable Blender download.

The server exposes `blender_status`, `build_building_study`, `build_nature_study`, `build_furnishings_study`, `build_mobs_study`
and `blender_job_status`. It launches a fresh background Blender process for each
study, returns a job id immediately, and writes into a unique ignored
`build/blender-study/<job-id>/` directory. It does **not** control an open Blender
window, run arbitrary submitted Python, or expose a network listener. Keep the
MCP client connected while the job runs; disconnecting terminates its unfinished
jobs. Job ids belong to the server session; completed files survive disconnects.

## Run and connect

Python 3.10+ and Blender are needed; no pip packages or Blender add-ons are needed.
Portable Blender 4.5.9 is installed locally under
`build/blender-tool/blender-4.5.9-windows-x64/`. Its official ZIP was checked against
the matching Blender SHA256 list:
`41da973b9bf95bb312cbeff4d1982feb13259b43c821686b9bafea4dfe5477cf`.
Blender is an authoring tool only; it is not a game runtime dependency.

From the repository root:

```powershell
python -B tools/wroughtwild-blender/run_study.py
python -B tools/wroughtwild-blender/run_study.py --nature
python -B tools/wroughtwild-blender/run_study.py --furnishings
python -B tools/wroughtwild-blender/run_study.py --mobs
python -B -m unittest discover -s tools/wroughtwild-blender -p test_server.py
powershell -NoProfile -ExecutionPolicy Bypass -File tools/wroughtwild-blender/check_godot.ps1 -Study build/blender-study/<job-id>
```

`run_study.py` exercises the actual MCP wire protocol, waits for Blender and reports
the output folder. Set `BLENDER_EXECUTABLE` to use a different Blender executable;
otherwise the server looks in the portable directory and then on PATH. Pass
`-Godot <path>` to the PowerShell checker on a different machine.

The local host registration uses:

```powershell
codex mcp add wroughtwild-blender -- 'C:/Users/Matty/AppData/Local/Programs/Python/Python313/python.exe' -B 'C:/Users/Matty/Dev/project-wroughtwild/tools/wroughtwild-blender/server.py' --project 'C:/Users/Matty/Dev/project-wroughtwild'
```

Restart the Codex session to discover the six tools. The current thread can
already exercise the server through `run_study.py`. A companion plugin manifest
is supplied for packaging, with machine-specific paths in `.mcp.json`; it has not
been published to a marketplace. Change those paths when moving the checkout.

## Asset contract

- Existing `wall_panel`, `pillar` and `beam` IDs/dimensions come directly from
  `data/tuning/construction.json`. A metre is a metre; pivots remain centred.
- Blender coordinates are `(Godot.x, -Godot.z, Godot.y)`. glTF Y-up export restores
  Godot axes. Transforms are applied before export.
- Timber colour and frame darkening come from `game/art/building_look.gd`.
  `study.json` contains presentation-only controls and explains every value.
- `*.glb` holds visible geometry and baked, embedded wood colour textures.
  `*_collision.glb` holds a single box-equivalent convex proxy, named with Godot's
  `-convcolonly` suffix. Importing the latter creates a static collision body.
  Do not add it alongside an existing `PlacedBlock` collider: use the existing
  `PieceMesh.collision_for` shapes when integrating visual replacements.
- The source `.blend` contains a hidden SOURCE collection at the origin plus an
  assembled corner study. Show SOURCE to edit the individual parts. The scene's
  floor, lights, camera and decorative corner cap are review aids, not exports.
- Shallow seams have solid backing. Small worn edges remain inside the existing
  envelope. Automatic corner trims remain a Godot concern under D-017.

The generated Godot project is deliberately isolated from `game/`, its extension,
and game saves. The checker verifies imported bounds, centred pivots, invisible
collision proxies, real physics ray hits/misses, a panel seam and rotation.
To view imported geometry and collision envelopes, run its `godot_preview.gd`
with rendering enabled; it saves `godot-review.png` and exits.

## Land and nature fixtures

The owner's follow-up, "go with the land/nature fixtures", authorises the next
six-role study: broadleaf tree, harvestable boulder, shrub, fern bed, short rotten
deadfall and stump. Run `run_study.py --nature`, then the same Godot checker; it
detects the study type from `report.json`.

Each fixture is one mesh and one material with exported linear vertex colours.
Colours come from the current habitat and weathered terrain/woodland resources,
including their foliage darkening. `nature.json` explains the art controls.
The tree is 10,264 triangles; boulder 1,428; shrub 558; fern bed 1,364; deadfall
158; stump 256. A repeat build compares geometry and colour data for determinism,
and checks finite coordinates, non-degenerate faces and habitat footprint sizes.

The tree trunk and boulder keep the existing `ResourceNode` collision dimensions
and offsets. The source script checks those contracts before exporting. Godot's
automatic convex generation approximates some decimal dimensions, so the review
importer `nature_collision_import.gd` keeps these as the original **BoxShape3D**
primitives. `check_godot.ps1` configures this for the two collision imports.
When integrating a visual replacement into the game, retain its existing body;
do not attach a second collider. The other four fixtures export no collider and
create no additional wood or stone sources.

The nature checker runs 90 checks, including real sweeps with the player scene's
1.92 m tall, 0.42 m radius capsule: solid resources block it, a route alongside
the trunk under the canopy stays open, and decorative cover does not obstruct it.
The accompanying `nature_preview.gd` renders the imported models and collision
envelopes to `nature-godot.png`. Use Forward+, matching the game: Compatibility
handles linear vertex-colour rendering differently. The checker configures the
nature review project accordingly.

`nature-study.blend` contains a hidden SOURCE collection of surface-anchored
fixtures and a landscape display. The ground patch, small turf tufts and display
placements are review aids, not a replacement for editable game terrain.
The generator also saves `nature-landscape.png`, `nature-ground-detail.png`, six
visual GLBs and two collision GLBs, all in the ignored job directory.

## Furnishings

The owner's next continuation, "go through all the furnishing", covers the six
existing types: chest, campfire, workbench, mason's yard, basic forge and improved
forge. `run_study.py --furnishings` creates all six, with embedded grain/mineral
colour textures, worn edges, joinery, iron fittings, masonry and static embers.
The chest has separate body and lid meshes; the lid rotates about its rear hinge.
The other five types each export one mesh. `furnishings.json` documents every
art control and the fixture proportions. No external art or Python package is used.

Outputs include `furnishings-study.blend`, `furnishings-catalogue.png`,
`furnishings-workshop.png`, six visual GLBs and six existing-body collision GLBs.
Pivots match StationSite/PieceMesh: stations sit on the ground, the chest floor
is local Y -0.5 m, and the campfire floor is local Y -0.25 m. The chest's closed
lid now fits its 1.0 x 0.7 x 0.8 m box, removing the old visual overhang. Retain
these original pivots when replacing meshes; do not apply the display's ground
lift a second time in the game.

**Separate collision proposal:** all four stations currently have a 0.96 x 2.0
x 0.96 m box. The four `*_fit_collision.glb` files lower its top to 0.95 m for
the two work surfaces, 1.575 m for the basic forge and 1.96 m for the upgraded
forge, retaining the same horizontal footprint and solid underside. Small tools
remain decoration. These are review candidates, not an accepted gameplay change.
The normal game continues using its existing bodies. Applying the candidates
would change above-table movement/projectile clearance and interaction targeting;
review those effects in the normal player scene before adoption.

The shared `nature_collision_import.gd` keeps both existing and candidate proxies
as precise BoxShape3D primitives. The furnishing checker independently compares
against the actual `PieceMesh.collision_for` function, construction data and the
StationSite scene, then checks all four rotations with the player capsule.
Its 302 checks cover exported materials/textures, bounds, cell anchors, hinge
rotation, walking obstruction, side clearance, interaction rays, low fire height
and the candidates' clear space above the worktops. It does not exercise actual
inventory panels, fuel consumption, jumping/stepping logic or save restoration.

`furnishings_preview.gd` saves `furnishings-collision.png` (current bodies green,
proposals amber) and `furnishings-godot.png` in the isolated Godot review project.
Run it with rendering enabled, as for the other preview scripts. A repeated
Blender build reproduced all 16 GLBs byte for byte, including embedded textures.

## Mobs and creature rigs

The owner's continuation, "After that - mobs", covers the current 12-actor
roster: ten hostile families, the Forge Tyrant and passive Valley Elk. Run
`run_study.py --mobs`, followed by the same Godot checker. The Blender recipe
reads `world.json`, `trial.json`, `combat_realtime.json`, the actor scene capsules,
actor palette/scale code and current creature-motion controls. `mobs.json`
documents presentation controls and proportions. No downloaded creature art,
add-on or Python dependency is used.

Each actor exports one mesh, one vertex-colour material and a six-part rig
(eight parts for the two crawlers). All vertices have one rigid part weight,
matching the current prototype's approach. The bone names and rest pivots follow
CharacterLook, with family scales applied into mesh vertices and bone positions.
Coordinates are **actual Godot world metres**, facing -Z, with a ground origin.
Integration must not multiply the family's visual scale a second time. The
single material retains a straightforward status-flash override path; family
colour is already baked into linear vertex colours and must not be tinted twice.

There are 47 exported presentation clips: idle/walk for everyone, windup/release
for hostile actors, and an extra inhale for the boss. Windup/inhale durations
come from the combat table; release uses the current 0.22-second presentation
recovery. The in-place walk lasts one second for inspection, not runtime travel
pacing. The clips have no damage/event tracks or actor-root movement. The passive
elk has no attack clips. Animation clips are isolated using Blender NLA tracks.

`mobs-study.blend` holds all editable rigs in a hidden SOURCE collection and a
visible humanoid review set. `mobs-beasts.png` and `mobs-humanoids.png` show the
two groups at actual scale. Each actor has a visual GLB plus `_collision.glb`.
`mobs_collision_import.gd` restores the latter to a **CharacterBody3D with the
source CapsuleShape3D**, rather than accepting an approximated convex hull.
The shared checker invalidates only the affected generated scene cache when it
adds a post-import script, avoiding Godot's same-second timestamp cache issue.

The mob checker independently reads the actual actor scene dimensions and
CharacterLook pivot function. It checks normalized skin weights, inverse binds,
rest bounds, named joints, every clip's pose/duration, root stability and all
four rotations of player-capsule/projectile-sphere contact and side clearance.
The review export has 855 passing checks. A repeat build reproduced all twelve
skinned/animated GLBs byte for byte. Capsule proxy geometry and attributes also
match; Blender can reorder their triangles between processes. Imported capsule
primitives remain exact and deterministic.

Run `mobs_preview.gd` with rendering enabled in the generated Godot review
project. It saves `mobs-roster.png`, `mobs-collision.png`, and a 24-frame reel with
play/pause/scrubbing at `mobs-motion.html`. This uses the actual imported skins
and AnimationPlayers, not Blender screenshots. No browser library is needed.

**Collision finding:** ordinary actors all retain the current radius 0.35 m,
height 1.3 m capsule; the boss retains radius 0.9 m, height 3.2 m. Family and
elite visual scaling currently leave those bodies unchanged. The small wisps
have about 0.694 m of empty collision above them, while long muzzles, tails,
crawler legs, shields and larger forms extend outside their body's cylinder.
The report records these differences; passing compatibility checks does not
mean the silhouette fits the hitbox. Attack ranges and ranged muzzle heights
remain independent source values. Choosing per-family movement/hurt shapes is
a combat follow-up, with balance and traversal implications, not silently done
by this art recipe.

## Scope and next work

This proves mesh/export/collision conventions, not production art or a complete
asset editor. Building pieces, six nature fixtures, six furnishings and the 12-actor mob roster are the current recipes. Extend the reviewed
Blender script for subsequent asset studies; the MCP has no freeform modelling
or live scene-inspection tool yet. The wall is 628 triangles, post and beam 44
each before Godot import. The wall still exports multiple mesh parts/materials;
consolidation is needed before widespread runtime use. Fine-scale variants,
doors, stairs and pitched roofs are not validated. Mob checks verify the existing
body/projectile contact contracts, not live melee/cone combat balance. Capsule
sweeps cover nature, furnishings and mobs. The staged corner cap is a presentation proposal.

Nature meshes are static prototypes: no wind rig, felling animation, distant
tree LOD authoring or biome variants yet. A dense forest performance review and
the game's existing harvesting/shrink/grounding integration remain before normal
world adoption. The current study does not change world placement or saves.

Furnishings remain static prototypes with 3-5 material surfaces per type, not an
atlased/LOD production set. The chest has a useful hinge but no authored animation
clip or runtime lid interaction. Campfire/forge embers are static; runtime fuel,
fire lighting and burn-out stay on their existing gameplay paths. New furniture
roles such as beds, chairs, shelving and lamps are not part of the current catalogue.

Mob art remains a visibly faceted prototype. Rigid weights give mechanical knees
and elbows; no foot planting, terrain IK, smooth deformation, death animation,
LOD or crowd performance pass is included. Normal actors still use their current
meshes and CreatureMotion. Adoption needs an explicit scaled-rig adapter and
event-driven animation integration, including freeze/stagger, status colours,
committed ranged aim and the boss's breath cues. Do not attach two animators to
the same rig or make animation events authoritative for damage.

Normal game art, collision rules, costs, unlocks, saves and tuning are unchanged.
After review, the next integration is a visual mesh replacement on the existing
placed-piece path, keeping the existing primitive collision bodies and testing
the first-person walking route in the workshop.

References: [Blender command line](https://docs.blender.org/manual/en/4.2/advanced/command_line/index.html),
[Godot collision import suffixes](https://docs.godotengine.org/en/4.5/tutorials/assets_pipeline/importing_3d_scenes/node_type_customization.html),
[MCP stdio](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports),
[Codex MCP configuration](https://developers.openai.com/codex/mcp/).
