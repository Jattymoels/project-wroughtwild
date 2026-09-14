"""Check the final UTF-8 player replay against all previously validated native states."""
import os,subprocess,sys
from pathlib import Path
from inspect_inputs import ROOT,read,sha
from compose import write
out=ROOT/'build/art07-repairs/r8/v01';env={**os.environ,'PYTHONUTF8':'1'};proof=[]
for renderer in ['forward_plus','gl_compatibility']:
    final=out/'evidence'/('fingerprints-final-'+renderer+'.json')
    paths=[out/'runtime/evidence'/('paid-'+mode+'-r8-'+mode+'-'+renderer+'-final')/'paid.json' for mode in ['art','baseline']]
    for p in paths:
        report=read(p);assert report['count']==865 and report['failures']==0,p
    subprocess.run([sys.executable,'-B',str(ROOT/'tools/wroughtwild-art07/g1/fingerprints.py'),*map(str,paths),str(final)],check=True,env=env)
    before=read(out/'evidence'/('fingerprints-'+renderer+'.json'));after=read(final)
    assert before['stages']==after['stages'] and before['walk_metres']==after['walk_metres']
    probe=out/'evidence'/('probes-final-'+renderer+'.json')
    paths=[out/'evidence'/('probe-'+mode+'-'+renderer+'-final')/'probe.json' for mode in ['art','baseline']]
    subprocess.run([sys.executable,'-B',str(ROOT/'tools/wroughtwild-art07/g1/probe_compare.py'),*map(str,paths),str(probe)],check=True,env=env)
    assert read(probe)==read(out/'evidence'/('probes-'+renderer+'.json'))
    proof.append({'renderer':renderer,'fingerprints':str(final),'fingerprints_sha256':sha(final),'probe':str(probe),'probe_sha256':sha(probe)})
write(out/'evidence/final-player-checks.json',{'all_stages_and_geography_match_prior':True,'checks':proof,'scope':'Fresh final-byte untraced art-on/off paid flows and probes in both renderers; full native stage fingerprints and controller walk equal the prior accepted runs. No test assertions changed.'})
print('R8_FINAL_PLAYER_STATES_MATCH')
