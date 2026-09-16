# RF-08 recovery composition and art

This is presentation derived from existing map records. Native terrain, collision,
impact and trace IDs/topology/exposure, stock, source work and saves remain owners.

One original Blender creeping mat (540 triangles, 0.315 m radius, 0.142 m height)
adds broad low woodland leaves. The original B2 leaf/tube helpers build five
connected runners and thirty folded leaves, with matte vertex colours. No external
asset, reference-image pixels, model download or new dependency was used.

- Editable master: `D:/Wroughtwild/source-art/rf08-impact-scars/rf08-creeping-mat.blend`.
- Repeatable recipe: `tools/wroughtwild-rf08/build_mat.py`, also retained beside the master.
- Runtime: `assets/creeping-mat.glb`; dimensions/source receipt: `source.json`.
- Metres, Blender Z up, ordinary glTF Y up. No asset collision or yields.
- Reused RF02 turf/litter maps and grass, RF01 ferns, RF07 settled shingle.
  Their original masters remain in `D:/Wroughtwild/source-art/rf02-ground-grass/`,
  `rf06b-fen-art/` and `rf07-highland-recovery/`. No parent package was copied.

`context.gd` builds a small map mask around existing impact records once at entry.
Nine-metre seeded pockets are stretched irregularly along the native impact
bearing, with an outer blend into the existing biome. It feeds both soil/moss
colour and the existing RF01 cover compositor, not a second scatter layer.
The ground mask preserves native biome/original surface height; plants retain
full sampled support, per-chunk lifetime and paid footprint suppression.
Fen/highland low cover retains its existing kit; Ember Wastes and old V1-V5 cover
are not re-skinned. The small smithy strike keeps its prior reservation.

`settings.json` explains distribution, footprint and blend controls. The mat's
0.34 m support radius includes sway; fitted chips use 0.42 m. Only woodland
recovery replaces 74% of selected upright plants with the low mat. Ground shade
uses the same growth mask, blending existing forest litter with moss-coloured turf.
It adds no terrain displacement, physical shelf, regrowth or resource hint.

`fissure.tres` overrides the existing physical renderer only in eligible profiles:
20% of native width, clamped 0.16–0.32 m; chipped lips rise at most 4.2 cm;
16 cm meander; 38% interrupted light coverage. Pale mineral rims enclose dark
olive/charcoal mouths. The narrow core's albedo is reduced so emission supplies
its living light. A 7.5-second sine varies emission by 62% around strength 1.12;
no local light or particles are added. UV phases stagger nearby sections.
The per-world clock pauses with the scene tree. Existing camera dip/hand-sway
preferences keep their meanings; there is no global environmental-motion toggle.
V4/V5 retain their original shared resource, shader branch and 47-second variation.

Only native exposure 2 contributes geometry. The scoped renderer now also rejects
removed original top cells even if a neighbouring smoothed triangle overhangs the
hole. Those extra native lookups cache per cell within each existing tile refresh.
Deferred per-tile rebuilding and sampled chunk-identity reuse remain in place.
Shared mat/chip resources prepare during real entry before player control.
