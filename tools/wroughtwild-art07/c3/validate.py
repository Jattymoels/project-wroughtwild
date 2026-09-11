"""Small receipt index over recorded checks, without replacing their assertions."""
import ast,json,re,sys
from pathlib import Path
run=Path(sys.argv[1]).resolve();recipe=Path(__file__).parent
for path in recipe.glob('*.py'):ast.parse(path.read_text(),filename=str(path))
regression=[]
for path in sorted((run/'current-checks').glob('*.log')):
    found=re.findall(r'(\d+) checks, (\d+) failures',path.read_text(errors='replace'))
    assert len(found)==1 and int(found[0][1])==0,path
    regression.append({'log':str(path),'checks':int(found[0][0]),'failures':0})
assert len(regression)==14 and sum(r['checks'] for r in regression)==8225
jobs=[]
for folder in ['final-capture','final-motion','final-walk','final-native-v05','final-benchmark']:
    for path in sorted((run/folder).glob('*.job.json')):
        job=json.loads(path.read_text(encoding='utf-8-sig'))
        assert job['exit']==0,path
        jobs.append({'path':str(path),**job})
assert len(jobs)==14
audit=json.loads((run/'audit-v05.json').read_text())
assert len(audit['exports'])==23
report={'python_parse':True,'regression':regression,'regression_total':8225,'jobs':jobs,'audit_file':'audit-v05.json','audited_exports':23}
(run/'validation.json').write_text(json.dumps(report,indent=2)+'\n')
print('C3_VALIDATION_OK',len(jobs),'jobs;',sum(r['checks'] for r in regression),'regression checks')
