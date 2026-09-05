extends Resource
## Gait values: metres travelled per cycle, then maximum limb swing in degrees.
@export var gaits: Dictionary = {"beast":Vector2(1.6,28),"crawler":Vector2(1.1,22),"humanoid":Vector2(1.35,24)}
## Gentle settled breathing frequency and vertical displacement in mesh metres.
@export var idle_hz := 0.28
@export var idle_metres := 0.008
## Body rise per step; small enough to keep feet close to their contact surface.
@export var step_lift := 0.025
## How quickly the pose settles when actual movement stops (weight per second).
@export var settle_rate := 8.0
## Recovery after the existing attack event, never an extra damage delay.
@export var release_seconds := 0.22
## Bounded anticipation/strike/stagger body angles, in radians.
@export var windup_radians := 0.13
@export var strike_radians := 0.17
@export var stagger_radians := 0.19
## Maximum visual lunge in mesh metres; does not move the collision body.
@export var lunge_metres := 0.12
## Wisp hover displacement in mesh metres.
@export var hover_metres := 0.055
## Treat larger per-frame displacements as a teleport instead of a stride.
@export var teleport_metres := 2.0
## Extra renderer bounds to retain swinging limbs at the edge of the screen.
@export var cull_margin := 0.4
