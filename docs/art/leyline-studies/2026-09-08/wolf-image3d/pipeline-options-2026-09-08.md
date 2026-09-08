# Lower-cost image-to-3D options — 8 September 2026

Owner request: compare the supplied Meshy 7 screenshot and suggest alternatives
without expensive premium subscriptions. This is research and a proposed next
experiment, not approval of a new dependency, service upload or purchase.
[Actual wolf experiment and visual assessment](README.md).

## Shortlist

Prices below are advertised USD generation charges checked on this date, before
tax/currency conversion. They are per attempt, not per accepted game asset.
Quality on our wolf has not been tested for any of these alternatives.

| Option | Advertised cost | Practical fit and limitations |
| --- | --- | --- |
| [TRELLIS.2 on fal](https://fal.ai/models/fal-ai/trellis-2) | $0.25 at 512; $0.30 at 1024; $0.35 at 1536 | Low-cost comparison using the existing single image. The endpoint returns a GLB and is marked for commercial use. The resolution tiers describe generation settings, not a guaranteed final triangle budget. |
| [Rodin 2.5 on fal](https://fal.ai/models/fal-ai/hyper3d/rodin/v2.5) | Listed default: $0.40; HighPack adds $0.80 | Another candidate for the detailed wolf; the endpoint exposes downloadable model files and is marked for commercial use. This is the 2.5 endpoint, not a price copied from an older Rodin model. Verify the live quote when changing settings. |
| [Hunyuan3D 2.1 on fal](https://fal.ai/models/fal-ai/hunyuan3d-v21) | Listed default: $0.30 | A third comparison if the first two miss important forms. Cheap generation alone does not establish better fur, hidden geometry or animation readiness. |
| [TRELLIS.2 locally](https://github.com/microsoft/TRELLIS.2) | No hosted generation fee; electricity and setup time | Microsoft releases model/code under MIT; dependencies have separate terms. Official instructions require NVIDIA with at least 24 GB and are tested on Linux. Local `nvidia-smi` reports RTX 5090, 32607 MiB: sufficient advertised VRAM, but actual CUDA/extension compatibility and performance remain untested. |

fal uses prepaid credits, deducting each UI/API request's cost from the balance;
generation estimates are not a promise that an account can be funded with
exactly that amount. See its [billing terms](https://fal.ai/legal/terms-of-service).
No account, checkout, trial, upload or paid request was made for these options.

[Tripo's current free plan](https://www.tripo3d.ai/pricing) allows limited exports
but labels its models non-commercial, so it is not the preferred free route for
assets intended for Wroughtwild. Its paid plan is still a subscription. Model
and export restrictions matter more here than an attractive free credit count.

## Recommendation for this machine

Local TRELLIS.2 is worth a bounded feasibility trial because the owner already
has substantial GPU memory. Its official Linux setup means a Linux/WSL route
and compatible CUDA packages must be checked before calling it usable here.
Do not equate meeting the memory requirement with a successful installation.
Avoid introducing it into the game's runtime or normal development environment.

For the quickest cloud comparison, try one TRELLIS.2 1024 attempt and one Rodin
2.5 default attempt on the exact existing input: $0.70 in advertised generation
charges. Three of each would total $2.10, before taxes, changed settings or other
operations. A separately agreed small spending cap should precede paid work.
Keep input, settings, seeds when exposed, source files and actual costs with the
results. Do not repeatedly generate attractive previews without exporting and
inspecting the geometry.

## What makes the eventual asset better

Choose the source that preserves canine anatomy and useful large forms with the
least repair, not the largest polygon count. Use the same neutral Blender views
as this experiment, adding explicitly labelled views where the pose requires it.
Inspect face, underside, feet, tail and plate roots. Then:

1. Resolve the lean wolf proportions, eyes, opening mouth and distinct plate
   attachments. The animal must read without texture or glow.
2. Build deformation topology and test a head turn, opening jaw and bite. Plate
   roots must remain credible and tips must clear the neck and shoulders.
3. Keep silhouette-defining fur masses and plate edges in geometry; transfer fine
   fur/vein relief into maps. Build recessed scar materials with worn edges and
   restrained emission after the forms work.
4. Measure the resulting animated asset in an isolated Godot scene before
   proposing runtime adoption or extending the approach to other creatures.

This is an art workflow proposal. The moth, existing mob assets, gameplay,
normal saves, running playtest and broader woodland work are unchanged by this
comparison. A generation service can provide a starting surface; none of the
researched prices proves that it supplies the complete rigged character brief.
