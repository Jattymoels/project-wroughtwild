# RF-07: recovered highlands and a usable outlook

RF-07 gives ordinary Rocky Hills/Glasswind Uplands weathered stone, settled debris
and hardy vegetation pockets. Four original Blender forms join existing outcrops
to low tussocks, woody heath and cushion growth. A real seed-77 bench supports a
paid octagonal floor and workbench, reached and used through ordinary controls.
The treatment is installed in normal New World/Continue on this worker branch.

## Coordinator adoption and owner direction, 16 September

Integrated on main by fast-forward as `1312c20fe8853da770984f221b3fa1048ad186ee`.
Reused 34 placement, 16 Continue and 11 Forward+ route/use checks. Main's hidden
headless import passed in 4.87 s, exit 0, zero reported errors. Native DLL unchanged;
all owned checks ended. Only committed work was adopted; unrelated local import
metadata and private worker progress were preserved. The handoff below is historical.

The coordinator assessed the three retained game pictures: useful open space and
hardy growth, but the scene still reads as sparse grey-green scrubland. Ground
and large rocks blend together; plant clumps, simple outcrops and repeated trees
weaken the intended recovered-highland identity. The outlook is usable but not
yet especially memorable. This is a partial visual outcome, not full reference
atmosphere or a live coordinator playtest. The owner replied: "I agree, let's move on".

The [coordination sheet](coordinator-status-2026-09-15.md#original-plan-sequence-and-end-of-wave-cleanup)
prioritises rock/ground definition, then connected growth transitions and wider
shape/outlook composition for cleanup. Floor joints are lower priority. RF-08
impact/living-scar composition is next; no further RF-07 revision is selected now.

## Appearance and remaining weaknesses

The first player-height view was too pale and scattered. Correcting the local
material colour conversion, increasing patch scale/contrast, and strengthening
debris bands made the ground read as darker aged rock with greener sheltered
pockets. Large rocks frame a usable bench; the eastward view remains open.
The final images were inspected by the worker, with unchanged global lighting,
player height, terrain and camera settings. They demonstrate a playable visual
iteration, not owner aesthetic acceptance or reproduction of ENV-007.

- [Rock-framed approach](rf07-evidence-2026-09-16/01-recovered-rock.png): paid floor and bench sit between existing outcrop and planted shelf.
- [View from the paid floor](rf07-evidence-2026-09-16/02-outlook-floor.png): low recovery masses preserve the open eastward outlook.
- [Usable sheltered workbench](rf07-evidence-2026-09-16/03-sheltered-workbench.png): low scrub/tussocks frame the work area; ordinary E interaction opens it.
- [Continuous walk, about 3.3 seconds](rf07-evidence-2026-09-16/highland-walk.gif): silent 640x360 encoding of 49 engine frames sampled every four physics ticks. No cuts; PNGs are unretouched 1280x720 engine captures.

**Remaining weaknesses:** broad protected resource/work clearances still expose
bare ground; growth forms repeat at close range. Original trees retain angular,
repeated silhouettes, and large outcrops remain visibly faceted. Some metre
terraces have abrupt dark edges; this slice neither grades nor replaces them.
The nine-piece floor has visible joints/corner transitions. Fine debris and
lichen are subtle at distance, and the overall palette is subdued. The scene
improves low/middle composition; it does not deliver the reference's mountain
scale or a complete environment-art overhaul. Keep these notes for bounded
end-of-wave cleanup instead of extending RF-07.

## Ordinary seeded implementation

The representative bench was selected from the actual V8 seed-77 generated map
at `(840.5, 69, 708.5)`, about 7.3 m from an existing regional outcrop anchor.
The wider region is centred on `(814, 69, 664)`. These coordinates appear only
in private scene/test selection; runtime scenery has no capture-location branch.

`game/rf07/cover.gd` reuses the existing uplands anchor recipe. Regional ribs and
outcrops retain their roles; supported shingle/vegetation replaces the old
independent sedge/scree scatter. Native local rises, existing rock footprints
and seeded patch noise shape low growth, dense hearts and exposed margins.
V6/V7/V8 and current LF geography profiles use actual `rocky_hills`, including
region-forced low-altitude terrain. V1-V5, meadow/forest/fen/ember eligibility,
RF-06B planting, lakes and terrain generation remain unchanged.

The map-derived material mask keeps colour/relief near original top surfaces.
Full moving footprints sample actual upward triangles at at most 0.32 m spacing,
reject missing original support, water and other biomes, and stay inside their
own chunk. Existing paid floor/station clearance hides intersecting instances.
Local excavation and chunk retirement use existing rebuild paths. Shared assets
prepare during actual world build; no new movement-callback loads or per-frame
world scans are introduced. Creature/scenery preparation is unchanged.

No native code/DLL, world profile, heights, collision, save schema, progression,
finite yield, water rule or building cost changed. Both LF terrain publications
already enter through validated SaveManager restore and world rebuild; the new
cosmetic context follows the resulting map there. Existing LF publication/save
and arrival evidence is reused; no campaign replay was run.

### Editable source and tuning

- Master: `D:/Wroughtwild/source-art/rf07-highland-recovery/rf07-highland-master.blend`.
- [Recipe](../../tools/wroughtwild-rf07/build_kit.py), [art parameters](../../tools/wroughtwild-rf07/art.json), and four selected exports retained beside the master.
- [Source notes](../../game/rf07/SOURCE.md), [dimensions/provenance](../../game/rf07/source.json), [runtime settings and visible purposes](../../game/rf07/settings.json).
- 15 m patches, 4 m local shelter sampling, 5.5 m rock fringe, 0.85-1.5 full scale,
  0.48 narrow fringe, 4.5 cm root embedding and 78 m low-detail fade. Palette roles
  and surface binding are documented in the source notes.

## Checks actually run

| Focused job | Final result |
| --- | --- |
| Placement, support, biome and paid-work fixture | 34/34 passed; 49.08 s |
| Fresh-process Continue and exact saved ownership | 16/16 passed; 49.62 s |
| Forward+ player-height approach, floor and aimed station use | 11/11 passed; 55.26 s; 11.895 m walked |

The placement sample contains 286 cushion, 65 heath, 188 tussock and 71 shingle
instances in the nine selected chunks, before paid hiding. Maximum tested moving
width is 1.738 m. These counts describe this fixture, not whole-world coverage.
The check removes an outer support cell with existing heat/crack/dig behavior,
then verifies retirement/rebuild and exact restoration. Nine floor pieces cost
nine wood; the normal crafted workbench kit is consumed. Actual station-body
clearance, partial finite-source work and a cheap second-seed deterministic spot
check pass. Low-altitude Rocky Hills and historical/other-biome exclusion are
checked without generating a renderer/seed matrix.

Continue preserves exact native possessions/progression, blocks, stations,
contraptions, leylines, finite resource records, loose drops and excavation;
height/lake digests and cosmetic/paid-clearance state match. Movement and resaving
also pass. The walk leaves ordinary world systems active and opens the bench
through the aimed interaction ray. Acquisition/build placement is harness-paced
using actual finite work, pickups and payment; one disclosed initial staging
starts the short walk, with subsequent movement using the ordinary controller.

The necessary fresh import passed in 40.93 s. New assets imported during a later
3.84 s pass that exposed a GDScript inference error; its explicit float annotation
was corrected before the clean early scene and final jobs. Early scene passed
3 load/capture/save checks in 51.97 s. Placement was rerun once after strengthening
the visibly inadequate debris band. The first final walk passed movement but
missed the bench because the fixture aimed at its logical cell rather than the
actual body centre. Only that focused walk was rerun after fixing the aim.
No assertions were removed. Final jobs exited 0 with zero reported engine errors.

Rendered jobs verified visible/free mouse and no-focus window flags. All owned
checks ended and the temporary override was removed. Logs, private test slots
and raw captures remain in `build/rf07`; selected receipts are beside the images.
The unchanged native DLL is the SETUP-verified
`FBF7067477D63693E35B5D15CCFF0BBAD86BE7586D679E284A44C843B0404E2B`.
No performance benchmark, hardware clearance or broad regression wave was run.
Long entry, residual group-frame/scenery costs and the underground correlation
remain open; functional checks do not establish hitch-free play. Owner playtest
feedback is deferred.

## Exact private playtest

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:/Wroughtwild/work/rf07-highland-recovery/tools/wroughtwild-rf07/play.ps1"
```

Choose **Continue saved world**. Start at the checked highland bench near
`(840.5, 69, 708.5)`, facing east across the outlook. The paid octagonal floor
is just behind/left; the workbench is south, to your right, at cell `(840,69,712)`.
Walk around the rocky shoulder and vegetation pockets, step onto the floor,
then aim at the workbench until **Workbench - E to work** appears and press **E**.
WASD/mouse move/look, **F5** saves, **H** shows controls. Normal enemies remain
active. Close the game when finished.

The launcher creates `build/rf07/playtest-highland` only as needed and copies the
checked source save only when neither its save nor previous checkpoint exists.
Later launches preserve private progress. It restores process environment
variables on exit and never reads or writes normal owner saves. Add `-Fresh` to
use a separate `playtest-new` slot and start seed 77 at its normal class/opening.
The launcher receives a syntax check; the actual source fixture is covered by
ordinary Continue and the rendered walk, without launching an extra owner game.

## Handoff and next original work

Completed on `codex/rf07-highland-recovery` in the requested D: worktree. Checked
commit SHA is reported in the worker handoff. Coordinator adoption and any main
push remain separate; this worker does not merge or push main. Fresh imports
changed unrelated tracked sidecars locally; those are excluded from the slice
without resetting them. No parent package, native rebuild or source archive was
copied. The four small new exports and editable master are retained on D:.

RF-07 advances the original recovered-highland outcome. Next original work is
remaining impact/living-scar composition, then bounded cleanup. The weaknesses
above join that cleanup backlog; compass/coordinates remain parked. Stop here:
no impact/scar, fen continuation, performance tangent or next worker is started.
