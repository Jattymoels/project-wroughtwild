"""Install additive checks from verified common G1 sources into a fresh version."""
import argparse
from pathlib import Path
from measure import BUILD, TOOLS, read, write
from source import sha

def main(version):
    base=BUILD/version;game=base/'runtime/game';prepared=read(base/'prepared.json');source=Path(prepared['source']['path'])
    reference=source/'game/b3/native_resource.gd'
    assert sha(reference)==prepared['original_files']['game/b3/native_resource.gd']['sha256']
    write(game/'r2/reference_b3.gd',reference.read_text())
    manifest=read(source/'manifest.json')['files'];probe=source/'evidence/probe-art.json'
    assert sha(probe)==manifest['evidence/probe-art.json']['sha256']
    write(game/'r2/reference-probe.json',probe.read_text())
    for name in ['projection_checks','reloads']:
        write(game/'r2'/(name+'.gd'),(TOOLS/(name+'.gd')).read_text(encoding='utf-8-sig'))
        scene=(game/'b3/native_review.tscn').read_text().replace('res://b3/native_review.gd','res://r2/projection_checks.gd') if name=='projection_checks' else (game/'g1/paid.tscn').read_text().replace('res://g1/paid.gd','res://r2/reloads.gd')
        write(game/'r2'/(name+'.tscn'),scene)
    write(base/'check-reference-inputs.json',{'original_b3_sha256':sha(reference),'original_native_probe_sha256':sha(probe),'source':prepared['source']})
    print('R2_ADDITIVE_CHECKS_INSTALLED')

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
