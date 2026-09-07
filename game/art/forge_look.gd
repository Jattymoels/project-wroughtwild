class_name ForgeLook
extends Resource
## Authored Forge kit dimensions, metres. Geometry controls composition and
## clearance; combat values are supplied by trial_rules(), never this resource.
@export var room_width := 20.0 # Room breadth leaves room to flank a group.
@export var room_depth := 24.0 # Distance between threshold and reward alcove.
@export var row_spacing := 34.0 # Galleries separate each encounter decision.
@export var wing_offset := 18.0 # Physical left/right branches around the spine.
@export var gallery_width := 10.0 # Passing room between the two wings.
@export var wall_height := 7.0 # High walls preserve an enclosed dungeon silhouette.
@export var wall_thickness := 0.8 # Solid, readable reveals around thresholds.
@export var doorway_width := 5.0 # Enough clearance for boss-sized bodies.
## Route plaques stand before a branch in the gallery, rather than inside its
## side wall. Their unchanged solid bodies remain outside the doorway itself.
@export var route_gallery_edge_inset_m := 0.8
@export var route_approach_offset_m := 8.0
@export var navigation_cell := 1.0 # Authored floor polygon resolution around cover.
@export var navigation_clearance := 1.15 # Fits the 0.9 m boss capsule plus corner clearance.
@export var path_arrival_distance := 0.2 # Close waypoint arrival prevents cutting solid corners.
@export var path_refresh_seconds := 0.3 # Bound per-enemy navigation queries.
@export var stone := Color("343936")
@export var stone_light := Color("51534b")
@export var iron := Color("292c2a")
@export var clay := Color("69483b")
@export var glass := Color("46615b")
@export var ember := Color("ed9a4c")
@export var parchment := Color("e2d5b5")
## Fine workshop furnishings fade before the room silhouette; shared meshes
## carry their imported distance LODs. These values do not affect encounters.
@export var decor_detail_distance := 45.0
@export var lamp_distance := 38.0
@export var lamp_glow := 0.6 # Visible warm fixtures remain quieter than danger tells.
@export var lamp_gain := 1.65 # Lift body and floor readability inside dark basalt rooms.
