"""Compare matched actual captures, geometry and retained native resource state."""
import argparse
import hashlib
import json
import statistics
from pathlib import Path
from measure import BUILD, read, write


def state(row):
    # Auto-assigned node names may include per-process counters. The ordered mesh
    # transforms, visibility and every surface array remain the geometry oracle.
    return {'id':row['id'],'position':row['position'],'stock':row['stock'],'work':row['work'],'parts':[{k:p[k] for k in ['pose','visible','arrays_sha256']} for p in row['parts']]}


def main(before,after,out):
    from PIL import Image, ImageChops, ImageStat
    result={'comparisons':[],'scope':'Actual same-camera fixed-60-cadence captures. Pixel differences are reported, not hidden or accepted by an invented threshold. Exact geometry/native assertions are separate from owner visual review.'}
    for renderer in ['forward_plus','gl_compatibility']:
        relative='runtime/evidence/views-art-'+renderer+'-views-art-'+renderer
        a=BUILD/before/relative;b=BUILD/after/relative
        ra=read(a/'report.json');rb=read(b/'report.json')
        assert ra['failures']==rb['failures']==0
        assert len(ra['camera_audits'])==len(rb['camera_audits'])
        for x,y in zip(ra['camera_audits'],rb['camera_audits']):
            assert (x['view'],x['lighting'])==(y['view'],y['lighting'])
            xs=[state(r) for r in x['inventory']['resources']];ys=[state(r) for r in y['inventory']['resources']]
            assert xs==ys,(renderer,x['view'],x['lighting'],'resource geometry/state mismatch')
            assert x['inventory']['geometry']==y['inventory']['geometry'],(renderer,x['view'],'unique retained geometry mismatch')
            name=x['view']+'-'+x['lighting']+'.png'
            ai=Image.open(a/name).convert('RGB');bi=Image.open(b/name).convert('RGB')
            assert ai.size==bi.size==(1440,900)
            diff=ImageChops.difference(ai,bi);stats=ImageStat.Stat(diff)
            alpha_diff=ImageChops.difference(Image.open(a/name).convert('RGBA').getchannel('A'),Image.open(b/name).convert('RGBA').getchannel('A'))
            hist=diff.histogram();pixels=ai.width*ai.height
            result['comparisons'].append({'renderer':renderer,'view':x['view'],'lighting':x['lighting'],'before':str(a/name),'after':str(b/name),'before_sha256':hashlib.sha256((a/name).read_bytes()).hexdigest(),'after_sha256':hashlib.sha256((b/name).read_bytes()).hexdigest(),'width':ai.width,'height':ai.height,'rgb_mean_absolute_difference_255':sum(stats.mean)/3,'rgb_max_difference_255':max(e[1] for e in stats.extrema),'rgb_changed_channel_values':sum(sum(hist[i*256+1:(i+1)*256]) for i in range(3)),'alpha_max_difference_255':alpha_diff.getextrema()[1],'channel_fraction_over_2':sum(sum(hist[i*256+3:(i+1)*256]) for i in range(3))/(pixels*3),'resource_count':len(xs),'exact_resource_geometry_state':True,'retained_geometry':x['inventory']['geometry'],'before_cost':x['cost'],'after_cost':y['cost']})
    write(out/'visual-geometry.json',result)
    print('R2_MATCHED_CAPTURE_AND_GEOMETRY_CHECKED',len(result['comparisons']))
    print('RGB_MAE_MIN_MEDIAN_MAX',min(r['rgb_mean_absolute_difference_255'] for r in result['comparisons']),statistics.median(r['rgb_mean_absolute_difference_255'] for r in result['comparisons']),max(r['rgb_mean_absolute_difference_255'] for r in result['comparisons']))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--before',default='v01');p.add_argument('--after',default='v03');p.add_argument('--out',type=Path,required=True);a=p.parse_args();main(a.before,a.after,a.out)
