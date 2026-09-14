"""Compare the complete paid snapshots; expose the one engine-name difference.
Never omit a raw difference. The unchanged StationSite/SaveManager retain physical station_key and built state
separately from scene names; all other fields must remain exactly equal.
"""
import copy,json,re
from measure import OUT,write
E=OUT/'runtime/evidence'
def read(p):return json.loads(p.read_text())
def compare(a,b):
    result={'full_snapshot_equal':a==b,'raw_differences':[],'native_ownership_and_geography_equal':a==b}
    if a==b:return result
    aa=copy.deepcopy(a);bb=copy.deepcopy(b)
    assert len(aa['stations'])==len(bb['stations'])
    for index,(x,y) in enumerate(zip(aa['stations'],bb['stations'])):
        if x==y:continue
        x_name=x['name'];y_name=y['name']
        assert re.fullmatch(r'@StaticBody3D@[0-9]+',x_name) and re.fullmatch(r'@StaticBody3D@[0-9]+',y_name)
        assert x['station_key']==y['station_key'] and x['station_id']==y['station_id']=='forge_basic'
        y['name']=x['name'];assert x==y
        result['raw_differences'].append({'path':'stations/'+str(index)+'/name','before':x_name,'after':y_name,'station_key':x['station_key'],'classification':'Engine-generated scene name for a newly placed forge. Native ownership key, type, pose, rotation, upgrade and built flag are exactly equal. Save schema/code unchanged.'})
    assert len(result['raw_differences'])==1
    assert aa==bb,'Unexpected difference outside the fully reported generated forge name'
    result['native_ownership_and_geography_equal']=aa==bb
    return result
if __name__=='__main__':
    a=read(E/'r1-probe-before.json');b=read(E/'r1-probe-after.json')
    assert a['snapshot']==b['snapshot'] and a['geography_sha256']==b['geography_sha256']
    a=read(E/'paid-art-r1-before/paid.json');b=read(E/'paid-art-r1-after/paid.json')
    stages={key:compare(a[key],b[key]) for key in ['initial','paid','final']}
    assert stages['initial']['full_snapshot_equal']
    result={'full_probe_snapshot_equal':True,'finite_resource_records':len(read(E/'r1-probe-after.json')['snapshot']['resource_nodes']),'geography_sha256':read(E/'r1-probe-after.json')['geography_sha256'],'paid_snapshots':stages,'native_ownership_and_geography_equal':True,'checks_before':a['count'],'checks_after':b['count'],'walk_metres_before':a['walk']['metres'],'walk_metres_after':b['walk']['metres'],'raw_byte_equality_claimed':False,'original_native_assertions_changed':False,'authority_references':['game/scripts/save_manager.gd capture(): name and station_key separate fields; apply(): restores both','game/scripts/station_site.gd: station_key/player_built identify physical ownership; is_built uses station_id and unchanged sim knowledge']}
    write(OUT/'evidence/ownership-equivalence.json',result);print(json.dumps(result,indent=2))
