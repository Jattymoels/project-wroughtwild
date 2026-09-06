param(
    [string]$Godot = 'C:/Users/Matty/Godot/Godot_v4.5-stable_win64_console.exe',
    [string]$Runtime = 'runtime',
    [switch]$Prepare,
    [switch]$Import,
    [switch]$Full,
    [switch]$Smoke,
    [switch]$Rendered,
    [string[]]$Scenes = @('first_hour_journey'),
    [string]$SceneArguments = '',
    [int]$TimeoutSeconds = 180
)
# INT-01 and targeted reliability reviews use copied content and isolated user data. They never
# read a normal save or stop an editor/game belonging to the owner.
$ErrorActionPreference = 'Stop'
$intensiveRepo = Split-Path $PSScriptRoot
if ($Runtime -notmatch '^[a-zA-Z0-9_-]+$') { throw 'Runtime must be a simple directory name.' }
$intensiveRoot = Join-Path $intensiveRepo 'build/first-hour'
$intensiveCopy = Join-Path $intensiveRoot $Runtime
$intensiveGame = Join-Path $intensiveCopy 'game'
$intensiveLogs = Join-Path $intensiveRoot ('logs/' + $Runtime)
New-Item -ItemType Directory -Force -Path $intensiveLogs | Out-Null
if ($Prepare) {
    foreach ($intensiveFolder in @('game','data')) {
        & robocopy (Join-Path $intensiveRepo $intensiveFolder) (Join-Path $intensiveCopy $intensiveFolder) /E /XD .godot /NFL /NDL /NJH /NJS /NP | Out-Null
        if ($LASTEXITCODE -ge 8) { throw "Copy failed: $intensiveFolder" }
    }
}
if (-not (Test-Path -LiteralPath (Join-Path $intensiveGame 'project.godot'))) { throw 'Prepare an isolated project first.' }
# The historical world checkpoint fixture expects its review output directory
# to exist. Provision it inside the copied project, not the owner's build tree.
New-Item -ItemType Directory -Force -Path (Join-Path $intensiveCopy 'build/strange-frontier') | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $intensiveCopy 'build/codex-aesthetic') | Out-Null
$intensiveAppData = Join-Path $intensiveRoot ('appdata/' + $Runtime)
New-Item -ItemType Directory -Force -Path $intensiveAppData | Out-Null
$priorIntensiveAppData = $env:APPDATA
try {
    $env:APPDATA = $intensiveAppData
    function Invoke-IntensiveCheck([string]$Name, [string]$Arguments) {
        $intensiveOut = Join-Path $intensiveLogs ($Name + '.out.log')
        $intensiveErr = Join-Path $intensiveLogs ($Name + '.err.log')
        $intensiveProcess = Start-Process -FilePath $Godot -ArgumentList "--path `"$intensiveGame`" $Arguments" -WindowStyle Hidden -RedirectStandardOutput $intensiveOut -RedirectStandardError $intensiveErr -PassThru
        $intensiveHandle = $intensiveProcess.Handle
        $intensiveWatch = [Diagnostics.Stopwatch]::StartNew()
        while (-not $intensiveProcess.WaitForExit(1000)) {
            if ($intensiveWatch.Elapsed.TotalSeconds -gt $TimeoutSeconds) {
                foreach ($intensiveChild in (Get-CimInstance Win32_Process -Filter "ParentProcessId = $($intensiveProcess.Id)")) {
                    Stop-Process -Id $intensiveChild.ProcessId -Force -ErrorAction SilentlyContinue
                }
                Stop-Process -Id $intensiveProcess.Id -Force -ErrorAction SilentlyContinue
                throw "$Name timed out; see $intensiveLogs"
            }
        }
        $intensiveOutput = (Get-Content -LiteralPath $intensiveOut,$intensiveErr -ErrorAction SilentlyContinue) -join "`n"
        $intensiveOutput -split "`n" | Select-String -Pattern 'CODEX_|checks|FAIL|SCRIPT ERROR|ERROR:' | ForEach-Object { $_.Line }
        if ($intensiveProcess.ExitCode -ne 0 -or $intensiveOutput -match '(?m)^(SCRIPT ERROR|FAIL)' -or ($Name -ne 'unit' -and $intensiveOutput -match '(?m)^ERROR:')) { throw "$Name failed ($($intensiveProcess.ExitCode)); see $intensiveLogs" }
        Write-Output "PASS $Name"
    }
    if ($Import) { Invoke-IntensiveCheck 'import' '--headless --import' }
    if ($Full) {
        # Run the committed shell pipeline's scene list using the installed
        # Windows executable, plus the first-hour fixtures added by this pass.
        Invoke-IntensiveCheck 'unit' '--headless --script res://tests/run_tests.gd'
        Invoke-IntensiveCheck 'art' '--headless --script res://tests/art_checks.gd'
        $intensivePipeline = Get-Content (Join-Path $intensiveGame 'run_headless_checks.sh') -Raw
        $intensiveScenes = [regex]::Matches($intensivePipeline,'res://(?:tests|experiments)/[a-z_]+\.tscn') | ForEach-Object Value | Select-Object -Unique
        foreach ($intensiveScene in $intensiveScenes) { Invoke-IntensiveCheck ([IO.Path]::GetFileNameWithoutExtension($intensiveScene)) "--headless $intensiveScene" }
        # These two-process checks cannot be collapsed into the unique scene
        # list: the reader must start after its writer process has exited.
        Invoke-IntensiveCheck 'loose_drop_write' '--headless res://tests/loose_drop_save.tscn -- --write-checkpoint'
        Invoke-IntensiveCheck 'loose_drop_read' '--headless res://tests/loose_drop_save.tscn -- --read-checkpoint'
        Invoke-IntensiveCheck 'world_drop_write' '--headless res://tests/first_hour_journey.tscn -- --pickup-probe'
        Invoke-IntensiveCheck 'world_drop_read' '--headless res://tests/first_hour_journey.tscn -- --pickup-restore'
        foreach ($intensiveIdentity in @('offence','guard','sustain','tempo')) { Invoke-IntensiveCheck "foundry_${intensiveIdentity}_identity" "--headless res://tests/foundry_${intensiveIdentity}_identity.tscn" }
        Invoke-IntensiveCheck 'smoke' '--headless --quit-after 120'
    }
    foreach ($intensiveScene in $Scenes) {
        if ($intensiveScene -notmatch '^[a-zA-Z0-9_]+$') { throw 'Scene must be a test basename.' }
        $intensiveFlags = if ($Rendered) { '--position -9999,-9999' } else { '--headless' }
        Invoke-IntensiveCheck $intensiveScene "$intensiveFlags res://tests/$intensiveScene.tscn -- $SceneArguments"
    }
    if ($Smoke -and -not $Full) { Invoke-IntensiveCheck 'smoke' '--headless --quit-after 120' }
    if ($Rendered -and $Runtime -ne 'baseline') {
        $intensiveCards = foreach ($intensivePanel in @('forge-kit','equipment','pack','guide','building','foundry')) {
            foreach ($intensiveHeight in @(720,1080)) {
                $intensiveImage = "$intensivePanel-$intensiveHeight.png"
                if (Test-Path -LiteralPath (Join-Path $intensiveCopy "captures/$intensiveImage")) {
                    "<section><h2>$intensivePanel · ${intensiveHeight}p</h2><div class='pair'><figure><figcaption>Before</figcaption><a href='baseline/captures/$intensiveImage'><img loading='lazy' src='baseline/captures/$intensiveImage'></a></figure><figure><figcaption>After</figcaption><a href='$Runtime/captures/$intensiveImage'><img loading='lazy' src='$Runtime/captures/$intensiveImage'></a></figure></div></section>"
                }
            }
        }
        $intensiveHtml = @"
<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>First-hour clarity review</title>
<style>body{background:#1b1916;color:#eee2cf;font:16px/1.5 system-ui;margin:2rem}h1,h2{font-weight:600}h2{font-size:1.1rem}.pair{display:grid;grid-template-columns:1fr 1fr;gap:1rem}figure{margin:0}img{width:100%;border:1px solid #655745}section{margin:2rem 0}figcaption{color:#c8bba6}a{color:inherit}@media(max-width:850px){.pair{grid-template-columns:1fr}}</style>
<h1>First-hour clarity</h1><p>Matched seed 77, class and supplied review stock. Click an image for full resolution. These captures review panel presentation; the separate paid journey checks the resource economy.</p>
$($intensiveCards -join "`n")
<section><h2>Paid first-home journey</h2><p>Gathered materials supplied the bench, yard, forge, first ingot, shelter and chest. Travel was accelerated for the check. <a href="$Runtime/game/first-hour-journey.txt">Journey notes</a>.</p><a href="$Runtime/game/first-hour-home.png"><img style="max-width:1100px" loading="lazy" src="$Runtime/game/first-hour-home.png" alt="The small home built with normally gathered and paid materials"></a></section>
</html>
"@
        [IO.File]::WriteAllText((Join-Path $intensiveRoot 'index.html'),$intensiveHtml)
    }
} finally { $env:APPDATA = $priorIntensiveAppData }
