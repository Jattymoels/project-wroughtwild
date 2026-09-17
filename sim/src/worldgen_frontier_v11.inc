// LAND-03 isolated successor. Published V10 is composed unchanged first.
// This bounded dry-country layer adds no resource ledger or campaign owner.
using namespace lake_frontier;
using fractured_frontier::point;
using fractured_frontier::originalRoof;
using fractured_frontier::pathDistance;

SurfacePoint local(const WorldMap& map,const DrySteppePlace& p,double u,double v) {
    return point(map,p.centre.x+p.direction.x*u-p.direction.z*v,p.centre.z+p.direction.z*u+p.direction.x*v);
}
std::pair<double,double> uv(const DrySteppePlace& p,double x,double z) {
    const double dx=x-p.centre.x,dz=z-p.centre.z;
    return {dx*p.direction.x+dz*p.direction.z,-dx*p.direction.z+dz*p.direction.x};
}
bool protectedPlace(const WorldMap& map,int x,int z,double pad=0) {
    if(!map.inBounds(x,z)||x<4||z<4||x>=map.width-4||z>=map.height-4)return true;
    if(std::hypot(x-map.spawnX,z-map.spawnZ)<36+pad)return true;
    for(const auto& l:map.lakes)if(std::hypot(x-l.x,z-l.z)<l.radiusM+42+pad)return true;
    for(const auto& p:map.scarwater) {
        if(pathDistance(x,z,p.ridge)<38+pad||std::hypot(x-p.scar.x,z-p.scar.z)<30+pad||std::hypot(x-p.smithy.x,z-p.smithy.z)<26+pad)return true;
        if(std::min(pathDistance(x,z,p.shelteredRoute),pathDistance(x,z,p.outlookRoute))<10+pad)return true;
        for(const auto& h:map.homeSites)if((h.id==p.groveHomeId||h.id==p.outlookHomeId)&&std::hypot(x-h.x,z-h.z)<h.radiusM+36+pad)return true;
    }
    for(const auto& h:map.habitats)if(std::hypot(x-h.x,z-h.z)<h.radiusM+6+pad)return true;
    for(const auto& r:map.rareSites)if(std::hypot(x-r.x,z-r.z)<r.radiusM+7+pad)return true;
    for(const auto& r:map.ruins)if(std::hypot(x-r.x,z-r.z)<std::max(r.widthM,r.depthM)+8+pad)return true;
    for(const auto& p:map.pressurePockets)if(std::hypot(x-p.x,z-p.z)<p.radiusM+12+pad)return true;
    for(const auto& l:map.landmarks)if(std::hypot(x-l.x,z-l.z)<18+pad)return true;
    return std::hypot(x-map.gateX,z-map.gateZ)<20+pad;
}
void extendDensity(WorldMap& map,int minX,int minZ,int maxX,int maxZ) {
    const auto& old=map.surfaceDensity;
    SurfaceDensityField next;
    next.minX=std::max(1,std::min(minX,old.minX));next.minZ=std::max(1,std::min(minZ,old.minZ));
    next.width=std::min(map.width-1,std::max(maxX,old.minX+old.width))-next.minX;
    next.height=std::min(map.height-1,std::max(maxZ,old.minZ+old.height))-next.minZ;
    next.depth=map.depth;next.values.assign(static_cast<size_t>(next.width)*next.height*next.depth,0);
    for(int z=old.minZ;z<old.minZ+old.height;++z)for(int x=old.minX;x<old.minX+old.width;++x)
        std::copy_n(&old.values[(static_cast<size_t>(z-old.minZ)*old.width+x-old.minX)*old.depth],old.depth,&next.sample(x,0,z));
    map.surfaceDensity=std::move(next);
}
// Surface modification keeps every old cave air cell below the original cap.
// The float crossing and solid voxel classification are authored together.
void seat(WorldMap& map,const tuning::WorldgenTable& table,int x,int z,double target) {
    const int original=map.at(x,z).height;
    target=std::clamp(target,3.0,double(map.depth-4));
    for(int y=std::max(1,int(std::floor(target))-2);y<original-1;++y)
        if(map.blockAt(x,y,z)==kAir)target=std::max(target,double(y+3));
    const int top=static_cast<int>(std::ceil(target-.5));
    for(int y=1;y<map.depth;++y) {
        auto& block=map.blocks[(static_cast<size_t>(z)*map.width+x)*map.depth+y];
        if(y>=std::min(original-1,top-1))block=y<top?(y==top-1?kSurface:y>=top-table.strata.dirtDepth-1?kDirt:kStone):kAir;
        double d=target-(y+.5);
        if(block==kAir)d=std::min(-.001,d);else d=std::max(.001,d);
        map.surfaceDensity.sample(x,y,z)=static_cast<float>(std::clamp(d,-2.0,2.0));
    }
    map.surfaceDensity.sample(x,0,z)=.5f;
    map.cells[z*map.width+x].height=top;
}
bool dryClear(const WorldMap& map,const frozen_frontier::SurfaceWalk& walk,int x,int z,int radius,int variation) {
    if(x<radius+2||z<radius+2||x>=map.width-radius-2||z>=map.height-radius-2)return false;
    if(walk.parent[z*map.width+x]<0)return false;
    for(int dz=-radius;dz<=radius;++dz)for(int dx=-radius;dx<=radius;++dx) {
        const int at=(z+dz)*map.width+x+dx;
        if(!walk.clear[at]||std::abs(walk.heights[at]-walk.heights[z*map.width+x])>variation||!originalRoof(map,x+dx,z+dz,2))return false;
    }
    return true;
}
SurfacePoint reachable(const WorldMap& map,const frozen_frontier::SurfaceWalk& walk,SurfacePoint target,int radius,int flat=1) {
    std::pair<double,int> best{1e30,-1};
    for(int dz=-radius;dz<=radius;++dz)for(int dx=-radius;dx<=radius;++dx) {
        const int x=target.x+dx,z=target.z+dz;
        if(!dryClear(map,walk,x,z,2,flat))continue;
        const double score=dx*dx+dz*dz;
        if(score<best.first)best={score,z*map.width+x};
    }
    if(best.second<0)throw std::runtime_error("LAND03: no reachable supported destination "+std::to_string(target.x)+","+std::to_string(target.z));
    return {best.second%map.width,walk.heights[best.second],best.second/map.width};
}

// A centre-height flood may take metre-step shortcuts across a steep density
// rib even while a nearby graded lane is walkable. Match the actual V10/V11
// gentle-roof eligibility and continuous crossings, then reserve capsule room.
auto physicalWalk(const WorldMap& map,int minX,int minZ,int maxX,int maxZ) {
    auto walk=surfaceWalk(map,1);
    auto safe=walk.clear;
    minX=std::max(3,minX);minZ=std::max(3,minZ);
    maxX=std::min(map.width-3,maxX);maxZ=std::min(map.height-3,maxZ);
    for(int z=minZ;z<=maxZ;++z)for(int x=minX;x<=maxX;++x) {
        if(!walk.clear[z*map.width+x])continue;
        double corners[4];bool valid=true;
        const int cx[]={0,1,1,0},cz[]={0,0,1,1};
        for(int corner=0;corner<4&&valid;++corner) {
            int low=map.depth,high=0;double total=0;
            for(int dz=-1;dz<=0;++dz)for(int dx=-1;dx<=0;++dx) {
                const int a=x+cx[corner]+dx,b=z+cz[corner]+dz,h=map.at(a,b).height;
                low=std::min(low,h);high=std::max(high,h);
                double surface=h;
                const double lower=map.surfaceDensity.at(a,h-1,b),upper=map.surfaceDensity.at(a,h,b);
                if(lower>0&&upper<0)surface=h-.5+lower/(lower-upper);
                total+=surface;
                valid=valid&&map.blockAt(a,h-1,b)!=kAir&&map.blockAt(a,h-2,b)!=kAir&&map.blockAt(a,h,b)==kAir;
            }
            // Exactly the engine's V11 guard. A wider span uses the density
            // solver and cannot be cleared by a height-only walking assertion.
            valid=valid&&high-low<=1;corners[corner]=total*.25;
        }
        if(valid) {
            const double centre=(corners[0]+corners[1]+corners[2]+corners[3])*.25;
            for(int i=0;i<4;++i) {
                const double edge=corners[(i+1)%4]-corners[i];
                const double inward=2*(centre-(corners[i]+corners[(i+1)%4])*.5);
                if(edge*edge+inward*inward>.60*.60)valid=false;
            }
        }
        if(!valid)safe[z*map.width+x]=false;
    }
    for(int z=minZ+1;z<maxZ;++z)for(int x=minX+1;x<maxX;++x) {
        if(!walk.clear[z*map.width+x])continue;
        for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx)
            if(!safe[(z+dz)*map.width+x+dx])walk.clear[z*map.width+x]=false;
    }
    std::fill(walk.parent.begin(),walk.parent.end(),-1);
    const int start=map.spawnZ*map.width+map.spawnX;
    walk.clear[start]=true;walk.parent[start]=start;
    std::queue<int> todo;todo.push(start);
    const int dx[]={1,0,-1,0},dz[]={0,1,0,-1};
    while(!todo.empty()) {
        const int at=todo.front();todo.pop();
        for(int d=0;d<4;++d) {
            const int x=at%map.width+dx[d],z=at/map.width+dz[d];
            if(!map.inBounds(x,z))continue;
            const int next=z*map.width+x;
            if(walk.parent[next]>=0||!walk.clear[next]||std::abs(walk.heights[next]-walk.heights[at])>1)continue;
            walk.parent[next]=at;todo.push(next);
        }
    }
    return walk;
}

void compose(WorldMap& map,const tuning::WorldgenTable& table,const tuning::LivingFrontierTable& rules) {
    if(map.scarwater.size()!=1||map.homeSites.size()!=4)throw std::runtime_error("LAND03: missing inherited composition");
    const auto& cfg=table.drySteppe;
    const auto& basin=map.scarwater.front();
    DrySteppePlace p;
    std::vector<const PlacedHomeSite*> homes;
    for(const auto& h:map.homeSites)if(h.id!=basin.groveHomeId&&h.id!=basin.outlookHomeId)homes.push_back(&h);
    if(homes.size()!=2)throw std::runtime_error("LAND03: expected two non-Scarwater homes");
    p.hollowHomeId=homes[0]->id;p.outlookHomeId=homes[1]->id;
    const double opposite=std::atan2(map.spawnZ-basin.centre.z,map.spawnX-basin.centre.x);
    const double angle=opposite+(cellNoise(map.seed,0,0,110101)-.5)*.35;
    p.direction={std::cos(angle),0,std::sin(angle)};
    p.halfLengthM=cfg.halfLengthM*(.94+.12*cellNoise(map.seed,0,0,110102));
    p.halfWidthM=cfg.halfWidthM*(.89+.22*cellNoise(map.seed,0,0,110103));
    p.ribHeightM=cfg.ribHeightM*(.82+.30*cellNoise(map.seed,0,0,110104));
    p.cutDepthM=cfg.cutDepthM*(.82+.18*cellNoise(map.seed,0,0,110105));
    p.phase=cellNoise(map.seed,0,0,110106)*tau;
    const auto initialWalk=surfaceWalk(map,1);
    bool selected=false;
    // Primary substrate/exposure candidates precede terrain/art. Reachable
    // fallback expands the distance/angle without replacing the world seed.
    for(int i=0;i<cfg.candidateCount+16;++i) {
        const bool fallback=i>=cfg.candidateCount;
        const double a=angle+((i%7)-3)*(fallback?.12:.045);
        const double distance=cfg.centreDistanceM+(i/7)*8+(fallback?12:0);
        p.centre=point(map,map.spawnX+std::cos(a)*distance,map.spawnZ+std::sin(a)*distance);
        p.redSource=local(map,p,18,-9);
        if(protectedPlace(map,p.redSource.x,p.redSource.z,14)||!dryClear(map,initialWalk,p.redSource.x,p.redSource.z,2,2))continue;
        bool roof=true;
        for(int dz=-10;dz<=10&&roof;dz+=2)for(int dx=-10;dx<=10;dx+=2)
            if(!originalRoof(map,p.redSource.x+dx,p.redSource.z+dz,4))roof=false;
        if(!roof)continue;
        p.fallback=fallback;selected=true;break;
    }
    if(!selected) {
        std::pair<double,int> best{1e30,-1};
        const auto desired=point(map,map.spawnX+p.direction.x*(cfg.centreDistanceM+18),map.spawnZ+p.direction.z*(cfg.centreDistanceM+18));
        for(int z=map.spawnZ-260;z<=map.spawnZ+260;z+=4)for(int x=map.spawnX-260;x<=map.spawnX+260;x+=4) {
            const double dx=x-map.spawnX,dz=z-map.spawnZ,d=std::hypot(dx,dz);
            if(d<160||d>260||dx*p.direction.x+dz*p.direction.z<140||protectedPlace(map,x,z,15)||!dryClear(map,initialWalk,x,z,3,2))continue;
            if(!originalRoof(map,x,z,4))continue;
            const double score=std::hypot(x-desired.x,z-desired.z);
            if(score<best.first)best={score,z*map.width+x};
        }
        if(best.second<0)throw std::runtime_error("LAND03: no cave-safe dry source candidate");
        p.redSource=point(map,best.second%map.width,best.second/map.width);
        p.centre=point(map,p.redSource.x-p.direction.x*18-p.direction.z*9,p.redSource.z-p.direction.z*18+p.direction.x*9);
        p.fallback=true;
    }
    p.reveal=local(map,p,-p.halfLengthM*.63,-7);
    const double base=std::min(double(p.centre.y),double(map.at(map.spawnX,map.spawnZ).height)+9);
    const auto rolling=[&](double u,double v) {
        return base+cfg.rollingReliefM*(.58*std::sin(u*.019+p.phase)+.42*std::cos(v*.024-p.phase))+.018*u;
    };
    const auto routePoint=[&](double u,double v,double lift) {
        auto at=local(map,p,u,v);at.y=static_cast<int>(std::round(rolling(u,v)+lift));return at;
    };
    p.lowRoute={p.reveal,routePoint(-52,-18,-p.cutDepthM),routePoint(-18,-22,-p.cutDepthM),routePoint(4,-18,-1),p.redSource};
    p.ridgeRoute={p.reveal,routePoint(-57,26,1),routePoint(-20,35,2),routePoint(20,28,1),p.redSource};
    p.redSource.y=static_cast<int>(std::round(rolling(18,-9)-.7));
    p.lowRoute.back()=p.redSource;p.ridgeRoute.back()=p.redSource;
    const int span=static_cast<int>(std::ceil(p.halfLengthM+p.halfWidthM*.35));
    int minX=std::max(2,p.centre.x-span),maxX=std::min(map.width-2,p.centre.x+span);
    int minZ=std::max(2,p.centre.z-span),maxZ=std::min(map.height-2,p.centre.z+span);
    for(const auto* home:homes) {
        minX=std::max(2,std::min(minX,home->x-60));maxX=std::min(map.width-2,std::max(maxX,home->x+60));
        minZ=std::max(2,std::min(minZ,home->z-60));maxZ=std::min(map.height-2,std::max(maxZ,home->z+60));
    }
    extendDensity(map,minX-2,minZ-2,maxX+2,maxZ+2);
    const auto old=map.cells;
    const int biome=regionBiome(table,"dry_steppe");
    struct MineralRib { double u,v,halfLength,halfWidth,height,turn,slope,bevel; };
    std::vector<MineralRib> ribs;
    // Low, grounded mineral sections have actual breaks, rotated faces and
    // asymmetric caps. A long Gaussian bank alone read as a sand dune.
    for(int row=-2;row<=2;++row)for(int section=-3;section<=3;++section) {
        const auto roll=[&](int salt){return cellNoise(map.seed,row,section,110200+salt);};
        const double u=section*cfg.ribSpacingM+(roll(1)-.5)*11;
        const double v=row*cfg.ribSpacingM+7*std::sin(u*.018+p.phase+row*.8)+row*u*.035;
        ribs.push_back({u,v,8+roll(2)*7,2.7+roll(3)*3.2,p.ribHeightM*(.55+.45*roll(4)),
                        (roll(5)-.5)*.50,(roll(6)-.5)*.12,1.4+roll(7)*1.8});
    }
    std::vector<uint8_t> changed(map.cells.size(),0);
    std::vector<const PlacedNode*> homeSupplies;
    for(const auto& n:map.nodes)if(n.resourceId.rfind("wnv6_homev6_",0)==0)homeSupplies.push_back(&n);
    for(int z=minZ;z<=maxZ;++z)for(int x=minX;x<=maxX;++x) {
        const auto [u,v]=uv(p,x,z);
        const double radial=std::hypot(u/p.halfLengthM,v/p.halfWidthM);
        // Two broad connected dry-country shoulders join the inherited homes
        // to the outward Steppe. They carry ground, growth and shelter together;
        // a biome label at an isolated home centre would not make a place.
        double homeConnection=0,connectionHeight=0;
        for(size_t i=0;i<homes.size();++i) {
            const auto* home=homes[i];
            const auto join=local(map,p,-p.halfLengthM*.40,i==0?-26:26);
            const double dx=join.x-home->x,dz=join.z-home->z,den=dx*dx+dz*dz;
            const double t=den>0?std::clamp(((x-home->x)*dx+(z-home->z)*dz)/den,0.0,1.0):0;
            const double distance=std::hypot(x-home->x-t*dx,z-home->z-t*dz);
            const double width=46+6*std::sin(t*3.14159265+p.phase+i);
            const double weight=ease((width-distance)/24);
            if(weight>homeConnection) {
                homeConnection=weight;
                connectionHeight=home->y+(rolling(-p.halfLengthM*.40,i==0?-26:26)-home->y)*ease(t);
            }
        }
        if((radial>=1&&homeConnection<=0)||protectedPlace(map,x,z)||!originalRoof(map,x,z,2))continue;
        const double country=ease((1-radial)/.23);
        const double blend=std::max(country,homeConnection);
        double target=rolling(u,v);
        // Broken low ribs: broad irregular swells separated by actual gaps.
        // Red's concentrated host swelling changes terrain before dressing.
        double mineral=0;
        for(const auto& rib:ribs) {
            const double du=u-rib.u,dv=v-rib.v;
            if(std::abs(du)>rib.halfLength+5||std::abs(dv)>rib.halfWidth+5)continue;
            const double a=du*std::cos(rib.turn)-dv*std::sin(rib.turn);
            const double b=du*std::sin(rib.turn)+dv*std::cos(rib.turn);
            const double toe=std::min({rib.halfLength-std::abs(a),rib.halfWidth-std::abs(b),
                (rib.halfLength+rib.halfWidth-rib.bevel-std::abs(a)-std::abs(b))*.707});
            double crown=std::max(0.0,std::min(rib.height+rib.slope*a-.12*b,toe*2.7));
            // One oblique cleft interrupts the crown; it is physical native
            // matter, not a painted line or a non-colliding decorative shell.
            const double split=1.2-std::abs(a-rib.halfLength*.30-b*.35);
            if(split>0)crown=std::min(crown,std::max(.0,rib.height*.38-split));
            mineral=std::max(mineral,crown);
        }
        const double cutline=-18+5*std::sin(u*.029+p.phase);
        const double cut=p.cutDepthM*std::exp(-std::pow((v-cutline)/8.5,2))*ease((u+95)/20)*ease((65-u)/28);
        target+=mineral-cut;
        // Swollen mineral concentration overlooks, never occupies, the work floor.
        const double sx=u-22,sz=v-11;
        const double swelling=p.ribHeightM*.66*std::exp(-sx*sx/360-sz*sz/42);
        target+=swelling;
        const double recess=std::exp(-std::pow((u-22)/10,2)-std::pow((v-6)/2.3,2));
        target-=1.25*recess;
        if(homeConnection>country)target=target*country+connectionHeight*(1-country);
        // Each path has different exposure and elevation; both are graded into
        // actual editable terrain with enough clear width for the capsule.
        double routeBlend=0,routeHeight=0;
        for(const auto* route:{&p.lowRoute,&p.ridgeRoute})for(size_t j=1;j<route->size();++j) {
            const auto& a=(*route)[j-1];const auto& b=(*route)[j];
            const double dx=b.x-a.x,dz=b.z-a.z,den=dx*dx+dz*dz;
            const double t=den>0?std::clamp(((x-a.x)*dx+(z-a.z)*dz)/den,0.0,1.0):0;
            const double dist=std::hypot(x-a.x-t*dx,z-a.z-t*dz);
            const double w=ease((cfg.routeWidthM*.5+5-dist)/5);
            if(w>routeBlend){routeBlend=w;routeHeight=a.y+(b.y-a.y)*t;}
        }
        target=target*(1-routeBlend)+routeHeight*routeBlend;
        const double work=ease((cfg.sourceWorkRadiusM+10-std::hypot(x-p.redSource.x,z-p.redSource.z))/10);
        target=target*(1-work)+p.redSource.y*work;
        for(const auto* home:homes) {
            const double d=std::hypot(x-home->x,z-home->z);
            if(d<home->radiusM+30) {
                const double hblend=ease((home->radiusM+26-d)/26);
                const double hu=(x-home->x)*p.direction.x+(z-home->z)*p.direction.z;
                if(home->id==p.hollowHomeId)target+=cfg.homeBankM*std::exp(-std::pow((hu-30)/12,2))*ease((d-home->radiusM)/8);
                target=target*(1-hblend)+home->y*hblend;
            }
        }
        target=old[z*map.width+x].height*(1-blend)+target*blend;
        // Guaranteed finite home supply retains support and reachable working room.
        for(const auto* node:homeSupplies)if(std::hypot(x-node->x,z-node->z)<4)target=old[z*map.width+x].height;
        seat(map,table,x,z,target);changed[z*map.width+x]=1;
        bool homeCore=false;
        for(const auto* home:homes)if(std::hypot(x-home->x,z-home->z)<home->radiusM+3)homeCore=true;
        // The exposed susceptible host is mineral, while the interrupted
        // grass/soil between ribs stays living dry country. Colour cannot
        // substitute for this physical/material distinction.
        if(country>.65&&(mineral>1.05||swelling>1.45)&&routeBlend<.12&&work<.08&&!homeCore) {
            const int top=map.at(x,z).height;
            for(int y=std::max(1,top-3);y<top;++y)
                if(map.blockAt(x,y,z)!=kAir)map.blocks[(static_cast<size_t>(z)*map.width+x)*map.depth+y]=kStone;
        }
        if(radial<.94||homeConnection>.12)map.cells[z*map.width+x].biomeIndex=biome;
    }
    reground(map,old);
    // Long views result from habitat structure, not a global population change.
    // Preserve every guaranteed supply, rare owner and crafted discovery.
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
        if(!changed[n.z*map.width+n.x]||!n.siteId.empty()||!n.habitatId.empty()||n.resourceId.rfind("wnv6_homev6_",0)==0||n.y!=map.at(n.x,n.z).height)return false;
        const bool passage=std::min(pathDistance(n.x,n.z,p.lowRoute),pathDistance(n.x,n.z,p.ridgeRoute))<cfg.routeWidthM*.5+2;
        const bool workplace=std::hypot(n.x-p.redSource.x,n.z-p.redSource.z)<cfg.sourceWorkRadiusM+3;
        return passage||workplace||((n.type=="tree"||n.type=="pine")&&cellNoise(map.seed,n.x,n.z,110120)<.87);
    }),map.nodes.end());
    for(auto& pack:map.packs)if(pack.biome!="cave"&&changed[pack.z*map.width+pack.x])pack.biome="dry_steppe";
    auto walk=physicalWalk(map,minX,minZ,maxX,maxZ);
    p.redSource=reachable(map,walk,p.redSource,18,0);
    p.reveal=reachable(map,walk,p.reveal,20);
    for(auto* route:{&p.lowRoute,&p.ridgeRoute}) {
        route->front()=p.reveal;route->back()=p.redSource;
        for(auto& at:*route)at=reachable(map,walk,at,15);
        std::vector<SurfacePoint> dense;
        for(size_t i=1;i<route->size();++i) {
            auto segment=localRoute(map,walk,(*route)[i-1],(*route)[i]);
            dense.insert(dense.end(),segment.begin(),segment.end());
        }
        *route=std::move(dense);
    }
    p.centre=point(map,p.centre.x,p.centre.z);
    for(int i=0;i<5;++i) {
        auto at=local(map,p,5+i*9,11+3*std::sin(i+p.phase));
        if(changed[at.z*map.width+at.x])p.mineralHosts.push_back(at);
    }
    for(int i=0;i<3;++i)p.releasePockets.push_back(local(map,p,13+i*9,6));
    map.leylineSourceSites.push_back({"red_home_margin",p.redSource,approachTo(map,walk,p.redSource.x,p.redSource.z)});
    // The other existing channels have real supported work anchors. Their
    // substantial authored journeys/selected hosts are deliberately LAND-04.
    const std::vector<std::string> sources={"white_home_margin","blue_home_margin","green_home_margin"};
    for(size_t i=0;i<sources.size();++i) {
        const auto& home=map.homeSites[(i+1)%map.homeSites.size()];
        const double a=std::atan2(home.z-map.spawnZ,home.x-map.spawnX);
        auto target=point(map,home.x+std::cos(a)*29,home.z+std::sin(a)*29);
        std::pair<double,int> best{1e30,-1};
        for(int dz=-38;dz<=38;++dz)for(int dx=-38;dx<=38;++dx) {
            const int x=target.x+dx,z=target.z+dz;
            if(!dryClear(map,walk,x,z,3,0))continue;
            bool occupied=false;
            for(const auto& h:map.homeSites)if(std::hypot(x-h.x,z-h.z)<h.radiusM+5)occupied=true;
            for(const auto& source:map.leylineSourceSites)if(std::hypot(x-source.at.x,z-source.at.z)<34)occupied=true;
            for(const auto& r:map.ruins)if(std::hypot(x-r.x,z-r.z)<std::max(r.widthM,r.depthM)+8)occupied=true;
            if(occupied)continue;
            const double score=dx*dx+dz*dz;
            if(score<best.first)best={score,z*map.width+x};
        }
        if(best.second<0)throw std::runtime_error("LAND03: no supported channel workplace "+sources[i]);
        SurfacePoint at{best.second%map.width,walk.heights[best.second],best.second/map.width};
        map.leylineSourceSites.push_back({sources[i],at,approachTo(map,walk,at.x,at.z)});
    }
    const auto hostDef=std::find_if(rules.hosts.begin(),rules.hosts.end(),[](const auto& h){return h.enemyId=="lf_red_boar";});
    if(hostDef==rules.hosts.end())throw std::runtime_error("LAND03: missing existing Red teaching host");
    const auto desired=local(map,p,69,66);
    std::pair<double,int> best{1e30,-1};
    const int reach=static_cast<int>(rules.hostSourceMaximumM);
    for(int z=p.redSource.z-reach;z<=p.redSource.z+reach;z+=2)for(int x=p.redSource.x-reach;x<=p.redSource.x+reach;x+=2) {
        const double ds=std::hypot(x-p.redSource.x,z-p.redSource.z);
        if(ds<rules.hostSourceMinimumM||ds>rules.hostSourceMaximumM||std::hypot(x-map.spawnX,z-map.spawnZ)<rules.hostMinimumSpawnM)continue;
        if(!dryClear(map,walk,x,z,2,0)||protectedPlace(map,x,z,5))continue;
        bool quiet=false;for(const auto& h:map.homeSites)if(std::hypot(x-h.x,z-h.z)<h.radiusM+25)quiet=true;
        if(quiet||table.biomes[map.at(x,z).biomeIndex].id!="dry_steppe")continue;
        const double score=std::hypot(x-desired.x,z-desired.z)+cellNoise(map.seed,x,z,110140);
        if(score<best.first)best={score,z*map.width+x};
    }
    if(best.second<0)throw std::runtime_error("LAND03: no separated Red teaching-host route");
    PlacedFrontierHost host;
    host.id=hostDef->id;host.sourceId=hostDef->sourceId;host.enemyId=hostDef->enemyId;host.influence=hostDef->influence;
    host.at={best.second%map.width,walk.heights[best.second],best.second/map.width};p.redHost=host.at;
    host.approach=approachTo(map,walk,host.at.x,host.at.z);
    host.sourceRoute=localRoute(map,walk,p.redSource,host.at);
    host.habits={{host.at.x-2,host.at.y,host.at.z},{host.at.x+2,host.at.y,host.at.z}};
    map.frontierHosts.push_back(host);
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](const auto& pack){
        return pack.biome!="cave"&&(std::hypot(pack.x-host.at.x,pack.z-host.at.z)<rules.encounterClearRadiusM||std::hypot(pack.x-p.redSource.x,pack.z-p.redSource.z)<cfg.sourceWorkRadiusM+9);
    }),map.packs.end());
    MobPack teaching;teaching.frontierHostId=host.id;teaching.enemies={host.enemyId};teaching.x=host.at.x;teaching.y=host.at.y;teaching.z=host.at.z;teaching.biome="living_frontier_habitat";
    map.packs.push_back(teaching);
    for(auto& h:map.homeSites) {
        if(!supportedFootprint(map,walk,h.x,h.z,0))throw std::runtime_error("LAND03: home core lost support "+h.id);
        h.approach=approachTo(map,walk,h.x,h.z);
    }
    map.drySteppe.push_back(std::move(p));
}
