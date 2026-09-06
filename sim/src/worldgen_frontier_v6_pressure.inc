// V6 composes its wider landscape, then identifies the same single accidental
// pressure pocket in an OLD smithy struck during the cataclysm. It adds no stock,
// recipe, energy conversion or post-impact civilisation to native generation.

SurfacePoint smithyPoint(const WorldMap& map,const PlacedRuin& ruin,int lateral,int forward) {
    int dx=lateral,dz=forward;
    switch(ruin.rotationQuarters){
        case 1: dx=forward;dz=-lateral;break;
        case 2: dx=-lateral;dz=-forward;break;
        case 3: dx=-forward;dz=lateral;break;
        default: break;
    }
    const int x=ruin.x+dx,z=ruin.z+dz;
    if(!map.inBounds(x,z))throw std::runtime_error("worldgen: old smithy point left bounded terrain");
    return {x,map.topSolid(x,z),z};
}

void composeFrontierV6Pressure(WorldMap& map,const tuning::WorldgenTable& table) {
    wide_frontier::composeFrontierV6Landscape(map,table);
    const auto site=std::find_if(map.rareSites.begin(),map.rareSites.end(),[](const auto& s){
        return s.resourceType=="ventlung" && !s.exceptional && s.id=="rsv6_ventlung_primary_0";
    });
    if(site==map.rareSites.end())throw std::runtime_error("worldgen: no first Ventlung discovery for old smithy");
    auto ruin=std::find_if(map.ruins.begin(),map.ruins.end(),[&](const auto& r){return r.linkedSiteId==site->id;});
    if(ruin==map.ruins.end())throw std::runtime_error("worldgen: pressure pocket has no pre-existing smithy foundation");
    const auto& inputs=table.pressureSite;
    const auto pocket=smithyPoint(map,*ruin,inputs.pocketLateralCells,inputs.pocketForwardCells);
    const auto work=smithyPoint(map,*ruin,inputs.workLateralCells,inputs.workForwardCells);
    const auto strike=smithyPoint(map,*ruin,inputs.strikeLateralCells,inputs.strikeForwardCells);
    if(pocket.y!=ruin->y || work.y!=ruin->y || strike.y!=ruin->y)
        throw std::runtime_error("worldgen: pressure composition left the supported old foundation");

    // The ruin was a modest blacksmith's building before impact. A later player
    // can tap the accidental pressure; its builders did not engineer a leyline.
    ruin->id="ruv6_old_blacksmith";
    ruin->kind="pre_cataclysm_blacksmith";
    const double dx=ruin->x-strike.x,dz=ruin->z-strike.z,length=std::max(1.0,std::hypot(dx,dz));
    ruin->damageDirection={dx/length,0,dz/length};

    PlacedImpact impact;
    impact.id="imv6_blacksmith_strike";impact.regionId=ruin->regionId;impact.kind="blacksmith_strike";
    impact.x=strike.x;impact.y=strike.y;impact.z=strike.z;
    impact.radiusM=inputs.strikeRadiusM;impact.influenceRadiusM=inputs.influenceRadiusM;
    impact.impactDirection={dx/length,-0.7,dz/length};

    const auto walk=wide_frontier::surfaceWalk(map,1);
    if(!wide_frontier::supportedFootprint(map,walk,work.x,work.z,1))
        throw std::runtime_error("worldgen: pressure pocket lacks a clear ordinary work position");
    auto approach=wide_frontier::approachTo(map,walk,work.x,work.z);
    impact.approach=approach;
    map.impacts.push_back(impact);

    // Reroute only this local history branch to the striking fragment; the final
    // exposed channel enters the old hearth by accident. All ordinary world
    // resources, cave/arrival routes and other ruin foundations stay untouched.
    auto branch=std::find_if(map.leylines.begin(),map.leylines.end(),[&](const auto& l){return l.id==ruin->leylineId;});
    if(branch==map.leylines.end())throw std::runtime_error("worldgen: old smithy has no local trace association");
    if(branch->points.empty())throw std::runtime_error("worldgen: empty old smithy trace");
    branch->points.back()=strike;
    branch->toImpactId=impact.id;

    PlacedLeyline accidental;
    accidental.id="lyv6_blacksmith_accident";
    accidental.fromImpactId=impact.id;accidental.regionId=ruin->regionId;accidental.property="light_pressure";
    accidental.widthM=inputs.traceWidthM;accidental.influenceRadiusM=inputs.influenceRadiusM;
    accidental.points={strike,pocket};accidental.exposure={2};
    map.leylines.push_back(accidental);
    ruin->impactId=impact.id;ruin->leylineId=accidental.id;

    PlacedPressurePocket source;
    source.id="ppv6_old_blacksmith";source.ruinId=ruin->id;source.impactId=impact.id;
    source.leylineId=accidental.id;source.linkedSiteId=site->id;
    source.origin="pre_cataclysm_blacksmith";source.accidental=true;
    source.x=pocket.x;source.y=pocket.y;source.z=pocket.z;source.radiusM=inputs.pocketRadiusM;
    source.workPosition=work;source.approach=std::move(approach);
    map.pressurePockets.push_back(std::move(source));
    wide_frontier::updateAugmentation(map,table);
}
