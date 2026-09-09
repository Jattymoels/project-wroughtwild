"""Copy only audited ART-04 deliverables into a fresh F5 package; pin current native/data."""
import argparse,json,shutil,subprocess,zipfile
from pathlib import Path
from audit import DEPOT,PACKAGES,read,sha,audit
BASE='56ce6bbe343012205690cf669491372958b80662'
def main():
    p=argparse.ArgumentParser();p.add_argument('native',type=Path);p.add_argument('output',type=Path);a=p.parse_args()
    native=a.native.resolve();out=a.output.resolve()
    assert not out.exists(),'Use a fresh output'
    report=audit(DEPOT);assert not report['failures']
    provenance=read(native/'provenance.json');assert provenance['revision']==BASE
    dll=native/'bin/libwroughtwild_sim.windows.x86_64.dll';assert sha(dll)==provenance['dll_sha256']
    out.mkdir(parents=True);(out/'audit').mkdir()
    (out/'audit/dependencies-before.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
    for colour,relative in PACKAGES.items():
        source=DEPOT/relative;dest=out/colour;dest.mkdir()
        manifest=read(source/'manifest.json');files=manifest.get('files',manifest)
        for name in files:
            parts=Path(name).parts
            # Old state/render reports are retained separately, never passed as this run's evidence.
            if parts[0] in ('editable','provenance') or (parts[0]=='review' and not parts[1].startswith('evidence')):
                target=dest/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source/name,target)
            elif parts[0]=='review' and parts[1].startswith('evidence') and name.endswith('.json'):
                target=out/'audit/historical'/colour/Path(name).relative_to('review');target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source/name,target)
        shutil.copy2(source/'manifest.json',dest/'original-manifest.json')
        shutil.copy2(source/'README.md',dest/'original-README.md')
        review=dest/'review'
        for target in (review/'data').rglob('*'):
            if target.is_file():target.unlink()
        shutil.copytree(native/'snapshot/data',review/'data',dirs_exist_ok=True)
        shutil.copy2(dll,review/'bin'/dll.name)
        shutil.copy2(native/'snapshot/game/bin/wroughtwild_sim.gdextension',review/'bin')
        old=read(review/'provenance.json')
        old['historical_native']=old['native'];old['native']=provenance
        old['f5_base_game_native_commit']=BASE
        (review/'provenance.json').write_text(json.dumps(old,indent=2),encoding='utf-8')
        # Application names keep each study's saves separate beneath the F5 launcher APPDATA.
        for folder in ('evidence','evidence-compat'):(review/folder).mkdir(exist_ok=True)
    print('F5_CURRENT_REVIEWS_PREPARED',out)
if __name__=='__main__':main()
