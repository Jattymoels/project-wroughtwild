"""Retain unretouched engine PNGs and a pulse GIF with actual capture timing."""
from pathlib import Path
import json,shutil
from PIL import Image
root=Path(__file__).resolve().parents[2];out=root/'build/rf08';media=out/'media'
report=json.loads((out/'walk-checks.json').read_text(encoding='utf-8'))
assert report['failures']==0
names=['01-recovered-impact.png','02-living-scar.png','03-growth-and-fragments.png','04-emission-disabled.png']
evidence=root/'docs/prototype/rf08-evidence-2026-09-16';evidence.mkdir(parents=True,exist_ok=True)
for name in names:shutil.copy2(media/name,evidence/name)
times=json.loads((out/'frame-times.json').read_text(encoding='utf-8'))
frames=[]
for i in range(report['captured_frames']):
 with Image.open(media/f'walk-{i:03d}.jpg') as im:frames.append(im.resize((960,540),Image.Resampling.LANCZOS).convert('RGB'))
durations=[times[i+1]-times[i] for i in range(len(times)-1)]
durations.append(durations[-1])
assert min(durations)>0 and 9000<sum(durations)<10500
# GIF stores centiseconds. Round cumulative time so intervals do not lose
# fractional centiseconds repeatedly and gradually accelerate the pulse.
elapsed=0
encoded_elapsed=0
encoded_durations=[]
for duration in durations:
 elapsed+=duration
 endpoint=round(elapsed/10)*10
 encoded_durations.append(endpoint-encoded_elapsed)
 encoded_elapsed=endpoint
palette=frames[0].quantize(colors=256)
frames=[im.quantize(palette=palette,dither=Image.Dither.NONE) for im in frames]
frames[0].save(evidence/'living-scar-pulse.gif',save_all=True,append_images=frames[1:],duration=encoded_durations,loop=0,optimize=False)
for name in ['placement-checks.json','continue-checks.json','walk-checks.json','expected.json','scout.json','frame-times.json','placement-result.json','continue-result.json','walk-result.json']:
 shutil.copy2(out/name,evidence/name)
(evidence/'media.json').write_text(json.dumps({'source':'Unretouched ordinary Godot Forward+ viewport PNGs. GIF only resizes/quantizes the engine frames.','frames':len(frames),'duration_ms':sum(encoded_durations),'captured_duration_ms':sum(durations),'timing':'Actual wall-clock capture intervals, no time acceleration.'},indent=2)+'\n',encoding='utf-8')
print(evidence)

# The private opening uses the exact native approach already physically walked.
# Only the initial pose differs from the paid/finite-work Continue fixture.
state=json.loads((out/'checked-world.json').read_text(encoding='utf-8'))
state['player']={'position':[481.5,38.1,196.5],'yaw':0.0,'pitch':-0.12}
(out/'approach-world.json').write_text(json.dumps(state,indent=2)+'\n',encoding='utf-8')
