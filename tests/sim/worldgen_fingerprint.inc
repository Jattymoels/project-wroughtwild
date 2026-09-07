// Byte-exact encoding for INT-07B's preserved/current executable comparison.
// Include every WorldMap field, collection length and floating-point bit.
// Timings deliberately exclude this encoding and its complete voxel scan.
struct ExactWorldFingerprint {
    uint64_t value=1469598103934665603ull;
    void byte(uint8_t b){value=(value^b)*1099511628211ull;}
    template<class T> void add(T item){
        static_assert(std::is_arithmetic<T>::value,"explicit record encoding required");
        const auto* bytes=reinterpret_cast<const unsigned char*>(&item);
        for(size_t i=0;i<sizeof(item);++i)byte(bytes[i]);
    }
    void add(const std::string& text){add(static_cast<uint64_t>(text.size()));for(unsigned char b:text)byte(b);}
    template<class... T> void fields(const T&... items){(add(items),...);}
    template<class T,class F> void sequence(const std::vector<T>& items,F record){
        add(static_cast<uint64_t>(items.size()));for(const auto& item:items)record(item);
    }
    void point(const worldgen::SurfacePoint& p){fields(p.x,p.y,p.z);}
    void direction(const worldgen::WorldDirection& d){fields(d.x,d.y,d.z);}
    void path(const std::vector<worldgen::SurfacePoint>& items){sequence(items,[&](const auto& p){point(p);});}
    uint64_t world(const worldgen::WorldMap& m){
        fields(m.profileId,m.seed,m.width,m.height,m.depth,m.cellSize,m.spawnX,m.spawnZ,m.gateX,m.gateZ);
        sequence(m.cells,[&](const auto& c){fields(c.height,c.biomeIndex);});
        sequence(m.blocks,[&](auto b){byte(b);});
        sequence(m.nodes,[&](const auto& n){fields(n.type,n.x,n.y,n.z,n.resourceId,n.habitatId,n.siteId,n.regionId,n.exceptional,n.unitsOverride);});
        sequence(m.packs,[&](const auto& p){
            sequence(p.enemies,[&](const auto& e){add(e);});
            fields(p.x,p.y,p.z,p.eliteMemberIndex,p.eliteModifierId,p.grazer,p.biome,p.patrols,p.routeX,p.routeZ,p.hasForeign,p.foreignX,p.foreignZ,p.foreignBiome);
        });
        sequence(m.landmarks,[&](const auto& p){fields(p.id,p.x,p.z);});
        sequence(m.habitats,[&](const auto& p){fields(p.id,p.biome,p.x,p.y,p.z,p.radiusM);path(p.approach);});
        sequence(m.regions,[&](const auto& p){fields(p.id,p.biome,p.x,p.y,p.z,p.radiusM,p.transitionM,p.impactId,p.augmentationProperty);path(p.approach);path(p.caveApproach);});
        sequence(m.rareSites,[&](const auto& p){fields(p.id,p.resourceType,p.regionId,p.x,p.y,p.z,p.radiusM,p.clueRadiusM,p.exceptional,p.guarded);path(p.approach);path(p.cluePoints);});
        sequence(m.impacts,[&](const auto& p){fields(p.id,p.regionId,p.kind,p.x,p.y,p.z,p.radiusM,p.influenceRadiusM);direction(p.impactDirection);path(p.approach);});
        sequence(m.leylines,[&](const auto& p){fields(p.id,p.fromImpactId,p.toImpactId,p.regionId,p.property,p.widthM,p.influenceRadiusM);path(p.points);sequence(p.exposure,[&](auto b){byte(b);});});
        sequence(m.ruins,[&](const auto& p){fields(p.id,p.regionId,p.kind,p.impactId,p.leylineId,p.linkedSiteId,p.augmentation,p.x,p.y,p.z,p.rotationQuarters,p.widthM,p.depthM);direction(p.damageDirection);point(p.entrance);path(p.approach);path(p.discoveryRoute);path(p.foundation);});
        sequence(m.pressurePockets,[&](const auto& p){fields(p.id,p.ruinId,p.impactId,p.leylineId,p.linkedSiteId,p.origin,p.x,p.y,p.z,p.radiusM,p.accidental);point(p.workPosition);path(p.approach);});
        fields(m.starterQuietRadiusM,m.hostileBoundaryM,m.starterFirstSiegeNight);
        sequence(m.homeSites,[&](const auto& p){fields(p.id,p.x,p.y,p.z,p.radiusM);path(p.approach);});
        sequence(m.augmentationField,[&](auto f){add(f);});
        return value;
    }
};
