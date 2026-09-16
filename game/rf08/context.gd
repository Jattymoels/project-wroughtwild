extends RefCounted
## Derived map context only. The native world remains the sole owner of damage.
const PROFILES := ["frontier_v6","frontier_v7","frontier_v8","living_frontier_wave1","living_frontier_wave3"]
static var settings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://rf08/settings.json"))
static var debris: ArrayMesh
static var groundleaf: ArrayMesh
var noise:=FastNoiseLite.new()
var mask: ImageTexture
var width: int
var height: int
var pixels:=PackedByteArray()
static func eligible(profile: String) -> bool:return profile in PROFILES
func _init(map: Dictionary,seed_value: int,profile: String) -> void:
 noise.seed=int(hash(str(seed_value)+"/"+profile+"/rf08") & 0x7fffffff)
 noise.frequency=1.0/float(settings.patch_m)
 width=int(map.width)
 height=int(map.height)
 pixels.resize(width*height*4)
 if not eligible(profile):return
 for impact: Dictionary in map.get("impacts",[]):
  if impact.get("kind","")=="blacksmith_strike":continue
  var centre:=Vector2(float(impact.x)+.5,float(impact.z)+.5)*float(map.cell_size)
  var radius:=float(impact.radius_m)
  var outer:=radius*float(settings.outer_radius_gain)
  var direction: Vector3=impact.get("impact_direction",Vector3.FORWARD)
  var axis:=Vector2(direction.x,direction.z).normalized()
  for z in range(maxi(0,floori(centre.y-outer)),mini(height,ceili(centre.y+outer))):
   for x in range(maxi(0,floori(centre.x-outer)),mini(width,ceili(centre.x+outer))):
    var idx:=z*width+x
    var biome: String=map.biome_defs[map.biomes[idx]].id
    if biome not in ["meadow","forest"]:continue
    var offset:=Vector2(x+.5,z+.5)-centre
    var weight:=1.0-smoothstep(radius*float(settings.inner_radius_gain),outer,offset.length())
    if weight<=.0:continue
    var tongue:=smoothstep(-.28,.27,noise.get_noise_2d(x,z)+sin(offset.dot(axis.orthogonal())*.36+noise.get_noise_2d(x+53,z-17)*3.0)*.16)
    if float(pixels[idx*4])/255.0>weight:continue
    pixels[idx*4]=int(weight*255)
    pixels[idx*4+1]=int(tongue*255)
    pixels[idx*4+2]=int(map.heights[idx])
    pixels[idx*4+3]=255 if biome=="forest" else 0
 mask=ImageTexture.create_from_image(Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,pixels))
 prepare()
func sample(x: float,z: float) -> Vector2:
 var xi:=floori(x)
 var zi:=floori(z)
 if xi<0 or zi<0 or xi>=width or zi>=height:return Vector2.ZERO
 var idx: int=(zi*width+xi)*4
 return Vector2(float(pixels[idx])/255.0,float(pixels[idx+1])/255.0)
func density(x: float,z: float,base: float) -> float:
 var s:=sample(x,z)
 return lerpf(base,lerpf(float(settings.quiet_density),float(settings.grown_density),s.y),s.x)
func bind(material: ShaderMaterial) -> void:
 material.set_shader_parameter("rf08_enabled",true)
 # Rock tops also use the existing authored maps; RF02's regular binding is soil-only.
 var ground=preload("res://rf02/ground.tres")
 material.set_shader_parameter("rf02_meadow_albedo",ground.meadow_albedo)
 material.set_shader_parameter("rf02_woodland_albedo",ground.woodland_albedo)
 material.set_shader_parameter("rf08_mask",mask)
 material.set_shader_parameter("rf08_ground_mix",float(settings.ground_mix))
static func prepare() -> void:
 if debris!=null:return
 var kit=preload("res://rf07/cover.gd")
 kit.prepare()
 var source: ArrayMesh=kit.meshes.shingle
 var radius: float=source.get_meta("rf07_radius")
 var fit:=.40/radius
 debris=ArrayMesh.new()
 for i in source.get_surface_count():
  var st:=SurfaceTool.new()
  st.begin(Mesh.PRIMITIVE_TRIANGLES)
  st.append_from(source,i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*fit),Vector3.ZERO))
  st.set_material(source.surface_get_material(i))
  st.commit(debris)
 debris.set_meta("rf01_clearance",debris.get_aabb())
 var root: Node3D=load("res://rf08/assets/creeping-mat.glb").instantiate()
 groundleaf=ArrayMesh.new()
 AuthoredAssets._collect(root,Transform3D.IDENTITY,groundleaf)
 root.free()
 var leaf_material:=ShaderMaterial.new()
 leaf_material.shader=preload("res://rf06b/plant.gdshader")
 leaf_material.set_shader_parameter("plant_bend",.017)
 R7Cover.materials.append(leaf_material)
 for i in groundleaf.get_surface_count():groundleaf.surface_set_material(i,leaf_material)
 groundleaf.set_meta("rf01_clearance",groundleaf.get_aabb().grow(.005))
static func mesh_for(role: String) -> ArrayMesh:
 return debris if role=="rf08-shingle" else groundleaf
static func reserve_fragments(index: Dictionary,impact: Dictionary,cell: float) -> void:
 var centre:=Vector3((float(impact.x)+.5)*cell,0,(float(impact.z)+.5)*cell)
 var direction: Vector3=impact.get("impact_direction",Vector3.FORWARD)
 var yaw:=atan2(-direction.x,-direction.z)
 var box:=AuthoredAssets.mesh_for("cataclysm_impact_fragment").get_aabb()
 var transforms: Array[Transform3D]=[Transform3D(Basis(Vector3.UP,yaw).scaled(preload("res://art/cataclysm_look.tres").impact_scale),centre)]
 for i in 3:
  var at:=centre+Basis(Vector3.UP,yaw)*Vector3(-2.4+i*2.6,0,-4.0-i*1.2)
  transforms.append(Transform3D(Basis(Vector3.UP,yaw+.24*(i-1)).scaled(Vector3.ONE*(.24+i*.07)),at))
 for pose in transforms:
  var bounds:=pose*box
  var radius:=Vector2(bounds.size.x,bounds.size.z).length()*.5+float(settings.fragment_clearance_m)
  StrangeSites._reserve(index,bounds.get_center(),radius)
