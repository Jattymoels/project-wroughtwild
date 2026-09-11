# F2 integration contracts

Only presentation in a frozen review copy changes. Native code, tuning, save
schema, collision shapes, work ownership and normal-world generation are the
unchanged base `4b5d89b376765fbf4d46049aa099e0bb154a82da`.

| Identity | Exact cost / ownership |
| --- | --- |
| `thrumroot` finite source | 3 units; four ordinary work presses release three pickups; collection transfers them into the native pack. Partial `drive_progress` and depletion persist. |
| `assemble_cargo_winch` | 8 wood + 2 iron_ingot + 1 thrumroot creates one `cargo_winch_kit`. Native paid placement consumes it once. |
| `assemble_winch_landing` | 6 wood + 1 iron_ingot creates one `winch_landing_kit`. No rare core. |
| Complete pair | 14 wood + 3 iron_ingot + 1 thrumroot. Study supplies are explicitly granted to isolate paid transactions, not first-hour pacing. |
| Cargo ownership | Only the `cargo_winch` native record owns cargo. `winch_landing` forwards requests; it has no basket instance or copied cargo ledger. |
| Winding / trip | Hand `wind` stores one operation, capacity 4. Each `start` spends one at departure, including empty return; requests do not generate energy or queue unpaid work. |
| Collection | At landing, withdrawal forwards to the same drum cargo. Partial 7 of 20 leaves 13; repeated empty collection pays nothing. |
| Landing removal | Recalls the same basket to drum, clears link/moving/at_landing/progress; contents remain drum-owned. Refund is 3 wood, 0 iron, 0 roots. |
| Drum removal | Returns all cargo, 4 wood + 1 iron + the one intact Thrumroot; stored winding is vented. A repeated removal cannot pay again. |

Native serialized fields consumed by the visual are `kind`, `position`,
`quarter_turns`, `link`, `energy`, `cargo`, `moving`, `at_landing`, `progress`,
`completed_trips`. The native ledger is authoritative, not shader parameters or
scene names. Meaningful conditions are idle at drum, wound, travelling outbound,
physically blocked (same paid progress), arrived, partially collected, paid
return, recalled and removed. These descriptive conditions are not new save enums.
The source uses `remaining_units`, `drive_progress`, `drive_presses`,
`units_per_harvest`, `resource_id` and the ordinary depletion lifecycle.

## Metric geometry

All coordinates below are Godot XYZ metres. Blender recipes convert once to
X,-Z,Y. Mesh origins stay at ground centre. Do not change native geography to fit
the art. The import adapter strips only Godot's extra GLB wrapper, exposing the
authored `Drum` as the immediate child required by current `ContraptionSite`.

| Contract | Value |
| --- | --- |
| Drum / landing native solid body | 1.4 × 1.83 × 1.15; collider centre (0,.915,0) |
| Both native cable sockets | (0,1.7,0); authored `CableSocket` matches |
| Drum pivot / axis | (0,1.05,0), local X; entire winding, shaft and crank rotate together |
| Native rotation formula | `(energy * .45 + progress * 3.0) * TAU` around X |
| Native basket placement | Interpolated endpoint cable position plus (0,-.45,0) |
| Basket swept collision | Radius .3 centred cable plus (0,-.25,0); every exported vertex fits that sphere |
| Winch final visual envelope | Approximately 1.32 × 1.8175 × 1.02 |
| Landing final envelope | Approximately 1.26 × 1.8175 × 1.02 |
| Basket final envelope | .37728 × .42362 × .30528; origin relative lowest vertex .025 |
| Source native body | 2.2 × .9 × .75; selected visual approximately 2.14 × .792 × .71 |
| Recovered visual sample | Approximately .396 × .202 × .396; no collision or inventory authority |
| Native capacity / travel | 96 cargo units; 3 m/s; maximum span 32 m; minimum trip .5 s |
| Study span | 8 m, endpoints (.5,0,.5) and (8.5,0,.5); support is actual physics ground |

The old pivot export was rejected before delivery. Final reopen checks verify
the actual GLB transforms, body envelopes, finite vertices and basket sweep.
The original .15/.4 support probe and native sphere sweep stay unchanged.
Turning an endpoint does not invent an offset socket.

## Materials and visual controls

D4 supplies face/end timber and bog oak; D6 supplies iron. Albedo is sRGB,
normal and ORM are linear. D4 face repeats .5 m across and 2 m along each member;
end faces use the separate .5 m end-grain map. Meshes share materials and maps.
ORM uses G roughness, B metalness; imported glTF embeds the source textures.

TRELLIS source keeps its original UV/albedo and receives real surface-following
cuts before reduction. The +90° Blender Z turn corrects the generated long axis;
uniform scale 2.1364885987864177 establishes a 2.14 m width. A separate documented
depth-only finishing factor .5364793037157609 reduces 1.323 m depth to .71 m.
This is a deliberate native-body fit, not an assertion of uniform raw scaling.
Scars: .046 m influence radius, .026 m requested recession; same-ray measured
median .0224118 m, maximum .0257534 m. Winding/recovered cross-sections recess
.012/.014 m. Their small attached spurs are .003 m deep.

The source shader uses vertex R for the dark scar margin and G for its subdued
inner tissue. `work_level` follows accepted work only. Device scar shader
`winding` is energy/4; `paid_phase` is native progress; `travelling` gates moving
light. Neither shader reads `TIME`. Pausing or blocking freezes the moving
light and drum; unpaid idle has only a faint static material response. `G`
sets `emission_off` for source and drum. Geometry remains readable with it off.
Glow strengths (.04 idle, .25 stored winding, .3 narrow moving pulse; source
.08 idle + .4 accepted-work level) control subtle tissue light, never actions.
UI reset restores a captured paid inspection state. It is a review tool, not
a new gameplay reset or save mechanic.

Source LOD exports are 64,000 / 26,000 / 9,000 triangles with one surface each.
The isolated native scene uses near; middle/far are supplied for F4 selection
and independently imported/rendered. Devices keep bounded geometry at all study
distances: about 22,360 / 3,716 / 3,848 / 7,708 triangles for drum, landing,
basket, recovered sample. Exact final counts and surface totals are recorded
by fresh imports, not estimated from screenshots.

## Limits

This is an isolated art/native study. No shared game adoption, new rules,
resource renewal, save migration or generated-world economy test is included.
The original native work depletion removes the source; no new persistent stump
or harvest owner is invented. The recovered sample is explicitly a static
inspection view shown when the native pack owns roots, not a second pickup.
Its wound silhouette is intentionally controlled and regular, with woody grain
and cut tissue distinguishing it from rope; owner assessment remains pending.
TRELLIS bark is softer at extreme close range than a hand-sculpted surface.
Source depth compression and far-LOD loss of small roots remain visible tradeoffs.
Manual wind snaps to the native stored-energy angle; this slice does not invent
an interpolated hand animation or change the authoritative rotation formula.
Benchmarks cover this two-endpoint scene on the recorded local GPU only.
Cargo contents use the native aggregate count in the study UI; this slice does
not add a separate mesh for every carried item inside the basket.
