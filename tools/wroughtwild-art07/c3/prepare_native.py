"""Freeze current game/data, reusing a binary only after exact code equivalence."""
import sys, subprocess, zipfile, shutil, json
from pathlib import Path
from prerequisites import PACKAGES, REVISION, sha
out=Path(sys.argv[1]).resolve();assert not out.exists();out.mkdir(parents=True)
compiled='56ce6bbe343012205690cf669491372958b80662'
subprocess.run(['git','diff','--exit-code',compiled,REVISION,'--','game','sim','data'],check=True)
archive=out/'current.zip'
subprocess.run(['git','archive','--format=zip','--output='+str(archive),REVISION,'game','data'],check=True)
with zipfile.ZipFile(archive) as z:z.extractall(out)
dll=PACKAGES['b1'][0]/'native/game/bin/libwroughtwild_sim.windows.x86_64.dll'
assert sha(dll)=='b4d7c28447e54e0de59c7185ff2b13875f48be8a6fad71fce7f826873d22c5e6'
shutil.copy2(dll,out/'game/bin'/dll.name)
(out/'provenance.json').write_text(json.dumps({'revision':REVISION,'binary_compiled_revision':compiled,'game_sim_data_diff_empty':True,'dll_sha256':sha(dll),'source':str(dll)},indent=2)+'\n')
print('C3_CURRENT_NATIVE_COPY_OK')
