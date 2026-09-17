// LAND-04 isolated successor. All published V11 country is composed first;
// physical host selection precedes this slice's local landform, plant anchors,
// final sources and finite encounter placement. No economy or campaign state.
using namespace lake_frontier;
using dry_steppe_frontier::seat;
using dry_steppe_frontier::extendDensity;
using dry_steppe_frontier::physicalWalk;
using dry_steppe_frontier::dryClear;
using fractured_frontier::point;
using fractured_frontier::pathDistance;
using fractured_frontier::originalRoof;

SurfacePoint local(const WorldMap& map,const ForceJourney& j,double u,double v) {
    return point(map,j.at.x+j.direction.x*u-j.direction.z*v,j.at.z+j.direction.z*u+j.direction.x*v);
}
SurfacePoint workStance(const WorldMap& map,const ForceJourney& j) {
    const bool alongX=std::abs(j.direction.x)>=std::abs(j.direction.z);
    return point(map,j.at.x+(alongX?(j.direction.x>0?-2:2):0),
                     j.at.z+(!alongX?(j.direction.z>0?-2:2):0));
}
std::pair<double,double> localUV(const ForceJourney& j,double x,double z) {
    const double dx=x-j.at.x,dz=z-j.at.z;
    return {dx*j.direction.x+dz*j.direction.z,-dx*j.direction.z+dz*j.direction.x};
}
std::string biomeAt(const WorldMap& map,const tuning::WorldgenTable& table,int x,int z) {
    return table.biomes[map.at(x,z).biomeIndex].id;
}
// Protect inherited guarantees and every physical water/cave owner. The
// deliberately smaller bank margin permits nearby rooted White composition
// without touching the approved Scarwater rock masses or its existing routes.
bool protectedGround(const WorldMap& map,int x,int z,double pad=0) {
    if(x<4||z<4||x>=map.width-4||z>=map.height-4)return true;
    if(std::hypot(x-map.spawnX,z-map.spawnZ)<55+pad)return true;
    for(const auto& h:map.homeSites)if(std::hypot(x-h.x,z-h.z)<h.radiusM+8+pad)return true;
    for(const auto& l:map.lakes)if(l.bedAt(x,z)!=255||std::hypot(x-l.x,z-l.z)<l.radiusM+12+pad)return true;
    for(const auto& p:map.scarwater) {
        if(pathDistance(x,z,p.ridge)<13+pad||std::hypot(x-p.scar.x,z-p.scar.z)<22+pad||std::hypot(x-p.smithy.x,z-p.smithy.z)<24+pad)return true;
        if(std::min(pathDistance(x,z,p.shelteredRoute),pathDistance(x,z,p.outlookRoute))<5+pad)return true;
    }
    for(const auto& p:map.drySteppe) {
        if(std::hypot(x-p.redSource.x,z-p.redSource.z)<28+pad||std::hypot(x-p.redHost.x,z-p.redHost.z)<23+pad)return true;
        if(std::min(pathDistance(x,z,p.lowRoute),pathDistance(x,z,p.ridgeRoute))<4+pad)return true;
    }
    for(const auto& h:map.habitats)if(std::hypot(x-h.x,z-h.z)<h.radiusM+3+pad)return true;
    for(const auto& r:map.rareSites)if(std::hypot(x-r.x,z-r.z)<r.radiusM+5+pad)return true;
    for(const auto& r:map.ruins)if(std::hypot(x-r.x,z-r.z)<std::max(r.widthM,r.depthM)+7+pad)return true;
    for(const auto& r:map.pressurePockets)if(std::hypot(x-r.x,z-r.z)<r.radiusM+10+pad)return true;
    for(const auto& r:map.landmarks)if(std::hypot(x-r.x,z-r.z)<20+pad)return true;
    return std::hypot(x-map.gateX,z-map.gateZ)<22+pad;
}
bool woodland(const std::string& b) {return b=="forest"||b=="gallery_woodland";}
bool eligible(const std::string& channel,const std::string& biome,bool fallback,bool secondary) {
    if(secondary)return biome=="dry_steppe";
    if(channel=="blue")return biome=="fen"||(fallback&&biome=="rocky_hills");
    if(channel=="green")return woodland(biome);
    return woodland(biome)||biome=="rocky_hills";
}

struct RouteField {std::vector<int> parent, distance;};
RouteField routeField(const WorldMap& map,const frozen_frontier::SurfaceWalk& walk,SurfacePoint start) {
    RouteField out;out.parent.assign(map.cells.size(),-1);out.distance.assign(map.cells.size(),-1);
    const int origin=start.z*map.width+start.x;out.parent[origin]=origin;out.distance[origin]=0;
    std::queue<int> todo;todo.push(origin);
    const int dx[]={1,0,-1,0},dz[]={0,1,0,-1};
    while(!todo.empty()) {
        const int at=todo.front();todo.pop();
        for(int d=0;d<4;++d) {
            const int x=at%map.width+dx[d],z=at/map.width+dz[d];if(!map.inBounds(x,z))continue;
            const int next=z*map.width+x;
            if(out.parent[next]>=0||!walk.clear[next]||std::abs(walk.heights[next]-walk.heights[at])>1)continue;
            out.parent[next]=at;out.distance[next]=out.distance[at]+1;todo.push(next);
        }
    }
    return out;
}
ForceJourney selectSite(const WorldMap& map,const tuning::WorldgenTable& table,
                        const frozen_frontier::SurfaceWalk& walk,const tuning::LivingFrontierTable& rules,const std::string& channel,bool secondary) {
    const auto& cfg=table.forceJourneys;
    ForceJourney j;j.channel=channel;j.secondary=secondary;j.radiusM=secondary?cfg.radiusM*.72:cfg.radiusM;
    j.id="journey_"+channel+(secondary?"_steppe":"_source");j.sourceId=secondary?"":channel+"_home_margin";
    j.phase=cellNoise(map.seed,0,0,frozen_frontier::stableSalt(j.id))*tau;
    SurfacePoint desired=point(map,map.spawnX,map.spawnZ);
    if(secondary)desired=local(map,map.forceJourneys.back(),0,0);
    else for(const auto& source:map.leylineSourceSites)if(source.sourceId==j.sourceId)desired=source.at;
    std::pair<double,int> best{1e30,-1};
    // The fallback is a bounded second eligibility/search pass, never a seed
    // retry or a biome relabel. Blue uses actual fen first, then dry hills.
    for(int pass=0;pass<3&&best.second<0;++pass) {
        const bool wider=pass>0, hills=pass==2;
        const int reach=static_cast<int>(wider?cfg.fallbackSearchM:cfg.primarySearchM);
        if(reach==0)continue;
        const int stride=cfg.candidateStrideM;
        std::vector<std::pair<double,int>> candidates;
        for(int z=std::max(40,map.spawnZ-reach);z<=std::min(map.height-40,map.spawnZ+reach);z+=stride)
            for(int x=std::max(40,map.spawnX-reach);x<=std::min(map.width-40,map.spawnX+reach);x+=stride) {
                const double spawn=std::hypot(x-map.spawnX,z-map.spawnZ);
                if(spawn<125||spawn>reach||protectedGround(map,x,z,9))continue;
                const auto biome=biomeAt(map,table,x,z);
                if(!eligible(channel,biome,hills,secondary))continue;
                if(channel=="blue"&&hills&&biome!="rocky_hills")continue;
                if(!dryClear(map,walk,x,z,3,0)||!originalRoof(map,x,z,5))continue;
                bool reject=false;
                for(const auto& other:map.forceJourneys)if(std::hypot(x-other.at.x,z-other.at.z)<cfg.sourceSeparationM)reject=true;
                for(const auto& source:map.leylineSourceSites)if(source.sourceId=="red_home_margin"&&std::hypot(x-source.at.x,z-source.at.z)<cfg.sourceSeparationM)reject=true;
                for(const auto& host:map.frontierHosts)if(std::hypot(x-host.at.x,z-host.at.z)<55)reject=true;
                if(reject)continue;
                // Most of the growth/physical envelope must retain the named
                // host biome, and the source itself needs an untouched roof.
                int supported=0,matching=0;
                for(int dz=-18;dz<=18;dz+=9)for(int dx=-18;dx<=18;dx+=9) {
                    if(!protectedGround(map,x+dx,z+dz)&&originalRoof(map,x+dx,z+dz,3))++supported;
                    if(eligible(channel,biomeAt(map,table,x+dx,z+dz),hills,secondary))++matching;
                }
                if(supported<20||matching<18)continue;
                const double prefer=channel=="white"&&biome=="gallery_woodland"?-55:0;
                const double score=spawn*.14+std::hypot(x-desired.x,z-desired.z)*.16+prefer+cellNoise(map.seed,x,z,frozen_frontier::stableSalt(j.id))*9;
                candidates.push_back({score,z*map.width+x});
            }
        std::sort(candidates.begin(),candidates.end());
        // Source and animal form one journey. A supported woodland source is
        // not eligible if all of its nearby clearings lie across a long detour
        // or in the wrong host biome. Preflight only the best bounded shortlist.
        for(size_t choice=0;choice<std::min<size_t>(48,candidates.size());++choice) {
            const auto candidate=candidates[choice];
            if(secondary){best=candidate;break;}
            const auto source=point(map,candidate.second%map.width,candidate.second/map.width);
            const auto paths=routeField(map,walk,source);
            const auto sourceBiome=biomeAt(map,table,source.x,source.z);
            bool viable=false;SurfacePoint candidateHost;
            const int hostReach=static_cast<int>(rules.hostSourceMaximumM);
            for(int z=source.z-hostReach;z<=source.z+hostReach&&!viable;z+=2)for(int x=source.x-hostReach;x<=source.x+hostReach;x+=2) {
                if(!map.inBounds(x,z))continue;
                const double ds=std::hypot(x-source.x,z-source.z);
                if(ds<rules.hostSourceMinimumM||ds>rules.hostSourceMaximumM||std::hypot(x-map.spawnX,z-map.spawnZ)<rules.hostMinimumSpawnM)continue;
                const int distance=paths.distance[z*map.width+x];
                if(distance<rules.hostSourceMinimumM||distance>rules.hostSourceMaximumM-3||!dryClear(map,walk,x,z,2,0)||protectedGround(map,x,z,4))continue;
                const auto b=biomeAt(map,table,x,z);
                if(channel=="green"&&!woodland(b))continue;
                if(channel=="blue"&&b!=sourceBiome)continue;
                if(channel=="white"&&!(woodland(b)||b=="meadow"||b=="rocky_hills"))continue;
                bool occupied=false;
                for(const auto& h:map.frontierHosts)if(std::hypot(x-h.at.x,z-h.at.z)<rules.hostSeparationM)occupied=true;
                for(const auto& h:map.homeSites)if(std::hypot(x-h.x,z-h.z)<h.radiusM+25)occupied=true;
                for(const auto& other:map.leylineSourceSites)if(other.sourceId!=j.sourceId&&std::hypot(x-other.at.x,z-other.at.z)<45)occupied=true;
                if(!occupied){viable=true;candidateHost=point(map,x,z);break;}
            }
            if(viable) {
                best=candidate;j.hostAt=candidateHost;
                // Retain the preflight's actual path, not just its boolean
                // result. Local bank composition must preserve the route that
                // made this source/host pair eligible in the first place.
                for(int cell=candidateHost.z*map.width+candidateHost.x;;cell=paths.parent[cell]) {
                    j.hostRoute.push_back({cell%map.width,walk.heights[cell],cell/map.width});
                    if(paths.parent[cell]==cell)break;
                }
                std::reverse(j.hostRoute.begin(),j.hostRoute.end());
                break;
            }
        }
        if(best.second>=0)j.fallback=wider;
    }
    if(best.second<0)throw std::runtime_error("LAND04: no supported eligible "+j.id);
    j.at=point(map,best.second%map.width,best.second/map.width);j.biome=biomeAt(map,table,j.at.x,j.at.z);
    double angle=std::atan2(j.at.z-map.spawnZ,j.at.x-map.spawnX)+(cellNoise(map.seed,j.at.x,j.at.z,120041)-.5)*.8;
    if(channel=="white"&&!map.scarwater.empty())angle=std::atan2(map.scarwater[0].direction.z,map.scarwater[0].direction.x)+(cellNoise(map.seed,j.at.x,j.at.z,120042)-.5)*.4;
    j.direction={std::cos(angle),0,std::sin(angle)};
    j.host=channel=="white"?"offset_mineral_braced_roots":channel=="blue"?(j.biome=="fen"?"retained_fen_banks_sheaths":"retained_hill_laminations_bracts"):
        secondary?"low_steppe_shrub_root_colony":"woodland_root_fans_junctions";
    j.reveal=local(map,j,-cfg.approachLengthM,0);j.workStance=workStance(map,j);
    j.approach=approachTo(map,walk,j.at.x,j.at.z);
    return j;
}

void composeSite(WorldMap& map,const tuning::WorldgenTable& table,ForceJourney& j) {
    const auto& cfg=table.forceJourneys;const auto old=map.cells;
    const int span=static_cast<int>(std::ceil(j.radiusM+7));
    extendDensity(map,j.at.x-span-2,j.at.z-span-2,j.at.x+span+3,j.at.z+span+3);
    const double base=j.at.y;
    std::vector<SurfacePoint> inheritedLane;
    for(const auto& at:j.approach)if(std::hypot(at.x-j.at.x,at.z-j.at.z)<j.radiusM+10)inheritedLane.push_back(at);
    for(const auto& at:j.hostRoute)if(std::hypot(at.x-j.at.x,at.z-j.at.z)<j.radiusM+10)inheritedLane.push_back(at);
    // Later sites may meet earlier cross-country approaches. Preserve their
    // local supported capsule corridors before applying another force shape.
    // The mask is only this site's small footprint, not a full-world reserve.
    const int localWidth=span*2+1, corridor=static_cast<int>(std::ceil(cfg.routeWidthM*.5));
    std::vector<uint8_t> committed(static_cast<size_t>(localWidth)*localWidth,0);
    const auto reserve=[&](const std::vector<SurfacePoint>& route) {
        for(const auto& at:route) {
            if(std::abs(at.x-j.at.x)>span+corridor||std::abs(at.z-j.at.z)>span+corridor)continue;
            for(int dz=-corridor;dz<=corridor;++dz)for(int dx=-corridor;dx<=corridor;++dx) {
                const int x=at.x+dx-j.at.x+span,z=at.z+dz-j.at.z+span;
                if(x>=0&&z>=0&&x<localWidth&&z<localWidth)committed[z*localWidth+x]=1;
            }
        }
    };
    for(const auto& prior:map.forceJourneys) {
        reserve(prior.approach);reserve(prior.sourceRoute);reserve(prior.hostRoute);
    }
    const double relief=j.channel=="white"?cfg.whiteReliefM:j.channel=="blue"?cfg.blueReliefM:cfg.greenReliefM;
    // Blue's open concave shelves and White's interrupted offsets are native
    // editable matter. The runtime kit dresses their actual crests/flanks.
    for(int z=j.at.z-span;z<=j.at.z+span;++z)for(int x=j.at.x-span;x<=j.at.x+span;++x) {
        const auto [u,v]=localUV(j,x,z);const double distance=std::hypot(u,v);
        if(distance>j.radiusM+5||protectedGround(map,x,z)||!originalRoof(map,x,z,3))continue;
        if(committed[(z-j.at.z+span)*localWidth+x-j.at.x+span])continue;
        // The candidate already has a proved physical approach. Preserve its
        // six-metre local corridor all the way into the selected flat native
        // core. A pretty new floor must not strand a source, and regrading an
        // already walkable slope can push it past the contact slope limit.
        // Retain the corridor's exact native cap/contact and biome.
        if(pathDistance(x,z,inheritedLane)<cfg.routeWidthM*.5)continue;
        const bool hostEligible=eligible(j.channel,biomeAt(map,table,x,z),j.fallback,j.secondary);
        const double curve=2.5*std::sin((u+cfg.approachLengthM)*.09)*ease((-u-6)/7);
        const double lane=ease((cfg.routeWidthM*.5+3-std::abs(v-curve))/3)*ease((3-u)/4);
        // A plain walking lane may cross the next soil patch without changing
        // its biome or extending the force to an ineligible living host.
        if(!hostEligible&&lane<=0&&distance>cfg.workRadiusM)continue;
        const double country=ease((j.radiusM+5-distance)/9);
        // Inherited surface closes the approach smoothly; central work remains
        // dry and shallow grading never fills original cave air.
        const double near=ease((j.radiusM-2-distance)/16);
        double ground=old[z*map.width+x].height*(1-near)+base*near;
        double bank=0;
        if(j.channel=="blue") {
            // Three uneven, broken horseshoes nest into the uphill bank. Their
            // unequal axes/heights and open mouth avoid manufactured circles.
            for(int layer=0;layer<3;++layer) {
                const double centre=4+layer*.8, radius=8.5+layer*6;
                const double bend=(v>0?1.05:.87)+.035*std::sin(j.phase+layer);
                const double r=std::hypot((u-centre)*1.12,v*bend);
                // Cumulative shelves retain actual matter behind each lip.
                // Isolated equal-height bands hid one another at player eye
                // height and read as a single wall in the first game picture.
                const double shelf=ease((r-radius+1.0)/1.9);
                const double open=ease((u+3.5+layer*1.2)/5);
                const double interruption=ease((std::abs(v-(layer-1)*8.0)-.6)/2.0);
                const double held=.68+.32*interruption;
                const double asym=.88+.12*std::sin(v*.13+j.phase+layer*.7);
                const double increment=layer==0?.28:layer==1?.30:.42;
                bank+=relief*increment*shelf*open*held*asym;
            }
        } else if(j.channel=="white") {
            for(int row=-1;row<=1;row+=2)for(int part=0;part<3;++part) {
                const double centre=-15+part*13+row*2.7;
                const double lateral=row*(9+part*1.6)+u*.14;
                const double a=u-centre,b=v-lateral;
                const double toe=std::min(6.0-std::abs(a),3.8-std::abs(b));
                const double cap=relief*(.74+.16*part)+(a*.06*row);
                bank=std::max(bank,std::max(0.0,std::min(cap,toe*1.45)));
            }
        } else {
            // A connected low support network follows compatible soil. Two
            // real dry breaks cut the Steppe network; the art must stop too.
            for(int arm=-1;arm<=1;++arm) {
                const double line=arm*(6+std::max(0.0,u+9)*.23)+2*std::sin(u*.08+j.phase);
                const double along=ease((u+24)/5)*ease((24-u)/6);
                double value=relief*std::exp(-std::pow((v-line)/3.6,2))*along;
                if(j.secondary&&(std::abs(u+3)<2.3||std::abs(u-13)<1.8))value=0;
                bank=std::max(bank,value);
            }
        }
        // The source and approach are a separately supported unoccupied lane.
        const double work=ease((cfg.workRadiusM+3-distance)/3);
        const double clear=std::max(lane,work);
        bank*=hostEligible?1-clear:0;
        if(!hostEligible)ground=old[z*map.width+x].height;
        double target=ground+bank;
        const double floorWeight=clear*ease((j.radiusM+2-distance)/7);
        const double slope=std::clamp((-u-3)/(cfg.approachLengthM-3),0.0,1.0);
        const double routeFloor=base+(j.reveal.y-base)*slope*(1-work);
        target=target*(1-floorWeight)+routeFloor*floorWeight;
        target=old[z*map.width+x].height*(1-country)+target*country;
        seat(map,table,x,z,target);
        if(bank>1.0&&j.channel!="green") {
            const int top=map.at(x,z).height;
            for(int y=std::max(1,top-3);y<top;++y)if(map.blockAt(x,y,z)!=kAir)
                map.blocks[(static_cast<size_t>(z)*map.width+x)*map.depth+y]=kStone;
        }
    }
    reground(map,old);
    // Only unowned scattered surface obstacles are cleared for the new lane,
    // native mineral body and calm work floor. Guaranteed nodes retain identity.
    map.nodes.erase(std::remove_if(map.nodes.begin(),map.nodes.end(),[&](const auto& n) {
        if(!n.siteId.empty()||!n.habitatId.empty()||n.resourceId.rfind("wnv6_homev6_",0)==0||n.y!=map.at(n.x,n.z).height)return false;
        const auto [u,v]=localUV(j,n.x,n.z);
        if(std::hypot(u,v)>j.radiusM||protectedGround(map,n.x,n.z))return false;
        const double curve=2.5*std::sin((u+cfg.approachLengthM)*.09)*ease((-u-6)/7);
        return std::hypot(u,v)<cfg.workRadiusM+3||pathDistance(n.x,n.z,inheritedLane)<cfg.routeWidthM*.5+1||(u<5&&std::abs(v-curve)<cfg.routeWidthM*.5+3)||
            (j.channel!="green"&&std::abs(v)>6&&std::abs(v)<25);
    }),map.nodes.end());
    j.at=point(map,j.at.x,j.at.z);j.workStance=workStance(map,j);
    // Anchors name the actual native crest, with no extra invisible collision
    // mesh or renderer-only mineral volume. Each has at least a two-cell roof.
    const std::vector<std::pair<double,double>> forms=j.channel=="blue"?
        std::vector<std::pair<double,double>>{{7,-8},{9,10},{13,-15},{17,17},{23,-7}}:
        j.channel=="white"?std::vector<std::pair<double,double>>{{-18,-12},{-12,8},{-5,-10},{1,12},{10,-11},{15,15}}:
        std::vector<std::pair<double,double>>{{-18,-5},{-10,8},{4,-12},{7,10},{20,-4}};
    const auto anchor=[&](SurfacePoint desired,bool crest) {
        std::pair<double,int> best{1e30,-1};
        for(int dz=-4;dz<=4;++dz)for(int dx=-4;dx<=4;++dx) {
            const int x=desired.x+dx,z=desired.z+dz;
            if(protectedGround(map,x,z)||!originalRoof(map,x,z,2)||!eligible(j.channel,biomeAt(map,table,x,z),j.fallback,j.secondary))continue;
            const auto [u,v]=localUV(j,x,z);
            if(std::hypot(u,v)<cfg.workRadiusM+2||(u<4&&std::abs(v)<cfg.routeWidthM*.5+2))continue;
            if(j.secondary&&(std::abs(u+3)<3||std::abs(u-13)<3))continue;
            const bool inset=x%16>=3&&x%16<=12&&z%16>=3&&z%16<=12;
            const double raised=map.at(x,z).height-old[z*map.width+x].height;
            const double score=dx*dx+dz*dz+(inset?0:35)-(crest?raised*3:0);
            if(score<best.first)best={score,z*map.width+x};
        }
        return best.second;
    };
    for(const auto& [u,v]:forms) {
        const int cell=anchor(local(map,j,u,v),j.channel!="green");
        if(cell>=0)j.formAnchors.push_back(point(map,cell%map.width,cell/map.width));
    }
    if(j.channel=="blue")for(const auto& [u,v]:std::vector<std::pair<double,double>>{{1,-8},{1,8},{9,-10},{9,10}}) {
        const int cell=anchor(local(map,j,u,v),false);
        if(cell>=0)j.growthAnchors.push_back(point(map,cell%map.width,cell/map.width));
    }
    for(int arm=-1;arm<=1;arm+=2)for(int part=0;part<5;++part) {
        const double u=-22+part*10+(arm>0?2:0),v=arm*(7.0+part*2.2)+1.5*std::sin(j.phase+part);
        if(j.secondary&&(std::abs(u+3)<3||std::abs(u-13)<3))continue;
        const int cell=anchor(local(map,j,u,v),false);
        if(cell>=0)j.growthAnchors.push_back(point(map,cell%map.width,cell/map.width));
    }
}

// One flood from the actual working stance supplies honest route lengths and
// separates encounter selection from the occupied source centre.
std::vector<SurfacePoint> routeTo(const WorldMap& map,const frozen_frontier::SurfaceWalk& walk,const RouteField& field,SurfacePoint end) {
    std::vector<SurfacePoint> result;int at=end.z*map.width+end.x;
    if(field.parent[at]<0)throw std::runtime_error("LAND04: disconnected physical route");
    while(true) {result.push_back({at%map.width,walk.heights[at],at/map.width});if(field.parent[at]==at)break;at=field.parent[at];}
    std::reverse(result.begin(),result.end());return result;
}
void placeHost(WorldMap& map,const tuning::WorldgenTable& table,const tuning::LivingFrontierTable& rules,
               const frozen_frontier::SurfaceWalk& walk,ForceJourney& j) {
    const auto def=std::find_if(rules.hosts.begin(),rules.hosts.end(),[&](const auto& h){return h.sourceId==j.sourceId;});
    if(def==rules.hosts.end())throw std::runtime_error("LAND04: missing existing host definition");
    const auto paths=routeField(map,walk,j.workStance);std::pair<double,int> best{1e30,-1};
    const int reach=static_cast<int>(rules.hostSourceMaximumM);
    for(int z=j.at.z-reach;z<=j.at.z+reach;z+=2)for(int x=j.at.x-reach;x<=j.at.x+reach;x+=2) {
        if(!map.inBounds(x,z))continue;
        const double ds=std::hypot(x-j.at.x,z-j.at.z),spawn=std::hypot(x-map.spawnX,z-map.spawnZ);
        if(ds<rules.hostSourceMinimumM||ds>rules.hostSourceMaximumM||spawn<rules.hostMinimumSpawnM)continue;
        if(!dryClear(map,walk,x,z,2,0)||protectedGround(map,x,z,4))continue;
        const int distance=paths.distance[z*map.width+x];
        if(distance<rules.hostSourceMinimumM||distance>rules.hostSourceMaximumM)continue;
        bool occupied=false;
        for(const auto& h:map.frontierHosts)if(std::hypot(x-h.at.x,z-h.at.z)<rules.hostSeparationM)occupied=true;
        for(const auto& h:map.homeSites)if(std::hypot(x-h.x,z-h.z)<h.radiusM+25)occupied=true;
        for(const auto& s:map.leylineSourceSites)if(std::hypot(x-s.at.x,z-s.at.z)<45)occupied=true;
        if(occupied)continue;
        const auto b=biomeAt(map,table,x,z);
        if(j.channel=="green"&&!woodland(b))continue;
        if(j.channel=="blue"&&b!=j.biome)continue;
        // White observes the loaded bank from a wooded/meadow clearing; the
        // finite boar and moth remain within their selected physical habitat.
        if(j.channel=="white"&&!(woodland(b)||b=="meadow"||b=="rocky_hills"))continue;
        const double score=distance+(spawn-rules.hostMinimumSpawnM)*.05+cellNoise(map.seed,x,z,120089)*4;
        if(score<best.first)best={score,z*map.width+x};
    }
    if(best.second<0)throw std::runtime_error("LAND04: no separated physically reachable host "+j.id);
    PlacedFrontierHost h;h.id=def->id;h.sourceId=def->sourceId;h.enemyId=def->enemyId;h.influence=def->influence;
    h.at=point(map,best.second%map.width,best.second/map.width);h.sourceRoute=routeTo(map,walk,paths,h.at);
    h.approach=approachTo(map,walk,h.at.x,h.at.z);
    h.habits={point(map,h.at.x-2,h.at.z),point(map,h.at.x+2,h.at.z)};
    j.hostId=h.id;j.hostAt=h.at;j.hostRoute=h.sourceRoute;
    map.frontierHosts.push_back(h);
    map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](const auto& p) {
        return p.frontierHostId.empty()&&p.biome!="cave"&&
            (std::hypot(p.x-h.at.x,p.z-h.at.z)<rules.encounterClearRadiusM||std::hypot(p.x-j.at.x,p.z-j.at.z)<table.forceJourneys.workRadiusM+14);
    }),map.packs.end());
    MobPack p;p.frontierHostId=h.id;p.enemies={h.enemyId};p.x=h.at.x;p.y=h.at.y;p.z=h.at.z;
    p.grazer=j.channel=="white"||j.channel=="green";p.biome="living_frontier_habitat";map.packs.push_back(p);
}

SurfacePoint revealOnApproach(const WorldMap& map,const tuning::WorldgenTable& table,
                                    const frozen_frontier::SurfaceWalk& walk,const ForceJourney& j) {
    const auto route=approachTo(map,walk,j.workStance.x,j.workStance.z);
    if(route.empty())throw std::runtime_error("LAND04: source has no reveal approach "+j.id);
    std::pair<double,size_t> best{1e30,route.size()-1};
    for(size_t i=0;i<route.size();++i) {
        const auto& at=route[i];const double d=std::hypot(at.x-j.at.x,at.z-j.at.z);
        if(d<16||d>j.radiusM+5)continue;
        const double score=std::abs(d-table.forceJourneys.approachLengthM)+.12*std::hypot(at.x-j.reveal.x,at.z-j.reveal.z);
        if(score<best.first)best={score,i};
    }
    if(best.first==1e30)best.second=route.size()>20?route.size()-20:0;
    return route[best.second];
}

void compose(WorldMap& map,const tuning::WorldgenTable& table,const tuning::LivingFrontierTable& rules) {
    if(map.leylineSourceSites.size()!=4||map.frontierHosts.size()!=1||map.homeSites.size()!=4)
        throw std::runtime_error("LAND04: missing inherited V11 owners");
    auto walk=physicalWalk(map,3,3,map.width-4,map.height-4);
    // Establish the least mature host first. Other force choices see that
    // physical place and keep their own quiet extents distinct.
    for(const auto& channel:std::vector<std::string>{"blue","white","green"}) {
        auto j=selectSite(map,table,walk,rules,channel,false);composeSite(map,table,j);
        map.forceJourneys.push_back(j);
        walk=physicalWalk(map,3,3,map.width-4,map.height-4);
        auto& placed=map.forceJourneys.back();
        if(!dryClear(map,walk,placed.workStance.x,placed.workStance.z,1,0)) {
            const auto w=placed.workStance;
            std::string detail=" at "+std::to_string(w.x)+","+std::to_string(w.y)+","+std::to_string(w.z)+" parent="+std::to_string(walk.parent[w.z*map.width+w.x]);
            for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx) {
                const int cell=(w.z+dz)*map.width+w.x+dx;
                detail+=" ["+std::to_string(dx)+","+std::to_string(dz)+":h"+std::to_string(walk.heights[cell])+" c"+std::to_string(walk.clear[cell])+" roof"+std::to_string(originalRoof(map,w.x+dx,w.z+dz,2))+"]";
            }
            for(size_t i=1;i<placed.approach.size();++i) {
                const auto& at=placed.approach[i];const int cell=at.z*map.width+at.x;
                if(!walk.clear[cell]||walk.parent[cell]<0) {
                    detail+=" first approach break "+std::to_string(at.x)+","+std::to_string(at.y)+","+std::to_string(at.z)+" final="+std::to_string(walk.heights[cell])+" clear="+std::to_string(walk.clear[cell])+" source="+std::to_string(placed.at.x)+","+std::to_string(placed.at.z);
                    break;
                }
            }
            throw std::runtime_error("LAND04: source work stance is not physically supported "+placed.id+detail);
        }
        placed.reveal=revealOnApproach(map,table,walk,placed);
        placed.sourceRoute=localRoute(map,walk,placed.reveal,placed.workStance);
        placed.approach=approachTo(map,walk,placed.workStance.x,placed.workStance.z);
        auto source=std::find_if(map.leylineSourceSites.begin(),map.leylineSourceSites.end(),[&](const auto& s){return s.sourceId==placed.sourceId;});
        source->at=placed.at;source->approach=placed.approach;
        placeHost(map,table,rules,walk,placed);
    }
    auto secondary=selectSite(map,table,walk,rules,"green",true);composeSite(map,table,secondary);
    walk=physicalWalk(map,3,3,map.width-4,map.height-4);
    secondary.workStance=dry_steppe_frontier::reachable(map,walk,secondary.workStance,10,1);
    secondary.reveal=revealOnApproach(map,table,walk,secondary);
    secondary.approach=approachTo(map,walk,secondary.workStance.x,secondary.workStance.z);
    secondary.sourceRoute=localRoute(map,walk,secondary.reveal,secondary.workStance);
    map.forceJourneys.push_back(std::move(secondary));
    // Cross-country approaches can cross a later-composed site's margins.
    // Resolve every route only against the final physical terrain; earlier
    // flood parents/heights are placement evidence, not published routes.
    for(auto& j:map.forceJourneys) {
        j.approach=approachTo(map,walk,j.workStance.x,j.workStance.z);
        j.reveal=revealOnApproach(map,table,walk,j);
        j.sourceRoute=localRoute(map,walk,j.reveal,j.workStance);
        if(!j.secondary) {
            auto source=std::find_if(map.leylineSourceSites.begin(),map.leylineSourceSites.end(),[&](const auto& s){return s.sourceId==j.sourceId;});
            source->approach=j.approach;
            j.hostRoute=localRoute(map,walk,j.workStance,j.hostAt);
            const auto distance=j.hostRoute.size()-1;
            if(distance<rules.hostSourceMinimumM||distance>rules.hostSourceMaximumM) {
                // Later physical margins must not turn a bounded observation
                // walk into a long detour. Re-select only that affected owner
                // against final terrain, retaining its stable finite identity.
                map.frontierHosts.erase(std::remove_if(map.frontierHosts.begin(),map.frontierHosts.end(),[&](const auto& h){return h.id==j.hostId;}),map.frontierHosts.end());
                map.packs.erase(std::remove_if(map.packs.begin(),map.packs.end(),[&](const auto& p){return p.frontierHostId==j.hostId;}),map.packs.end());
                placeHost(map,table,rules,walk,j);
            } else {
                auto host=std::find_if(map.frontierHosts.begin(),map.frontierHosts.end(),[&](const auto& h){return h.id==j.hostId;});
                host->sourceRoute=j.hostRoute;
            }
        }
    }
    // Physical source bodies occupy their centre cells. Apply this only
    // after all geography and finite-host selection: candidate preflights may
    // start at a source anchor, while a real controller must walk around it.
    // Mask a three-by-three cell footprint (including capsule clearance), with
    // the validated two-metre work stances remaining outside that footprint.
    for(const auto& source:map.leylineSourceSites)for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx) {
        const int x=source.at.x+dx,z=source.at.z+dz;
        if(map.inBounds(x,z))walk.clear[z*map.width+x]=false;
    }
    walk.parent=routeField(map,walk,point(map,map.spawnX,map.spawnZ)).parent;
    for(auto& j:map.forceJourneys) {
        if(walk.parent[j.workStance.z*map.width+j.workStance.x]<0)
            throw std::runtime_error("LAND04: occupied-source routing disconnected work stance "+j.id);
        j.approach=approachTo(map,walk,j.workStance.x,j.workStance.z);
        j.sourceRoute=localRoute(map,walk,j.reveal,j.workStance);
        if(!j.secondary) {
            j.hostRoute=localRoute(map,walk,j.workStance,j.hostAt);
            const auto distance=j.hostRoute.size()-1;
            if(distance<rules.hostSourceMinimumM||distance>rules.hostSourceMaximumM)
                throw std::runtime_error("LAND04: occupied-source route exceeds finite host walk bound "+j.id);
            auto source=std::find_if(map.leylineSourceSites.begin(),map.leylineSourceSites.end(),[&](const auto& s){return s.sourceId==j.sourceId;});
            source->approach=j.approach;
            auto host=std::find_if(map.frontierHosts.begin(),map.frontierHosts.end(),[&](const auto& h){return h.id==j.hostId;});
            host->sourceRoute=j.hostRoute;
        }
    }
    for(auto& host:map.frontierHosts)host.approach=approachTo(map,walk,host.at.x,host.at.z);
    for(auto& h:map.homeSites) {
        if(!supportedFootprint(map,walk,h.x,h.z,0))throw std::runtime_error("LAND04: inherited home lost support "+h.id);
        h.approach=approachTo(map,walk,h.x,h.z);
    }
}