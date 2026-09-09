#include "wroughtwild/resonance.h"
#include <algorithm>
#include <cmath>
#include <set>
#include <sstream>
#include <stdexcept>

namespace wroughtwild::resonance {
namespace {
int integer(const json::Value& v, int lo, int hi) {
    const double n=v.asNumber();
    if (!std::isfinite(n) || n!=std::floor(n) || n<lo || n>hi) throw std::runtime_error("Invalid resonance integer");
    return static_cast<int>(n);
}
const worldgen::FutureTransformation& envelope(const worldgen::WorldMap& map) {
    if (map.profileId!="living_frontier_wave3") throw std::runtime_error("Resonance requires its published LF geography");
    for (const auto& f:map.futureTransformations) if (f.id=="retained_fen") return f;
    throw std::runtime_error("Retained Fen envelope is missing");
}
}
Config Config::load(const std::string& path) {
    auto v=json::parseFile(path); Config c;
    c.maxRise=integer(v->get("max_rise_m"),1,2); c.blend=integer(v->get("blend_m"),1,12);
    c.minimumColumns=integer(v->get("minimum_changed_columns"),1,1000);
    c.oreCount=integer(v->get("ore_nodes"),4,4); c.oreUnits=integer(v->get("ore_units"),1,100);
    c.ownershipMargin=integer(v->get("ownership_margin_m"),2,12);
    c.resourceMargin=integer(v->get("resource_margin_m"),2,12);
    c.oreSpacing=integer(v->get("ore_spacing_m"),3,20); return c;
}
std::string State::toJson() const {
    std::ostringstream s; s<<"{\"version\":1,\"event\":\"retained_fen\",\"phase\":\""<<phase<<"\",\"seed\":"<<seed<<",\"columns\":[";
    for (size_t i=0;i<columns.size();++i) { const auto& c=columns[i]; if(i)s<<','; s<<'['<<c.x<<','<<c.z<<','<<c.before<<','<<c.after<<']'; }
    s<<"],\"ore_units\":"<<oreUnits<<",\"ore\":[";
    for(size_t i=0;i<ore.size();++i) { const auto& p=ore[i]; if(i)s<<','; s<<'['<<p.x<<','<<p.y<<','<<p.z<<']'; }
    s<<"]}"; return s.str();
}
State State::fromJson(const json::Value& v) {
    if(integer(v.get("version"),1,1)!=1 || v.get("event").asString()!="retained_fen") throw std::runtime_error("Unsupported resonance event");
    State s; s.phase=v.get("phase").asString();
    if(s.phase!="dormant" && s.phase!="pending" && s.phase!="applied") throw std::runtime_error("Unsupported resonance phase");
    s.seed=integer(v.get("seed"),0,2147483647);
    for(const auto& a:v.get("columns").asArray()) {
        const auto& p=a->asArray(); if(p.size()!=4) throw std::runtime_error("Invalid resonance column");
        s.columns.push_back({integer(*p[0],0,4095),integer(*p[1],0,4095),integer(*p[2],1,1023),integer(*p[3],1,1023)});
    }
    s.oreUnits=integer(v.get("ore_units"),0,100);
    for(const auto& a:v.get("ore").asArray()) {
        const auto& p=a->asArray(); if(p.size()!=3) throw std::runtime_error("Invalid resonance opportunity");
        s.ore.push_back({integer(*p[0],0,4095),integer(*p[1],1,1023),integer(*p[2],0,4095)});
    }
    if(s.phase=="applied" ? (s.columns.empty() || s.ore.size()!=4 || s.oreUnits<1) : (!s.columns.empty() || !s.ore.empty() || s.oreUnits!=0))
        throw std::runtime_error("Resonance phase and terrain disagree");
    return s;
}
State prepare(const worldgen::WorldMap& base,const Config& cfg,const std::vector<Bounds>& ownership) {
    const auto& fen=envelope(base);
    const int n=base.width*base.height;
    std::vector<int> rise(n,0); std::vector<Bounds> keep;
    auto protect=[&](double x,double z,double rx,double rz) {keep.push_back({x-rx,z-rz,x+rx,z+rz});};
    auto point=[&](int x,int z,double r) {protect((x+.5)*base.cellSize,(z+.5)*base.cellSize,r,r);};
    auto path=[&](const std::vector<worldgen::SurfacePoint>& route) {for(const auto& p:route) point(p.x,p.z,cfg.ownershipMargin);};
    for(const auto& b:ownership) keep.push_back({b.minX-cfg.ownershipMargin,b.minZ-cfg.ownershipMargin,b.maxX+cfg.ownershipMargin,b.maxZ+cfg.ownershipMargin});
    point(base.spawnX,base.spawnZ,cfg.ownershipMargin); point(base.gateX,base.gateZ,cfg.ownershipMargin);
    for(const auto& h:base.homeSites) {point(h.x,h.z,h.radiusM);path(h.approach);}
    for(const auto& p:base.nodes) point(p.x,p.z,cfg.resourceMargin);
    for(const auto& h:base.habitats) path(h.approach);
    for(const auto& r:base.regions) {path(r.approach);path(r.caveApproach);}
    for(const auto& l:base.laboratories) {protect((l.at.x+.5)*base.cellSize,(l.at.z+.5)*base.cellSize,l.widthM*.5+cfg.ownershipMargin,l.depthM*.5+cfg.ownershipMargin);path(l.approach);}
    for(const auto& r:base.ruins) {point(r.x,r.z,std::max(r.widthM,r.depthM)*.5+cfg.ownershipMargin);path(r.approach);path(r.discoveryRoute);}
    for(const auto& r:base.rareSites) {point(r.x,r.z,r.radiusM);path(r.approach);}
    for(const auto& h:base.frontierHosts) {point(h.at.x,h.at.z,cfg.ownershipMargin);path(h.approach);path(h.sourceRoute);path(h.habits);}
    path(base.laboratoryTrail);
    for(const auto& p:base.pressurePockets) {point(p.x,p.z,p.radiusM);path(p.approach);}
    for(const auto& l:base.landmarks) point(l.x,l.z,cfg.ownershipMargin);
    // Rasterise local protection once; do not scan thousands of paths per cell.
    std::vector<bool> protectedCell(n,false);
    for(const auto& b:keep) for(int z=std::max(0,static_cast<int>(std::floor(b.minZ/base.cellSize)));z<=std::min(base.height-1,static_cast<int>(std::ceil(b.maxZ/base.cellSize)));++z)
        for(int x=std::max(0,static_cast<int>(std::floor(b.minX/base.cellSize)));x<=std::min(base.width-1,static_cast<int>(std::ceil(b.maxX/base.cellSize)));++x) protectedCell[z*base.width+x]=true;
    for(int z=1;z<base.height-1;++z) for(int x=1;x<base.width-1;++x) {
        const int i=z*base.width+x;
        const double margin=fen.radiusM-std::hypot((x-fen.at.x)*base.cellSize,(z-fen.at.z)*base.cellSize);
        if(protectedCell[i] || margin<cfg.blend || base.topSolid(x,z)!=base.at(x,z).height) continue;
        bool caveLip=false;
        for(int dz=-1;dz<=1;++dz) for(int dx=-1;dx<=1;++dx) if(base.topSolid(x+dx,z+dz)!=base.at(x+dx,z+dz).height)caveLip=true;
        if(!caveLip) rise[i]=std::min(cfg.maxRise,static_cast<int>(margin/cfg.blend));
    }
    // Monotonic relaxation: taper at every protected edge and preserve the
    // original height difference (or a normal one-metre step) in both directions.
    bool changed=true;
    while(changed) { changed=false;
        for(int z=1;z<base.height-1;++z) for(int x=1;x<base.width-1;++x) {
            const int i=z*base.width+x; if(!rise[i])continue;
            int allowed=rise[i];
            for(int dz=-1;dz<=1;++dz) for(int dx=-1;dx<=1;++dx) {
                const int j=(z+dz)*base.width+x+dx;
                const int diff=base.cells[i].height-base.cells[j].height;
                allowed=std::min(allowed,rise[j]+std::max(1,std::abs(diff))-diff);
                if(rise[j]==0) allowed=std::min(allowed,1);
            }
            if(allowed<rise[i]) {rise[i]=std::max(0,allowed);changed=true;}
        }
    }
    State s; s.phase="applied";s.seed=base.seed;s.oreUnits=cfg.oreUnits;
    for(int z=0;z<base.height;++z) for(int x=0;x<base.width;++x) {
        const int i=z*base.width+x;if(rise[i]>0 && base.cells[i].height+rise[i]<base.depth) s.columns.push_back({x,z,base.cells[i].height,base.cells[i].height+rise[i]});
    }
    if(static_cast<int>(s.columns.size())<cfg.minimumColumns) throw std::runtime_error("Resonance pending: Retained Fen needs an unoccupied patch; current ownership is protected. Retry after clearing a patch.");
    for(const auto& c:s.columns) {
        bool clear=true;
        for(const auto& p:s.ore) if(std::hypot(c.x-p.x,c.z-p.z)*base.cellSize<cfg.oreSpacing)clear=false;
        for(int dz=-1;dz<=1;++dz)for(int dx=-1;dx<=1;++dx)if(rise[(c.z+dz)*base.width+c.x+dx]==0)clear=false;
        if(clear) s.ore.push_back({c.x,c.after,c.z});
        if(static_cast<int>(s.ore.size())==cfg.oreCount)break;
    }
    if(static_cast<int>(s.ore.size())!=cfg.oreCount)throw std::runtime_error("Resonance pending: protected ground leaves insufficient ore workplaces. Retry after clearing a patch.");
    validate(base,s);return s;
}
void validate(const worldgen::WorldMap& base,const State& s) {
    const auto& fen=envelope(base);
    if(s.phase=="dormant")return;
    if(s.seed!=base.seed)throw std::runtime_error("Resonance belongs to a different world seed");
    std::set<std::pair<int,int>> seen;
    for(const auto& c:s.columns) {
        if(!base.inBounds(c.x,c.z) || !seen.emplace(c.x,c.z).second || c.before!=base.at(c.x,c.z).height || base.topSolid(c.x,c.z)!=c.before || c.after<=c.before || c.after>c.before+2 || c.after>=base.depth || std::hypot(c.x-fen.at.x,c.z-fen.at.z)*base.cellSize>=fen.radiusM)
            throw std::runtime_error("Saved resonance does not match the published terrain");
    }
    std::set<std::pair<int,int>> ore;
    for(const auto& p:s.ore) {
        auto it=std::find_if(s.columns.begin(),s.columns.end(),[&](const Column& c){return c.x==p.x && c.z==p.z && c.after==p.y;});
        if(it==s.columns.end() || !ore.emplace(p.x,p.z).second)throw std::runtime_error("Invalid saved resonance ore workplace");
    }
}
void apply(worldgen::WorldMap& map,const State& s) {
    validate(map,s); if(s.phase!="applied")return;
    for(const auto& c:s.columns) {
        // Add only above the former surface: no cave or saved excavation fills.
        for(int y=c.before;y<c.after;++y)map.blocks[(static_cast<size_t>(c.z)*map.width+c.x)*map.depth+y]=y==c.after-1?worldgen::kSurface:worldgen::kDirt;
        map.cells[c.z*map.width+c.x].height=c.after;
    }
    for(size_t i=0;i<s.ore.size();++i) {
        const auto& p=s.ore[i];worldgen::PlacedNode node(i%2==0?"copper_vein":"tin_vein",p.x,p.y,p.z);
        node.resourceId="lf4_fen_ore_"+std::to_string(i);node.habitatId="retained_fen";node.unitsOverride=s.oreUnits;map.nodes.push_back(node);
    }
}
}
