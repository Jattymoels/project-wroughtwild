"""Keep shader-input distinctions when equal texture paths become shared."""
import argparse
from measure import BUILD, read, replace
from source import sha, sha_bytes

def main(version):
    base=BUILD/version;runtime=base/'runtime';record=read(base/'changes.json');original=read(base/'prepared.json')['original_files']
    changes={r['path']:r for r in record['files']}
    substitutions=[
      ('game/c6/adapter.gd','\tvar key := str(base.albedo_texture.resource_path if base.albedo_texture else base.albedo_color) + str(base.metallic) + str(base.roughness) + str(scarred)','\t# Equal textures may still have distinct tint or ORM inputs.\n\tvar key:Array=[base.albedo_texture,base.albedo_color,base.metallic,base.roughness,scarred,base.roughness_texture]','material_for'),
      ('game/c1/present.gd','\t\t\tvar key:=str(role)+":"+str(conform)+":"+old.resource_name+":"+(image.resource_path if image else str(old.albedo_color))+":"+str(old.vertex_color_use_as_albedo)','\t\t\t# Preserve every shader input while sharing equivalent texture objects.\n\t\t\tvar key:Array=[role,conform,old.resource_name,image,old.albedo_color,old.vertex_color_use_as_albedo,old.roughness_texture]','install')]
    for name,old,new,function in substitutions:
        path=runtime/name
        assert sha(path)==(changes[name]['after_sha256'] if name in changes else original[name]['sha256']),name
        text=replace(path.read_text(encoding='utf-8-sig'),old,new)
        path.write_text(text,encoding='utf-8',newline='\n')
        if name not in changes:
            row={'path':name,'before_sha256':original[name]['sha256'],'after_sha256':sha(path),'functions_or_settings':[function],'purpose':'Cache by complete actual shader inputs so sharing an immutable texture cannot conflate different tints or ORM maps.','overlaps':['r7: C6 retained-anchor materials; preserve complete shader-input identity when composing.'],'replacement_asset':None}
            record['files'].append(row)
        else:
            changes[name]['after_sha256']=sha(path);changes[name]['functions_or_settings'].append(function+' complete shader-input key');changes[name]['purpose']+=' Cache identity also retains tint and ORM distinctions.'
    record['application']+=' Then run material_keys.py for complete shader-input cache keys.'
    (base/'changes.json').write_text(__import__('json').dumps(record,indent=2),encoding='utf-8',newline='\n')
    print('R2_MATERIAL_INPUT_IDENTITIES_PRESERVED')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
