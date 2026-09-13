"""Independent source/presentation/ancestry audit against Git and the sealed bytes."""
import hashlib
import json
import subprocess
import zipfile
from pathlib import Path
from verify_copy import ROOT, BUILD, sha, write_new
OUT=BUILD/'v01'
SEALED=OUT/'sealed'
BASE='6bb2e044dcd0bf1788896aa2c19cdf56fee93522'

def git_tree(rev):
    rows=subprocess.check_output(['git','-C',str(ROOT),'ls-tree','-r','-z',rev]).split(b'\0')
    return {row.split(b'\t',1)[1].decode():row.split(b'\t',1)[0].split()[2].decode() for row in rows if row}

def blob(data):
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()

def norm(data):
    return data.decode('utf-8-sig').replace('\r\n','\n')

tree=git_tree(BASE)
audit={'runtime_revision':BASE,'archives':{},'runtime_identical':[], 'runtime_patched':[], 'recipes':[]}
integration=json.loads((SEALED/'integration.json').read_text())
assert integration['base']==BASE
for archive_name in ['baseline.zip','native/baseline.zip']:
    with zipfile.ZipFile(SEALED/archive_name) as archive:
        files=[n for n in archive.namelist() if not n.endswith('/')]
        newline_only=[]
        for name in files:
            data=archive.read(name)
            assert name in tree,(archive_name,name,'not in pinned Git tree')
            if blob(data)!=tree[name]:
                data.decode('utf-8') # A binary difference cannot pass as a text normalization.
                assert blob(data.replace(b'\r\n',b'\n'))==tree[name],(archive_name,name,'non-newline Git difference')
                newline_only.append(name)
        audit['archives'][archive_name]={'files':len(files),'sha256':sha(SEALED/archive_name),'matches_git':True,'git_crlf_only_files':newline_only}
        if archive_name!='baseline.zip': continue
        newline_only=[]
        for name in files:
            if Path(name).suffix=='.uid':continue
            actual=SEALED/name
            assert actual.is_file(),name
            data=archive.read(name)
            if actual.read_bytes()==data:
                audit['runtime_identical'].append(name)
                continue
            expected=norm(data)
            applicable=[p for p in integration['patches'] if 'game/'+p['file']==name]
            for patch in applicable:
                assert expected.count(patch['before'])==1,(name,'ambiguous recorded patch')
                expected=expected.replace(patch['before'],patch['after'])
            if name=='game/project.godot':
                expected=expected.replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="ART07G1"')
                expected=expected.replace('run/main_scene="res://scenes/sandpit.tscn"','run/main_scene="res://g1/play.tscn"')
            assert norm(actual.read_bytes())==expected,(name,'unexplained runtime change')
            audit['runtime_patched'].append({'file':name,'recorded_hooks':len(applicable),'sha256':sha(actual)})
# G1 recipe executable statements agree with published files; only recorded final blank lines differ.
trailing=[]
for published in sorted((ROOT/'tools/wroughtwild-art07/g1').iterdir()):
    sealed=SEALED/'recipes/g1'/published.name
    if not sealed.exists():continue
    a,b=norm(sealed.read_bytes()),norm(published.read_bytes())
    if a!=b:
        assert a.rstrip('\n')==b.rstrip('\n'),published.name
        trailing.append(published.name)
    audit['recipes'].append({'file':published.name,'sealed_sha256':sha(sealed),'published_sha256':sha(published),'lf_equal':a==b,'executable_equal':True})
assert set(trailing)=={'build-native.ps1','gpu-slot.ps1','paid.gd'}
audit['trailing_blank_line_only']=trailing
catalogue=json.loads((ROOT/'docs/art/concepts/environment/2026-09-09-frontier/asset-catalogue.json').read_text())
fauna=catalogue['fauna_presentation']
world=json.loads((SEALED/'data/tuning/world.json').read_text())
actors={r['id']:r for r in world['enemies']}
assert set(actors)=={r['id'] for r in fauna} and len(actors)==16
manifest_path=SEALED/'game/assets/authored/mobs/manifest.json'
models=json.loads(manifest_path.read_text())['assets']
audit['fauna']=[]
for entry in fauna:
    ident=entry['id']; row=actors[ident]; visual=row.get('visual_id',ident); model=models[visual]
    asset=SEALED/'game/assets/authored/mobs'/(visual+'.glb')
    assert asset.is_file() and sha(asset)==model['sha256']
    assert asset.relative_to(SEALED).as_posix() in audit['runtime_identical']
    audit['fauna'].append({'id':ident,'approved_ancestry':entry['ancestry'],'native_behaviour':row['behaviour'],
           'visual_id':visual,'existing_model_animal':model.get('animal'),'rig_version':model.get('rig_version',1),
           'existing_triangles':model['triangles'],'collision':model['collision'],'glb_sha256':sha(asset),
           'status':'retained existing animal' if model.get('animal') else 'retained older presentation; approved ART-06C animal adoption remains open'})
for name in ['game/scripts/enemy.gd','game/art/creature_motion.gd','game/art/frontier_host_look.gd','game/art/recovered_actor_art.gd','game/assets/authored/mobs/manifest.json']:
    assert name in audit['runtime_identical'],name
assert sum(1 for f in audit['fauna'] if not f['existing_model_animal'])==6
# Coverage is an inventory, not a statement that every supporting role is instantiated.
audit['coverage']={key:len(catalogue[key]) for key in ['shapes','materials','resource_nodes','nature_support','fauna_presentation']}
audit['limits']=['Six approved ART-06C animals remain older runtime presentations; this review preserves their IDs and direction and claims no completed adoption or new rigs.',
                 'Catalogue completeness does not imply full in-world composition coverage. G1 maps only three B2 roles and the B4 sway shader; unmatched roles remain supporting sources.',
                 'C5 replaces raised ore only on native fallback path. Native faceted terrain, resource positions and stock remain unchanged.']
write_new(OUT/'source-audit.json',audit)
print('G2_SOURCE_AUDIT',len(audit['runtime_identical']),'identical;',len(audit['runtime_patched']),'explained runtime changes;',len(audit['fauna']),'retained actor IDs')
