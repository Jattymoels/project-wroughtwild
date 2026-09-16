// LAND-02: White impulse shapes a reusable basin before final habitat/discovery
// placement. Published V8 functions are reused only as the underlying draft.
// Stock remains in MachineWorld; this record is regenerated, never saved twice.
// Preserve every original air cell below the old surface cap. Uplift adds
// native stone above that roof; lowering stops above the highest shallow cave.
// The inherited dirt-cap reseater is intentionally not used for these larger
// changes, because its deeper fill range can refill shallow original passages.
void reseatScarwater(WorldMap& map,const tuning::WorldgenTable& table,int x,int z,int height) {
    const int old=map.at(x,z).height;
    height=std::clamp(height,2,map.depth-3);
    if(height<old)for(int y=std::max(1,height-2);y<old;++y)
        if(map.blockAt(x,y,z)==kAir)height=std::max(height,y+3);
    if(height==old)return;
    map.cells[z*map.width+x].height=height;
    auto* column=&map.blocks[(static_cast<size_t>(z)*map.width+x)*map.depth];
    for(int y=std::min(old,height)-1;y<std::max(old,height);++y)
        column[y]=y>=height?kAir:y==height-1?kSurface:y>=height-1-table.strata.dirtDepth?kDirt:kStone;
}
SurfacePoint point(const WorldMap& map,double x,double z) {
    const int ix=std::clamp(static_cast<int>(std::round(x)),2,map.width-3);
    const int iz=std::clamp(static_cast<int>(std::round(z)),2,map.height-3);
    return {ix,map.topSolid(ix,iz),iz};
}
SurfacePoint local(const WorldMap& map,const ScarwaterPlace& p,double u,double v) {
    return point(map,p.centre.x+p.direction.x*u-p.direction.z*v,p.centre.z+p.direction.z*u+p.direction.x*v);
}
std::pair<double,double> uv(const ScarwaterPlace& p,double x,double z) {
    const double dx=x-p.centre.x,dz=z-p.centre.z;
    return {dx*p.direction.x+dz*p.direction.z,-dx*p.direction.z+dz*p.direction.x};
}
bool originalRoof(const WorldMap& map,int x,int z,int cut=6) {
    if(!map.inBounds(x,z)||x<2||z<2||x>=map.width-2||z>=map.height-2)return false;
    const int h=map.at(x,z).height;
    for(int y=std::max(1,h-cut);y<h;++y)if(map.blockAt(x,y,z)==kAir)return false;
    return h>cut+2;
}
bool protectedGround(const WorldMap& map,int x,int z,double pad=0) {
    if(std::hypot(x-map.spawnX,z-map.spawnZ)<32+pad)return true;
    for(const auto& h:map.homeSites)if(std::hypot(x-h.x,z-h.z)<h.radiusM+4+pad)return true;
    for(const auto& m:map.landmarks)if(std::hypot(x-m.x,z-m.z)<12+pad)return true;
    return std::hypot(x-map.gateX,z-map.gateZ)<16+pad;
}
double pathDistance(double x,double z,const std::vector<SurfacePoint>& route) {
    double d=1e9;
    for(size_t i=1;i<route.size();++i)d=std::min(d,segmentDistance(x,z,route[i-1],route[i]));
    return d;
}
void composePlace(WorldMap& map,const tuning::WorldgenTable& table) {
    if(map.lakes.size()!=1||map.homeSites.size()!=4)throw std::runtime_error("Scarwater: missing inherited lake/home draft");
    auto& lake=map.lakes.front();const auto& cfg=table.scarwater;
    ScarwaterPlace p;
    p.lakeId=lake.id;p.outlookHomeId=lake.homeId;p.centre={lake.x,static_cast<int>(std::ceil(lake.surfaceY)),lake.z};
    const double angle=std::atan2(lake.z-map.spawnZ,lake.x-map.spawnX);
    p.direction={std::cos(angle),0,std::sin(angle)};
    p.ridgeHalfLengthM=cfg.ridgeHalfLengthM*(.82+.36*cellNoise(map.seed,0,0,92001));
    p.reliefM=cfg.ridgeReliefM*(.88+.22*cellNoise(map.seed,0,0,92002));
    p.ridgeWidthM=cfg.ridgeWidthM*(.86+.28*cellNoise(map.seed,0,0,92003));
    p.ridgeOffsetM=lake.radiusM+28+12*cellNoise(map.seed,0,0,92004);
    p.ridgeArcM=-10+24*cellNoise(map.seed,0,0,92005);
    p.fissureWidthM=cfg.fissureWidthM;p.fissureDepthM=cfg.fissureDepthM;
    p.fissureLengthM=cfg.fissureLengthM;p.woodlandBandM=cfg.woodlandBandM;
    // Stable bounded dry-bank candidates; host selection precedes reshaping.
    // Last candidates broaden the shoulder/reduce relief, never omit the slot.
    bool selected=false;
    for(int i=0;i<cfg.candidateCount+8;++i) {
        const bool fallback=i>=cfg.candidateCount;
        const double u=lake.radiusM+(fallback?43:22)+(i%4)*6;
        const double v=-p.ridgeHalfLengthM*.60+(i/4)*11;
        const auto scar=local(map,p,u,v),smithy=local(map,p,u-9,v-26);
        bool safe=true;
        for(int along=-15;along<=15&&safe;++along)for(int across=-6;across<=6;++across) {
            const auto at=local(map,p,u+across,v+along);
            if(!originalRoof(map,at.x,at.z,2)||protectedGround(map,at.x,at.z)||lake.bedAt(at.x,at.z)<lake.surfaceY){safe=false;break;}
        }
        for(int dz=-8;dz<=8&&safe;++dz)for(int dx=-8;dx<=8;++dx)
            if(!originalRoof(map,smithy.x+dx,smithy.z+dz,2)||protectedGround(map,smithy.x+dx,smithy.z+dz)){safe=false;break;}
        if(!safe)continue;
        p.scar=scar;p.smithy=smithy;p.fallback=fallback;selected=true;
        if(fallback){p.reliefM*=.83;p.ridgeWidthM*=1.15;}
        break;
    }
    if(!selected)throw std::runtime_error("Scarwater: no cave-safe dry fissure/smithy candidate");
    double groveScore=1e30;
    for(const auto& h:map.homeSites)if(h.id!=p.outlookHomeId) {
        const auto q=uv(p,h.x,h.z);
        const double score=std::hypot(h.x-p.smithy.x,h.z-p.smithy.z)+(q.second>0?35:0);
        if(score<groveScore){groveScore=score;p.groveHomeId=h.id;}
    }
    p.reveal=local(map,p,-lake.radiusM-11,-5);
    // Different banks, lengths and exposure, rather than two copies of a path.
    for(int i=0;i<=14;++i) {
        const double a=3.141592653589793*(1.0-i/14.0);
        const double radius=lake.radiusM+18;
        p.shelteredRoute.push_back(local(map,p,std::cos(a)*radius,-std::sin(a)*(radius*lake.aspect+11)));
        p.outlookRoute.push_back(local(map,p,std::cos(a)*(radius+7),std::sin(a)*(radius*lake.aspect+23)));
    }
    // Both routes end on the dry work terrace; join on the lakeward side of cut.
    auto near=local(map,p,lake.radiusM+9,-8);
    p.shelteredRoute.push_back(near);p.shelteredRoute.push_back(p.smithy);
    p.outlookRoute.push_back(near);p.outlookRoute.push_back(p.smithy);
    const auto old=map.cells;
    // Impulse lifts the shoulder before exposing it. Set the lip above the old
    // roof rather than cutting a lake-level terrace through inherited caves.
    int lipHeight=static_cast<int>(std::ceil(lake.surfaceY))+3;
    for(int dz=-16;dz<=16;++dz)for(int dx=-16;dx<=16;++dx)
        lipHeight=std::max(lipHeight,map.at(p.scar.x+dx,p.scar.z+dz).height+2);
    const auto scarUV=uv(p,p.scar.x,p.scar.z);
    const int span=static_cast<int>(p.ridgeHalfLengthM+p.ridgeWidthM+lake.radiusM+30);
    const int gallery=regionBiome(table,"gallery_woodland"),meadow=regionBiome(table,"meadow"),rock=regionBiome(table,"rocky_hills");
    const double phase=cellNoise(map.seed,0,0,92006)*tau;
    for(int z=std::max(2,lake.z-span);z<std::min(map.height-2,lake.z+span);++z)
      for(int x=std::max(2,lake.x-span);x<std::min(map.width-2,lake.x+span);++x) {
        if(protectedGround(map,x,z)||!originalRoof(map,x,z,2)||lake.bedAt(x,z)<lake.surfaceY)continue;
        const auto q=uv(p,x,z);const double u=q.first,v=q.second;
        const double segment=(v+p.ridgeHalfLengthM)/(p.ridgeHalfLengthM*.57);
        const double segmentT=segment-std::floor(segment);
        const double offset=std::floor(segment)*3.5;
        const double ridgeCentre=p.ridgeOffsetM+p.ridgeArcM*std::pow(v/p.ridgeHalfLengthM,2)+offset;
        const double along=ease((p.ridgeHalfLengthM-std::abs(v))/24);
        const double front=ease((u-(ridgeCentre-p.ridgeWidthM*.42))/(p.ridgeWidthM*.24));
        const double back=ease((ridgeCentre+p.ridgeWidthM-u)/p.ridgeWidthM);
        const double ribs=(.82+.18*segmentT)*(1-.24*std::exp(-std::pow((segmentT-.06)/.075,2)));
        double target=old[z*map.width+x].height+p.reliefM*along*front*back*ribs;
        const double bank=std::hypot(u,v/lake.aspect)-lake.radiusM;
        const double terrace=ease((30-bank)/18)*ease((bank+1)/8);
        target=target*(1-terrace)+(lake.surfaceY+1.8+1.2*std::sin(v*.026+phase))*terrace;
        // Dry old work ground meets the open fissure lip. Only the roof/cap
        // changes: original caves below and openings outside this host survive.
        const double sd=std::hypot(x-p.scar.x,z-p.scar.z),wd=std::hypot(x-p.smithy.x,z-p.smithy.z);
        const double flat=std::max(ease((24-sd)/9),ease((21-wd)/9));
        const double lip=lipHeight;
        target=target*(1-flat)+lip*flat;
        // Routes are 5m passages with soft shoulders; no hidden walk collider.
        const double rd=std::min(pathDistance(x,z,p.shelteredRoute),pathDistance(x,z,p.outlookRoute));
        const double route=ease((cfg.routeWidthM+4-rd)/4);
        // Gain elevation over the full bank approach, not a short steep ramp
        // at the far shore. This also accommodates the higher fallback host.
        const double climb=ease((u+lake.radiusM+16)/(scarUV.first-9+lake.radiusM+16));
        if(bank>2&&rd<cfg.routeWidthM+4&&sd>17)target=target*(1-route)+(std::ceil(lake.surfaceY)+2+(lip-std::ceil(lake.surfaceY)-2)*climb)*route;
        // Protected homes meet their surroundings through a soft collar,
        // never a one-cell height jump at the reservation boundary.
        double protectedBlend=1;
        for(const auto& home:map.homeSites)protectedBlend=std::min(protectedBlend,ease((std::hypot(x-home.x,z-home.z)-home.radiusM-4)/14));
        for(const auto& landmark:map.landmarks)protectedBlend=std::min(protectedBlend,ease((std::hypot(x-landmark.x,z-landmark.z)-12)/14));
        protectedBlend=std::min(protectedBlend,ease((std::hypot(x-map.spawnX,z-map.spawnZ)-32)/16));
        protectedBlend=std::min(protectedBlend,ease((std::hypot(x-map.gateX,z-map.gateZ)-16)/14));
        target=old[z*map.width+x].height+(target-old[z*map.width+x].height)*protectedBlend;
        // A true native open slot, tapered at the ends to a walkable ramp.
        const double su=u-scarUV.first,sv=v-scarUV.second;
        const double cross=ease((p.fissureWidthM*.5-std::abs(su))/1.3);
        const double ends=ease((p.fissureLengthM*.5-std::abs(sv))/7);
        if(std::abs(su)<p.fissureWidthM*.5&&std::abs(sv)<p.fissureLengthM*.5)
            target=lip-p.fissureDepthM*cross*ends;
        reseatScarwater(map,table,x,z,static_cast<int>(std::round(target)));
        // Ecological biome distinct from discovery regions: bank/shelter and
        // roots follow the effect, while open water/views stay unplanted.
        const bool band=bank>5&&bank<5+p.woodlandBandM+5*std::sin(v*.03+phase)&&v<8&&u<lake.radiusM+20;
        bool grove=false;
        for(const auto& h:map.homeSites)if(h.id==p.groveHomeId)
            grove=std::hypot(x-h.x,z-h.z)<h.radiusM+cfg.woodlandBandM+13&&std::hypot(x-h.x,z-h.z)>h.radiusM+4;
        if(band||grove)map.cells[z*map.width+x].biomeIndex=gallery;
        else if(along*front*back>.32&&flat<.4&&rd>cfg.routeWidthM+3)map.cells[z*map.width+x].biomeIndex=rock;
        else if(bank>0&&bank<30)map.cells[z*map.width+x].biomeIndex=meadow;
        if(sd<16||cross*ends>.1)map.cells[z*map.width+x].biomeIndex=rock;
    }
    reground(map,old);
    // Existing finite ordinary sources become the bank canopy. Remove original
    // rolls only inside new native water/route/cut/work clearances.
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
        if(n.y!=map.at(n.x,n.z).height||!n.siteId.empty()||!n.habitatId.empty())return false;
        const double rd=std::min(pathDistance(n.x,n.z,p.shelteredRoute),pathDistance(n.x,n.z,p.outlookRoute));
        const auto q=uv(p,n.x,n.z);
        const bool view=std::abs(q.second)<11&&q.first>-lake.radiusM-23&&q.first<lake.radiusM+10;
        return view||rd<cfg.routeWidthM*.55||std::hypot(n.x-p.scar.x,n.z-p.scar.z)<19||std::hypot(n.x-p.smithy.x,n.z-p.smithy.z)<13;
    }),map.nodes.end());
    for(int z=std::max(2,lake.z-span);z<std::min(map.height-2,lake.z+span);z+=7)
      for(int x=std::max(2,lake.x-span);x<std::min(map.width-2,lake.x+span);x+=7) {
        const auto q=uv(p,x,z);
        if(std::abs(q.second)<11&&q.first>-lake.radiusM-23&&q.first<lake.radiusM+10)continue;
        if(map.at(x,z).biomeIndex!=gallery||protectedGround(map,x,z,3)||!originalRoof(map,x,z,2))continue;
        if(std::min(pathDistance(x,z,p.shelteredRoute),pathDistance(x,z,p.outlookRoute))<5)continue;
        if(cellNoise(map.seed,x,z,92007)>.78)continue;
        bool occupied=false;for(const auto& n:map.nodes)if(distanceSquared(x,z,n.x,n.z)<36){occupied=true;break;}
        if(occupied)continue;
        PlacedNode tree{"tree",x,map.topSolid(x,z),z};tree.resourceId="wnv9_gallery_"+std::to_string(x)+"_"+std::to_string(z);map.nodes.push_back(tree);
    }
    for(int i=0;i<=18;++i) {
        const double v=-p.ridgeHalfLengthM+i*p.ridgeHalfLengthM/9;
        const double u=p.ridgeOffsetM+p.ridgeArcM*std::pow(v/p.ridgeHalfLengthM,2)+4*std::sin(v*.035+phase);
        p.ridge.push_back(local(map,p,u,v));
    }
    p.scar.y=map.topSolid(p.scar.x,p.scar.z);p.smithy.y=map.topSolid(p.smithy.x,p.smithy.z);
    p.reveal.y=map.topSolid(p.reveal.x,p.reveal.z);
    for(auto* route:{&p.shelteredRoute,&p.outlookRoute})for(auto& at:*route)at.y=map.topSolid(at.x,at.z);
    map.scarwater.push_back(p);
}

void seatSmithy(WorldMap& map,const tuning::WorldgenTable& table) {
    auto& p=map.scarwater.front();
    auto it=std::find_if(map.ruins.begin(),map.ruins.end(),[](const auto& r){return r.linkedSiteId=="rsv6_ventlung_primary_0";});
    if(it==map.ruins.end())throw std::runtime_error("Scarwater: existing smithy identity missing");
    auto& ruin=*it;ruin.x=p.smithy.x;ruin.z=p.smithy.z;ruin.y=map.topSolid(ruin.x,ruin.z);
    const int hx=map.spawnX-ruin.x,hz=map.spawnZ-ruin.z;
    ruin.rotationQuarters=std::abs(hz)>=std::abs(hx)?(hz>=0?0:2):(hx>=0?1:3);
    const int half=static_cast<int>(std::ceil(std::max(ruin.widthM,ruin.depthM)*.5));
    const int ex[]={0,1,0,-1},ez[]={1,0,-1,0};
    ruin.entrance={ruin.x+ex[ruin.rotationQuarters]*(half-1),ruin.y,ruin.z+ez[ruin.rotationQuarters]*(half-1)};
    ruin.foundation.clear();
    const auto old=map.cells;
    for(int dz=-half-8;dz<=half+8;++dz)for(int dx=-half-8;dx<=half+8;++dx) {
        const int x=ruin.x+dx,z=ruin.z+dz;
        if(!originalRoof(map,x,z,2))continue;
        const double blend=ease(1.0-std::max(0,std::max(std::abs(dx),std::abs(dz))-half)/8.0);
        reseatScarwater(map,table,x,z,static_cast<int>(std::round(map.at(x,z).height*(1-blend)+ruin.y*blend)));
        if(std::abs(dx)<=half&&std::abs(dz)<=half)ruin.foundation.push_back({x,ruin.y,z});
    }
    reground(map,old);
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){return n.siteId.empty()&&n.habitatId.empty()&&ruinFootprint(ruin,n.x,n.z,3);}),map.nodes.end());
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](const auto& pack){return pack.biome!="cave"&&ruinFootprint(ruin,pack.x,pack.z,8);}),map.packs.end());
    auto branch=std::find_if(map.leylines.begin(),map.leylines.end(),[&](const auto& l){return l.id==ruin.leylineId;});
    if(branch!=map.leylines.end())branch->points.back()={ruin.x,ruin.y,ruin.z};
    for(auto* route:{&p.shelteredRoute,&p.outlookRoute}) {route->back()=ruin.entrance;}
}

// The bank path must fit the existing capsule, not just a point flood over
// integer heights. Match V9's four shared roof corners, reject steep fan
// triangles and keep one cell away from their edges. No movement rule changes.
auto bankWalk(const WorldMap& map,const ScarwaterPlace& place) {
    auto walk=surfaceWalk(map,1);
    auto safe=walk.clear;
    const int radius=static_cast<int>(place.ridgeHalfLengthM+map.lakes.front().radiusM+65);
    const int minX=std::max(3,place.centre.x-radius),maxX=std::min(map.width-3,place.centre.x+radius);
    const int minZ=std::max(3,place.centre.z-radius),maxZ=std::min(map.height-3,place.centre.z+radius);
    for(int z=minZ;z<maxZ;++z)for(int x=minX;x<maxX;++x) {
        double hs[4];bool valid=true;
        const int cx[]={0,1,1,0},cz[]={0,0,1,1};
        for(int corner=0;corner<4;++corner) {
            int low=map.depth,high=0;double sum=0;
            for(int dz=-1;dz<=0;++dz)for(int dx=-1;dx<=0;++dx) {
                const int a=x+cx[corner]+dx,b=z+cz[corner]+dz,h=map.at(a,b).height;
                low=std::min(low,h);high=std::max(high,h);sum+=h;
                valid=valid&&originalRoof(map,a,b,2);
            }
            valid=valid&&high-low<=2;hs[corner]=sum*.25;
        }
        const double middle=(hs[0]+hs[1]+hs[2]+hs[3])*.25;
        for(int i=0;i<4;++i) {
            const double edge=hs[(i+1)%4]-hs[i],inward=2*(middle-(hs[i]+hs[(i+1)%4])*.5);
            if(edge*edge+inward*inward>.75*.75)valid=false;
        }
        if(!valid)safe[z*map.width+x]=false;
    }
    for(int z=minZ+1;z<maxZ-1;++z)for(int x=minX+1;x<maxX-1;++x) {
        if(!walk.clear[z*map.width+x])continue;
        for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx)
            if(!safe[(z+dz)*map.width+x+dx])walk.clear[z*map.width+x]=false;
    }
    std::fill(walk.parent.begin(),walk.parent.end(),-1);
    const int start=map.spawnZ*map.width+map.spawnX;
    std::queue<int> pending;pending.push(start);walk.parent[start]=start;
    const int dx[]={1,0,-1,0},dz[]={0,1,0,-1};
    while(!pending.empty()) {
        const int at=pending.front();pending.pop();
        for(int d=0;d<4;++d) {
            const int x=at%map.width+dx[d],z=at/map.width+dz[d];
            if(!map.inBounds(x,z))continue;
            const int next=z*map.width+x;
            if(!walk.clear[next]||walk.parent[next]>=0||std::abs(walk.heights[next]-walk.heights[at])>1)continue;
            walk.parent[next]=at;pending.push(next);
        }
    }
    return walk;
}

void finish(WorldMap& map,const tuning::WorldgenTable& table) {
    auto& p=map.scarwater.front();const auto& source=map.pressurePockets.front();
    p.pressureId=source.id;p.ruinId=source.ruinId;
    // The inherited pressure source remains one finite, accidental owner.
    // Its strike echoes the same displacement direction; no coloured LF stock.
    for(auto& impact:map.impacts)if(impact.id==source.impactId)impact.impactDirection=p.direction;
    for(auto& ruin:map.ruins)if(ruin.id==source.ruinId)ruin.damageDirection=p.direction;
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
        if(!n.siteId.empty()||!n.habitatId.empty()||n.resourceId.rfind("wnv6_homev6_",0)==0||n.y!=map.at(n.x,n.z).height)return false;
        return std::min(pathDistance(n.x,n.z,p.shelteredRoute),pathDistance(n.x,n.z,p.outlookRoute))<3;
    }),map.nodes.end());
    const auto walk=bankWalk(map,p);
    for(auto* route:{&p.shelteredRoute,&p.outlookRoute}) {
        // Store dense native routes via the selected distinct bank waypoints.
        std::vector<SurfacePoint> dense;
        for(auto& waypoint:*route) {
            if(walk.parent[waypoint.z*map.width+waypoint.x]>=0)continue;
            bool found=false;
            for(int ring=1;ring<=24&&!found;++ring)for(int dz=-ring;dz<=ring&&!found;++dz)for(int dx=-ring;dx<=ring;++dx) {
                const int x=waypoint.x+dx,z=waypoint.z+dz;
                if(map.inBounds(x,z)&&walk.parent[z*map.width+x]>=0) {waypoint={x,walk.heights[z*map.width+x],z};found=true;break;}
            }
            if(!found)throw std::runtime_error("Scarwater: no reachable bank waypoint at "+std::to_string(waypoint.x)+","+std::to_string(waypoint.z));
        }
        for(size_t i=1;i<route->size();++i) {
            auto a=(*route)[i-1],b=(*route)[i];
            if(walk.parent[a.z*map.width+a.x]<0||walk.parent[b.z*map.width+b.x]<0)
                throw std::runtime_error("Scarwater: bank route waypoint unreachable");
            auto segment=localRoute(map,walk,a,b);dense.insert(dense.end(),segment.begin(),segment.end());
        }
        *route=std::move(dense);
    }
    // Appropriate existing ordinary fauna in the recovered habitat. These are
    // standard grazers with unchanged bodies/rewards, no White host powers.
    for(int side:{-1,1}) {
        auto at=local(map,p,-map.lakes.front().radiusM*.25,side*(map.lakes.front().radiusM+26));
        if(walk.parent[at.z*map.width+at.x]<0)continue;
        MobPack pack;pack.x=at.x;pack.y=at.y;pack.z=at.z;pack.grazer=true;
        pack.biome=side<0?"gallery_woodland":"meadow";pack.enemies={"valley_elk"};map.packs.push_back(pack);
    }
    (void)table;
}

// Reuse the established finite discovery sequence after all home land edits.
void composeFrontierV6Landscape(WorldMap& map, const tuning::WorldgenTable& table) {
    if(table.regions.size()!=3||table.rareSites.size()!=5)
        throw std::runtime_error("worldgen: frontier_v6 needs its complete region and rare-site definitions");
    composeRegions(map,table);
    composeReclaimedLand(map,table);
    // Ordinary rolls follow the final region, at the same bounded outer density.
    repopulateRegionResources(map,table);
    // Two authored lake proportions, selected by the seed, combine with its
    // independent radius/orientation/country. Both retain the fixed-water rules.
    auto basinTable=table;
    if((map.seed&1)==0)basinTable.lake.aspect-=table.scarwater.lakeAspectDelta;
    composeReclaimedHomes(map,basinTable);
    composePlace(map,table);
    moveProgressionSites(map,table);
    placeWideHabitats(map,table);
    addRootvaultCave(map,table);
    placeRuinFoundations(map,table);
    seatSmithy(map,table);
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n){
        if(!n.habitatId.empty())return false;
        for(const auto& a:map.impacts)if(distanceSquared(n.x,n.z,a.x,a.z)<64)return true;
        return false;
    }),map.nodes.end());
    const auto walk=surfaceWalk(map,1);
    for(auto& ruin:map.ruins){
        if(walk.parent[ruin.entrance.z*map.width+ruin.entrance.x]<0)
            throw std::runtime_error("worldgen: ruin foundation has no ordinary entrance "+ruin.id);
        ruin.approach=approachTo(map,walk,ruin.entrance.x,ruin.entrance.z);
    }
    for(auto& impact:map.impacts){
        int selected=-1;
        for(int ring=0;ring<=12&&selected<0;++ring)for(int dz=-ring;dz<=ring&&selected<0;++dz)for(int dx=-ring;dx<=ring;++dx){
            if(supportedFootprint(map,walk,impact.x+dx,impact.z+dz,1)){selected=(impact.z+dz)*map.width+impact.x+dx;break;}
        }
        if(selected<0)throw std::runtime_error("worldgen: impact has no reachable reveal");
        impact.approach=approachTo(map,walk,selected%map.width,selected/map.width);
    }
    for(auto& habitat:map.habitats) {
        if(walk.parent[habitat.z*map.width+habitat.x]<0)
            throw std::runtime_error("worldgen: cave interrupted a material habitat route");
        habitat.approach=approachTo(map,walk,habitat.x,habitat.z);
    }
    for(auto& region:map.regions) {
        if(!supportedFootprint(map,walk,region.x,region.z,1)) {
            bool found=false;
            for(int ring=1;ring<=12&&!found;++ring)for(int dz=-ring;dz<=ring&&!found;++dz)for(int dx=-ring;dx<=ring;++dx)
                if(supportedFootprint(map,walk,region.x+dx,region.z+dz,1)) {
                    region.approach=approachTo(map,walk,region.x+dx,region.z+dz);found=true;break;
                }
            if(!found)throw std::runtime_error("worldgen: no reachable regional clearing "+region.id);
        } else region.approach=approachTo(map,walk,region.x,region.z);
        if(!region.caveApproach.empty()) {
            const auto& entrance=region.caveApproach.front();
            if(walk.parent[entrance.z*map.width+entrance.x]<0)
                throw std::runtime_error("worldgen: rootvault cave approach is inaccessible");
            auto surface=approachTo(map,walk,entrance.x,entrance.z);
            surface.insert(surface.end(),region.caveApproach.begin()+1,region.caveApproach.end());
            region.caveApproach=std::move(surface);
        }
    }
    updateAugmentation(map,table);
    placeRareSites(map,table);
    protectDiscoveryRoutes(map,table);
    finishHistoryRoutes(map,table);
}
