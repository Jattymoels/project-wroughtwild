"""Focused checks for immutable package integrity and owned tool syntax."""
import ast,hashlib,json,sys
from pathlib import Path
from handoff import verify
from inspect_inputs import ROOT,sha
from compose import write
out=Path(sys.argv[1]);assert not out.exists();out.mkdir(parents=True)
tools=ROOT/'tools/wroughtwild-art07-repairs/r8';checked=[]
for p in tools.glob('*.py'):
    ast.parse(p.read_text(encoding='utf-8-sig'),filename=str(p));checked.append({'path':str(p),'sha256':sha(p)})
valid=out/'valid';valid.mkdir();(valid/'one.txt').write_bytes(b'known content')
m={'file_count':1,'bytes':13,'files':{'one.txt':{'bytes':13,'sha256':sha(valid/'one.txt')}}};write(valid/'manifest.json',m);h=sha(valid/'manifest.json');verify(valid,h)
results=[]
for mode in ['extra','tampered','missing','wrong-manifest']:
    p=out/mode;p.mkdir();write(p/'manifest.json',m)
    if mode!='missing':(p/'one.txt').write_bytes(b'known content' if mode!='tampered' else b'altered bytes')
    if mode=='extra':(p/'unexpected.txt').write_bytes(b'extra')
    try:verify(p,'0'*64 if mode=='wrong-manifest' else h)
    except AssertionError:results.append({'case':mode,'rejected':True})
    else:raise AssertionError(mode+' accepted')
write(out/'checks.json',{'python_syntax':checked,'valid_exact_package_passed':True,'rejected_cases':results})
print('R8_TOOLS_CHECKED',len(checked),'valid package plus',len(results),'invalid cases')
