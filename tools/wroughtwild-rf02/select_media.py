from pathlib import Path
from PIL import Image
import json

root = Path(__file__).resolve().parents[2]
source = root / 'build/rf02/media'
target = root / 'docs/prototype/rf02-evidence-2026-09-15'
target.mkdir(parents=True, exist_ok=True)
for stem in ('01-meadow', '02-woodland-edge', '03-woodland'):
    with Image.open(source / (stem + '.png')) as frame:
        frame.convert('RGB').save(target / (stem + '.jpg'), quality=90, optimize=True)

# The 120 captured frames represent eight seconds at 15 fps. Keep the same
# duration at 10 fps for an inline GIF; resize/encode only, with no retouching.
paths = sorted(source.glob('walk-*.jpg'))
assert len(paths) == 120, len(paths)
frames = []
for i in range(80):
    with Image.open(paths[(i * 3) // 2]) as frame:
        frames.append(frame.convert('RGB').resize((640, 360), Image.Resampling.LANCZOS))
atlas = Image.new('RGB', (640, 360 * 8))
for i in range(8):
    atlas.paste(frames[i * 10], (0, i * 360))
palette = atlas.quantize(colors=128, method=Image.Quantize.MEDIANCUT)
indexed = [frame.quantize(palette=palette, dither=Image.Dither.NONE) for frame in frames]
clip = target / 'walking.gif'
indexed[0].save(clip, save_all=True, append_images=indexed[1:], duration=100,
                loop=0, optimize=False, disposal=2)
with Image.open(clip) as check:
    assert check.n_frames == 80
    duration = 0
    for i in range(check.n_frames):
        check.seek(i)
        duration += check.info['duration']
    assert duration == 8000, duration
print(json.dumps({'clip': str(clip), 'frames': 80, 'duration_ms': duration,
                  'bytes': clip.stat().st_size,
                  'pictures': [p.name for p in target.glob('*.jpg')]}))