// Shared historical encoding: captured before V4 and V5 profile changes.
uint64_t completeFingerprint(const worldgen::WorldMap& m) {
 uint64_t h=fingerprint(m);
 auto add=[&](const std::string& s){for(unsigned char c:s)h=(h^c)*1099511628211ull;h=(h^0xffu)*1099511628211ull;};
 auto path=[&](const auto& points){for(const auto& p:points)add(std::to_string(p.x)+","+std::to_string(p.y)+","+std::to_string(p.z));};
 for(const auto& n:m.nodes){add(n.resourceId);add(n.habitatId);add(n.siteId);add(n.regionId);add(std::to_string(n.unitsOverride));add(std::to_string(n.exceptional));}
 for(const auto& r:m.regions){add(r.id);add(r.biome);add(std::to_string(r.x)+","+std::to_string(r.y)+","+std::to_string(r.z));path(r.approach);path(r.caveApproach);}
 for(const auto& s:m.rareSites){add(s.id);add(s.resourceType);add(s.regionId);add(std::to_string(s.exceptional));add(std::to_string(s.guarded));path(s.approach);path(s.cluePoints);}
 for(const auto& r:m.habitats){add(r.id);add(r.biome);path(r.approach);}
 return h;
}
uint64_t historyFingerprint(const worldgen::WorldMap& m) {
 uint64_t h=completeFingerprint(m);
 auto add=[&](const auto& value){const std::string s=std::to_string(value);for(unsigned char c:s)h=(h^c)*1099511628211ull;};
 auto text=[&](const std::string& s){for(unsigned char c:s)h=(h^c)*1099511628211ull;};
 auto path=[&](const auto& points){for(const auto& p:points){add(p.x);add(p.y);add(p.z);}};
 for(const auto& a:m.impacts){text(a.id);text(a.regionId);text(a.kind);add(a.x);add(a.y);add(a.z);add(a.radiusM);add(a.influenceRadiusM);add(a.impactDirection.x);add(a.impactDirection.y);add(a.impactDirection.z);path(a.approach);}
 for(const auto& l:m.leylines){text(l.id);text(l.fromImpactId);text(l.toImpactId);text(l.regionId);text(l.property);add(l.widthM);add(l.influenceRadiusM);path(l.points);for(auto e:l.exposure)add(e);}
 for(const auto& r:m.ruins){text(r.id);text(r.kind);text(r.regionId);text(r.linkedSiteId);text(r.impactId);text(r.leylineId);text(r.augmentation);add(r.x);add(r.y);add(r.z);add(r.rotationQuarters);add(r.widthM);add(r.depthM);add(r.damageDirection.x);add(r.damageDirection.z);path(r.approach);path(r.discoveryRoute);path(r.foundation);}
 for(auto f:m.augmentationField)add(f);
 return h;
}
