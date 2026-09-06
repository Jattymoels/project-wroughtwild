"""Build the local review from actual Godot captures; no authored mock images."""
from pathlib import Path
import html
import json

root = Path(__file__).resolve().parents[1]
output = root / "build" / "pressure-workshop"
report = json.loads((output / "manifest.json").read_text(encoding="utf-8"))
views = [
    ("struck-hearth", "An older smithy, struck by an asteroid",
     "The hearth and walls predate the catastrophe. Pressure crossed the ruined material by accident."),
    ("working", "The player's new containment and feeder",
     "Ventlung contains pressure; Thrumroot stores its work. Clay and ordinary fuel fire the existing bricks."),
    ("rebuilt", "Useful material for reconstruction",
     "Four firing cycles make sixteen bricks. The red masonry here was paid for from the output tray."),
]
cards = []
for key, title, description in views:
    for light in ("day", "dusk"):
        filename = f"{key}-{light}.png"
        if filename not in report["captures"] or not (output / filename).is_file():
            raise RuntimeError(f"Missing reviewed capture: {filename}")
    cards.append(f'''<section><h2>{html.escape(title)}</h2><p>{html.escape(description)}</p>
<a href="{key}-day.png" class="image-link"><img src="{key}-day.png" data-view="{key}" alt="{html.escape(title)}" loading="lazy"></a></section>''')
document = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>The struck smithy · Wroughtwild</title><style>
:root{color-scheme:dark;font:17px/1.6 system-ui;background:#171c1b;color:#e0dfd1}body{margin:32px auto;max-width:1200px;padding:0 24px}h1{font-size:40px;line-height:1.15;margin-bottom:14px}h2{font-size:24px;margin-top:36px}p{max-width:900px;color:#b9c3b5}button{font:inherit;border:1px solid #78866e;border-radius:8px;padding:8px 18px;background:#27322c;color:#eee;margin:0 8px 12px 0;cursor:pointer}button[aria-pressed=true]{background:#bdc999;color:#182018}img{width:100%;border:1px solid #536052;border-radius:8px;display:block}.facts{padding:16px 20px;border:1px solid #4b594a;border-radius:10px}small{color:#b0b9aa}a{color:#d4c59a}
</style><body><small>WROUGHTWILD · PRESSURE WORKSHOP · ACTUAL GODOT CAPTURES</small>
<h1>The struck smithy</h1><p>An accidental overlap of old craft and meteor-borne augmentation. The player discovers what remains, contains its pressure, and puts the work to use.</p>
<div class="facts">One finite pocket · 24 strokes · 96 bricks of source-driven work<br>Four cycles per start · ordinary clay and fuel · hand winding after depletion</div>
<p>Seed 1, frontier_v5. Current visual finish accepted for now; a later graphical pass is deferred.</p>
<nav aria-label="Lighting"><button data-light="day" aria-pressed="true">Daylight</button><button data-light="dusk" aria-pressed="false">Dusk</button></nav>
''' + "".join(cards) + f'''<p><strong>{report['checks']} rendered integration checks, {report['failures']} failures.</strong> The review uses seeded recipe supplies and scripted active ticks through real placement, local controls and saving. It does not measure discovery feel or balance. Native finite-stock checks and support/obstruction checks are separate.</p>
<script>document.querySelectorAll('[data-light]').forEach(button=>button.addEventListener('click',()=>{{const light=button.dataset.light;document.querySelectorAll('[data-view]').forEach(image=>{{image.src=image.dataset.view+'-'+light+'.png';image.parentElement.href=image.src}});document.querySelectorAll('[data-light]').forEach(other=>other.setAttribute('aria-pressed',String(other===button)))}}));</script></body></html>'''
(output / "index.html").write_text(document, encoding="utf-8")
print(f"Pressure workshop gallery: {len(views)*2} verified captures; {output / 'index.html'}")
