# A2 - finished fauna in the ordinary game

The normal game on main uses the approved ART-01 boar and ART-03 wolf/stag
rigs, clips and materials. Existing LF visual aliases use the same finished
families; the liked moth retains its earlier art and motion. The checked worker
was integrated as `27e742d` and successfully pushed to `origin/main`.
Owner standing approval applies; owner playtesting remains deferred.

## Player-visible change and limits

`ember_whelp`, `ash_hound` and `valley_elk` now show the finished animals through
ordinary new-world and Continue entry. `lf_red_boar`, `lf_blue_boar`,
`lf_paired_boar` and `lf_white_stag` follow their current `visual_id`; the three
moth identities retain their existing adapter. There is no seed, route or save
filter. [Representative Forward+ view](../art/mainline-fauna-a2-2026-09-15.png).

The existing actors still own movement, collider dimensions, attacks, release
clocks, tells, status priority, loot and saves. Stags still flee. The wolf's cool
scars add no Frost/Retention mechanic. A manually sampled AnimationPlayer uses
native travel, windup/release and the existing release signal. Freeze holds the
pose; stagger cancels follow-through; death stops sampling; pause stops the
cosmetic clock. Native status light fully suppresses scar emission until it
expires. LF hosts retain their channel colours and ground warning shapes.

Only one pose driver runs. Meshes/textures are shared; each actor has a separate
skeleton, AnimationPlayer and shader material. The old hidden surface retains
its existing envelope/label contract, and family/elite scaling applies once.
All production resources are tracked below `game/`. No masters, pilot checkpoint,
preview bootstrap, native DLL, generated engine cache or owner save is included.

Remaining limits: selected mid detail only; no terrain IK or distance switching;
fast travel can still show foot sliding. Generated topology, simple mouth
interiors and the delivered shallow browsing range remain. Legacy envelope
meshes stay cached in addition to the new render meshes. No performance matrix,
minimum-hardware clearance or broad campaign regression was run. PLAY-01-04,
canopy completeness and six replacement-mob rigs remain open; R9 stays stopped.

## Settings and provenance

- `game/assets/authored/mobs/manifest.json`, each adopted entry's `finished`:
  stride per pre-family/elite cycle is 1.25 m boar, 1.5 m wolf/stag. These control
  leg cadence, not movement speed. Idle uses delivered `root` (boar/wolf) or
  `graze` (stag). A 0.5 m extra mesh cull margin covers moving extremities.
- Uniform grounding fits the previous visual envelope. Observed pre-family fit
  scales: boar 1.048434, wolf 1.052462, stag 0.705476. Bodies are unchanged.
- `game/assets/authored/fauna/manifest.json` records selected inputs, source
  hashes, maps and inherited scars: 4-second periods; boar minimum 25%, peak 3.2,
  crest 0.18; wolf/stag minimum 22%, peak 2.8, crest 0.2. No extra point lights.
  Source linear scar colours are converted for the shader's colour uniform;
  LF aliases use the existing channel palette. Normal strength is the delivered
  1.0 boar / 0.65 wolf/stag. Native status tint uses ART-05's 0.65 blend, with
  cosmetic emission fully disabled while a status is active.
- `tools/wroughtwild-fauna/cook_runtime.py OWNER_DEPOT CHECKOUT` reuses ART-05's
  cooked boar and selected ART-03 mid meshes. Mesh, skin and animation buffer
  bytes are retained. Unused embedded fallback materials/maps are removed;
  twelve bound maps are capped at 2048 pixels, lossless with mipmaps and full
  normal/mask channels. Import clips at 100 Hz; automatic mesh LOD is disabled.
  Geometry: 64,983 boar / 62,147 wolf / 68,257 stag triangles. Runtime additions
  are about 75.5 MB; approved editable sources remain in their original handoffs.

## Focused checks actually run

Three focused jobs, Forward+ as the sole rendered backend:

1. Worker game import/load passed (initial import about 30 seconds); the twelve
   explicit texture settings were then refreshed (about 4 seconds). No native
   rebuild or parent-package review. Reused ART-01/03 rig/clip evidence.
2. Actual actors: **62 behavior assertions passed** in about 7 seconds. All
   current family/alias bindings, native numbers/capsules, moving boar/wolf/stag,
   LF windup/release tell timing, freeze/stagger/hit/burn/bleed, pause, passive
   stag, shared resources and independent pose/materials, and reconfiguration.
   The first run had one additional failed capture-comfort assertion: the
   disposable override used the wrong no-focus setting. Corrected to
   `display/window/size/no_focus=true` per [Godot's window guidance](https://docs.godotengine.org/en/stable/tutorials/ui/creating_applications.html).
   Repeated **only the capture**, which passed visible mouse + unfocusable
   window (**1 check, 0 failures**, about 3 seconds). Used the verified
   `--r8-no-mouse-capture` branch; removed `game/override.cfg` after capture.
3. One generated LF Red host: **14 checks, 0 failures**, headless. Native
   streaming returns one finished visual without rewards; duplicate death
   callback pays once; whole-game SaveManager write/read restores identity,
   native ownership, finite sources, loose drops and kill counter; defeated
   host cannot respawn or pay again. Save/Continue uses the same save manager;
   the graphical Continue button itself reuses unchanged A1 evidence.

The restoration job exposed an existing A1 missing `res://c3/surface.gdshader`
while rematerialising nearby resinheart resources. Added the unchanged shader
from its tracked C3 recipe; the checked rerun has no shader/script errors.
The fixture also compared moving drops with an earlier snapshot, then mixed
rounded JSON with full-precision saved doubles. It now compares the saved
checkpoint at matching JSON precision on both sides, retaining every field and
exact ownership assertions. A small saved-drop diagnostic confirmed that issue;
no gameplay/save code was changed. Both failed logs remain in `build/a2/`.

Import-through-final-check elapsed approximately 13 minutes including fixture
writing and diagnostics, with roughly three minutes in engine processes.
Initial reading/cook and final Git/report preparation are additional; no broad
review, benchmark or background continuation was launched. All owned tests have
exited. Private logs, diagnostic and checkpoint stay under `build/a2/` on D:.

## Main integration

Worker commit `e7347d0db771c624533b5a6acf7603591155e295` was cherry-picked onto
main `bfbe815` as `27e742d`; the ordinary `bfbe815..27e742d` push succeeded.
There were no intervening gameplay changes. Git tree comparison confirmed the
integrated game/simulation/tuning match the checked worker; current AGENTS.md and
the owner's existing dirty captures were preserved. The committed diff check passed.

One hidden headless import prepared main's new resources in **6.23 seconds**,
exit code 0, with no reported error lines. Its private application data and logs
are at `D:/Wroughtwild/work/mainline-a2-import`. The owned process exited. Reused
the 62 passing actor assertions, the corrected capture-only pass and 14 passing
restoration checks; no actor/camera matrix, full campaign or gameplay rerun was
performed by the coordinator. Original failed logs remain in the worker's build.

## Manual launch and handoff

From PowerShell:

```powershell
& 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64.exe' --path 'C:/Users/Matty/Dev/project-wroughtwild/game'
```

1. Use the normal chooser to Continue an existing world, or choose a class and
   new seed. No A2/ART-05 flag is required. Normal saves and controls apply.
2. Explore existing Ember Whelp, Ash Hound and Valley Elk habitats. Walk near
   the stag to see its flee behavior; observe boar/wolf travel and attack tells.
3. Save through the normal game controls, restart and Continue. Existing finite
   LF hosts retain their deaths; the optional LF campaign keeps its usual flags.
   Moths and A1 environment/stations remain present.

For focused checks, set APPDATA and LOCALAPPDATA to private D: test folders,
then run `res://tests/mainline_fauna.tscn` or
`res://tests/mainline_fauna_restore.tscn` with `--headless --path game`.
The optional `--a2-capture-only` fixture additionally requires the disposable
no-focus override above and `--r8-no-mouse-capture`; remove it after the capture.

The checked A2 slice is integrated and published; the worker remains available
at its D: path. Owner playtesting stays deferred under standing approval.
Next is [PLAY-01/03 stutter and underground access](play01-movement-worker-2026-09-15.md),
followed by PLAY-02 canopy work.
