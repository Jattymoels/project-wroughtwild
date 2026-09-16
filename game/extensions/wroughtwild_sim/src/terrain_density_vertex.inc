// V10 dual contour vertex. Called only for the regenerated local density field.
// The eight cell-centre samples are the same on both sides of every chunk seam.
// A bounded regularised QEF retains intersecting rock planes instead of rounding
// every crossing to a midpoint. The topology and triangle owner remain voxels.
std::map<int64_t,Vector3> densityCache;
auto densityVertex = [&](int x,int y,int z,int ownerX,int ownerY,int ownerZ) {
    double samples[8];
    for(int i=0;i<8;++i) {
        const int a=x-1+(i&1),b=y-1+((i>>1)&1),c=z-1+((i>>2)&1);
        double d=map.surfaceDensity.at(a,b,c);
        const bool solid=eff(a,b,c)!=kAir;
        // Edits, later protected foundations and inherited caves win over a
        // generated sample. Never leave a render-only surface over removed land.
        if(d==0 || ((d>0)!=solid))d=solid?.5:-.5;
        samples[i]=d;
    }
    // A lattice corner can contain diagonally touching but disconnected
    // solids. Give each six-connected solid component its own dual vertex;
    // otherwise two opposite cliff faces pinch into a non-manifold seam.
    int component=0;
    const int owner=(ownerX-x+1)|((ownerY-y+1)<<1)|((ownerZ-z+1)<<2);
    int pending=1<<owner;
    while(pending) {
        int at=0;while(!(pending&(1<<at)))++at;
        pending&=~(1<<at);component|=1<<at;
        for(int axis=0;axis<3;++axis) {
            const int next=at^(1<<axis);
            if(samples[next]>0 && !(component&(1<<next)))pending|=1<<next;
        }
    }
    const int64_t key=((int64_t(z)*(map.width+1)+x)*(map.depth+1)+y)*256+component;
    auto cached=densityCache.find(key);if(cached!=densityCache.end())return cached->second;
    for(int i=0;i<8;++i)if(!(component&(1<<i)))samples[i]=-std::abs(samples[i]);
    auto gradient=[&](const Vector3& t) {
        Vector3 g;
        for(int axis=0;axis<3;++axis) {
            double value=0;
            for(int i=0;i<8;++i)if(!(i&(1<<axis))) {
                double weight=1;
                for(int j=0;j<3;++j)if(j!=axis)weight*=i&(1<<j)?t[j]:1-t[j];
                value+=(samples[i+(1<<axis)]-samples[i])*weight;
            }
            g[axis]=-value;
        }
        return g.normalized();
    };
    Vector3 points[12],normals[12],mass;
    int count=0;
    for(int i=0;i<8;++i)for(int axis=0;axis<3;++axis) {
        if(i&(1<<axis))continue;
        const int j=i+(1<<axis);
        if((samples[i]>0)==(samples[j]>0))continue;
        Vector3 p(i&1,(i>>1)&1,(i>>2)&1);
        p[axis]=std::clamp(samples[i]/(samples[i]-samples[j]),0.0,1.0);
        points[count]=p;normals[count]=gradient(p);mass+=p;++count;
    }
    if(!count)return Vector3(x,y,z)*cs;
    mass/=count;
    // Solve in local coordinates about the crossing centroid. Small diagonal
    // regularisation leaves planar surfaces stable and anchors unconstrained axes.
    double q[3][4]={{.035,0,0,0},{0,.035,0,0},{0,0,.035,0}};
    for(int i=0;i<count;++i) {
        const Vector3 n=normals[i];const double d=n.dot(points[i]-mass);
        for(int a=0;a<3;++a) {
            for(int b=0;b<3;++b)q[a][b]+=n[a]*n[b];
            q[a][3]+=n[a]*d;
        }
    }
    for(int k=0;k<3;++k) {
        int pivot=k;for(int j=k+1;j<3;++j)if(std::abs(q[j][k])>std::abs(q[pivot][k]))pivot=j;
        for(int j=k;j<4;++j)std::swap(q[k][j],q[pivot][j]);
        const double divisor=q[k][k];
        if(std::abs(divisor)<1e-10)continue;
        for(int j=k;j<4;++j)q[k][j]/=divisor;
        for(int a=0;a<3;++a)if(a!=k) {
            const double factor=q[a][k];
            for(int b=k;b<4;++b)q[a][b]-=factor*q[k][b];
        }
    }
    Vector3 result=mass+Vector3(q[0][3],q[1][3],q[2][3]);
    // Keep a vertex within its dual cell; a bad corner cannot fold across an
    // adjacent editable owner. This bounds render/contact approximation to .5 m.
    // A small interior margin prevents different dual cells collapsing onto
    // the same grid edge and deleting the triangles joining a narrow cleft.
    for(int a=0;a<3;++a)result[a]=std::clamp(result[a],0.02f,0.98f);
    const Vector3 vertex=(Vector3(x-.5,y-.5,z-.5)+result)*cs;
    densityCache[key]=vertex;return vertex;
};
