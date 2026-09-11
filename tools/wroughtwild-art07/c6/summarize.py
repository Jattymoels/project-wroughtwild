"""Collect measured costs and original-source integrity without changing any input."""
import json, sys, re, subprocess
from pathlib import Path
import numpy as np
from PIL import Image
from prerequisites import sha, REVISION

root, review, out = [Path(p).resolve() for p in sys.argv[1:]]
model = json.loads((root/'kit-v06/model-report.json').read_text())
audit = json.loads((root/'audit-v06-rays.json').read_text())
result = {'base': REVISION, 'sources': {}, 'assets': {}, 'checks': {}, 'jobs': {}, 'periodic_texture_edges': {}}
for name, source in model['sources'].items():
    if 'path' not in source: continue
    path = Path(source['path'])
    assert sha(path) == source['sha256'], path
    relative = 'game/assets/authored/'+path.name
    import hashlib
    original = subprocess.check_output(['git','show',REVISION+':'+relative])
    assert hashlib.sha256(original).hexdigest() == source['sha256'], relative
    result['sources'][name] = source
for item in audit['exports']:
    name = item['file'].rsplit('-lod',1)[0]
    result['assets'].setdefault(name,[]).append(item)
for folder in ['current-checks','native-checks','selected-native-checks']:
    if not (root/folder).exists(): continue
    rows = []
    for path in sorted((root/folder).glob('*.log')):
        matches = re.findall(r'(\d+) checks, (\d+) failures',path.read_text())
        assert len(matches)==1 and int(matches[0][1])==0,path
        job = json.loads(path.with_suffix('.log.job.json').read_text())
        assert job['exit']==0
        rows.append({'name':path.name,'checks':int(matches[0][0]),'exit':0,'seconds':job['seconds']})
    result['checks'][folder] = {'jobs':rows,'total':sum(x['checks'] for x in rows)}
for folder in ['release-check','release-capture','release-walk','release-motion','release-benchmark']:
    for path in sorted((root/folder).glob('*.job.json')):
        job = json.loads(path.read_text());assert job['exit']==0,path
        stderr = Path(str(path).replace('.job.json','.stderr')).read_text()
        assert not re.search('SCRIPT ERROR|SHADER ERROR|Parse Error|Traceback',stderr),path
        if folder!='release-check':assert 'ERROR:' not in stderr,path
        job['stderr'] = stderr
        result['jobs'][folder+'/'+path.name] = job
for path in sorted((root/'kit-v06/textures').glob('*.png')):
    data = np.asarray(Image.open(path).convert('RGB'),dtype=float)
    horizontal = np.abs(np.diff(data,axis=1)).mean();vertical = np.abs(np.diff(data,axis=0)).mean()
    result['periodic_texture_edges'][path.name] = {'sha256':sha(path),'size':list(Image.open(path).size),'seam_x_mean_8bit':float(np.abs(data[:,0]-data[:,-1]).mean()),'interior_x_mean_8bit':float(horizontal),'seam_y_mean_8bit':float(np.abs(data[0]-data[-1]).mean()),'interior_y_mean_8bit':float(vertical)}
result['cook'] = json.loads((review/'cook.json').read_text())
result['root_contact'] = model['root_contact'];result['scar'] = model['scar']
result['packed_images'] = audit['packed_images']
out.write_text(json.dumps(result,indent=2)+'\n')
print('C6_SUMMARY_OK',len(result['assets']),{k:v['total'] for k,v in result['checks'].items()})
