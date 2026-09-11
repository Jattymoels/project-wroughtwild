"""Freeze one published revision; reuse B3 binary only after exact source comparison."""
import json,sys,subprocess,zipfile,shutil,hashlib
from pathlib import Path
out=Path(sys.argv[1]).resolve();assert not out.exists();out.mkdir(parents=True)
revision='f5e481a28fb032a7d4d7ebec1e3e01cc1aca0bc9'
compiled='f00d4b76274ef2a73c3b6f4a275d2bd3ca0f958d'
subprocess.run(['git','diff','--exit-code',compiled,revision,'--','game','sim','data'],check=True)
archive=out/'game.zip';subprocess.run(['git','archive','--format=zip','--output='+str(archive),revision,'game','data'],check=True)
with zipfile.ZipFile(archive) as z:z.extractall(out)
dll=Path('C:/Users/Matty/Dev/project-wroughtwild/build/art07/b3/worktree/build/art07/b3/v01/handoff-v02/native/game/bin/libwroughtwild_sim.windows.x86_64.dll')
digest=hashlib.sha256(dll.read_bytes()).hexdigest();assert digest=='6d8094fc95c0854f9100b161806a11d9fa3a67bb4f870080976bcd8d2e8f2279'
shutil.copy2(dll,out/'game/bin'/dll.name)
(out/'provenance.json').write_text(json.dumps({'revision':revision,'binary_compiled_at':compiled,'binary_source':str(dll),'dll_sha256':digest,'game_sim_data_diff_empty':True},indent=2)+'\n')
(out/'game/c1').mkdir()
recipe=Path(__file__).parent
shutil.copy2(recipe/'measure_native.gd',out/'game/c1/measure_native.gd')
print('C1_NATIVE_FROZEN',out)
