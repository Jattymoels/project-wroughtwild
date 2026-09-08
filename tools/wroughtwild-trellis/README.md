# Local TRELLIS wolf experiment

Owner-approved local setup, 8 September 2026. This uses the **community Windows
port [trellis.cpp](https://github.com/pwilkin/trellis.cpp/tree/v0.6.0)** of
Microsoft TRELLIS.2, with its CUDA runtime and portable Trellis Studio interface.
It is not Microsoft's official Python/WSL installation. Output quality is judged
from our exported wolf, not the port's advertised parity claims.

All executables, libraries, models, download caches, local configuration and
generated GLBs live in ignored `build/trellis-local/`. The game has no dependency
on this tool. No WSL installation, driver change, global Python package, external
image upload or paid inference is required. The GUI binds to `127.0.0.1:8743`.

## Reproduce the installation

`install-manifest.json` pins release v0.6.0, release target commit, model revision,
archive/model sizes and upstream SHA-256 digests. The two Windows packages and
ten unquantized 16-bit GGUF model files total about 17.2 GB of downloads, with
additional disk space for the unpacked runtime and caches. Licenses are distinct:
the [runtime](https://github.com/pwilkin/trellis.cpp/blob/v0.6.0/LICENSE) and
[TRELLIS.2](https://github.com/microsoft/TRELLIS.2/blob/main/LICENSE) use MIT;
the DINOv3 conditioner retains its
[own model license](https://huggingface.co/timm/vit_large_patch16_dinov3.lvd1689m).
The background remover is [BiRefNet](https://github.com/ZhengPeng7/BiRefNet).
Do not redistribute the dependency bundle as if it shared the game's license.

From the repository root in PowerShell 7:

```powershell
./tools/wroughtwild-trellis/install.ps1 -SkipModels
python -m venv build/trellis-local/downloader
./build/trellis-local/downloader/Scripts/python.exe -m pip install huggingface_hub==1.30.0 hf_xet==1.6.0
./build/trellis-local/downloader/Scripts/python.exe tools/wroughtwild-trellis/download-models.py
```

The download client uses an isolated environment and project-local cache,
anonymous access and disabled telemetry. It verifies every model against the
manifest after transfer. Full-file curl and PowerShell transfers stalled in this
session; partial files were preserved when moving to the chunked client.
`install.ps1` without `-SkipModels` also supports resumable curl downloads, with
size/hash checks and bounded connection/stall timeouts.

## Use it

The installation and first textured wolf are complete on the owner's RTX 5090.
[Measured result, images and limitations](../../docs/art/leyline-studies/2026-09-08/wolf-image3d/trellis-local/README.md):
about 183 seconds at resolution 1024 / seed 42; 295,880 triangles and two 2048²
textures. This is a source candidate with no rig, not an adopted game asset.
The generated GLB reports a different binary build commit from the release
target; both are preserved in the result record.

Double-click **`open-studio.cmd`** from your normal desktop session. Choose the
input image, resolution and seed, generate, and inspect/save the GLB. Its local
output folder is `build/trellis-local/studio/data/output/`.
The launcher preserves WebView data under the same local tool folder. The native
app cannot initialize in the restricted agent sandbox; its desktop launch and
loopback health check succeeded outside that sandbox. No administrator install
is required. The recorded wolf was generated with the CLI below; GUI generation
controls have not been separately tested.

For the exact comparison input and a logged attempt:

```powershell
./tools/wroughtwild-trellis/run-wolf.ps1 -Resolution 1024 -Seed 42
```

Add `-GeometryOnly` for a clay comparison without the three texture-model files.
This deliberately produces a raw untextured asset. In the tested build, that
branch skips final remeshing/simplification and produced 8.49 million triangles;
it is useful for diagnosis but is not the final processed export.

Every call creates a fresh directory under `build/trellis-local/output/`.
The record contains input/source hashes, settings, duration and exit status.
`--require-gpu` refuses silent CPU fallback. The script does not contact a service.

## Inspect or reproduce the Blender handoff

Open `build/trellis-local/normalized-review/wolf-candidate.blend` for the current
editable wolf, or `build/trellis-local/matched-review/wolf-review.blend` for the
saved review scene. Original raw output:
`build/trellis-local/output/wolf-1024-seed42-20260908-221914-245/wolf.glb`.

The scripts below take fresh output directories and run in background Blender
with `--python-exit-code 1`. The paths after `--` are positional arguments:

```text
prepare-review.py -- RAW.glb wolf-review.json NEW_PREPARED
../wroughtwild-blender/scripts/review_wolf.py -- NEW_PREPARED/wolf-normalized.glb NEW_REVIEW BASELINE_REPORT.json
../wroughtwild-blender/scripts/extra_wolf_views.py -- NEW_REVIEW/wolf-review.blend wolf-review.json NEW_DETAILS
verify-review.py -- RAW.glb NEW_PREPARED NEW_REVIEW NEW_DETAILS NEW_VERIFICATION.json
```

Use `docs/art/leyline-studies/2026-09-08/wolf-baseline/report.json` as the baseline.
`wolf-review.json` pins the inspected raw GLB's hash and uniform review transform.
A different generated candidate must be inspected before choosing its transform
and pinning its hash. The audit counts actual imported geometry, including split
vertices at UV seams; successful verification does not establish clean anatomy
or animation topology. No generated working GLB or Blender file is committed.

## Run settings

| Setting | Purpose |
| --- | --- |
| Resolution 1024 | Use the coarse-to-fine geometry pass; 512 is the lighter smoke-test option. The 1536 option is exposed but has higher resource demands. |
| Seed 42 | Repeat the candidate's stochastic starting point; cross-runtime and cross-GPU bitwise equality is not promised. |
| BiRefNet + saved cutout | Separate the same wolf image from its background and make that conditioning step inspectable. |
| PNG textures (`--webp off`) | Keep exported textures directly compatible with the existing Blender inspection. |
| Eight CPU threads | Bound CPU-side work while other development may be running. GPU work is still substantial. |
| Default model/export settings | Retain the port's sampling and mesh processing for this first comparison; its face simplification is not an approved runtime asset budget. |

Mesh generation, Blender inspection, deformation quality and runtime adoption
are separate checkpoints. Original wolf/moth assets and normal saves are not
modified by these helpers. Never commit downloaded dependencies or caches.
