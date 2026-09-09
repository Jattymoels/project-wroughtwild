"""Read-only ART-04 dependency audit; writes only a fresh F5 receipt."""
import argparse, hashlib, json, struct
from pathlib import Path
DEPOT=Path('C:/Users/Matty/Dev/project-wroughtwild')
PACKAGES={'red':'build/workshop-art04/red-handoff','white':'build/workshop-white/white-handoff','blue':'build/workshop-blue/blue-handoff','green':'build/workshop-green/green-handoff'}
def sha(path):
    with path.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def read(path):return json.loads(path.read_text(encoding='utf-8-sig'))
def glb_json(path):
    with path.open('rb') as f:
        assert f.read(4)==b'glTF'
        version,total,size,kind=struct.unpack('<4I',f.read(16))
        assert version==2 and kind==0x4E4F534A
        return json.loads(f.read(size))
def audit(depot):
    result={'packages':{},'failures':[]}
    for colour,relative in PACKAGES.items():
        package=depot/relative
        manifest=read(package/'manifest.json');files=manifest.get('files',manifest)
        mismatches=[]
        for name,expected in files.items():
            path=package/name
            if not path.is_file() or sha(path)!=expected['sha256']:mismatches.append(name)
        raw=list((package/'provenance').glob('*.glb'))[0]
        generation=read(package/'provenance/generation.json')
        config=read(package/'recipe'/(colour+'.json'))
        input_png=next((package/'provenance').glob('*.png'))
        assert sha(input_png)==generation['input_sha256'],colour+' original image changed'
        assert sha(raw)==generation['glb_sha256'],colour+' generated source hash changed'
        assert sha(raw)==config['source_sha256'],colour+' raw source changed'
        entry={'path':str(package),'manifest_sha256':sha(package/'manifest.json'),'manifest_files':len(files),
            'manifest_bytes':sum(v['bytes'] for v in files.values()),'mismatches':mismatches,
            'source_path':str(raw),'source_sha256':sha(raw),'raw_glb_asset_metadata':glb_json(raw).get('asset'),
            'generation':generation,'config':config,
            'packed_master_sha256':sha(package/f'editable/{colour}-workshop.blend'),
            'historical_geometry_checks':read(package/'editable/asset-checks.json'),
            'native_provenance':read(package/'review/provenance.json'),
            'unlisted_files':[p.relative_to(package).as_posix() for p in package.rglob('*')
                if p.is_file() and p.relative_to(package).as_posix() not in files and p.name!='manifest.json']}
        result['packages'][colour]=entry
        result['failures'] += [colour+'/'+name for name in mismatches]
    return result
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('output',type=Path)
    parser.add_argument('--depot',type=Path,default=DEPOT);args=parser.parse_args()
    assert not args.output.exists(),'Use a fresh audit output'
    report=audit(args.depot);args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2),encoding='utf-8')
    print(json.dumps({k:{'files':v['manifest_files'],'mismatches':v['mismatches'],'unlisted_files':len(v['unlisted_files'])}
        for k,v in report['packages'].items()},indent=2))
    assert not report['failures'],report['failures']
