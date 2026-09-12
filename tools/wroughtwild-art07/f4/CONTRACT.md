# ART-07F4 pressure pocket and feeder contract

Frozen game, native and tuning revision: `bbcb3a7dfd235e8f803141ccb57c38e03d6c1708`.
Presentation changes exist only in a copied review project. No ordinary-world
adoption, save migration, rule change or extra resource is included.

## Identity and ownership

`assemble_pressure_feeder` consumes 1 Ventlung, 1 Thrumroot, 8 wood,
2 iron ingots and 2 raw reed at the existing workbench. One paid placement
creates one `pressure_feeder`. A refused occupied placement retains its kit.
The two organic meshes represent those existing components; they are not
additional harvestable cores or separate stores.

The generated `pressure_pocket` retains its native ID, support test, position,
finite capacity of 24 strokes, inspection and exhaustion. The old hearth shell
is presentation, not an operational or free forge. Its membrane compresses with
remaining/capacity, disappears at zero and never refills. Hand winding remains
available after exhaustion. Hover and refresh cannot change stock. A small
read-only observer refreshes the pocket pose when the native ledger changes,
including after SaveManager restores depletion following generated-scene setup.

The feeder's existing ledger owns clay/fuel/output, energy, reserved inputs,
reserved drive, fractional work, pause, attachment IDs and completed cycles.
Capacity is 4 drive, 64 hopper units, 32 output units; a normal 8-second cycle
reserves 8 raw clay, 1 wood and 1 drive to produce 4 bricks. This is unchanged
native behaviour, not new F4 tuning. Pressure is motion; paid fuel supplies heat.
Cancellation and dismantling use existing atomic recovery/overflow operations.
The original checks cover trial restrictions, cancellation, contents and recovery.

## Metric geometry and motion

All positions are Godot XYZ metres; recipes convert once to Blender X,-Z,Y.

| Contract | Value |
| --- | --- |
| Feeder native body | 1.5 × 1.45 × 1.45; centre `(0,.725,0)` |
| Feeder selected visual | 1.390 × 1.365 × 1.210; minimum Y 0 |
| Pocket native body | 1.05 × 1.25 × 1.05; centre `(0,.625,0)` |
| Pocket selected visual | .910 × 1.0055 × .890; minimum Y .0095 |
| Ground origins | `(0,0,0)`; native quarter-turn yaw retained |
| Both real attachment origins | global centre + `(0,.85,0)`; no offset or directional gate |
| Attachment range / line radius | native 8 m / .045 m |
| Drum | immediate child `Drum`, pivot `(.33,.66,.02)`, local X |
| Native drum rotation | `(energy*.25 + cycle_seconds/8)*TAU`; explicitly not F2's winch formula |
| Bellows | immediate child `Bellows`, origin `(-.31,.32,.1)` |
| Native bellows Y scale | `.72 + .28*(.5+.5*sin(progress*TAU))` during reserved drive, otherwise `.72+.28*energy/4` |
| Clay load | `(-.14,1.24,-.26)`, native .23 × .12 × .40 envelope |
| Fuel load | `(.14,1.24,-.26)`, same native envelope |
| Output load | `(.12,.33,.30)`, native .56 × .12 × .43 envelope |

The preserved F2 `MovingAssembly` (root winding, shaft and crank together) is
scaled .49 about its old `(0,1.05,0)` pivot into the feeder pivot. No second drum
or reconstructed organic mechanism is used. Native full-body and support probes
remain unchanged. Five complete rotation samples and all detail envelopes are
checked on imported geometry; existing placement checks exercise all four yaws.

F3 membranes are fitted to .42 × .50 × .46 in the feeder and .58 × .52 × .62
in the pocket. The feeder's bearing, platen and guides support its native squash;
the pocket rests on the retained E2 hearth floor. Pocket lower masonry uses E2's
actual lower two courses, hearth floor/rims, scarred jamb and fireback with upper
hearth pieces shifted down .40 m. The functional E2 forge is a separate unchanged
published neighbour in the review and is required for the real attachment tests.

## Surface, incision and detail contract

F2/D4 timber face/end and bog-oak maps, D6 iron, E2/D5 stone/soot and F3 original
Ventlung albedo/ORM are reused by exact source hash. Albedo is sRGB; normal/ORM
and F3 scar vertex data are linear. ORM G drives roughness, B drives metalness.
External textures share content-hash paths across instances and detail levels.
GLBs also contain embedded maps: count that packaging and import duplication,
not just the external directory. The asset-cost JSON and renderer counters do so.

Finished meshes normalize donor UV layer names before joining. Mapped root
travel coordinates are preserved; collapsed inherited metal charts receive
metric planar UVs. `source/uv-repairs.json` records these presentation repairs.
The packed master retains separate finished pieces and immutable donor copies.

The inherited E2 jamb cut is .038 m deep. F2 winding cross-sections retain their
real .012 m recess at .49 scale: .00588 m, with .00147 m small-spur recesses.
F3's published .026 m nominal incision and R damaged margin / G deep route /
B travel vertex attributes survive the mount. The packed reopen records actual
axis scales: the nominal near incision maps to .01224–.01540 m in the feeder
and .01413–.02076 m in the pocket before native compression. These transform
bounds are not a new BVH depth measurement. Emission-off clay and engine views
demonstrate the form.

The shader has no `TIME`. Static stored glow reads native energy/4 or finite
remaining/capacity. Moving light reads paid cycle progress only while the native
fixture is active, unpaused, unblocked and the tree is unpaused. Paused/blocked
poses retain exact progress. Red forge heat and feeder drive remain separate.
`appearance.json` documents the timber tint, normal strength, stored/work glow
and wave spacing; these are art controls and add no gameplay tuning.

Near feeder is 47,488 triangles, middle/far 33,988. Near pocket is 23,980,
middle/far 10,480. The conservative F3 middle/far membrane is 8,500 triangles
versus 22,000 near. Three native visible load meshes add 1,728 triangles and
3 surfaces when all are shown. Actual imported counts and texture totals are
recorded independently in the final cost and packed-reopen JSONs.
Detail selection is explicit inspection (`F4Art.detail`), not an invented
automatic distance or streaming policy. No arbitrary performance budget is claimed.

## Review and limits

The native generated workshop scenario supplies labelled inspection stock and
uses ordinary transactions. It is not a measured first-hour gathering playthrough.
`E` opens native controls; `W` winds, `F` starts, `P` pauses/resumes, `X` cancels,
`K` collects real output, `G` disables/enables emission, `Esc` exits. This is a
fixed inspection camera; use the panel's existing mouse controls for deposits.
The standalone launcher opens only a verified fresh copy and isolates APPDATA.

The fresh importer found no nonfinite vertices, degenerate triangles or mesh
repairs. The three joined clay panel assemblies each have 20 nonmanifold edges
after a 1 µm weld at panel contacts; other imported assemblies have zero. These
are joined panel containers, not watertight boolean ceramic solids. Native
collision and contents ownership do not use those render-mesh seams.

The construction is still visually regular: the clay containers are plain and
the timber arrangement is rectilinear. Native connection lines and status sphere
remain visible. The pocket's borrowed masonry is clearly a cut-down hearth.
Near/middle/far do not reduce the reused drum or frame. Texture and shadow costs
need assessment on target hardware; an RTX 5090 does not establish lower-spec
acceptance. Technical delivery does not imply owner visual acceptance.
