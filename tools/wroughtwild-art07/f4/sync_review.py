"""Update only F4 review-owned files in a disposable copy, never a sealed package."""
import shutil,sys
from pathlib import Path
from inputs import ROOT
game=Path(sys.argv[1]).resolve();assert game.is_relative_to(ROOT/'build/art07/f4') and not any((p/'manifest.json').exists() for p in game.parents)
for p in Path(__file__).parent.iterdir():
 if p.suffix in ['.gd','.gdshader'] or p.name=='appearance.json':shutil.copy2(p,game/'f4'/p.name)
(game/'f4/review.tscn').write_text((game/'tests/pressure_workshop.tscn').read_text().replace('res://tests/pressure_workshop.gd','res://f4/review.gd'))
print('F4_REVIEW_SYNCED')
