"""Native full-world checks use actual renderers with deterministic inspection cadence."""
import argparse
from measure import BUILD, write
from source import sha

def main(version):
    base=BUILD/version;game=base/'runtime/game';records=[]
    for ident,scene in [('paid','g1/paid')]+[(s,'tests/'+s) for s in ['living_frontier_flow','living_frontier_wave2_flow','living_frontier_green_flow','living_frontier_heat_flow']]:
        source='res://'+scene+'.gd';name='r2/native_'+ident
        body='extends "'+source+'"\nfunc _ready():\n\tsuper._ready()\n\tget_window().size=Vector2i(1440,900)\n\tget_viewport().msaa_3d=Viewport.MSAA_4X\n\tDisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)\n'
        write(game/(name+'.gd'),body)
        write(game/(name+'.tscn'),(game/(scene+'.tscn')).read_text().replace(source,'res://'+name+'.gd'))
        records.append({'source':scene+'.gd','source_sha256':sha(game/(scene+'.gd')),'wrapper':name+'.gd','scope':'Inherit all original assertions and native flow. Configure inspection display after the synchronous parent ready method and before its deferred exercise.'})
    write(base/'native-renderer-wrappers.json',records)
    print('R2_NATIVE_RENDERER_WRAPPERS',len(records))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
