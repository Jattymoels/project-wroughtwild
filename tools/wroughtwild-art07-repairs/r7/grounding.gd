extends Node
# Load the retained sandpit resource graph in its normal successful order,
# then run the original standalone physics fixture without changing assertions.
const WORLD_RESOURCES=preload("res://scenes/sandpit.tscn")
func _ready():
    var test=load("res://tests/scenery_grounding.tscn").instantiate()
    add_child(test)
