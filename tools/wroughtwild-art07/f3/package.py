"""Seal only deliberate F3 source, review, reproduction and evidence files."""
import json,hashlib,shutil,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];TOOL=Path(__file__).resolve().parent
BASE='4b5d89b376765fbf4d46049aa099e0bb154a82da'
def sha(p):
 with p.open('rb') as f:return hashlib.file_digest(f,'sha256').hexdigest()
def copy(a,b):b.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(a,b)
def main():
 assets,review,out=[Path(a).resolve() for a in sys.argv[1:]]
 assert all(p.is_relative_to(ROOT/'build/art07/f3') for p in [assets,review,out]);out.mkdir(parents=True,exist_ok=False)
 for p in assets.iterdir():
  if p.suffix in ['.glb','.blend','.json']:copy(p,out/'source'/p.name)
 for kind,folder in [('pullstone','v03/pullstone'),('ventlung','v02/ventlung')]:
  for name in ['source.glb','source_cutout.png','source_base.png','generation.log','generation.log.json','files.json']:
   copy(ROOT/'build/art07/f3'/folder/name,out/'raw'/kind/name)
 files=subprocess.check_output(['git','-C',str(ROOT),'ls-tree','-r','--name-only',BASE,'game','data'],text=True).splitlines()
 for rel in files:
  src=review.parent/rel
  copy(src,out/'review'/rel)
 for p in (review/'f3').rglob('*'):
  if p.is_file() and p.suffix not in ['.import','.uid'] and '.godot' not in p.parts and not any(part.endswith('-motion') for part in p.parts):copy(p,out/'review/game'/p.relative_to(review))
 copy(review/'bin/libwroughtwild_sim.windows.x86_64.dll',out/'review/game/bin/libwroughtwild_sim.windows.x86_64.dll')
 for p in TOOL.iterdir():
  if p.is_file() and p.name not in ['manifest.json']:copy(p,out/'recipes'/p.name)
 media=ROOT/'docs/art/leyline-studies/2026-09-09/art07/f3'
 for p in media.iterdir():
  if p.is_file():
   copy(p,out/'evidence'/p.name)
   if p.name=='README.md':
    t=(out/'evidence/README.md').read_text().replace('[receipt](../../../../../prototype/art07-production/receipts/f3.md)','[reproduction notes](../recipes/README.md)').replace('../../../../../../tools/wroughtwild-art07/f3/CONTRACT.md','../CONTRACT.md')
    (out/'evidence/README.md').write_text(t)
 # The standalone README has local links; its evidence inventory must describe
 # those delivered bytes, while the repository keeps its own curated inventory.
 evidence_manifest=out/'evidence/evidence-manifest.json'
 ev=json.loads(evidence_manifest.read_text());ev['files']=[{'path':p.name,'bytes':p.stat().st_size,'sha256':sha(p)} for p in sorted((out/'evidence').iterdir()) if p.is_file() and p!=evidence_manifest]
 evidence_manifest.write_text(json.dumps(ev,indent=2)+'\n')
 for name in ['v01/provenance.json','v13/provenance-final.json','v01/native/provenance.json','v02/native-checks/commands.json','v02/native-checks/core-test.log','v02/native-checks/world-test.log','v03/inspection/inspection.json','v22/asset-costs.json','v23/reopen/reopen-audit.json']:
  copy(ROOT/'build/art07/f3'/name,out/'provenance'/name.replace('/','-'))
 for p in (ROOT/'build/art07/f3/v17/native-regressions').iterdir():
  if p.is_file():copy(p,out/'provenance/native-regressions'/p.name)
 for p in (ROOT/'build/art07/f3').glob('*.log*'):
  if p.name.startswith(('v09-build','v17-checks','v17-restart','v22-selection','v23-','v24-')) and p.suffix in ['.log','.json']:copy(p,out/'provenance/runs'/p.name)
 copy(TOOL/'CONTRACT.md',out/'CONTRACT.md')
 copy(TOOL/'launch.ps1',out/'launch.ps1')
 (out/'README.md').write_text('ART-07F3 isolated source candidate. See CONTRACT.md and recipes/README.md. Copy before engine import.\nUse review/game/project.godot with -- --interactive for the native review, with an isolated APPDATA.\nRuntime binaries/assets and packed masters are local-only. Source illustration is not model evidence.\n')
 records=[]
 for p in sorted(out.rglob('*')):
  if p.is_file():records.append({'path':p.relative_to(out).as_posix(),'bytes':p.stat().st_size,'sha256':sha(p)})
 manifest={'slice':'ART-07F3','base_commit':BASE,'owner_visual_acceptance':'pending','ordinary_adoption':False,'files':records}
 (out/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
 print('F3_PACKAGE_SEALED',str(out),len(records),sha(out/'manifest.json'))
if __name__=='__main__':main()
