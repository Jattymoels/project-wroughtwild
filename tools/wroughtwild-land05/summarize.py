"""Summarize the retained bounded lakeside traces; never launch a benchmark."""
import json, hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/'build/land05'
summary={"scope":"Chosen seed 77 V12, 48.828m Scarwater outlook path out/back. Unknown owner seed/route. First process each run; existing driver cache retained. 1280x720 Forward+, VSync off, 120fps cap. Staging/setup separate. Timing spans overlap, never sum them."}
for label,prefix in [('before','before-'),('filter_only','intermediate-'),('final','')]:
    report=json.loads((OUT/(prefix+'diagnostic-checks.json')).read_text())
    path=Path(report['trace']);raw=path.read_bytes();trace=json.loads(raw)
    record={"entry_ms":report['setup_ms'],"retention":report['retention'],"trace":str(path),"trace_sha256":hashlib.sha256(raw).hexdigest(),"hardware":trace['metadata'],"checks":report['checks'],"failures":report['failures'],"windows":{}}
    for window in ['first_walk','turnaround','revisit','stationary','staged_arrival']:
        frames=[f for f in trace['frames'] if f.get('land05_window')==window]
        values=sorted(f['frame_ms'] for f in frames)
        phases={}
        for frame in frames:
            for event in frame.get('arrivals',[]):
                name=event['phase'];phases[name]=max(phases.get(name,0),event['duration_ms'])
        record['windows'][window]={"frames":len(values),"median_ms":values[int((len(values)-1)*.5)],"p95_ms":values[int((len(values)-1)*.95)],"max_ms":max(values),"over_33_3_ms":sum(v>100/3 for v in values),"phase_max_ms":phases,"slowest_frames":sorted(frames,key=lambda f:f['frame_ms'],reverse=True)[:3]}
    summary[label]=record
(OUT/'timing-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
print(json.dumps({k:{w:v['max_ms'] for w,v in summary[k]['windows'].items()} for k in ['before','filter_only','final']},indent=2))
