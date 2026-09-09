"""Encode only frames from the latest accepted rendered route run."""
import datetime,json,sys
from pathlib import Path
from PIL import Image
run=Path(sys.argv[1]);evidence=run/'evidence-art'
start=json.loads((run/'check_route-art-process.json').read_text(encoding='utf-8-sig'))['utc']
started=datetime.datetime.fromisoformat(start.replace('Z','+00:00')).timestamp()
record={}
for kind,duration in [('walk',300),('combat',200)]:
 paths=[p for p in sorted((evidence/kind).glob('*.png')) if p.stat().st_mtime>=started]
 assert paths and [int(p.stem) for p in paths]==list(range(len(paths))), 'Contiguous current frames required: '+kind
 frames=[]
 for p in paths:
  im=Image.open(p).convert('RGB');im.thumbnail((800,500),Image.Resampling.LANCZOS);frames.append(im)
 frames[0].save(evidence/(kind+'.webp'),save_all=True,append_images=frames[1:],duration=duration,loop=0,quality=78,method=4)
 record[kind]={'frames':[p.relative_to(evidence).as_posix() for p in paths],'frame_duration_ms':duration,'note':'Sampled actual engine frames. Playback repeats the recorded sequence; this is not benchmark timing or a new event.'}
(evidence/'captured-frames.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
print('ART05_MEDIA_OK',{k:len(v['frames']) for k,v in record.items()})
