"""Timing-only diagnostic wrappers around the unchanged G1 method bodies."""
import re
from measure import BUILD, TOOLS, install, jobs, write

version='v02'
install(version)
game=BUILD/version/'runtime/game'
selected={
 'b1/native_tree.gd': [('_apply_visual','',False)],
 'b3/native_resource.gd': [('_apply_visual','',False),('reproject','',False),('own_materials','model',False)],
 'c1/native_resource.gd': [('_apply_visual','',False)],
 'c1/present.gd': [('install','model,id,conform,own',True)],
 'c2/native_resource.gd': [('_apply_visual','',False)],
 'c3/asset_view.gd': [('model','key,base',True)],
 'c4/native_tree.gd': [('_apply_visual','',False)],
 'c6/adapter.gd': [('mesh_for','id,level',True),('install','world',False),('material_for','source,struck',True)],
 'g1/environment.gd': [('cover_mesh','entry',True),('install','owner_world',False)],
 'g1/materials.gd': [('material_for','family,role',True)],
 'g1/colours.gd': [('scar','prefix',True),('add_model','role',False)],
 'scripts/authored_assets.gd': [('mesh_for','id',True),('scaled_mesh','id,scale',True)],
}
record=[]
for name,methods in selected.items():
    path=game/name
    source=path.read_text(encoding='utf-8')
    original=source
    source=source.replace('load(', 'R2Profile.resource(').replace('preR2Profile.resource(', 'preload(')
    for function,args,returns in methods:
        pattern=r'^(static )?func '+re.escape(function)+r'\([^\n]+\n'
        match=re.search(pattern,source,re.M)
        assert match,(name,function)
        signature=match.group(0)
        assert signature.rstrip().endswith(':'),(name,signature)
        signature_new=signature.replace('func '+function+'(', 'func r2_original_'+function+'(')
        source=source[:match.start()]+signature_new+source[match.end():]
        wrapper=signature+'\tvar started:=Time.get_ticks_usec()\n'
        wrapper+='\t'+('var result=' if returns else '')+'r2_original_'+function+'('+args+')\n'
        wrapper+='\tR2Profile.record("'+name+':'+function+'",started)\n'
        if returns:wrapper+='\treturn result\n'
        source+='\n'+wrapper
    # A top-level constant may follow extends/class_name and declarations.
    source+='\nconst R2Profile=preload("res://r2/profile.gd")\n'
    path.write_text(source,encoding='utf-8',newline='\n')
    record.append({'path':name,'changes':'Timing wrappers and load() wall timers only; original method bodies retained. Inclusive nested spans must not be added.'})
write(BUILD/version/'profile-instrumentation.json',record)
jobs(version,'benchmark',1)
print('R2_PROFILE_INSTRUMENTED',len(record))
