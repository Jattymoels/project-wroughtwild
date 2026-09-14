"""Verify inherited assertions, display-only wrappers and owned Python syntax."""
import argparse
import ast
from measure import BUILD, TOOLS, read, write
from source import sha


def main(version,out):
    base=BUILD/version;game=base/'runtime/game';prepared=read(base/'prepared.json');rows=[]
    for row in read(base/'source-replay-derivatives.json'):
        original=game/row['source'];actual=game/row['derivative']
        assert sha(original)==row['source_sha256']==prepared['original_files']['game/'+row['source']]['sha256']
        reverse=actual.read_text(encoding='utf-8-sig')
        for old,new in reversed(row['substitutions']):reverse=reverse.replace(new,old)
        assert reverse==original.read_text(encoding='utf-8-sig'),row['derivative']
        rows.append({'path':row['derivative'],'sha256':sha(actual),'all_original_assertions_and_logic_preserved':True,'allowed_substitutions':row['substitutions']})
    for ident,scene in [('paid','g1/paid')]+[(s,'tests/'+s) for s in ['living_frontier_flow','living_frontier_wave2_flow','living_frontier_green_flow','living_frontier_heat_flow']]:
        actual=game/('r2/native_'+ident+'.gd')
        source=game/(scene+'.gd')
        assert sha(source)==prepared['original_files']['game/'+scene+'.gd']['sha256']
        lines=['extends "res://'+scene+'.gd"','func _ready():','\tsuper._ready()','\tget_window().size=Vector2i(1440,900)','\tget_viewport().msaa_3d=Viewport.MSAA_4X','\tDisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)']
        assert actual.read_text().splitlines()==lines,str(actual)
        rows.append({'path':actual.relative_to(game).as_posix(),'sha256':sha(actual),'inherits_all_original_assertions':True,'display_settings':[1440,900,'MSAA_4X','VSYNC_DISABLED']})
    python=[]
    for path in sorted(TOOLS.glob('*.py')):
        ast.parse(path.read_text(encoding='utf-8-sig'),filename=str(path))
        python.append({'path':path.name,'sha256':sha(path),'ast_parse':True})
    write(base/out,{'source_replays_and_wrappers':rows,'python':python,'scope':'Static preservation and syntax check. Actual engine outcomes are separately indexed; this is not an engine run.'})
    print('R2_ASSERTIONS_AND_WRAPPERS_VERIFIED',len(rows),'PYTHON_PARSED',len(python))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);p.add_argument('--out',default='analysis/harness-source-proof.json');a=p.parse_args();main(a.version,a.out)
