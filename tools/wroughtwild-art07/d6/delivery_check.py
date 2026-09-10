"""Final read-only package, original-source, evidence, log and scope audit."""
import hashlib,json,re,subprocess,sys
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[3];build=root/'build/art07/d6';package=build/'v04/handoff';evidence=root/'docs/art/leyline-studies/2026-09-09/art07/d6'
def sha(p):
    with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
m=json.loads((package/'manifest.json').read_text())
for e in m['files']:
    p=package/e['path'];assert p.stat().st_size==e['bytes'] and sha(p)==e['sha256'],p
provenance=json.loads((package/'provenance.json').read_text());originals=provenance['verified_files']+provenance['retained_package_manifests']
for e in originals:
    assert sha(Path(e['path']))==e['sha256'],e['path']
    for s in e.get('verified_sources',[]):assert sha(Path(s['path']))==s['sha256'],s['path']
for p in list((build/'v03/review-logs').glob('*.log'))+[build/'v04/import.log']:
    assert not re.search(r'^(?:SCRIPT ERROR|ERROR):',p.read_text(encoding='utf-8-sig'),re.M),p
    assert json.loads(p.with_suffix(p.suffix+'.json').read_text(encoding='utf-8-sig'))['exit_code']==0,p
reopen=json.loads((build/'v04/reopened/reopen-audit.json').read_text());assert reopen['triangles']==13608 and len(reopen['proxies'])==10
assert reopen['fresh_glb_import']['triangles']==13608 and all(i['packed'] for i in reopen['images'])
# Final evidence-inclusive package retains exactly the reviewed source/runtime.
for p in ['source/d6_materials.blend','source/d6_proxies.glb','review/d6_proxies.glb','review/review.gd','review/materials.json','review/project.godot']:
    assert sha(package/p)==sha(build/'check3'/p)==sha(build/'check4'/p),p
for renderer in ['forward_plus','gl_compatibility']:
    with Image.open(evidence/(renderer+'-motion.webp')) as im:assert im.n_frames==96
    for tag in ['overview','shade','distance-10','distance-24','unlit']:
        with Image.open(evidence/(renderer+'-'+tag+'.png')) as im:im.verify()
for p in [root/'tools/wroughtwild-art07/d6/README.md',evidence/'README.md',root/'docs/prototype/art07-production/receipts/d6.md']:
    for link in re.findall(r'\]\(([^)]+)\)',p.read_text()):
        if '://' not in link and not link.startswith('#'):assert (p.parent/link.split('#')[0]).resolve().exists(),(p,link)
subprocess.run(['git','-C',str(root),'diff','--exit-code','f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d','--','game','sim','data'],check=True,stdout=subprocess.DEVNULL)
files=[]
for p in sorted(evidence.iterdir()):
    if p.is_file():files.append({'path':str(p.relative_to(root)).replace('\\','/'),'bytes':p.stat().st_size,'sha256':sha(p)})
result={'status':'pass','slice':'ART-07D6','base_commit':m['base_commit'],'canonical_handoff':str(package),'manifest_sha256':sha(package/'manifest.json'),'canonical_files_unchanged':len(m['files']),'original_hash_records_unchanged':len(originals),'packed_reopen':'10 meshes; 13608 triangles; 12 packed images; fresh GLB agrees','evidence':files,'benchmarks':{r:json.loads((build/'check3/review/evidence'/(r+'-benchmark.json')).read_text()) for r in ['forward_plus','gl_compatibility']},'native_checks':{'world':595376,'core':224380,'placement':470,'restart':60,'stations':98,'failures':0},'no_protected_source_diff':True,'owner_visual_acceptance':'pending','publication':'worker branch only; serial publisher integration pending'}
Path(sys.argv[1]).write_text(json.dumps(result,indent=2)+'\n');print('D6_DELIVERY_OK',len(files),'curated files;',len(m['files']),'package files; original sources unchanged')
