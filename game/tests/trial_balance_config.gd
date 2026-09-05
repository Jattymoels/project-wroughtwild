extends Resource
## Review-only bot controls. No gameplay tuning is changed by this fixture.
@export var batch_seed:=741103 # Reproduces identical three-offer batches.
@export var offer_index:=0 # Fixed selection avoids cherry-picking conditions.
@export var physics_ticks:=240 # Combined with time_scale: 30 simulated steps/s.
@export var time_scale:=8.0 # Accelerates measurement; reported step stays explicit.
@export var exposure_seconds:=30.0 # Budget per isolated encounter; timeout != clear.
@export var decision_seconds:=0.12 # Bot reaction cadence, not instantaneous defence.
@export var ranged_distance:=7.5 # A useful projectile distance inside authored rooms.
@export var melee_distance:=2.1 # Approach close enough for ordinary melee reach.
