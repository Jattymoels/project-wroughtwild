"""Same actual G1 cameras, deterministic presentation cadence, separate capture jobs."""
from measure import BUILD, TOOLS, write, replace
for version in ['v01','v03']:
    base=BUILD/version;game=base/'runtime/game'
    source=(game/'r2/benchmark.gd').read_text()
    source=replace(source,'var camera:Camera3D','var camera_audits:Array=[]\nvar camera:Camera3D')
    source=replace(source,'\t\t\t\tget_viewport().get_texture().get_image().save_png(output+"/"+String(view.id)+"-"+lighting+".png")','\t\t\t\tget_viewport().get_texture().get_image().save_png(output+"/"+String(view.id)+"-"+lighting+".png")\n\t\t\t\tcamera_audits.append({"view":view.id,"lighting":lighting,"inventory":r2_inventory(),"cost":costs()})')
    source=replace(source,'"textures":texture_inventory()','"camera_audits":camera_audits,"textures":texture_inventory()')
    source+=(TOOLS/'inventory.gd.txt').read_text(encoding='utf-8-sig')
    write(game/'r2/views.gd',source)
    write(game/'r2/views.tscn',(game/'r2/benchmark.tscn').read_text().replace('res://r2/benchmark.gd','res://r2/views.gd'))
    jobs=[]
    for renderer in ['forward_plus','gl_compatibility']:
        ident='views-art-'+renderer
        jobs.append({'id':ident,'program':str(base/'runtime/engine/Godot_v4.5-stable_win64.exe'),'arguments':['--fixed-fps','60','--rendering-method',renderer,'--path',str(game),'res://r2/views.tscn','--','--run-id='+ident],'log':str(base/'logs'/(ident+'.log')),'state':str(base/'users'/ident)})
    write(base/'views-jobs.json',jobs)
print('R2_MATCHED_VIEWS_INSTALLED')
