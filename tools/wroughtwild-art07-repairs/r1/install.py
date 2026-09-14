"""Install R1 delta and test-only derivatives into the prepared pinned runtime."""
import json,shutil
from measure import ROOT,OUT,GAME,sha,write
TOOL=ROOT/'tools/wroughtwild-art07-repairs/r1'
target=GAME/'r1';target.mkdir(exist_ok=False);(target/'assets').mkdir()
for name in ['native_tree.gd','settings.json','views.gd','studio.gd','route.gd']:
    shutil.copy2(TOOL/name,target/name)
for kind in ['broadleaf','pine']:
    for name in [kind+'-a-lod2.glb',kind+'-stump.glb']:
        shutil.copy2(OUT/'models'/kind/name,target/'assets'/name)
source=GAME/'g1/art.gd';before=source.read_bytes();old='\t\tnode.set_script(load("res://"+script+".gd"))';new='\t\tif script=="b1/native_tree" and not "--r1-before" in OS.get_cmdline_user_args():\n\t\t\tscript="r1/native_tree"\n'+old
text=before.decode();assert text.count(old)==1;text=text.replace(old,new)
# Preserve G1's family selector and source owner metadata for both adapters.
text=text.replace('script=="b1/native_tree": node.source_kind','script in ["b1/native_tree","r1/native_tree"]: node.source_kind')
text=text.replace('node.set_meta("g1_source",script.split("/")[0])','node.set_meta("g1_source","b1" if script=="r1/native_tree" else script.split("/")[0])')
source.write_text(text,encoding='utf-8',newline='')
write(OUT/'evidence/overlay-application.json',{'file':'game/g1/art.gd','before_sha256':__import__('hashlib').sha256(before).hexdigest(),'after_sha256':sha(source),'functions':['G1Art.resource'],'purpose':'Select the R1 fitted B1 adapter while retaining G1 owner metadata, all resource IDs and family selection. --r1-before uses unchanged G1 B1 presentation.'})
scene=(GAME/'g1/review.tscn').read_text().replace('res://g1/review.gd','res://r1/views.gd');(target/'views.tscn').write_text(scene)
probe=(GAME/'g1/probe.gd').read_text();probe=probe.replace('"res://../evidence/probe-"+("art" if G1Art.enabled() else "baseline")','"res://../evidence/r1-probe-"+("before" if "--r1-before" in OS.get_cmdline_user_args() else "after")');(target/'probe.gd').write_text(probe)
(target/'probe.tscn').write_text((GAME/'g1/probe.tscn').read_text().replace('res://g1/probe.gd','res://r1/probe.gd'))
for ident in ['b1','c4']:
    text=(GAME/ident/'native_review.gd').read_text()
    text=text.replace('var output:="res://'+ident+'/evidence/"','var output:="res://../evidence/r1-native-'+ident+'-"')
    text=text.replace('output+=RenderingServer.get_current_rendering_method() if rendered else "headless"','output+=("before-" if "--r1-before" in OS.get_cmdline_user_args() else "after-")+(RenderingServer.get_current_rendering_method() if rendered else "headless")')
    if ident=='b1':
        text=text.replace('load("res://b1/native_tree.gd")','load("res://b1/native_tree.gd" if "--r1-before" in OS.get_cmdline_user_args() else "res://r1/native_tree.gd")')
        text=text.replace('Compact body fit; full-width source review is separate','R1 lower-trunk fit; attached broad crown; native work and fall')
    text=text.replace('\tif \"--restore-partial\" in OS.get_cmdline_user_args():','\tawait r1_envelope()\n\tif \"--restore-partial\" in OS.get_cmdline_user_args():')
    text=text.replace('var checks:=0','var checks:=0\nvar r1_capture_times:Array=[]')
    text=text.replace('\tawait RenderingServer.frame_post_draw\n\tcheck(get_viewport()', '\tawait RenderingServer.frame_post_draw\n\tr1_capture_times.append({"image":name+".png","physics_frame":Engine.get_physics_frames(),"draw_frame":Engine.get_frames_drawn(),"wall_msec":Time.get_ticks_msec()})\n\tcheck(get_viewport()')
    text=text.replace('func finish()->void:', 'func finish()->void:\n\tif rendered:FileAccess.open(output+"/motion-times.json",FileAccess.WRITE).store_string(JSON.stringify({"frames":r1_capture_times,"scope":"Native fall tween and work; captures include draw waits. Playback timing uses recorded simulation-frame intervals.","physics_ticks_per_second":Engine.physics_ticks_per_second},"  "))')
    text+='\n'+(TOOL/'movement.gd.txt').read_text(encoding='utf-8-sig')
    (target/(ident+'_native.gd')).write_text(text)
    (target/(ident+'_native.tscn')).write_text((GAME/ident/'native_review.tscn').read_text().replace('res://'+ident+'/native_review.gd','res://r1/'+ident+'_native.gd'))
# Preserve paid fixture's assertions and input route; redirect its disposable checkpoint.
paid=(GAME/'g1/paid.gd').read_text().replace('"res://g1/paid-home.json"','"res://r1/replayed-paid-home.json"')
paid=paid.replace('player.camera.position=Vector3(0,.65,0)','player.camera.position=Vector3.ZERO;player.spring_arm.position=Vector3(0,.72,0)')
(target/'paid.gd').write_text(paid)
(target/'paid.tscn').write_text((GAME/'g1/paid.tscn').read_text().replace('res://g1/paid.gd','res://r1/paid.gd'))
print('R1_DELTA_INSTALLED',len(list(target.rglob('*'))))

(target/'studio-assets').mkdir()
for kind in ['broadleaf','pine']:
    for path in (OUT/'models'/kind).glob('*.glb'):shutil.copy2(path,target/'studio-assets'/path.name)
shutil.copy2(ROOT/'tools/wroughtwild-art07/b1/canopy.gdshader',target/'canopy.gdshader')
(target/'studio.tscn').write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="res://r1/studio.gd" id="1"]\n[node name="R1Studio" type="Node3D"]\nscript=ExtResource("1")\n')

(target/'route.tscn').write_text((GAME/'g1/walk_review.tscn').read_text().replace('res://g1/walk_review.gd','res://r1/route.gd'))

# Unchanged native catalogue assertions, with R1-owned evidence output only.
(target/"catalogue.gd").write_text((GAME/"g1/catalogue.gd").read_text().replace("res://../evidence/catalogue-","res://../evidence/r1-catalogue-"))
(target/"catalogue.tscn").write_text((GAME/"g1/catalogue.tscn").read_text().replace("res://g1/catalogue.gd","res://r1/catalogue.gd"))
