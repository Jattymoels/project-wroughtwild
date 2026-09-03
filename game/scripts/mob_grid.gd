class_name MobGrid
## A spatial hash of every live mob, rebuilt each physics frame, so a mob
## asking "who is near me" reads one or two buckets instead of walking the
## whole enemies group (owner playtest, 3 Sep 2026: crowds lagged a good
## PC - separation was every mob against every mob, every frame).
##
## Double-buffered: mobs register into the current frame's buckets as they
## process, and queries read the previous frame's finished set, so the
## answer never depends on processing order. One frame of latency at
## 60 Hz is nothing to a steering push.

const CELL_M := 3.0

static var _frame := -1
static var _current: Dictionary = {}
static var _previous: Dictionary = {}
static var _count_previous := 0


static func _key(position: Vector3) -> Vector2i:
	return Vector2i(floori(position.x / CELL_M), floori(position.z / CELL_M))


## Called by each mob at the top of its physics step.
static func register(mob: Node3D) -> void:
	var frame := Engine.get_physics_frames()
	if frame != _frame:
		_frame = frame
		_previous = _current
		_count_previous = 0
		for bucket in _previous.values():
			_count_previous += (bucket as Array).size()
		_current = {}
	var key := _key(_where(mob))
	if not _current.has(key):
		_current[key] = []
	(_current[key] as Array).append(mob)


## Mobs within `radius` of `position` as of the last completed frame,
## excluding `except`. Freed nodes are skipped.
static func near(position: Vector3, radius: float, except: Node3D = null) -> Array:
	var out: Array = []
	var seen := {}
	var reach := ceili(radius / CELL_M)
	var centre := _key(position)
	var r2 := radius * radius
	# The finished frame, plus whoever has registered so far this frame (a
	# mob spawned and asked about in the same frame is still found).
	for buckets in [_previous, _current]:
		for dz in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var bucket: Array = buckets.get(Vector2i(centre.x + dx, centre.y + dz), [])
				for mob in bucket:
					if mob == except or not is_instance_valid(mob) or seen.has(mob.get_instance_id()):
						continue
					var d := _where(mob as Node3D) - position
					d.y = 0.0
					if d.length_squared() <= r2:
						seen[mob.get_instance_id()] = true
						out.append(mob)
	return out


## World position when the node has a world; local otherwise (tests).
static func _where(mob: Node3D) -> Vector3:
	return mob.global_position if mob.is_inside_tree() and mob.get_viewport() != null else mob.position


## How many mobs registered last frame (the live population).
static func population() -> int:
	return _count_previous


## Tests and scene changes: forget everything.
static func reset() -> void:
	_frame = -1
	_current = {}
	_previous = {}
	_count_previous = 0
