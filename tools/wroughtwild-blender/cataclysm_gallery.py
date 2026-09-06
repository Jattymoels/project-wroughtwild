"""Present unmodified, actual-game cataclysm captures and their verification."""
from pathlib import Path
import json

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "build" / "cataclysm"


def main():
    groups = []
    folders = sorted(OUT.glob("seed-*"))
    if (OUT / "actor-craft" / "manifest.json").exists():
        folders.append(OUT / "actor-craft")
    for folder in folders:
        manifest_path = folder / "manifest.json"
        if not manifest_path.exists():
            continue
        manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        assert manifest.get("failures") == 0, manifest_path
        for path in folder.glob("*.png"):
            assert path.stat().st_size > 1000, path
        stills = [p for p in sorted(folder.glob("*.png")) if not p.name.startswith("walk-")]
        walks = {}
        for path in sorted(folder.glob("walk-*.png")):
            route = path.stem.rsplit("-", 1)[0][5:]
            walks.setdefault(route, []).append(path.relative_to(OUT).as_posix())
        groups.append({"name": folder.name, "manifest": manifest,
                       "stills": [p.relative_to(OUT).as_posix() for p in stills], "walks": walks})
    assert groups, "No completed cataclysm gameplay reviews exist"
    data = json.dumps(groups).replace("<", "\\u003c")
    page = """<!doctype html><html lang="en"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Wroughtwild · After the cataclysm</title><style>
:root{color-scheme:dark;font-family:system-ui;background:#171d1b;color:#e2dfd1}*{box-sizing:border-box}
body{margin:0}header,main{max-width:1500px;margin:auto;padding:24px}header{padding-bottom:8px}
h1{font-family:Georgia,serif;font-size:clamp(28px,4vw,48px);font-weight:400;margin:8px 0}p{line-height:1.55;max-width:900px;color:#b9c1b4}
small{color:#a6b494}button,select,input{font:inherit}button,select{background:#303b33;border:1px solid #68755d;color:#eee;padding:9px 14px;border-radius:5px}
nav{display:flex;gap:10px;flex-wrap:wrap;margin:20px 0}.viewer{background:#101511;border:1px solid #4a5949;border-radius:8px;overflow:hidden}
.viewer img{display:block;width:100%;aspect-ratio:1.6;object-fit:contain}.bar{padding:12px;display:flex;align-items:center;gap:14px;flex-wrap:wrap}
.bar input{flex:1;min-width:180px}#caption{flex:1}#stills{display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:12px;margin:22px 0}
.thumb{padding:0;overflow:hidden;text-align:left;background:#222b25;border:1px solid #41503e;cursor:pointer}.thumb img{display:block;width:100%}.thumb span{display:block;padding:10px;font-size:13px}
details{margin:25px 0;padding:18px;background:#202923}pre{overflow:auto;white-space:pre-wrap;font-size:13px;color:#bac8b1}a{color:#c4d6a6}footer{padding:15px 0;color:#a6b494}
</style><header><small>WROUGHTWILD · ACTUAL GAMEPLAY SPACES</small><h1>A world shaped by augmentation</h1>
<p>Surviving craft, directed impact damage and altered living matter share one visual language. These captures use the normal world, authored assets and existing gathering/building systems.</p>
<p>New geography uses frontier_v4. The archived v3 views are a historical reference, not matched terrain comparisons. Walks are scripted camera evidence; visual enjoyment and combat feel still need human play.</p></header>
<main><nav><select id="seed" aria-label="World seed or actor study"></select><select id="route" aria-label="Walking route"></select><button id="walk">Show walk</button><a href="forge/index.html">Three complete Forge runs</a><a href="../frontier-polish/index.html">Previous world review</a></nav>
<section class="viewer"><img id="hero" alt="Actual Wroughtwild world capture"><div class="bar"><span id="caption"></span><button id="play">Play</button><input id="frame" aria-label="Walk frame" type="range" min="0" max="0" value="0"></div></section>
<section id="stills"></section><details><summary>Capture scope and measured evidence</summary><pre id="evidence"></pre></details><footer>1440 × 900 · First-person eye height · Daylight and dusk · Local authored Blender assets</footer></main>
<script>const groups=__DATA__;let frames=[],timer=null;const el=id=>document.getElementById(id);
function stop(){clearInterval(timer);timer=null;el('play').textContent='Play'}
function show(src,label){el('hero').src=src;el('caption').textContent=label}
function seek(){if(frames.length)show(frames[Number(el('frame').value)],`${el('route').value.replaceAll('_',' ')} · ${Number(el('frame').value)+1}/${frames.length}`)}
function select(){stop();const g=groups[Number(el('seed').value)];el('stills').replaceChildren();el('route').replaceChildren();frames=[];el('frame').max=0;
for(const [id,images]of Object.entries(g.walks)){const option=new Option(id.replaceAll('_',' '),id);el('route').add(option)}
for(const src of g.stills){const label=src.split('/').pop().replace('.png','').replaceAll('_',' ').replaceAll('-',' ');const b=document.createElement('button');b.className='thumb';const img=document.createElement('img');img.src=src;img.loading='lazy';img.alt=label;const text=document.createElement('span');text.textContent=label;b.append(img,text);b.onclick=()=>{stop();show(src,label)};el('stills').append(b)}
el('evidence').textContent=JSON.stringify(g.manifest,null,2);if(g.stills.length)show(g.stills[0],g.name+' · actual world');el('walk').disabled=!el('route').options.length}
groups.forEach((g,i)=>el('seed').add(new Option(g.name.replace('-',' '),String(i))));el('seed').onchange=select;
el('walk').onclick=()=>{stop();frames=groups[Number(el('seed').value)].walks[el('route').value]||[];el('frame').max=Math.max(0,frames.length-1);el('frame').value=0;seek()};
el('frame').oninput=()=>{stop();seek()};el('play').onclick=()=>{if(timer){stop();return}if(!frames.length)el('walk').click();if(!frames.length)return;el('play').textContent='Pause';timer=setInterval(()=>{el('frame').value=(Number(el('frame').value)+1)%frames.length;seek()},250)};select();</script></html>"""
    (OUT / "index.html").write_text(page.replace("__DATA__", data), encoding="utf-8")
    print(f"Cataclysm gallery: {len(groups)} review groups, {sum(len(g['stills']) for g in groups)} stills; {OUT / 'index.html'}")


if __name__ == "__main__":
    main()
