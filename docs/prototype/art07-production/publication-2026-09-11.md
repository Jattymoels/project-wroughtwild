# ART-07 second batch — 11 September 2026

The owner reported B2, B3, D5 and D6 complete. All four have checked source
handoffs and are integrated into main. Together with B1/D1/D4/F5, this is
**eight of 26 slices**. Owner visual acceptance and ordinary-world adoption
remain separate. No new implementation sessions were launched.

## Integrated commits and scope

Local main and the independently read remote both started at
`f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d`. Every clean worker branch used that
same published baseline. Each diff is confined to its own tools, curated art
and receipt. Exact worker commits were cherry-picked serially without conflicts
or source edits; the resulting tool/art Git blobs match the worker tips.

| Slice | Worker commits in order | Main commits in order | Handoff |
| --- | --- | --- | --- |
| B2 | `2f3cb09`, `8a64a9f` | `f51e824`, `8496673` | [Ground cover receipt](receipts/b2.md) |
| B3 | `a01c6ce`, `c37be9a` | `2ca4f4e`, `9f0ae11` | [Rock/contact receipt](receipts/b3.md) |
| D5 | `4aff2b6`, `a2ec335` | `a62c003`, `68b7ca1` | [Mineral/glass/fuel receipt](receipts/d5.md) |
| D6 | `20c5e0b`, `6925449` | `b7116c7`, `3bc4f68` | [Worked metal receipt](receipts/d6.md) |

No committed changes to `game/`, `sim/` or `data/` occur in this integration
range. The owner's five modified LF6 captures, untracked saves/imports and
other local work remain intact. Source packages and worker checkouts were read
only; all fresh imports and test saves use the publisher's ignored directory.
No new game tuning, package, generator profile or gameplay rule was introduced.

## Fresh verification

The [machine-readable record](publication-2026-09-11.json) records full SHAs,
canonical package paths and manifest hashes, scoped files, exact commands,
process IDs, isolated APPDATA, durations, exits and verification summaries.

| Slice | Package files verified | Independently repeated checks |
| --- | ---: | --- |
| B2 | 274 | Packed ground/source masters and all 34 GLBs; attachment/topology audit; fresh import and both-renderer bounds, exclusive LOD, pause and supported physical walk checks; original numerical/image/source verifier |
| B3 | 1,541 | Packed master and 30 GLBs; incision depth, body bounds and cave opening; fresh review/native imports; interactive pause; 16,621 native flow, 10 partial-restart and 8 final-restart checks; both-renderer actual captures |
| D5 | 290 | Packed master with 48 images, fresh 40-mesh/1,760-triangle GLB import; all 48 map hash/channel/seam/trait checks; fresh import configuration and both-renderer captures with fixed-window blocking |
| D6 | 78 | Packed master with 12 images, fresh 10-mesh/13,608-triangle GLB import; 12 map and material-gate checks; fresh import and both-renderer captures; original source/evidence/package verifier |

All **2,183 package files** matched before copying, after copying and again in
the canonical packages after checks. **All 25 fresh subprocesses exited zero.**
Python syntax checks and all 21 worker PowerShell script parses pass. The
previous B1 and D1 dependencies were also rehashed: 1,533 and 1,597 files match
their published manifests. They remain available at the receipts' local paths.

The updated `session_plan.py`, `catalogue.py` and `verify_art.py` checks pass:
26 unchanged worker prompts, 131 exclusively owned catalogue entries, 60
dependency edges, 81 dispatch links, 273 legal material/shape pairs and all six
original concept image/prompt records. The index matches its generator.

The first publisher wrapper treated Godot's known sandbox root-certificate-store
diagnostic as a failure after an otherwise successful offline import. It now
retains that exact diagnostic while still failing all script/shader/other engine
errors. No asset or test assertion was changed. Generation, benchmarking and
the workers' full simulation regression suites were not repeated for publication;
their original evidence remains in the receipts. GPU work was serial under the
existing cooperative mutex. No unrelated process was stopped.

Fresh copies, runner scripts, complete logs and audit JSON are under
`C:/Users/Matty/Dev/project-wroughtwild/build/art07-publication-2026-09-11`.
The tracked record retains their identities and exact worker-script invocations.
No normal world save was opened. A clean Git clone still needs the local handoff
packages or their documented reconstruction; generated binaries are not in Git.

## Visual and performance limits carried forward

Actual Blender and Godot evidence was inspected. These are source libraries and
small review scenes, not a completed forest or house.

- B2's shrub tips and repeated fern/lichen forms remain visible compromises.
  A lush near fern is about 90k triangles; the review submits 687 draws. Opaque
  foliage avoids alpha-card overdraw but retains geometry/shadow costs and
  duplicate embedded textures. Discrete LODs and arbitrary slopes need context.
- B3's cave modules repeat and need site fitting. Near source topology retains
  small open edges; the native seam work ribbon remains conspicuous. Embedded
  textures duplicate residency. Cave passage is a retained-wall/floor fixture,
  not proof for every generated cave. The new shelf incision measures 0.064496 m.
- D5's materials are distinct but visibly regular on long walls. Fieldstone and
  fossils are surface treatments; owning modules must supply physical contacts.
  The conservative RGBA8 mip estimate is 160 MiB for the complete source maps.
- D6's broad finishes and joints differ, but their motifs repeat. Its smooth
  arches and I-shaped girders are material proxies, not replacements for native
  stepped-arch/box bodies. Shared source texture estimate is 64 MiB with mips.
- Both-renderer brightness differences, B1's full-width tree/body fit, dense
  forest budgets, texture sharing and lower-spec performance remain open.
  Tiny RTX 5090 measurements do not establish whole-world readiness.

## Recommended next four

1. [B4 — first composed walk, light and distance](prompts/B4.md): combines B1–B3
   into the first composition and cost checkpoint before wider habitat reuse.
2. [D2 — roofs, door and metal spans](prompts/D2.md): completes seven existing
   forms around D1 joins and exact native movement/collision contracts.
3. [D3 — fine pieces and complete wall coverings](prompts/D3.md): completes
   fine-grid pieces and framed panels/glazing around the same D1 lattice.
4. [E2 — basic and improved forge](prompts/E2.md): uses D5/D6 materials for a
   compact working forge and its in-place upgrade, with real work/reload proof.

All four can author independently after inspecting published main and verifying
their own local prerequisites. B4 must address the recorded canopy fit/cost and
ground-contact questions rather than treating technical source delivery as final
visual acceptance. D2/D3 use native geometry rules rather than copying D5/D6
inspection proxies. Only one GPU job runs at a time. Regional kits, E1/E3 and
F1–F3 are also dependency-ready, but remain planned; no worker was started here.
G1/G2 and ordinary-world rollout remain later checkpoints.

## Publication

Local integration is complete through
`3bc4f6844fc0adf7b9cb00c93852b9dd81de4222`. An ordinary non-force push succeeded:
`origin/main` advanced from `f00d4b7` to `3bc4f68` at the owner-approved
`https://github.com/Jattymoels/project-wroughtwild.git`. The final queue/notes
commit and remote verification are reported separately by the coordinating
session; a notes commit cannot record its own SHA. Sandbox network access needed
the approved escalation. No automatic approval-review rejection occurred.
