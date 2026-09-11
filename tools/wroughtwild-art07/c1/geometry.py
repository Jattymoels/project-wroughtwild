"""B2 leaf/tube derivative of ART-02 build_grove.py; explicit attached foliage."""
import bpy, math
from mathutils import Vector
class Mesh:
    def __init__(self): self.v=[]; self.f=[]; self.uv=[]; self.colors=[]
    def vert(self,p,uv=(0,0),color=(.1,.18,.04)):
        self.v.append(tuple(p));self.uv.append(uv);self.colors.append((*color,1));return len(self.v)-1
    def face(self,*v): self.f.append(v)
    def obj(self,name,mat):
        mesh=bpy.data.meshes.new(name);mesh.from_pydata(self.v,[],self.f);mesh.update()
        uv=mesh.uv_layers.new(name="Leaf grain")
        color=mesh.color_attributes.new(name="Plant colour",type="FLOAT_COLOR",domain="POINT")
        for i,c in enumerate(self.colors):color.data[i].color=c
        for l in mesh.loops:uv.data[l.index].uv=self.uv[l.vertex_index]
        for p in mesh.polygons:p.use_smooth=True
        ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);mesh.materials.append(mat);return ob
def tube(m,path,radii,color=(.12,.075,.035),sides=6):
    path=list(map(Vector,path));base=len(m.v)
    for j,(p,r) in enumerate(zip(path,radii)):
        d=(path[min(j+1,len(path)-1)]-path[max(0,j-1)]).normalized()
        u=d.cross(Vector((0,0,1)))
        if u.length<.001:u=d.cross(Vector((0,1,0)))
        u.normalize();v=d.cross(u).normalized()
        for k in range(sides):
            a=k/sides*math.tau;m.vert(p+(u*math.cos(a)+v*math.sin(a))*r,(k/sides,j/(len(path)-1)),color)
    for j in range(len(path)-1):
        for k in range(sides):
            a=base+j*sides+k;b=base+j*sides+(k+1)%sides;m.face(a,b,b+sides,a+sides)
    m.face(*[base+k for k in reversed(range(sides))])
    m.face(*[base+(len(path)-1)*sides+k for k in range(sides)])
def leaf(m,p,d,length,width,color,detail=0,ivy=False):
    p=Vector(p);d=Vector(d).normalized();u=d.cross(Vector((0,0,1)))
    if u.length<.001:u=Vector((1,0,0))
    u.normalize();base=len(m.v);m.vert(p,(.5,0),color)
    sections=[.13,.24,.36,.49,.62,.75,.87] if detail==0 else ([.25,.5,.75] if detail==1 else [.4,.75])
    for j,t in enumerate(sections):
        shape=math.sin(math.pi*t)**.72
        if ivy:shape*=1.0+.22*math.cos(t*math.pi*6)
        else:shape*=1.0+(.12 if j%2==0 else -.08)
        mid=p+d*length*t+Vector((0,0,length*.09*math.sin(t*math.pi)))
        for side in [-1,0,1]:
            co=mid+u*width*shape*side+Vector((0,0,-abs(side)*length*.025))
            m.vert(co,(side*.5+.5,t),tuple(c*(1.07 if side==0 else 1) for c in color))
    tip=m.vert(p+d*length,(.5,1),color);m.face(base,base+1,base+2);m.face(base,base+2,base+3)
    for j in range(len(sections)-1):
        for k in range(2):
            a=base+1+j*3+k;m.face(a,a+3,a+4,a+1)
    a=base+1+(len(sections)-1)*3;m.face(a,tip,a+1);m.face(a+1,tip,a+2)
