"""Compact authored ecology shapes. No runtime generation or gameplay rules.

Each hero is a rooted organism or eroded rock mass, with quiet silhouette
variation and connected secondary growth. The fixed recipe is seed-repeatable.
"""
import math
from mathutils import Vector


def install(recipes, Geometry, palette, config):
    def tint(c, s): return tuple(max(0,min(1,v*s)) for v in c)
    bark=palette['bark']; wood=palette['heartwood']
    leaf=(.25,.36,.16); leaf_light=(.39,.48,.22); moss=(.29,.36,.18)

    def curved(points,radii,steps=3):
        points=list(map(Vector,points));out=[];rs=[]
        for i in range(len(points)-1):
            a=points[max(0,i-1)];b=points[i];c=points[i+1];d=points[min(len(points)-1,i+2)]
            for j in range(steps):
                t=j/steps
                out.append(.5*((2*b)+(-a+c)*t+(2*a-5*b+4*c-d)*t*t+(-a+3*b-3*c+d)*t*t*t))
                rs.append(radii[i]*(1-t)+radii[i+1]*t)
        return out+[points[-1]],rs+[radii[-1]]

    def limb(g,points,radii,colour=bark,sides=12,steps=3):
        points,radii=curved(points,radii,steps);rings=[];normals=[];previous=None
        phase=g.rng.uniform(0,6.28)
        for i,(p,r) in enumerate(zip(points,radii)):
            axis=(points[min(i+1,len(points)-1)]-points[max(0,i-1)]).normalized()
            across=axis.cross(Vector((0,1,0))) if previous is None else previous-axis*previous.dot(axis)
            if across.length<.01: across=axis.cross(Vector((1,0,0)))
            across.normalize();previous=across;up=axis.cross(across).normalized()
            ring=[];norm=[]
            for k in range(sides):
                a=k*math.tau/sides+phase+i*.023
                n=across*math.cos(a)+up*math.sin(a)
                ridge=1+.12*math.sin(a*5+.8)+.035*math.sin(i*.83+a*2)
                ring.append(p+n*r*ridge);norm.append(n)
            rings.append(ring);normals.append(norm)
        for i in range(len(rings)-1):
            for k in range(sides):
                n=(k+1)%sides
                colour_here=tint(colour,.90+.15*math.sin(k*2.41)**2+.045*math.sin(i*.64))
                g.face([rings[i][k],rings[i][n],rings[i+1][n],rings[i+1][k]],colour_here,points[i],
                       [normals[i][k],normals[i][n],normals[i+1][n],normals[i+1][k]])
        g.face(rings[0],tint(colour,.8),points[1])
        g.face(rings[-1],wood,points[-2])
        # Interrupted raised bark seams follow the actual root, never detached spikes.
        if max(radii)>.35:
            for k in range(0,sides,3):
                start=g.rng.randrange(0,max(1,len(points)//3))
                end=min(len(points),start+max(3,len(points)//2))
                seam=[rings[j][k] for j in range(start,end)]
                if len(seam)>2: g.tube(seam,[min(.033,radii[start]*.08)]*len(seam),tint(colour,.66),sides=4)

    def patch(g,centre,scale,colour,seed_phase=0,detail=True):
        """Scalloped leaf volume with quiet uneven normals, not a cone/card ball."""
        centre=Vector(centre);scale=Vector(scale);rows=7;segments=14
        rings=[];normals=[]
        for row in range(rows+1):
            latitude=-math.pi*.5+(row+.15)/(rows+.30)*math.pi
            ring=[];norm=[]
            for k in range(segments):
                a=k*math.tau/segments
                ripple=1+(.15 if detail else .085)*math.sin(a*5+seed_phase+row*.63)+.065*math.cos(a*3-row*.7)
                n=Vector((math.cos(a)*math.cos(latitude),math.sin(latitude),math.sin(a)*math.cos(latitude)))
                shaped=Vector((n.x*scale.x,n.y*scale.y,n.z*scale.z))*ripple
                if detail and latitude<0:
                    shaped.y+=scale.y*(.23*math.sin(a*3+seed_phase)+.16*math.sin(a*7+row*.45))
                ring.append(centre+shaped)
                normal=Vector((n.x/scale.x,n.y/scale.y,n.z/scale.z)).normalized()
                norm.append(normal)
            rings.append(ring);normals.append(norm)
        for row in range(rows):
            for k in range(segments):
                # Small gaps and ragged low edges expose the actual supporting
                # branches. A perfectly closed lower hemisphere reads as a bowl.
                if detail and row<2 and (k+int(seed_phase)*3)%5 in [0,1]: continue
                nxt=(k+1)%segments
                amount=.80+.19*(row/rows)+g.rng.uniform(-.045,.065)
                g.face([rings[row][k],rings[row][nxt],rings[row+1][nxt],rings[row+1][k]],tint(colour,amount),centre,
                       [normals[row][k],normals[row][nxt],normals[row+1][nxt],normals[row+1][k]])
        if not detail: g.face(rings[0],tint(colour,.71),centre)
        g.face(rings[-1],colour,centre)
        if detail:
            # Overlapping small leaf sprays sit on the outer lobes; foliage has
            # a solid inner volume and a leafy silhouette rather than confetti.
            for k in range(96):
                a=g.rng.random()*math.tau
                y=g.rng.uniform(-.92,-.35) if k%3!=0 else g.rng.uniform(-.12,.84)
                side=math.sqrt(1-y*y)
                at=centre+Vector((math.cos(a)*side*scale.x*.94,y*scale.y,math.sin(a)*side*scale.z*.94))
                tip=at+Vector((math.cos(a+.7)*.43,(-.15 if y<0 else .08)+g.rng.random()*.06,math.sin(a+.7)*.43))
                leaf_blade(g,at,tip,.095,tint(colour,g.rng.uniform(1.05,1.32)))

    def leaf_blade(g,start,end,width,colour):
        start=Vector(start);end=Vector(end);axis=end-start
        cross=axis.cross(Vector((0,1,0)))
        if cross.length<.01: cross=axis.cross(Vector((1,0,0)))
        cross.normalize();mid=start.lerp(end,.47);top=mid+Vector((0,width*.28,0))
        points=[start,mid+cross*width,end,mid-cross*width]
        for k in range(4):
            g.face([points[k],points[(k+1)%4],top],colour)
            g.face([top-Vector3up(width*.18),points[(k+1)%4],points[k]],tint(colour,.86))

    def Vector3up(y): return Vector((0,y,0))

    def crown(g,at=(0,0,0),scale=1):
        at=Vector(at)
        clusters=[(-3.3,1.5,.3,2.2),(-2.0,2.6,-2.2,2.3),(.2,3.4,-1.0,2.5),
                  (2.5,2.35,-2.0,2.2),(3.2,1.8,.6,2.3),(1.1,2.4,2.3,2.5),
                  (-1.8,2.1,2.0,2.4),(-.8,3.65,1.0,2.4),(0,1.9,.2,2.7)]
        for index,(x,y,z,r) in enumerate(clusters):
            p=at+Vector((x,y,z))*scale
            foot=at+Vector((-.15,.2,0))*scale
            elbow=at+Vector((x*.5,y*.67,z*.6))*scale
            limb(g,[foot,elbow,p],[.30*scale,.15*scale,.035*scale],sides=8,steps=2)
            for side in [-1,1]:
                twig_start=elbow.lerp(p,.63)
                twig_end=p+Vector((side*.70,-.20,side*.44))*scale
                limb(g,[twig_start,twig_start.lerp(twig_end,.55),twig_end],[.072*scale,.032*scale,.012*scale],sides=5,steps=2)
            colour=tint(leaf,.94+(index%3)*.065)
            patch(g,p,(r*scale,.40*r*scale,r*.80*scale),colour,index)

    def elder(g,variant=0):
        # A massive leaning bole is supported by several merging flared roots.
        # The open passage is the irregular space between those buttresses.
        shift=(variant-1)*.65
        trunk=[(-4.6,-.18,-.15),(-4.05,1.6,.18),(-4.3,3.4,-.2),(-3.55,5.4,-.6),(-3.8,7.3,-.72),(-3.1,9.3,-.65)]
        limb(g,trunk,[1.28,1.01,.85,.72,.53,.29],sides=16)
        sweeps=[
            ([(-4.2,3.65,-.1),(-2.3,4.8-variant*.4,-.1),(.8+shift,4.0-variant*.35,.15),(3.8,1.95,.5),(6.9,-.15,1.2)],[.74,.62,.46,.35,.11]),
            ([(-4.1,2.9,-.2),(-2.2,3.75,-1.5),(.9,2.85,-2.2),(3.0,.6,-2.8),(5,-.14,-3.2)],[.59,.48,.32,.19,.06]),
            ([(-4.2,4.8,.1),(-5.6,3.2,1.8),(-6.2,.9,3.0),(-7.1,-.16,3.8)],[.55,.42,.23,.04]),
            ([(-4.1,1.8,0),(-3.6,.6,2.3),(-1.5,.12,3.4),(1.0,-.15,4.0)],[.56,.4,.22,.035])]
        for pts,rs in sweeps: limb(g,pts,rs,sides=13)
        for k in range(8):
            a=k*.78+.2
            start=Vector((-4.5,.75,0));end=start+Vector((math.cos(a)*3,-.94,math.sin(a)*2.5))
            limb(g,[start,start.lerp(end,.5)+Vector((0,-.15,0)),end],[.25,.14,.025],sides=8,steps=2)
        # Branches fork into the canopy, with blunt weathered old break ends.
        for pts,rs in [([(-3.7,6.2,-.6),(-5.2,7.3,-.45),(-5.9,8.6,-1.0)],[.36,.22,.08]),
                       ([(-3.8,7.1,-.6),(-2.1,8.0,.3),(-1.3,9.3,.4)],[.3,.21,.06])]: limb(g,pts,rs,sides=9)
        for k in range(5):
            at=(-4.4+g.rng.uniform(-1.1,1.4),g.rng.uniform(.04,.18),g.rng.uniform(-1.3,1.4))
            patch(g,at,(.7,.15,.5),moss,k,False)

    def tree(g):
        trunk=[(0,-.15,0),(-.15,1.6,.12),(.3,3.8,-.08),(.05,6.0,.14),(.5,7.7,-.08)]
        limb(g,trunk,[.59,.42,.32,.23,.12],sides=13)
        for k in range(6):
            a=k*1.06
            limb(g,[(0,.5,0),(math.cos(a)*.9,.12,math.sin(a)*.9),(math.cos(a)*1.65,-.12,math.sin(a)*1.5)],[.21,.12,.018],sides=7,steps=2)
        crown(g,(.35,6.0,0),.82)

    def hollow(g,small=False):
        height=2.25 if small else config['hollow_trunk_height_m']
        radius=.70 if small else 1.05
        angles=[.54+i*4.7/22 for i in range(23)]
        rings=[];inner=[]
        rows=8
        breaks=[.80+.16*math.sin(i*.72)+.08*math.sin(i*2.11) for i in range(23)]
        for row in range(rows+1):
            t=row/rows;outside=[];inside=[]
            for k,a in enumerate(angles):
                top=height*breaks[k]
                y=-.13+(top+.13)*t
                r=radius*(1-.12*t+.08*math.sin(a*5+t*1.8))
                lean=Vector((.26*t+.10*math.sin(t*4),y,.15*t*t))
                n=Vector((math.sin(a),0,math.cos(a)))
                outside.append(lean+n*r)
                inside.append(lean+n*(r-(.20 if small else .28)))
            rings.append(outside);inner.append(inside)
        for row in range(rows):
            for k in range(22):
                r=[rings[row][k],rings[row][k+1],rings[row+1][k+1],rings[row+1][k]]
                centre=Vector((.1,sum(p.y for p in r)/4,0))
                colour=tint(bark,.88+.13*math.sin(k*2.13)**2+.09*row/rows)
                ns=[Vector((p.x-centre.x,0,p.z)).normalized() for p in r]
                g.face(r,colour,centre,ns)
                r=[inner[row][k+1],inner[row][k],inner[row+1][k],inner[row+1][k+1]]
                g.face(r,tint(bark,.68+.03*(k%3)))
        for k in range(22):
            g.face([rings[-1][k],rings[-1][k+1],inner[-1][k+1],inner[-1][k]],tint(wood,.9+(k%3)*.05))
        for k in [0,-1]:
            for row in range(rows):g.face([rings[row][k],rings[row+1][k],inner[row+1][k],inner[row][k]],wood)
        for k in range(1,23,3):
            g.tube([rings[row][k] for row in range(rows+1)],[.025]*(rows+1),tint(bark,.64),sides=4)
        for k in range(6):
            a=k*1.06+.3
            limb(g,[(math.sin(a)*radius*.7,.65,math.cos(a)*radius*.7),(math.sin(a)*radius*1.45,.12,math.cos(a)*radius*1.45),(math.sin(a)*radius*2.1,-.14,math.cos(a)*radius*2.1)],[radius*.28,radius*.15,.025],sides=8,steps=2)
        for sign in [-1,1]:
            level=.42 if sign<0 else .68
            limb(g,[(sign*radius*.8,height*level,-.25),(sign*radius*1.3,height*(level+.12),-.5),(sign*radius*1.55,height*(level+.09),-.72)],[radius*.23,radius*.12,radius*.08],sides=8,steps=2)
        for k in range(10):
            a=.55+k*.45
            p=(math.sin(a)*radius*.6,height*(.25+.24*(k%3)/3),math.cos(a)*radius*.6)
            g.petal(p,.42 if small else .7,.12 if small else .20,a,tint(palette['paper_dark'],1.18))

    def rock(g,centre,size,colour,phase=0):
        centre=Vector(centre);size=Vector(size);rings=[]
        # A slab-sided mass, broad even at its broken top; no pointed cone cap.
        levels=[(-.5,.88),(-.12,1.0),(.28,.91),(.5,.69)]
        for row,(y,r) in enumerate(levels):
            ring=[]
            for i in range(9):
                a=i*math.tau/9
                jag=1+.09*math.sin(i*2.3+phase)+.065*math.cos(i*4.6+row)
                p=Vector((math.cos(a)*r*.5*size.x,y*size.y+math.sin(a*3+phase)*size.y*.045,math.sin(a)*r*.5*size.z))*jag
                p.x+=y*size.y*.13
                ring.append(centre+p)
            rings.append(ring)
        for row in range(3):
            for i in range(9):
                nxt=(i+1)%9
                g.face([rings[row][i],rings[row][nxt],rings[row+1][nxt],rings[row+1][i]],tint(colour,.9+.065*(i%3)+.018*row),centre)
        g.face(rings[-1],tint(colour,1.04),centre);g.face(rings[0],colour,centre)

    def outcrop(g,tall=False):
        base=palette['stone']
        if tall:
            height=config['stone_rib_height_m']
            for tower in range(3):
                h=height*(1-.25*tower);x=(tower-1)*1.15
                rings=[]
                for layer in range(13):
                    y=layer*h/12-.12
                    radius=1-layer*.017+(0.035 if layer%2==0 else -.025)
                    ring=[]
                    for edge in range(10):
                        a=edge*math.tau/10
                        # Broad continuous faces are cut by shallow strata;
                        # varying fractures split the final ledge, not each layer.
                        jag=1+.08*math.sin(edge*2.1+tower)+.025*math.sin(layer*.8+edge)
                        yy=y+.035*math.sin(edge*2.7+layer*.25)
                        if layer==12: yy-=abs(math.sin(a*2+tower))*.34
                        ring.append(Vector((x+y*.19+math.cos(a)*radius*jag,yy,-tower*.3+math.sin(a)*.64*radius*jag)))
                    rings.append(ring)
                for layer in range(12):
                    for edge in range(10):
                        nxt=(edge+1)%10
                        centre=Vector((x+(layer+.5)*h/12*.19,(layer+.5)*h/12,-tower*.3))
                        g.face([rings[layer][edge],rings[layer][nxt],rings[layer+1][nxt],rings[layer+1][edge]],tint(base,.93+.045*(layer%3)-tower*.025),centre)
                g.face(rings[-1],base,Vector((x,h*.5,-tower*.3)))
                g.face(rings[0],base,Vector((x,h*.5,-tower*.3)))
            for k in range(5):
                rock(g,(g.rng.uniform(-2,2),.13,g.rng.uniform(-1.5,1.6)),(g.rng.uniform(.4,1.1),.4,g.rng.uniform(.35,.7)),palette['stone_dark'],k)
        else:
            for k,(x,y,z,sx,sy,sz) in enumerate([(-.8,.42,.1,2.5,1.0,1.9),(.8,.22,.5,2.1,.7,1.5),(.3,.72,-.4,2.6,1.4,1.6),(-1.2,.12,-.7,1.7,.45,1.2)]):
                rock(g,(x,y,z),(sx,sy,sz),tint(base,.93+(k%3)*.04),k)

    def scree(g):
        for k in range(24):
            a=g.rng.random()*math.tau;r=math.sqrt(g.rng.random())
            size=g.rng.uniform(.14,.46)
            rock(g,(math.cos(a)*r*1.35,.025,math.sin(a)*r*.92),(size,size*.38,size*.75),tint(palette['stone_dark'],g.rng.uniform(.87,1.14)),k)

    def sedge(g):
        for tuft in range(5):
            base=Vector((g.rng.uniform(-.32,.32),-.025,g.rng.uniform(-.32,.32)))
            for k in range(15):
                a=k*2.399+tuft;height=g.rng.uniform(.27,.81);spread=g.rng.uniform(.18,.44)
                points=[base,base+Vector((math.cos(a)*spread*.28,height*.57,math.sin(a)*spread*.28)),base+Vector((math.cos(a)*spread,height,math.sin(a)*spread))]
                colour=tint(leaf_light,g.rng.uniform(.76,1.12))
                right=Vector((-math.sin(a),0,math.cos(a)))
                for j in range(2):
                    width=.023*(1-j*.35)
                    g.face([points[j]-right*width,points[j]+right*width,points[j+1]+right*width*.25,points[j+1]-right*width*.25],colour)
                    g.face([points[j+1]-right*width*.25,points[j+1]+right*width*.25,points[j]+right*width,points[j]-right*width],tint(colour,.88))

    def fern(g):
        for frond in range(11):
            a=frond*2.399;length=g.rng.uniform(.57,.98);rise=g.rng.uniform(.48,.79)
            forward=Vector((math.cos(a),0,math.sin(a)));right=Vector((-math.sin(a),0,math.cos(a)))
            pts=[Vector((0,.02,0)),forward*length*.35+Vector((0,rise*.9,0)),forward*length*.72+Vector((0,rise,0)),forward*length+Vector((0,rise*.8,0))]
            path,rs=curved(pts,[.012,.009,.005,.001],4)
            g.tube(path,rs,tint(leaf,.8),sides=4)
            for k in range(2,len(path)-1):
                t=k/(len(path)-1);width=.18*math.sin(t*math.pi)**.65
                for sign in [-1,1]:
                    start=path[k];tip=start+right*width*sign+forward*.08+Vector((0,.025,0))
                    leaf_blade(g,start,tip,width*.29,tint(leaf_light,.87+.12*t))

    def moss_clump(g):
        for k in range(7):
            a=k*2.399;r=.44*math.sqrt(k/7)
            patch(g,(math.cos(a)*r,.075,math.sin(a)*r*.8),(.36,.13,.31),tint(moss,.92+(k%3)*.06),k,False)

    recipes['root_arch']=lambda g:elder(g,0)
    recipes['hollow_trunk']=hollow
    recipes['lantern_shell']=lambda g:hollow(g,True)
    recipes['stone_rib']=lambda g:outcrop(g,True)
    # Added at the end: old finite core and contraption seeds remain unchanged.
    recipes.update({'root_arch_b':lambda g:elder(g,1),'root_arch_c':lambda g:elder(g,2),
                    'root_crown':crown,'wildwood_tree':tree,'low_outcrop':outcrop,
                    'scree':scree,'sedge':sedge,'fern':fern,'moss':moss_clump})
