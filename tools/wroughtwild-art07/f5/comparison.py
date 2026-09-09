"""Build a portable four-family comparison page from actual engine evidence."""
import sys,json,html
from pathlib import Path
package=Path(sys.argv[1]).resolve()
families={
'red':{'label':'Red / paid heat','purpose':'2 Salt buys 1 stored heat. The feeder separately pays clay and winding.','source':'02-source-ready-day','off':'03-source-light-off','device':'10-buffer-real-firing','material':'07-recovered-fragments','motion':'red-paid-firing.webp','size':'1.00 × 1.20 × 1.00 m'},
'white':{'label':'White / immediate request','purpose':'One lever request passes immediately. The receiver owns its winding.','source':'source-ready','off':'source-no-glow','device':'post-request','material':'white-mineral','motion':'white-request.webp','size':'0.65 × 1.18 × 0.55 m'},
'blue':{'label':'Blue / hold and release','purpose':'One request waits 3 active seconds. Pause and obstruction hold its exact progress.','source':'source-ready','off':'source-no-glow','device':'delay-held','material':'blue-flakes','motion':'blue-delay.webp','size':'0.65 × 1.18 × 0.55 m'},
'green':{'label':'Green / two requests','purpose':'Two distinct receiver branches each pay their own winding and ingredients.','source':'source-ready','off':'source-no-glow','device':'junction-unwound','material':'green-resin','motion':'green-junction.webp','size':'0.65 × 1.18 × 0.55 m'}}
template='''<!doctype html>
<html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Wroughtwild · Four retained colours</title>
<style>
:root{color-scheme:dark;font:16px/1.5 system-ui;color:#e6e6df;background:#181d1c}*{box-sizing:border-box}
body{max-width:1500px;margin:auto;padding:32px}header{max-width:900px}h1{font-size:36px;line-height:1.1;margin:8px 0 18px;font-weight:650}
p{color:#b9c4be}small,.eyebrow{color:#99ab9f}select,button{font:inherit;background:#2c3933;color:#fff;border:1px solid #728d7c;border-radius:6px;padding:9px 12px}
.controls{display:flex;flex-wrap:wrap;gap:20px;margin:24px 0;position:sticky;top:0;background:#181d1cee;padding:12px 0;z-index:2}
label{display:flex;gap:10px;align-items:center}.grid{display:grid;grid-template-columns:1fr 1fr;gap:22px}
article{border:1px solid #445249;border-radius:8px;overflow:hidden;background:#222b26}article img{display:block;width:100%;aspect-ratio:1.6;object-fit:contain;background:#121816}
.text{padding:18px 22px}h2{font-size:22px;margin:0}article p{margin:8px 0}a{color:#bcdfc8}.meta{font-size:13px}
footer{margin:32px 0;font-size:14px}code{background:#29332d;padding:2px 5px}#view-note{min-height:24px}
@media(max-width:800px){body{padding:18px}.grid{grid-template-columns:1fr}h1{font-size:29px}}
</style>
<header><div class="eyebrow">WROUGHTWILD / ART-07 F5</div><h1>Four colours, retained.</h1>
<p>The approved ART-04 source → recovered material → device families. These are actual Blender and Godot model renders from the F5 audit. Native controls remain in each standalone study.</p>
<p>All studies use native revision <code>56ce6bbe</code> and copied historical paid checkpoints. The comparison grants no materials, changes no geography and does not certify owner visual acceptance.</p></header>
<div class="controls"><label>View <select id="view">
<option value="device">Device / native state</option><option value="source">Ready source</option><option value="off">Source / emission off</option><option value="material">Recovered material</option><option value="blender">Packed Blender source</option><option value="motion">Paid request or firing / motion</option>
</select></label><label>Godot renderer <select id="renderer"><option value="evidence">Forward+</option><option value="evidence-compat">Compatibility</option></select></label><button id="reset">Restart clips</button></div>
<p id="view-note"></p><main class="grid" id="grid"></main>
<footer><p>Open a full-size image to inspect it. Motion is a replay of one paid recorded sequence; looping the file cannot repeat native production. Blender views are retained non-emissive material inspection. Each source body is 1.5 × 1.1 × 1.5 m; all dimensions use Godot X/Y/Z.</p>
<p>Native review: <code>&amp; './Launch review.ps1' -Colour white</code> (red / blue / green also supported). Use <code>-Compatibility</code> for the fallback renderer. Keys: 1 source, 2 device, 3 route, 4 recovered material; D day/shade, G emission, N/M/F detail, Space pause, R copied-checkpoint reset. See each original README for its native actions.</p>
<p><a href="manifest.json">Delivered file hashes</a> · <a href="conformance.json">Dependency, attachment and material contract</a> · <a href="README.md">Reproduction and limitations</a></p></footer>
<script>
const families=FAMILIES;
function render(){
const view=document.querySelector('#view').value,renderer=document.querySelector('#renderer').value;
document.querySelector('#view-note').textContent=view==='motion'?'Actual recorded native sequence. Native motion was captured separately from benchmarks.':view==='blender'?'Fresh-process Blender reopen of the unchanged packed editable masters.':'Actual Godot 4.5 · 1600 × 1000 · 4× MSAA · bloom off.';
document.querySelector('#grid').innerHTML=Object.entries(families).map(([c,f])=>{
const path=view==='blender'?c+'/evidence/packed-reopen.png':view==='motion'?c+'/evidence/'+(renderer==='evidence'?'forward-':'compat-')+f.motion:c+'/review/'+renderer+'/'+f[view]+'.png';
return '<article><a href="'+path+'"><img src="'+path+'" alt="'+f.label+' actual '+view+' model evidence"></a><div class="text"><h2>'+f.label+'</h2><p>'+f.purpose+'</p><div class="meta">Native device body '+f.size+' · <a href="'+c+'/original-README.md">Controls and original limitations</a></div></div></article>';
}).join('');
}
document.querySelector('#view').onchange=render;document.querySelector('#renderer').onchange=render;document.querySelector('#reset').onclick=render;render();
</script></html>'''
(package/'comparison.html').write_text(template.replace('FAMILIES',json.dumps(families)),encoding='utf-8')
print('F5_COMPARISON_PAGE_WRITTEN')
