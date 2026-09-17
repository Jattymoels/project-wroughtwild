extends "res://tests/land03/common.gd"
func _ready() -> void:
 begin()
 run.call_deferred()
func run() -> void:
 if not await started():return finish_job("early")
 var view: Vector3=place_data.reveal
 ready_at(view+Vector3.UP*1.1);terrain.set_process(true)
 for i in 40:await tick()
 face_at(place_data.red_source+Vector3.UP*2.0)
 check(player.is_on_floor(),"grounded Steppe reveal at player height")
 await still("reveal.png")
 var red:=source("red_home_margin")
 check(red!=null and red.supported(),"real Red source supported")
 if red!=null:
  var at: Vector3=red.global_position-place_data.direction*9
  terrain.ensure_area(at,20)
  at.y=terrain.rendered_height(at.x,at.z,terrain.height_at(int(at.x),int(at.z)))+1.1
  ready_at(at)
  for i in 35:await tick()
  face_at(red.global_position+Vector3.UP*.8)
  await still("red-source.png")
 var home:=home_for(place_data.hollow_home_id)
 var at:=Vector3(home.x+.5,home.y+1.1,home.z+.5)
 ready_at(at)
 for i in 30:await tick()
 face_at(place_data.centre+Vector3.UP*2)
 await still("hollow.png")
 finish_job("early",{"place":place_data,"player":player.position})
