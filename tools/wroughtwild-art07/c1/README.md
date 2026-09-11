# ART-07C1 — Lantern Fen / Rustwater resources

This isolated art handoff owns `bog_oak`, `clay_bank`, `reed_bed`, `fen_sedge` and `fungal_detritus` only. It does not install art into the normal game. Owner visual acceptance is pending.

## Selected source and scope

The authoritative source is `source/c1-master.blend`, with SOURCE, FINISHED, RUNTIME and REVIEW collections and eleven packed images. `source/models/` has 51 separately audited GLBs, including finite work quantities and three explicit detail levels. Blender `(x,y,z)` exports as Godot `(x,z,-y)`. The origin is the ground/work pivot; generated geometry below grade is intentionally buried. The stump has a closed, independently UV-mapped top cut. Original bark and buried undersides are not claimed watertight.

Selected lineage: clay input v01 → immutable TRELLIS source → kit-v04 → reed clearance finish kit-v05 → closed stump face kit-v06. Review-v05 adds constrained bank seating. Rejected intermediate candidates remain outside the handoff: kit-v02 pinched the trunk; kit-v05's stump looked open. The scripts reconstruct the selected sequence, without claiming bit-identical Blender exports across versions.

B1 supplies broadleaf wood, attached foliage/twigs and end grain. B2 supplies the explicit tube/leaf modelling recipe. B3's bank was inspected and rejected for clay because it read as jagged stone. One new isolated clay input was generated. B4 ground/water geometry, terrain equation, water material and the ART-02 floor image remain unchanged. `provenance.json` records verified package, input, model, executable and raw-source hashes.

The frozen native game/data commit is `f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9`. Its game/sim/data tree matches the B3 DLL's recorded source revision; `native/provenance.json` records the source comparison and DLL hash. Native-v06 was made from a fresh Git archive, excluding earlier test-generated checkpoints. Normal saves, DLLs, geography, generation guarantees, material gates and resource definitions are untouched.

## Native contracts

| Resource | Unchanged Godot body, metres | Stock / release | Presses per release | Art states |
| --- | --- | --- | --- | --- |
| Bog oak | 0.7 × 3 × 0.7; centre Y 1.5 | 14 / 14 | 6 | Intact, physical chopping wound, native lean/fall, inert stump |
| Clay bank | 1.8 × 0.38 × 1.25; centre Y 0.19 | 24 / 4 | 3 | 24/20/16/12/8/4 units, progressively excavated bank, inert aftermath |
| Reed bed | 1 × 1.3 × 1; centre Y 0.65 | 24 / 6 | 3 | 24/18/12/6 units, cut groups, inert stubble |

Sedge is short splayed dressing. Fungi attach to a small fallen wood fragment. Neither has a harvest identity, renewable timer, inventory item or collision body. Ordinary materials emit zero light. The adapter preserves native highlight/heat authority; it adds no autonomous success pulse.

The copied-game adapter inherits ResourceNode work, payout, pickup ownership, body, work punch, lean/fall and SaveManager. It selects art from actual remaining stock/progress. Depleted identities stay absent after reload; session-only aftermath does not persist, matching current semantics. The fixture uses the actual player work dispatcher and pickups, but its three sites and inactive player are posed setup, not paid first-hour or generated-world traversal.

## Review and tuning

`review/` is a 60-anchor wet margin with unchanged B4 surface/water, native-sized resource bodies and a 0.32 m radius / 1.8 m tall walking capsule. Low plant vertices follow the bank; mature seed heads keep the existing picking height. Clay follows downhill ground, capped at its existing body top, with the uphill portion buried. This measured presentation adaptation is not a new slope-placement rule. Native copied-game art uses a flat fixture without B4 seating.

Escape toggles mouse capture; WASD/QE flies the camera; R restores overview; L cycles day/shade/dusk; Space pauses the art clock; 0 selects automatic detail; 1/2/3 force near/middle/far. The native fixture completes automatically. `recipes/kit.json` documents every exposed dimension, seed, wind and detail-distance control with its purpose. Recipe constants additionally define the smooth lower-trunk fit, leaf construction and posed review locations; they are art construction parameters, not gameplay tuning.

| Candidate | Near / middle / far actual triangles | Exported surfaces |
| --- | --- | --- |
| Full or worked oak | 219738 / 98188 / 13355 | 4 |
| Stump | 10074 / 3588 / 1677 | 3 |
| Clay stock stages | 15999 / 5999 / 1799 | 1 |
| Full reed bed | 5120 / 3008 / 1984 | 1 |
| Quarter reed bed | 1664 / 1136 / 880 | 1 |
| Sedge | 1456 / 360 / 128 | 1 |
| Fungal wood | 5159 / 2200 / 1050 | 3 |

Tree detail distances are 7/22 m; small assets use 4/12 m. Cooking preserves every geometry-buffer byte and shares six content-addressed images, limited to 1024 pixels with mipmaps (29,360,126 estimated RGBA8 mip bytes), plus the unchanged ART-02 floor. Albedo uses colour sampling; ORM is linear. No generated normal-map claim is made. Leaves are actual opaque, two-sided geometry. Small sedge shadows are disabled. See the receipt/evidence for measured costs, not a promised world density budget.

## Launch and verification

Never import into the canonical handoff. On this verified machine:

```powershell
& '<absolute handoff>/launch.ps1' -CopyTo '<fresh absolute copy outside the handoff>' -Renderer forward_plus -Stage capture
```

Use `gl_compatibility`, or stage `motion`, `review`, `benchmark`, `native`. The launcher verifies every manifest hash before copying, imports the copy, isolates APPDATA/LOCALAPPDATA below it, and holds `Local\Wroughtwild-Art07-GPU` for its own process. It launches hidden by default and never stops another process. For a visible interactive view, open the copied project in Godot. Benchmark only in a coordinated quiet window. Large sources/models and the frozen DLL are local artifacts; a Git clone alone is not the runnable package.

Repository reproduction uses fresh outputs under this worktree's `build/art07/c1/`:

1. Run `prerequisites.py <fresh-report.json>` to verify all 4,150 prerequisite files. `provenance.py <v01-root> <fresh-provenance.json>` verifies ten pinned weights and records actual runtime metadata.
2. Exact prompt/input and retained cutout are included. `generate-clay.ps1` records the local CLI route: v0.6.0, GPU 0 required, 1024, seed 42, BiRefNet, PNG, eight threads. Reuse `raw/source.glb` to avoid needless generation.
3. Use depot Blender 4.5.9 with `--background --threads 8 --python-exit-code 1 --python build.py -- <raw/source.glb> <fresh-kit>`, then `finish.py -- <fresh-kit> <fresh-reed-finish>`, then `cap_finish.py -- <fresh-reed-finish> <fresh-closed-kit>` (each as Blender's `--python` script). The packed master preserves all stages.
4. In another Blender process run `audit.py -- <selected-kit> <fresh-audit.json>`: packed images, all actual GLB triangles, finite vertices, body bounds, non-emission, work depth, and leaf roots against stalk faces only. `render.py` creates 60 actual multi-angle material/clay/hidden-side views.
5. `prepare.py <selected-kit> <fresh-review>` cooks shared textures. `freeze_native.py <fresh-frozen-source>` and `prepare_native.py <fresh-frozen-source> <fresh-review> <fresh-native>` create an explicit Git-archive source and adapter. `run-current-checks.ps1` runs 14 unchanged native suites. `run-native.ps1` runs work and separate partial/final restart processes sharing only their own isolated checkpoint directory.
6. `run-stage.ps1` runs capture, a full wind period, checks or separate fixed-view benchmarks. Logs retain actual arguments, PID, exit and duration. Original PNG frames remain; `media.py` encodes evidence and checks paused frames are identical and resume changes pixels.
7. `package.py <v01-root> <fresh-handoff>` hashes every delivered file. `copy_verify.py <handoff> <fresh-copy>` verifies both before import. Fresh-copy validation evidence is kept outside the immutable package.

## Limits

The oak retains a heavy inherited near mesh and visibly faceted upper branches. Lower wood is compressed to fit the native body; the broad leaning canopy remains overhead. This is an art candidate, not final forest optimization. Stump end-grain UVs are coherent; original bark has generated chart/underside weaknesses. Clay retains coarse generated cavities and the generator's three point-collapsed UV faces, and is not a seamless terrain material. Wind is restrained. Bank seating is demonstrated only on this retained review terrain. RTX 5090 measurements do not approve lower devices, large forests, controller UI, navigation or actual world integration. No new gameplay tuning or third-party dependency is introduced.

The native adapter verifies near art only; automatic LOD selection is demonstrated in the standalone review. Future G1 integration must connect these detail levels to the real world presentation. Source `models.json` counts Blender material slots (including unused slots); the table reports actual exported glTF primitive surfaces. Compatibility renders have darker foliage/backlighting than Forward+ in the same posed lighting.
