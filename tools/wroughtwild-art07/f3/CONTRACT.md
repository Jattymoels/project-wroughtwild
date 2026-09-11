# F3 source/device contract

All native references below are frozen at `4b5d89b376765fbf4d46049aa099e0bb154a82da`.
This is an isolated presentation package, with no normal-world adoption.

| Identity | Current native contract |
| --- | --- |
| `pullstone` | `magnetic` property; native body 2 × 1.2 × 1.1 m; one finite lot of 3, 3 per completed harvest, four ordinary presses. Brace clinging grit → separate nodule. No tool/heat/era gate. |
| `ventlung` | `pressure` property; native body 1.2³ m; one finite lot of 3, 3 per completed harvest, four ordinary presses. Open side seam → release stored pressure → lift membrane. No tool/heat/era gate. |
| `magnetic_sorter` | `assemble_magnetic_sorter` at workbench: 1 Pullstone + 4 wood + 1 iron ingot → 1 `magnetic_sorter_kit`. Full box body 1.3 × 1.3 × .85 m. |
| `ventlung_bellows` | `assemble_ventlung_bellows` at workbench: 1 Ventlung + 3 wood + 2 raw reed → 1 `ventlung_bellows_kit`. Full box body .92 × .97 × 1.15 m. The nozzle and bindings add no iron cost. |

All dimensions above are Godot XYZ metres. Each body has centre `(0,height/2,0)`
relative to its ground pivot. Quarter-turn yaw comes from the existing native
record. Export applies Blender `(x,y,z)` → Godot `(x,z,-y)` exactly once.
The input/raw normalization and final part transforms are measured in the asset
audit; studio longest-dimension normalization is not the game scale.

The sorter owns three distinct dictionaries: `input`, `ferrous`, `remainder`.
Only `iron_ore`, `iron_ingot`, `iron_fittings`, `bog_iron` are ferrous in the current
table. Each hand `sort` routes at most 16 units in native item order, subject to
64 input units and 64 units per tray. Full destinations or an empty input cannot
lose stock. Representative chips are pictures of those stores, never pickups.
Native sorting is immediate; the existing .7-second chip route illustrates the
completed transfer and does not delay the transaction or promise automatic work.

Existing sort animation positions, local Godot metres:

| Position | XYZ |
| --- | --- |
| Input start | `(0,1.05,-.12)` with the existing small per-chip X spacing |
| Ferrous attraction | `(-.35,.86,.02)` |
| Remainder route | `(.32,.66,.02)` |
| Ferrous landing | `(-.4,.32,.15)` |
| Remainder landing | `(.4,.32,.15)` |

The bellows owns `energy`, 0–4. `prime` stores one hand operation; `release`
spends one only when the existing nearby target qualifies. A seam needs its
existing set wedge; clay/slate/shellstone/cork respond to their existing impact
route, and hot eligible ore cracks through its existing rule. Target selection
uses nearest responsive ResourceNode within 3 m and the current line of sight.
No new facing, nozzle ray, heat, impact multiplier, resource or mining gate.
The line starts at `(0,.6,0)` and aims at target ground + `(0,.3,0)`.
The visible release starts at `(0,.55,0)` and travels for the existing .4 seconds.
The cosmetic nozzle tip is `(0,.55,-.555)`; it is not a new targeting socket.

Device source node roles: `Housing`, `Pullstone`, `Membrane`, `Platen`.
Every exported device root and housing uses the native ground origin `(0,0,0)`.
The mounted sorter nodule has uniform scale `.48` and translation
`(-.35,.61,-.045)` in Godot metres. The source nodule has scale `.70` and
translation `(0,.16,.08)`; the source membrane has scale `.87` and translation
`(0,.19,0)`. These mounts leave the native full body unchanged.
The bellows' membrane starts at `(0,.22,-.03)` in Godot. Its Y scale reads
`.40 + .12*energy/4`; the guided top platen sits at `.22 + .96*scale + .025`.
The top platen and its grip move together; no idle breathing or success loop.
At zero/full stored pressure the platen origin is Y `.629`/`.7442` m;
its moving-part local mesh spans Y `-.025` to `.165` m. The membrane's X/Z
scale stays `.70`. The Blender assembly is posed near the raised state; the
engine replaces that pose with the current native stored pressure.
This mesh is a supported guided bellows, not a new simulated mechanism.
Neither device has a native cable/energy endpoint; F4 must not infer one from
a decorative lashing or nozzle. F4's pressure-feeder sockets remain its own
existing contract and must be fitted separately when reusing the membrane.

`settings.json` documents every art-only dimension and candidate detail count.
Original albedo and ORM remain separate from the added geometric injury and
`F3_SCAR` point-color data: R = damaged margin, G = deep energy route,
B = route travel coordinate. Albedo is sRGB, ORM and scar data linear.
The shader has no `TIME` clock. An accepted native transfer or pressure change
starts its short event; source work is notified only by the player's accepted
work-result path. Refresh/reload never replays an event, and pausing stops travel.

Grounded source shells have no inventory, interaction, body or yield. The native
ResourceNode alone owns the finite intact lot and its original collision; the
source stage's empty shell remains as labelled noninteractive aftermath.
The test stage is authored inspection geometry, not a changed generated region.
Current generated-world regression checks separately preserve geography/stock.

Dismantling the sorter returns 1 Pullstone, 2 wood, 0 iron ingot, plus every
remaining input/ferrous/remainder item. Bellows returns 1 Ventlung, 1 wood,
1 raw reed; stored pressure vents. Core/common-frame/contents refunds share
the existing atomic overflow check. Repeated removal pays nothing.
Failed placement retains the kit; successful placement consumes exactly one.
Normal SaveManager checkpoints restore native ownership and partial finite work
in a fresh process. No F3 save field or schema migration is introduced.
