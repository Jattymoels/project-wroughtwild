"""Make labelled playback previews from actual engine-captured PNG frames only."""
import argparse
import hashlib
from pathlib import Path
from measure import BUILD, write


def sequence(source,destination,durations,scope,pattern="*.png"):
    from PIL import Image
    paths=sorted(source.glob(pattern))
    assert paths and not destination.exists(),str(source)
    frames=[];provenance=[]
    for path in paths:
        with Image.open(path) as image:
            assert image.size==(1440,900),str(path)
            frames.append(image.convert('RGB').resize((720,450),Image.Resampling.LANCZOS).convert('P',palette=Image.Palette.ADAPTIVE,colors=256))
        provenance.append({'path':str(path.resolve()),'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    destination.parent.mkdir(parents=True,exist_ok=True)
    times=[durations[i%len(durations)] for i in range(len(frames))]
    frames[0].save(destination,save_all=True,append_images=frames[1:],duration=times,loop=0,optimize=False,disposal=2)
    return {'preview':str(destination.resolve()),'preview_sha256':hashlib.sha256(destination.read_bytes()).hexdigest(),'preview_size':[720,450],'original_size':[1440,900],'frame_durations_ms':times,'source_frames':provenance,'scope':scope+' Preview is resized and palette-quantized GIF playback; original PNGs remain unchanged for visual review. No generated or retouched frames.'}


def main(version):
    base=BUILD/version;out=base/'analysis/motion'
    f4=base/'runtime/evidence/replays/f4/forward_plus'
    walk=base/'runtime/evidence/paid-art-forward_plus-r2-walk/walk'
    assert len(list(f4.glob('motion-*.png')))==60 and list(walk.glob('*.png'))
    rows=[sequence(f4,out/'native-work-pause-block.gif',[30,30,40],'Original F4 inspection: 60 actual source frames, one 1/30-second native work tick per frame, including working, paused and physically blocked phases. Explicit inspection stock; not a real-time performance measurement.',pattern='motion-*.png'),sequence(walk,out/'native-controller-route.gif',[300],'Original G1 walk: actual input/controller movement along the paid retained route; capture every 18 harness physics-frame waits, played at nominal 60 Hz. Capture-paced evidence, not traversal benchmark timing.')]
    write(out/'motion-provenance.json',rows)
    print('R2_ACTUAL_MOTION_PREVIEWS',[(len(r['source_frames']),r['preview']) for r in rows])

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--version',required=True);a=p.parse_args();main(a.version)
