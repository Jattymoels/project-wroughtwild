#include "wroughtwild/worldgen.h"
#include <algorithm>
#include <chrono>
#include <iostream>
#include <type_traits>
using namespace wroughtwild;
#include "worldgen_fingerprint.inc"

// One fresh map at a time; report generation separately from exact output
// hashing. Compile this same fixture against preserved and current sources.
// Arguments: tuning directory, profile, then one or more explicit seeds.
int main(int argc,char** argv){try{
    const std::string dir=argc>1?argv[1]:"data/tuning";
    const std::string profile=argc>2?argv[2]:"frontier_v6";
    tuning::Tuning t;
    t.worldgen=tuning::loadWorldgen(dir+"/worldgen.json");
    t.legacyWorldgen=tuning::loadWorldgen(dir+"/worldgen-legacy-v1.json");
    t.frontierV2Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v2.json");
    t.frontierV3Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v3.json");
    t.frontierV4Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v4.json");
    t.frontierV5Worldgen=tuning::loadWorldgen(dir+"/worldgen-frontier-v5.json");
    for(int i=3;i<std::max(4,argc);++i){
        const auto seed=argc>i?std::stoull(argv[i]):uint64_t{1};
        const auto begin=std::chrono::steady_clock::now();
        const auto map=worldgen::generateProfile(t,seed,profile);
        const double ms=std::chrono::duration<double,std::milli>(std::chrono::steady_clock::now()-begin).count();
        std::cout<<"WORLD_PERFORMANCE profile="<<profile<<" seed="<<seed<<" generation_ms="<<ms
                 <<" exact_hash="<<ExactWorldFingerprint{}.world(map)<<"\n"<<std::flush;
    }
    return 0;
}catch(const std::exception& e){std::cerr<<"FAIL world performance: "<<e.what()<<"\n";return 1;}}
