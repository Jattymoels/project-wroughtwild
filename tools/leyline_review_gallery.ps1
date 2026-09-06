param([string]$Phase = 'after')
$ErrorActionPreference = 'Stop'
$leyGalleryRoot = Join-Path (Split-Path $PSScriptRoot) 'build/leyline-visual'
$leyBaseline = Get-Content -LiteralPath (Join-Path $leyGalleryRoot 'baseline/manifest.json') -Raw | ConvertFrom-Json
$leyAfter = Get-Content -LiteralPath (Join-Path $leyGalleryRoot "$Phase/manifest.json") -Raw | ConvertFrom-Json
$leyPairs = foreach ($leyView in $leyAfter.views) {
    $leyPrior = $leyBaseline.views | Where-Object id -eq $leyView.id | Select-Object -First 1
    if (-not $leyPrior) { throw "Missing matched baseline for $($leyView.id)" }
    [ordered]@{
        id = $leyView.id
        before = [ordered]@{ day = $leyPrior.day; dusk = $leyPrior.dusk }
        after = [ordered]@{ day = $leyView.day; dusk = $leyView.dusk }
    }
}
$leyPayload = ConvertTo-Json -InputObject @($leyPairs) -Depth 8 -Compress
# The two strings are embedded as JSON, not executed as shell commands.
$leyPhaseJson = ConvertTo-Json -InputObject $Phase -Compress
$leyHtml = @'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Wroughtwild · Leylines and rare resources</title>
<style>
:root{color-scheme:dark;font:16px/1.55 system-ui,sans-serif;background:#101715;color:#dddccf}
*{box-sizing:border-box}body{margin:0}main{max-width:1180px;margin:auto;padding:48px 24px 64px}
h1{font-size:clamp(28px,5vw,48px);font-weight:550;line-height:1.12;letter-spacing:-.035em;margin:12px 0 20px}
p{max-width:780px;color:#aab8af}.eyebrow{color:#badbe1;letter-spacing:.14em;font-size:12px;text-transform:uppercase}
.controls{position:sticky;top:0;background:#101715ed;z-index:3;padding:16px 0;display:flex;gap:10px;align-items:center;backdrop-filter:blur(12px)}
button{font:inherit;color:#aab8af;border:1px solid #45534c;background:transparent;border-radius:6px;padding:8px 20px;cursor:pointer}
button[aria-pressed=true]{background:#bbd9df;color:#101715;border-color:#bbd9df}.controls span{margin-left:auto;color:#aab8af;font-size:13px}
section{margin:34px 0 48px}h2{font-size:22px;font-weight:550;margin:0 0 12px;text-transform:capitalize}
.compare{position:relative;aspect-ratio:8/5;overflow:hidden;border:1px solid #38483f;border-radius:8px;background:#1e2722}
.compare img{position:absolute;inset:0;width:100%;height:100%;object-fit:cover}.before{clip-path:inset(0 50% 0 0)}
.divider{position:absolute;top:0;bottom:0;left:50%;width:2px;background:#e4eef0;pointer-events:none}
.label{position:absolute;bottom:12px;padding:3px 10px;background:#101715de;font-size:12px;color:#e1e5df;border-radius:3px}.left{left:12px}.right{right:12px}
input[type=range]{width:100%;accent-color:#bbd9df;margin:12px 0;cursor:ew-resize}
.metrics{display:flex;gap:24px;flex-wrap:wrap;font:13px/1.5 ui-monospace,monospace;color:#aab8af}.metrics b{color:#dce4db;font-weight:500}
small{color:#94a59b}footer{border-top:1px solid #34483b;padding-top:22px;color:#aab8af;font-size:13px}
@media(max-width:640px){main{padding:26px 14px}.controls span{display:none}.metrics{gap:8px 18px}}
</style></head><body><main>
<div class="eyebrow">Wroughtwild · Actual generated world · V5 / seed 1</div>
<h1>Fractured ground.<br>Something alive inside.</h1>
<p>Matched gameplay cameras show the leyline and rare-resource graphics pass. Drag each slider to compare the original presentation with the new finish. Character and gameplay interface are hidden for the review.</p>
<div class="controls"><button aria-pressed="true" data-light="day">Daylight</button><button aria-pressed="false" data-light="dusk">Dusk</button><span>Before ← drag → After</span></div>
<div id="views"></div>
<footer>1440 × 900 · Forward+ · FOV 75 · grounded eye height 1.65 m.<br>Per view: 90 warmup frames, then 600 uncapped samples; screenshot readback excluded. Values are observed wall-frame times and may include concurrent playthrough load. These static views do not certify moving-world streaming performance or resolve known cold-view hitches.</footer>
</main><script>
const pairs=__PAIRS__, phase=__PHASE__;
let light='day';
const titles={connected_leyline:'Exposed leyline',rare_lanternheart:'Lanternheart',rare_thrumroot:'Thrumroot',rare_stormglass:'Stormglass',rare_pullstone:'Pullstone',rare_ventlung:'Ventlung',struck_old_smithy:'The struck old smithy'};
const number=n=>Number(n).toFixed(2);
for(const pair of pairs){
 const section=document.createElement('section');section.dataset.id=pair.id;
 section.innerHTML=`<h2>${titles[pair.id]||pair.id.replaceAll('_',' ')}</h2><div class="compare"><img class="after" alt="After graphics pass"><img class="before" alt="Before graphics pass"><div class="divider"></div><span class="label left">Before</span><span class="label right">After</span></div><input type="range" min="0" max="100" value="50" aria-label="Compare ${titles[pair.id]||pair.id}"><div class="metrics"></div>`;
 const slider=section.querySelector('input');slider.addEventListener('input',()=>{section.querySelector('.before').style.clipPath=`inset(0 ${100-slider.value}% 0 0)`;section.querySelector('.divider').style.left=slider.value+'%'});
 document.getElementById('views').append(section);
}
function render(){
 for(const pair of pairs){
  const section=document.querySelector(`section[data-id="${pair.id}"]`), before=pair.before[light], after=pair.after[light];
  section.querySelector('.before').src=`baseline/${pair.id}-${light}.png`;
  section.querySelector('.after').src=`${phase}/${pair.id}-${light}.png`;
  section.querySelector('.metrics').innerHTML=`<span>Median <b>${number(before.median_ms)} → ${number(after.median_ms)} ms</b></span><span>p95 <b>${number(before.p95_ms)} → ${number(after.p95_ms)} ms</b></span><span>Draw calls <b>${before.draw_calls} → ${after.draw_calls}</b></span>`;
 }
 for(const button of document.querySelectorAll('[data-light]'))button.setAttribute('aria-pressed',String(button.dataset.light===light));
}
for(const button of document.querySelectorAll('[data-light]'))button.addEventListener('click',()=>{light=button.dataset.light;render()});render();
</script></body></html>
'@
$leyHtml = $leyHtml.Replace('__PAIRS__', $leyPayload).Replace('__PHASE__', $leyPhaseJson)
$leyGalleryPath = Join-Path $leyGalleryRoot 'index.html'
[IO.File]::WriteAllText($leyGalleryPath, $leyHtml, [Text.UTF8Encoding]::new($false))
Write-Output $leyGalleryPath
