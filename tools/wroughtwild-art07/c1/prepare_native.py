"""New native review from the verified frozen source, never from normal saves."""
import shutil,sys,subprocess
from pathlib import Path
source,review,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);assert not out.exists();out.mkdir(parents=True)
for n in ['game','data']:shutil.copytree(source/n,out/n,ignore=shutil.ignore_patterns('.godot','c1','*.tmp'))
shutil.copy2(source/'provenance.json',out/'provenance.json')
subprocess.run([sys.executable,str(Path(__file__).with_name('install_native.py')),str(review),str(out/'game')],check=True)
print('C1_NATIVE_PREPARED',out)
