# ART-07B3 — rock and contact candidates

Six assigned roles only: boulder, stone_seam, river_bank, talus_pebbles,
rock_shelf and cave_threshold. Source candidates and a copied-game adapter;
ordinary-world adoption is not included. See the B3 receipt for the selected
package, measured costs, technical checks and visual limitations.

The immutable ART-02 quiet fractured rock supplies broad bedding, texture and
weathering. Its root-bank supplies attached roots. No new generation was needed.
`provenance.py` verifies the selected original files and every pinned local
TRELLIS model. The raw export records v0.6.0 CUDA, seed 42, build commit
16f3109e82f3922033bfa62b83c42899678b7b6f; the release target is a distinct commit.

Near surfaces retain the original UVs and albedo/ORM. Cut solids have separate
planar UV faces. The packed master retains unchanged original meshes/maps and
an unused closed-shell comparison, all hidden in source/finished collections.
Only the named GLBs in the manifest are selected runtime candidates. Selected packed geometry is v09, with v10 correcting its scar-channel export. Rejected
v01–v08 working versions are not handoffs. Near generated topology is not
certified as universally watertight: audited small open edges are retained;
the visible recovered cut face is capped. Inspect hidden-side views.

Blender metres map `(x,y,z)` to Godot `(x,z,-y)` once through glTF. All resource
pivots stay at their existing ground anchor. The boulder fits its unchanged
1.4 × 1.0 × 1.2 m native body. Its 9/6/3-unit appearances use three capped
states; native depletion still rolls it away and removes it. The supplied
released-chunk candidate is not adopted by the native cosmetic-chip routine.
No persistent resource remnant, stock, kit, drop, collision or recipe is added.

The seam keeps the original GroundedSeam work ribbon and picking shape, with
low adjacent bedding projected through Terrain's real SurfaceSampler. Missing
supports and excessive height differences remove triangles; repeated support
restoration is deterministic. Existing wedge, heat, cracked, work and depletion
state remain native. The copied adapter refreshes appearance through the normal
restore hook. A later world adapter must install it when streamed nodes are
created; this handoff does not patch the shared game's streamer.

The bank, talus, shelf and cave lip contain no decorative collision or resource
identity. Cave pieces are contacts for retained terrain walls, not an independent
new cave generator or a freestanding masonry arch. The authored support fixture
walks the real player capsule through a 2.4 m wide, 2.4 m high clear region.
Native-world adoption must fit/suppress these modules against each actual site.

`kit.json` documents every local dimension/detail/pulse control. The altered
shelf has a measured roughly 65 mm incision; original and altered finished
meshes retain corresponding vertices for independent measurement. Colour is
sRGB, ORM and scar attributes are linear. Only the altered shelf has ambient
moving energy. Its clock pauses, uses no bloom or per-scar light and has no
relationship to a work reward, element effect or source stock.

## Reproduction

Run from the isolated B3 worktree, with existing depot tools. The following
are argument contracts; use fresh output names. The actual executed paths,
argument arrays, PIDs, durations and exits are in the package's job logs.

1. `python provenance.py DEPOT ROOT/provenance.json`
2. `blender --background --threads 8 --python-exit-code 1 --python inspect_source.py -- DEPOT FRESH_INSPECTION`
3. `blender --background --threads 8 --python-exit-code 1 --python build_kit.py -- DEPOT ROOT/kit-v10 --no-render`
4. `blender --background --threads 8 --python-exit-code 1 --python render_master.py -- ROOT/kit-v10/b3-master.blend ROOT/blender-v09`
5. `blender --background --threads 8 --python-exit-code 1 --python audit.py -- ROOT/kit-v10 ROOT/audit-v10.json`
6. Use the existing `tools/wroughtwild-workshop/build-native.ps1 -Revision f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d -Output ROOT/native-v02` from the canonical depot. It reads existing godot-cpp headers/library and compiles all game rules from that exact revision.
7. `python prepare.py ROOT ROOT/kit-v10 ROOT/review-v06`
8. Fresh Godot `--headless --editor --path PROJECT --import` for review and native/game, then `verify_runtime.ps1 -Root ROOT/review-v06 -Logs FRESH_LOGS -Stage Native`, `Capture`, and separately `Benchmark`.
9. `run-current-checks.ps1 -Project ROOT/review-v06/native/game -Logs FRESH_LOGS` runs the unchanged current checks. Paired restore jobs share their isolated APPDATA.
10. `python encode_motion.py ROOT/review-v06 ROOT/motion`. `package.py ROOT FRESH_HANDOFF` collects the selected version folders and completed logs listed in its source; use matching fresh names when reconstructing.

Use `run-job.ps1` for isolated user directories, exit propagation and recorded
commands. Pass `-Gpu` for Godot captures/benchmarks; it acquires the shared
`Local\Wroughtwild-Art07-GPU` mutex and refuses existing renderer/generator jobs.
Blender evidence uses explicitly selected Cycles CPU, eight threads. Benchmarks
run after all competing authoring/capture work has ended. No global installation,
download, driver change or owner-save access is involved.

## Review

`recipe/launch-review.ps1 -Package HANDOFF -Visible` copies the standalone
review into a new sibling session and imports that copy. Add `-Compatibility`
for OpenGL, or `-Native` for the automated finite-work fixture. The latter
supplies six test wedges, performs normal work/pickup transactions and exits;
it is not paid first-hour gameplay. Canonical package contents remain unchanged.

Static controls: click/mouse to look; WASD/QE flight, L day/shade/dusk,
M energy on/off, Space pause, 0 automatic detail, 1/2/3 fixed detail, R overview,
Escape cursor. This flight scene is labelled static and has no harvesting.
The separate native scene verifies work, exact stock, capsule passage and
support removal/restoration. Both have actual Forward+ and Compatibility views.

Selected review-v06 tightens only the native fixture camera and hides the
player's first-person presentation from that external camera. Static captures
and separate benchmarks from review-v05 are retained byte-for-byte: its static
scripts, shader, assets and settings are identical. Native v06 checks and captures
were rerun. The raw floor PNG is intentionally included for the standalone
project; a compiled PCK export is not delivered or tested.

Use `python recipe/verify_package.py HANDOFF FRESH_COPY` before importing the
copy; rerun `python recipe/verify_package.py HANDOFF` afterward to prove the
canonical handoff was not changed. `audit.py FRESH_COPY/models FRESH_AUDIT.json`
is the Blender script's argument tail after `--`.

Do not infer full-world budgets, other-machine performance, normal-streaming
adoption, final aesthetics or owner approval from this bounded handoff.

`godot --headless --path REVIEW --script res://verify_pause.gd` separately
exercises the interactive Space key, advancing clock and every scar uniform.
The capture sequence holds its clock manually and is not itself proof of the
interactive pause/resume path.
