"""Cook selected ART-01/03 assets. Run with owner depot and target checkout paths.
Reuses ART-05 cooked boar geometry; never launches or modifies the pilot.
Mesh, skin and clip buffers are retained exactly; embedded fallback textures
are replaced by the four explicitly bound runtime maps (maximum 2048 pixels).
"""
import argparse, hashlib, json, struct
from pathlib import Path
from PIL import Image

p=argparse.ArgumentParser()
p.add_argument("owner", type=Path)
p.add_argument("checkout", type=Path)
a=p.parse_args()
out=a.checkout/"game/assets/authored/fauna"
out.mkdir(parents=True, exist_ok=True)
report={"models":{}, "texture_limit":2048, "import_fps":100,
        "note":"Selected mid meshes; exact geometry/skin/clip buffers, shared external maps. No generated master or preview bootstrap."}

def cook(source, name):
    raw=source.read_bytes()
    length=struct.unpack_from("<I",raw,12)[0]
    doc=json.loads(raw[20:20+length]); binary=raw[28+length:]
    removed={x["bufferView"] for x in doc.get("images",[]) if "bufferView" in x}
    chunks=[]; views=[]; mapping={}; offset=0
    for i,v in enumerate(doc.get("bufferViews",[])):
        if i in removed: continue
        b=binary[v.get("byteOffset",0):v.get("byteOffset",0)+v["byteLength"]]
        pad=(-offset)%4; chunks.append(bytes(pad)); offset+=pad
        mapping[i]=len(views); views.append(dict(v,byteOffset=offset))
        chunks.append(b); offset+=len(b)
    for ac in doc.get("accessors",[]):
        if "bufferView" in ac: ac["bufferView"]=mapping[ac["bufferView"]]
        for k in ("indices","values"):
            if k in ac.get("sparse",{}):
                v=ac["sparse"][k]; v["bufferView"]=mapping[v["bufferView"]]
    for key in ("images","textures","samplers","materials"): doc.pop(key,None)
    for m in doc["meshes"]:
        for prim in m["primitives"]: prim.pop("material",None)
    doc["bufferViews"]=views; doc["buffers"]=[{"byteLength":offset}]
    binary=b"".join(chunks); binary+=bytes((-len(binary))%4)
    js=json.dumps(doc,separators=(",",":")).encode(); js+=b" "*((-len(js))%4)
    cooked=struct.pack("<III",0x46546c67,2,28+len(js)+len(binary))+struct.pack("<II",len(js),0x4e4f534a)+js+struct.pack("<II",len(binary),0x004e4942)+binary
    (out/(name+".glb")).write_bytes(cooked)
    (out/(name+".glb.import")).write_text('[remap]\nimporter="scene"\ntype="PackedScene"\n[params]\nmeshes/generate_lods=false\nanimation/fps=100\n',encoding="utf-8")
    return {"source":str(source.relative_to(a.owner)).replace("\\","/"),"source_sha256":hashlib.sha256(raw).hexdigest(),"bytes":len(cooked),"triangles":sum(doc["accessors"][p["indices"]]["count"]//3 for m in doc["meshes"] for p in m["primitives"]),"clips":[x["name"] for x in doc.get("animations",[])]}

for animal in ("boar","wolf","stag"):
    folder=a.owner/("build/boar-art01/boar-handoff/review" if animal=="boar" else f"build/fauna-art03/fauna-handoff/{animal}/review")
    source=(a.owner/"build/art05/red-route-handoff/game/art05/assets/boar-mid.glb") if animal=="boar" else folder/(animal+"-mid.glb")
    entry=cook(source,animal)
    config=json.loads((folder/("boar-study.json" if animal=="boar" else animal+".json")).read_text(encoding="utf-8-sig"))
    entry["scar"]=config["scar"]
    entry["maps"]={}
    for kind,name in {"base":"base.png","orm":"orm.png","normal":"normal.png","scar":"scar-mask.png"}.items():
        im=Image.open(folder/name); im.load()
        im=im.convert("RGBA" if "A" in im.getbands() else "RGB")
        im.thumbnail((2048,2048),Image.Resampling.LANCZOS)
        filename=f"{animal}-{kind}.png"; im.save(out/filename)
        entry["maps"][kind]=filename
        (out/(filename+".import")).write_text('[remap]\nimporter="texture"\ntype="CompressedTexture2D"\n[params]\ncompress/mode=0\nmipmaps/generate=true\ndetect_3d/compress_to=0\n',encoding="utf-8")
    report["models"][animal]=entry
(out/"manifest.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
print("A2_COOK_OK",[(k,v["bytes"],v["triangles"]) for k,v in report["models"].items()])
