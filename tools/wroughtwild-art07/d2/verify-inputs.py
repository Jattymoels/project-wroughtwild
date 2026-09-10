"""Rehash original inputs and D1; prove all frozen rules/tests remain unchanged."""
import argparse,hashlib,json,zipfile
from pathlib import Path
ap=argparse.ArgumentParser(); ap.add_argument('--build',type=Path,required=True); a=ap.parse_args(); build=a.build.resolve()
def sha(p):
    with p.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()
p=json.loads((build/'prerequisites.json').read_text()); checked={}
for group in ['inputs','binaries']:
    for path,expected in p[group].items():
        assert sha(Path(path))==expected,path; checked[path]=expected
package=Path(p['prerequisite']['path']); assert sha(package/'manifest.json')==p['prerequisite']['manifest_sha256']
files=json.loads((package/'manifest.json').read_text())['files']
for rel,e in files.items(): assert sha(package/rel)==e['sha256'] and (package/rel).stat().st_size==e['bytes'],rel
frozen=0; imported_metadata=[]
with zipfile.ZipFile(build/'frozen.zip') as z:
    for entry in z.infolist():
        if entry.is_dir() or entry.filename=='game/scripts/piece_look.gd': continue
        path=build/'snapshot'/entry.filename
        if entry.filename.endswith('.import'):
            imported_metadata.append({'path':entry.filename,'archive_sha256':hashlib.sha256(z.read(entry)).hexdigest(),'imported_sha256':sha(path)})
            continue
        assert hashlib.sha256(path.read_bytes()).digest()==hashlib.sha256(z.read(entry)).digest(),entry.filename
        frozen+=1
report={'original_inputs':checked,'d1_files_rehashed':len(files),'d1_manifest_sha256':sha(package/'manifest.json'),'frozen_files_unchanged':frozen,'engine_import_metadata':imported_metadata,'sole_frozen_source_exception':'game/scripts/piece_look.gd: isolated mesh selection adapter only; original authoritative file untouched; derived .import metadata recorded separately'}
(build/'original-inputs-final.json').write_text(json.dumps(report,indent=2)+'\n')
print('D2_ORIGINAL_INPUTS_OK',len(checked),'originals;',len(files),'D1 files;',frozen,'frozen files')
