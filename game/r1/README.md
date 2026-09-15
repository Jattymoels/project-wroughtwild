# R1 active tree presentation — PLAY-02

Common `wood` and `pine` resource records use the delivered R1 **a-LOD1**
assemblies. `settings.json: runtime_lod = 1` now drives the adapter instead of
an unconditional a-LOD2 path. This retains fuller folded leaf surfaces in the
active trees; it does not add leaves, trees, resource identities or growth.
Packed scenes and settings are retained once for reuse. Meshes and imported
textures remain shared; per-instance material ownership is unchanged.

## Provenance

Selected source directory:
`D:/project-wroughtwild-art07-r1/build/art07-repairs/r1/v03/handoff/models/`.

| Family | Selected source | Source SHA-256 |
| --- | --- | --- |
| Broadleaf | `broadleaf/broadleaf-a-lod1.glb` | `ab6973fa4b8401b4c0be438f0ae5a2b6d3a0803c24a921b55507df0f1c270d1d` |
| Pine | `pine/pine-a-lod1.glb` | `d659f656904a9e63aef4f2891db4cb7e25706f2db30ad34776ef0e6f0d81768b` |

Only the image bindings differ from those selected source exports. Embedded PNG
bytes were checked against the existing tracked texture files before reusing
the same URI aliases as the previous a-LOD2 assets. The entire glTF binary
chunk, mesh hierarchy, accessors and materials are retained. No source master
was edited or copied. Editable `broadleaf/broadleaf-master.blend` and
`pine/pine-master.blend` remain in that source directory on D:.

LOD1 has 98,032 broadleaf / 130,597 pine triangles before Godot's import LODs.
The previous explicit LOD2 assemblies had 65,232 / 69,637. Leaf counts are
unchanged: the source recipe makes 8,120 broadleaf blades and 12,240 pine
shoots at every LOD; LOD1 gives each blade eight triangles instead of four.
It is a surface/silhouette correction, not omitted whole branch objects or
alpha transparency. Natural branch gaps and source broken limb ends remain.

Lower radius (0.343 m), clear height (2.6 m), crown recovery height (4.2 m),
root burial (broadleaf 0.65 m / pine 0.55 m), native bodies, transforms, work,
stock, fall/stump logic and distant-canopy eligibility are unchanged. There
is no new per-tree distance loop or per-frame work, and PLAY-01's shared
resource-work budget is unchanged. No performance-clearance claim is made.

[Checked slice and normal-game instructions](../../docs/prototype/play02-canopy-result-2026-09-15.md).
