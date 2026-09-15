# RF-06B: connected fen growth in ordinary play

RF-06B replaces the small repeated fen clumps with five original Blender forms:
spreading sedge, swept sedge, curved rush fans, arching ferns and shallow root
weaves. The seed-77 fen now has connected low planting, a distinct middle layer
and open walking space. The same seeded rules plant suitable existing dry lake
banks. This is a material scene improvement; owner response to this revision is
still pending, and passing functional checks is not aesthetic approval.

## Appearance, assessed from the actual game

The initial in-game look established wider overlapping leaves and curved groups.
It still left too much empty terrace edge. The final revision added a smaller
fully supported fringe and narrowed the sparse passage band. Final images show
low growth joining into irregular masses, ferns distinct from rushes, and open
space between them. Normal lighting, player height, HUD and gameplay remain.

- [Fen ground](rf06b-evidence-2026-09-16/01-fen-ground.png): broad leaves connect the foreground to a planted middle distance; rushes rise above them.
- [Fen passage](rf06b-evidence-2026-09-16/02-fen-opening.png): the four-metre walk reaches open ground between planted masses.
- [Lake outlook](rf06b-evidence-2026-09-16/05-planted-bank.png): dry bank planting frames visible water after an ordinary swim and exit.
- [Motion, eight seconds](rf06b-evidence-2026-09-16/fen-shore-walk.gif): silent 640x360 selection, with a disclosed cut from the fen to lake travel. The PNGs are unretouched 1280x720 engine captures.

**Remaining visual weaknesses:** large tree/resource clearances and abrupt
terraces still expose broad ground; repeated original trees dominate the distant
silhouette. Individual fern/rush patches remain recognisable at close range.
Lake-bank foliage loses detail in existing deep shade, while water glare and
angular shore geometry remain conspicuous. The scene is stronger at player
height than at distant tree-canopy scale. No tree, global-lighting or terrain
revision is included, and this does not claim the full reference atmosphere.

## Implementation and editable source

The ordinary RF-06 compositor now uses the new kit on its unchanged V6/V7/V8/LF
fen and suitable actual dry-bank eligibility. Seed/profile noise groups growth
and sparse passages; there are no capture-coordinate placement overrides.
New five-mesh resources prepare once through existing world entry, share
materials and the pause-aware wind clock, and use existing chunk MultiMeshes.
Mob/scenery arrival preparation is unchanged.

[Runtime tuning](../../game/rf06b/settings.json) explains each control: 13 m
patches, 68–94% eligible root coverage, 24% sparse passage coverage, low fringe
scale 0.48, rush/fern/root shares, unchanged 7 m bank band and 11 m tall-growth
home clearance. Full patches extend beyond the old single-cell envelope.
Support probes at most 0.35 m apart cover the footprint, reject holes/water and
abrupt unsupported shelves, and include shallow root dressing. Actual mesh
bounds clear paid work. Patches stay within their owning 16 m chunk, shrinking
at its edges. Existing ground textures receive a local surface-bound litter/turf
blend; there are no new terrain, water, collision, ownership or save rules.

- Editable master: `D:/Wroughtwild/source-art/rf06b-fen-art/rf06b-wetland-master.blend` (five separately editable meshes, metres).
- [Rebuild recipe](../../tools/wroughtwild-rf06b/build_kit.py), [art parameters](../../tools/wroughtwild-rf06b/art.json), also beside the master.
- [Provenance and dimensions](../../game/rf06b/source.json), [source notes](../../game/rf06b/SOURCE.md), selected GLBs in `game/rf06b/assets/`.

Direct Blender modelling suits these open thin-leaf silhouettes. The available
local image-to-3D option was not needed; no dependency, model or external asset
was downloaded. Blender ran in the background with an error exit code enabled.

## Functional verification, separate from appearance

| Focused check | Actual result |
| --- | --- |
| Changed-asset headless import | Exit 0; no reported errors; 8.11 s |
| Placement/support/paid clearing | 34/34; 51.96 s |
| Fresh-process Continue | 16/16; 63.47 s |
| Forward+ ordinary fen/home/bank route | 12/12; 95.65 s; 103.63 m, 734 swim and 52 wade frames, dry exit |

Placement exercised footprints over 1.5 m, excavation under their outer native
cell, exact retirement/rebuild, a paid nine-piece octagonal floor and usable
paid workbench, finite-source work and unchanged heights/water. Continue matched
native possessions/progression, blocks, stations, resources and cosmetic
placement exactly and resaved successfully. The inexpensive seed-78 spot check
verifies reproducible changed cosmetic noise at three locations; it is not a
second generated-world route. One non-lake V6 context retained no lakes.
Unchanged RF-06 profile/water evidence is reused. An initial harness type-inference
parse error was fixed before the passing placement run; assertions were retained.

The early Forward+ art look passed its three capture/load assertions in 74.28 s;
it is superseded by the final revised art captures. Both render runs verified
visible/free mouse and no-focus flags. All owned processes ended and the temporary
override was removed. Logs/raws remain in `build/rf06b/`; selected receipts are
[retained here](rf06b-evidence-2026-09-16/placement-checks.json).
Native DLL is unchanged from SETUP's verified SHA256
`FBF7067477D63693E35B5D15CCFF0BBAD86BE7586D679E284A44C843B0404E2B`.
No performance benchmark, hardware clearance or campaign replay was run. These
functional results do not establish hitch-free play.

## Exact private playtest

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "D:/Wroughtwild/work/rf06-fen-lakeside/tools/wroughtwild-rf06b/play.ps1" -Fen
```

Choose **Continue saved world**. This starts the checked seed-77 fen near
`(336.5, 33.1, 680.5)`, facing west. Walk west among the broad leaves and rushes,
then around the open ground on your right. WASD/mouse move/look; H shows controls;
F5 saves. Normal enemies remain active. Close the game when finished.

Run the same command without `-Fen` for the checked dry lake home. Walk toward
the water, around the boulders, wade/swim and return to the planted shore. Add
`-Fresh` instead to create a separate new seed-77 world. Fen/lake/new slots live
under `build/rf06b/playtest-{fen,lake,new}`. The launcher seeds a slot only if
neither its save nor previous checkpoint exists; later launches preserve progress.
The owner's normal saves and all earlier RF-06 slots are untouched. The launcher
was syntax-checked; automated ordinary Continue/movement used its source fixture.

## Handoff and deferred additions

Checked local implementation/evidence commit: `f6131e46c599a4abea1e95e754257ddc3038f44c`.
Coordinator adoption and main push remain separate; this worker did not push.
Generated unrelated import metadata is excluded from the commits and remains
locally modified/untracked. Automatic approval review rejected the proposed
broad tracked-sidecar reset because it would discard unrelated changes; no
reset was performed. Existing local imports remain available for play. No runtime package or native build was copied.

The visual weaknesses above join end-of-wave cleanup for owner prioritisation;
addressing tree-scale composition or lighting now would displace highland
recovery. Prior loading/group-frame, underground-correlation and swim-animation
notes remain open. No new performance or all-biome production wave is started.
RF-06B stops here. Next original outcomes are highland recovery, then remaining
impact/living-scar composition, then bounded cleanup.
