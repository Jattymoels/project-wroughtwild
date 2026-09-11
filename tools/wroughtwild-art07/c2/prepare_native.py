"""Current unchanged native rules with their verified B3 binary; isolated regression only."""
import sys,subprocess,zipfile,shutil,json
from pathlib import Path
from prerequisites import PACKAGES,sha
out=Path(sys.argv[1]).resolve();assert not out.exists();out.mkdir(parents=True)
revision='f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9'
compiled='f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d'
subprocess.run(['git','diff','--exit-code',compiled,revision,'--','game','sim','data'],check=True)
archive=out/'current.zip';subprocess.run(['git','archive','--format=zip','--output='+str(archive),revision,'game','data'],check=True)
with zipfile.ZipFile(archive) as z:z.extractall(out)
dll=PACKAGES['b3'][0]/'native/game/bin/libwroughtwild_sim.windows.x86_64.dll'
assert sha(dll)=='6d8094fc95c0854f9100b161806a11d9fa3a67bb4f870080976bcd8d2e8f2279'
shutil.copy2(dll,out/'game/bin'/dll.name)
(out/'provenance.json').write_text(json.dumps({'revision':revision,'binary_compiled_revision':compiled,'game_sim_data_diff_empty':True,'dll_sha256':sha(dll),'source':str(dll)},indent=2)+'\n')
print('C2_CURRENT_NATIVE_COPY_OK')
