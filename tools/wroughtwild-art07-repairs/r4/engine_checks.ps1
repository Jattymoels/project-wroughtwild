# R4's bounded evidence pipeline. Never changes shared runners or original packages.
$ErrorActionPreference='Stop'
$r4Python='C:/Users/Matty/.cache/codex-runtimes/codex-primary-runtime/dependencies/python/python.exe'
$r4Out='build/art07-repairs/r4/v01'
$r4Mutex=[Threading.Mutex]::new($false,'Local\Wroughtwild-Art07-GPU')
$r4Held=$false
try {
 $r4Held=$r4Mutex.WaitOne(60000)
 if(-not $r4Held){Write-Output 'R4_DEFERRED: shared GPU remains occupied; no child launched.';exit 3}
 & ./tools/wroughtwild-art07-repairs/run.ps1 -Spec "$r4Out/trace-repeat-jobs.json"
 & ./tools/wroughtwild-art07-repairs/run.ps1 -Spec "$r4Out/soak-after-jobs.json"
 & $r4Python -c "import json,pathlib; p=pathlib.Path('build/art07-repairs/r4/v01'); d=json.loads((p/'users/soak-after/ART07G1/r4-soak.json').read_text()); assert d['checks']==156 and d['observed_playbacks_alive']==0; s=(p/'logs/soak-after.log').read_text(encoding='utf-8-sig'); assert not any(x in s for x in ['Leaked instance:','ObjectDB instances leaked','Orphan StringName:','SCRIPT ERROR:','ERROR:']); print('R4_SOAK_RELEASE_VERIFIED')"
 if($LASTEXITCODE -ne 0){throw 'R4 teardown preflight failed; fixtures remain unchanged.'}
 & $r4Python tools/wroughtwild-art07-repairs/r4/work.py patch
 if($LASTEXITCODE -ne 0){throw 'R4 hash-guarded patch failed.'}
 & ./tools/wroughtwild-art07-repairs/run.ps1 -Spec "$r4Out/after-jobs.json"
 & $r4Python -c "import pathlib,sys; sys.path.insert(0,'tools/wroughtwild-art07-repairs/r4'); from audit import diagnostic; p=pathlib.Path('build/art07-repairs/r4/v01/logs'); files=list((p/'after').glob('*.log')); assert len(files)==22; [(print(f.name),d:=diagnostic(f),b:=diagnostic(p/'before'/f.name), (None if d['markers']==b['markers'] and d['exit_code']==0 and not any(d[k] for k in ['failure','leaks','warnings','errors','orphan_string_names']) and len(d['cleanup'])==1 else sys.exit('R4 clean shutdown or unchanged assertions failed: '+str(f)))) for f in files]; print('R4_ALL_22_CLEAN_AND_UNCHANGED')"
 if($LASTEXITCODE -ne 0){throw 'R4 post-repair audit failed; full logs retained.'}
 & ./tools/wroughtwild-art07-repairs/run.ps1 -Spec "$r4Out/render-after-jobs.json"
} finally {
 if($r4Held){$r4Mutex.ReleaseMutex()}
 $r4Mutex.Dispose()
}
