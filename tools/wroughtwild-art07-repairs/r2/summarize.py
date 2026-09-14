"""Validate repeated R2 observations and write an encoding-safe cost derivative."""
import argparse
import statistics
from pathlib import Path
from measure import BUILD, read, write

FIELDS=['scene','lighting','samples','camera','target','resources','resource_ids_sha256','chunks']
COSTS=[('Textures MiB','texture_bytes_total_loaded',2**20),('Buffers MiB','buffer_bytes_total_loaded',2**20),('Video allocations MiB','video_bytes_total_loaded',2**20),('Unique scene triangles including hidden','scene_unique_triangles',1),('Unique scene meshes including hidden','scene_unique_meshes_including_hidden',1)]

def span(values):
    return {'min':min(values),'median':statistics.median(values),'max':max(values),'each':values}

def reports(version,mode,renderer):
    found=[]
    for path in sorted((BUILD/version/'runtime/evidence').glob('benchmark-'+mode+'-'+renderer+'-benchmark-*/report.json')):
        result=read(path)
        assert result['failures']==0,str(path)
        assert result['viewport']=='(1440, 900)' and result['vsync']==0 and result['msaa']==2,str(path)
        assert len(result['samples'])==8
        for sample in result['samples']:
            assert sample['samples']==300 and len(sample['wall_samples_ms'])==300
            assert len(sample['warmup_samples_ms'])==120
            assert sample['frame_worst_ms']==max(sample['wall_samples_ms'])
        found.append((path,result))
    assert len(found)>=3,(version,mode,renderer,len(found))
    return found

def main(before,after,out):
    result={'conditions':'Three or more fresh processes per mode/backend; paired paid checkpoint/cameras/resources, 1440x900, 4x MSAA, vsync off, 120 warmup and 300 settled samples per view/light. Import, first-use and settled frames are separate. Current-device costs do not establish minimum-hardware acceptance.','renderers':{}}
    lines=['# ART-07R2 measured costs','',result['conditions'],'']
    for renderer in ['forward_plus','gl_compatibility']:
        groups={'art-off':reports(before,'baseline',renderer),'G1':reports(before,'art',renderer),'R2':reports(after,'art',renderer),'R2 art-off':reports(after,'baseline',renderer)}
        assert len({len(v) for v in groups.values()})==1
        reference=groups['G1'][0][1]
        for items in groups.values():
            for path,item in items:
                for field in ['gpu','cpu','gpu_api','engine','max_fps']:assert item[field]==reference[field],(path,field)
                for a,b in zip(item['samples'],reference['samples']):
                    for field in FIELDS:assert a[field]==b[field],(path,field)
        data={'device':{k:reference[k] for k in ['gpu','gpu_vendor','gpu_api','cpu','os','engine','viewport','msaa','vsync','max_fps']},'modes':{}}
        lines += [f'## {renderer}','',f"Actual device: {reference['gpu']} / {reference['cpu']}; {reference['gpu_api']}.",'','| Mode | Each setup, seconds | Setup min / median / max, seconds |','| --- | --- | --- |']
        for mode,items in groups.items():
            setup=span([item['setup_elapsed_ms']/1000 for _,item in items])
            data['modes'][mode]={'reports':[str(path) for path,_ in items],'setup_seconds':setup,'world_build_ms':span([r['world_build_ms'] for _,r in items]),'restore_ms':span([r['restore_ms'] for _,r in items]),'loaded_costs':{key:span([s['cost'][key]/divisor for _,r in items for s in r['samples']]) for _,key,divisor in COSTS},'views':[]}
            lines.append('| '+mode+' | '+' / '.join(f'{x:.3f}' for x in setup['each'])+' | '+' / '.join(f'{setup[k]:.3f}' for k in ['min','median','max'])+' |')
            for index,source in enumerate(reference['samples']):
                entries=[item['samples'][index] for _,item in items]
                data['modes'][mode]['views'].append({'scene':source['scene'],'lighting':source['lighting'],'frame_median_ms':span([e['frame_median_ms'] for e in entries]),'frame_p95_ms':span([e['frame_p95_ms'] for e in entries]),'frame_worst_ms':span([e['frame_worst_ms'] for e in entries]),'focus_ms':span([e['focus_ms'] for e in entries]),'warmup_worst_ms':span([max(e['warmup_samples_ms']) for e in entries])})
        old=data['modes']['G1']['setup_seconds'];new=data['modes']['R2']['setup_seconds']
        data['median_setup_reduction_percent']=100*(1-new['median']/old['median'])
        data['setup_observed_ranges_do_not_overlap']=new['max']<old['min']
        lines += ['',f"Observed median setup reduction: {data['median_setup_reduction_percent']:.2f}%. Every R2 run below every G1 run: {data['setup_observed_ranges_do_not_overlap']}.",'','| Loaded cost | Art-off range | G1 range | R2 range | R2 art-off range |','| --- | --- | --- | --- | --- |']
        for title,key,divisor in COSTS:
            vals=[data['modes'][m]['loaded_costs'][key] for m in groups]
            lines.append('| '+title+' | '+' | '.join(f"{v['min']:,.2f} to {v['max']:,.2f}" for v in vals)+' |')
        lines += ['','| Mode / view / light | Settled median min / median / max ms | Largest settled frame ms | Largest warmup frame ms | Largest focus call ms |','| --- | --- | --- | --- | --- | --- |']
        for mode in groups:
            for view in data['modes'][mode]['views']:
                m=view['frame_median_ms']
                lines.append(f"| {mode} / {view['scene']} / {view['lighting']} | {m['min']:.3f} / {m['median']:.3f} / {m['max']:.3f} | {view['frame_worst_ms']['max']:.3f} | {view['warmup_worst_ms']['max']:.3f} | {view['focus_ms']['max']:.3f} |")
        lines.append('')
        result['renderers'][renderer]=data
    write(out/'costs.json',result);write(out/'costs.md','\n'.join(lines))
    print('R2_COST_COMPARISON_VALID',str(out))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--before',default='v01');p.add_argument('--after',required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args();main(a.before,a.after,a.out)
