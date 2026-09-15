"""Summarize retained completed traces; never launches or changes the game."""
import json, statistics
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/play03-group'
def stats(rows):
    times=sorted(x['frame_ms'] for x in rows)
    return {'frames':len(times),'median_ms':statistics.median(times),'p95_ms':times[min(int(.95*len(times)),len(times)-1)],'max_ms':max(times)} if times else {}
def row(x):
    return {k:v for k,v in x.items() if k in ['frame','frame_ms','draw_process_frame','draw_wall_ms','process_to_draw_ms','chunk_tick_ms','resource_tick_ms','physics_callbacks_ms','physics_ticks','resource_arrival_visual','resource_arrival_max_ms','ensure_area_ms','player_physics_ms']}
def read(job):
    r=json.loads((OUT/job/'report.json').read_text())
    t=json.loads(Path(r['trace']).read_text()); rows=t['frames']
    i=next(i for i,x in enumerate(rows) if any(e['phase']=='group_horn' for e in x.get('arrivals',[])))
    phases={}
    for e in rows[i]['arrivals']:
        phases.setdefault(e['phase'],[]).append(e['duration_ms'])
    approach=[x for x in rows if r['walk_start_frame']<=x['frame']<=r['trigger_frame']]
    recovery=[x for x in rows[i+1:] if x['frame']<r['recovery_end_frame']]
    startup=[e for x in rows for e in x.get('arrivals',[]) if e['phase']=='roster_preparation']
    initial=next(x for x in rows if any(e['phase']=='fixture_position' for e in x.get('arrivals',[])))
    settle=[x for x in rows if initial['frame']<x['frame']<r['walk_start_frame']]
    return {'report':r,'hardware':t['metadata'],'arrival':row(rows[i]),'next_interval':row(rows[i+1]),'group_members':sum(len(p['ids']) for p in r['group']),
      'arrival_phases':{k:{'count':len(v),'total_ms':sum(v),'max_ms':max(v)} for k,v in phases.items()},
      'approach':stats(approach),'recovery':stats(recovery),'slow_recovery':[row(x) for x in recovery if x['frame_ms']>30],'slow_approach':[row(x) for x in approach if x['frame_ms']>30],
      'preparation':startup,'fixture_interval':row(initial),'settling':stats(settle),
      'roster_draw_intervals':[{'id':p['id'],'rows':[row(x) for x in rows if p.get('frame',-10)<=x['frame']<=p.get('frame',-10)+2]} for p in r.get('roster',[])]}
a=read('before');b=read('after')
assert a['report']['group']==b['report']['group'] and a['report']['initial_position']==b['report']['initial_position']
assert a['group_members']==b['group_members']==30
assert a['report']['failures']==0
# Retain the observed rendered fixture teardown failure honestly. The corrected
# native abandon/end/restore is checked in lifecycle, not a repeated renderer run.
assert b['report']['failures']==1
result={'before':a,'after':b,'lifecycle':json.loads((OUT/'lifecycle/report.json').read_text()),'restored_trial':json.loads((OUT/'restore/report.json').read_text()),
 'rendered_limit':'Final rendered pass: 37/38 checks; temporary human trial was not abandoned before restoration. Corrected teardown passed in the 120-check headless lifecycle; rendered group/roster data retained, no claim of zero failures.',
 'previous_commit':'039bccf49e6c99c1d40ec78102ccf6cc31efcc0e','native_dll_sha256':'fbf7067477d63693e35b5d15ccff0bbad86be7586d679e284a44c843b0404e2b'}
for job in ['lifecycle','restore']:
    r=json.loads((OUT/job/'report.json').read_text());t=json.loads(Path(r['trace']).read_text())
    result['lifecycle' if job=='lifecycle' else 'restored_trial']['preparation']=[e for x in t['frames'] for e in x.get('arrivals',[]) if e['phase']=='roster_preparation']
assert result['lifecycle']['failures']==result['restored_trial']['failures']==0
result['boss_display']=json.loads((OUT/'boss_display/report.json').read_text())
result['boss_before_human_cache']=json.loads((OUT/'boss_display/uncached-human-report.json').read_text())
assert result['boss_display']['failures']==0
path=ROOT/'tools/wroughtwild-play03-group/evidence/summary.json';path.parent.mkdir(exist_ok=True)
path.write_text(json.dumps(result,indent=2)+'\n')
for tag,d in [('before',a),('after',b)]:
    print(tag, 'frame',d['arrival'], 'approach',d['approach'],'recovery',d['recovery'],'settle',d['settling'],'fixture',d['fixture_interval'])
print('prep',b['preparation']);print('slow recovery',b['slow_recovery']);print('continued',result['lifecycle']['preparation']);print('restored',result['restored_trial']['preparation'])
