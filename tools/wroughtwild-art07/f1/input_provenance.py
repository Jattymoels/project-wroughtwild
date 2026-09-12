"""Record exact selected imagegen inputs/prompts and unchanged raw geometry."""
import hashlib,json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3]
DEST=ROOT/'docs/art/leyline-studies/2026-09-09/art07/f1'
GENERATED=Path('C:/Users/Matty/.codex/generated_images/01a08f22-f80e-7cb2-9301-d7dd5589739c')
IDS={'lanternheart':'exec-81c5363d-5441-4942-b58a-c05231adaa7a.png','stormglass':'exec-a9543175-ba69-4568-af9e-c25a86d64875.png'}
RAWS={'lanternheart':'d6d4b0ae3e4f9fd1cdb9831e89e630c1661a46d9fb52e6b5a87ef40439da43a7','stormglass':'00843958337ff1e5ec7401f8ba8386d130946d54f29fd7c12d3828eb78f3e6bb'}
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
records=[]
for kind,filename in IDS.items():
    src=GENERATED/filename;image=DEST/f'{kind}-input-v01.png';prompt=DEST/f'{kind}-prompt-v01.txt';raw=ROOT/'build/art07/f1/v05'/kind/'source.glb'
    assert sha(src)==sha(image) and sha(raw)==RAWS[kind]
    records.append({'subject':kind,'generator':'built-in imagegen; one isolated organic component','original_image_path':str(src),'selected_image':image.name,'selected_image_sha256':sha(image),'prompt_file':prompt.name,'prompt_file_sha256':sha(prompt),'prompt_utf8':prompt.read_text(encoding='utf-8-sig').strip(),'raw_source':str(raw),'raw_sha256':sha(raw)})
path=DEST/'input-manifest.json';assert not path.exists();path.write_text(json.dumps({'slice':'ART-07F1','selected_trellis_version':'v05','records':records},indent=2)+'\n')
print('F1_INPUTS_AND_RAW_UNCHANGED',path)
