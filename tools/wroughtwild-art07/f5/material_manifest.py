"""Record the retained material, attachment and dependency contract, without cooking assets."""
import sys,json,struct,hashlib,re
from pathlib import Path
from PIL import Image
from audit import DEPOT,PACKAGES,read,sha,glb_json
CUTOUTS={'red':'build/workshop-art04/red-source-v01/rock_cutout.png','white':'build/workshop-white/source-v01/rock_cutout.png','blue':'build/workshop-blue/source-v01/rock_cutout.png','green':'build/workshop-green/source-v01/rock_cutout.png'}
INSPECTIONS={'red':'build/workshop-art04/inspection-v01/inspection.json','white':'build/workshop-white/inspection-v03/inspection.json','blue':'build/workshop-blue/inspection-v02/inspection.json','green':'build/workshop-green/inspection-v01/inspection.json'}
def main():
    work,out=map(lambda x:Path(x).resolve(),sys.argv[1:3]);assert not out.exists()
    report={'task':'ART-07F5','base_game_native_commit':'56ce6bbe343012205690cf669491372958b80662','families':{},'failures':[]}
    look=(DEPOT/'game/art/contraption_look.gd').read_text()
    assert 'white_connection_bounds := Vector3(.65, 1.18, .55)' in look
    assert 'red_heat_bounds := Vector3(1,1.2,1)' in look
    assert 'Vector3(1.5, 1.1, 1.5)' in (DEPOT/'game/art/leyline_source_look.gd').read_text()
    catalogue=read(DEPOT/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json')
    ids={'red':'red_heat_buffer','white':'white_connection','blue':'blue_delay','green':'green_junction'}
    for colour,relative in PACKAGES.items():
        review=work/colour/'review';package=DEPOT/relative;cfg=read(review/(colour+'.json'))
        raw=list((package/'provenance').glob('*.glb'))[0]
        data=raw.read_bytes();length=struct.unpack_from('<I',data,12)[0];doc=glb_json(raw);binary=data[28+length:]
        textures=[]
        pbr=doc['materials'][0]['pbrMetallicRoughness']
        for role,key in [('base','baseColorTexture'),('orm','metallicRoughnessTexture')]:
            im=doc['images'][doc['textures'][pbr[key]['index']]['source']];view=doc['bufferViews'][im['bufferView']]
            embedded=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
            assert hashlib.sha256(embedded).hexdigest()==sha(review/f'{colour}-{role}.png'),colour+' original '+role
        for path in sorted(review.glob('*.png')):
            if not re.fullmatch(r'(?:red|white|blue|green|post|buffer|fragment-[123])-(?:base|orm|normal|scar)\.png',path.name):continue
            with Image.open(path) as im:
                size=list(im.size);mode=im.mode
                assert size==([1024,1024] if path.name.startswith('fragment-') else [2048,2048]),path
            role=path.stem.split('-')[-1]
            textures.append({'file':path.name,'bytes':path.stat().st_size,'sha256':sha(path),'dimensions':size,'mode':mode,
              'sampling':'sRGB albedo' if role=='base' else 'linear data','channels':'R core, G damage, B travel, A branch identity (not transparency)' if role=='scar' and colour=='green' else ('R core, G damage, B travel' if role=='scar' else ('R occlusion, G roughness, B metallic; shader uses G/B' if role=='orm' else ('tangent-space normal' if role=='normal' else 'base colour')))})
        assert len(textures)==19,(colour,len(textures))
        shader=review/f'{colour}_scar.gdshader'
        shader_text=shader.read_text();assert 'base_texture : source_color' in shader_text
        assert 'orm_texture : source_color' not in shader_text and 'scar_texture : source_color' not in shader_text
        assert 'NORMAL_MAP=' in shader_text.replace(' ','') and 'METALLIC=' in shader_text.replace(' ','')
        cutout=DEPOT/CUTOUTS[colour]
        inspection=read(DEPOT/INSPECTIONS[colour]);assert inspection['raw_sha256']==sha(raw)
        assigned=next(d for d in catalogue['devices'] if d['id']==ids[colour])
        report['families'][colour]={'source_id':colour+'_source','source_catalogue':next(d for d in catalogue['nature_support'] if d['id']==colour+'_source'),'device':assigned,
            'original_package_path':str(package),'original_input':{'path':str(next((package/'provenance').glob('*.png'))),'sha256':sha(next((package/'provenance').glob('*.png')))},'original_generation':read(package/'provenance/generation.json'),
            'source_sha256':sha(raw),'source_manifest_sha256':sha(package/'manifest.json'),
            'retained_cutout':{'path':str(cutout),'sha256':sha(cutout),'bytes':cutout.stat().st_size,'dimensions':list(Image.open(cutout).size)},
            'raw_to_game':inspection,'rotation_after_glb_import_degrees_z':-90 if colour=='white' else 0,
            'axis_mapping':'Blender (x,y,z) to Godot (x,z,-y), glTF importer/exporter handles it once',
            'pivot':'Ground centre, Blender Z=0 / Godot Y=0; arranged editable scene locations are NOT export transforms',
            'attachment':{'anchor_godot_xyz_m':[0,.85,0] if colour=='red' else [0,1.18,0],
                'meaning':'thermal connection to one feeder' if colour=='red' else 'shared native signal anchor; Green arms do not create separate physical native ports',
                'body_godot_xyz_m':assigned['bounds_m'],'source_body_godot_xyz_m':[1.5,1.1,1.5]},
            'textures':textures,'external_png_bytes':sum(t['bytes'] for t in textures),
            'uncompressed_rgba8_bytes_without_mips':sum(t['dimensions'][0]*t['dimensions'][1]*4 for t in textures),
            'shader_sha256':sha(shader),'controls':cfg,'original_base_orm_bytes_identical':True,
            'lod_selection':'N/M/F selects explicit near/mid/far. No automatic population/streaming policy adopted.',
            'conformance':'retained approved ART-04, geometric incision up to 3 mm; no ART-06C depth retrofit or aesthetic redesign'}
    out.write_text(json.dumps(report,indent=2),encoding='utf-8')
    print('F5_MATERIAL_DEPENDENCY_CONFORMANCE_OK',len(report['families']))
if __name__=='__main__':main()
