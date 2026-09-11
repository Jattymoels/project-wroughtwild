"""Freeze current committed game/data for unchanged placement regression checks."""
import json,shutil,subprocess,sys,zipfile
from pathlib import Path
root=Path(__file__).resolve().parents[3];out=Path(sys.argv[1]).resolve();native=Path(sys.argv[2]).resolve()
assert out.is_relative_to(root/'build/art07/f2');out.mkdir(parents=True,exist_ok=False)
base='4b5d89b376765fbf4d46049aa099e0bb154a82da'
subprocess.run(['git','-C',str(root),'archive','--format=zip','--output='+str(out/'frozen.zip'),base,'game','data'],check=True)
with zipfile.ZipFile(out/'frozen.zip') as z:z.extractall(out)
shutil.copy2(native/'bin/libwroughtwild_sim.windows.x86_64.dll',out/'game/bin/libwroughtwild_sim.windows.x86_64.dll')
p=out/'game/project.godot';txt=p.read_text();txt=txt.replace('[application]','[application]\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="F2Native"');p.write_text(txt)
shutil.copy2(native/'provenance.json',out/'native-provenance.json')
print('F2_FROZEN_GAME_OK',base,out)
