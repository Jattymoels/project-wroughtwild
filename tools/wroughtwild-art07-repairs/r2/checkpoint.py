"""Restore only the R2 disposable paid-test fixture from its pinned original bytes."""
import argparse
import copy
import struct
from pathlib import Path
from measure import BUILD, read, write
from source import sha

def main(version):
    base=BUILD/version;prepared=read(base/'prepared.json');name='game/g1/paid-home.json'
    source=Path(prepared['source']['path'])/name;target=base/'runtime'/name
    expected=prepared['original_files'][name]['sha256'];assert sha(source)==expected
    before=sha(target)
    if before!=expected:
        current=read(target)
        reports=list((base/'runtime/evidence').glob('paid-*-r2-*/paid.json'))
        matched=[]
        for report in reports:
            record=read(report)
            if not isinstance(record.get('paid'),dict) or record.get('failures')!=0:continue
            expected_state=copy.deepcopy(record['paid']);converted=[]
            # SaveManager uses JSON full_precision=true; paid.gd's report uses
            # the default shorter float rendering. Position is a native Vector3.
            # Recover only its exact Float32 values; compare every other value.
            for index,value in enumerate(expected_state['player']['position']):
                native=struct.unpack('<f',struct.pack('<f',value))[0]
                expected_state['player']['position'][index]=native
                if native!=value:converted.append({'path':'player/position/'+str(index),'report_value':value,'native_float32':native})
            if expected_state==current:matched.append({'report':str(report),'sha256':sha(report),'float32_position_recovery':converted})
        assert matched,'Only restore a fixture written by this task successful paid checks; all persisted values must match'
        preserved=base/'analysis/paid-fixture-written-by-test.json'
        assert not preserved.exists();preserved.parent.mkdir(parents=True,exist_ok=True)
        preserved.write_bytes(target.read_bytes());assert sha(preserved)==before
        write(base/'analysis/paid-fixture-origin-proof.json',{'written_fixture_sha256':before,'matches':matched,'scope':'Exact full state equality after recovering native Float32 position components from the report short JSON float rendering. Original SaveManager full-precision bytes are preserved separately; no native test assertion changes.'})
        target.write_bytes(source.read_bytes())
    assert sha(target)==expected
    write(base/'paid-fixture-restored.json',{'path':str(target),'before_sha256':before,'after_sha256':expected,'source':str(source),'scope':'Original shared G1 checkpoint restored in the disposable R2 runtime after original paid.gd test wrote its own checkpoint. Normal user saves and sealed originals were never touched.'})
    print('R2_DISPOSABLE_PAID_FIXTURE_PIN_RESTORED',expected)

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
