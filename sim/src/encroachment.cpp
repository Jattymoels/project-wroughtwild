#include "wroughtwild/encroachment.h"

#include <algorithm>
#include <cmath>

namespace wroughtwild::encroachment {

namespace {

uint64_t mix(uint64_t v) {
    v ^= v >> 33;
    v *= 0xff51afd7ed558ccdull;
    v ^= v >> 33;
    v *= 0xc4ceb9fe1a85ec53ull;
    v ^= v >> 33;
    return v;
}

double unit(uint64_t h) { return static_cast<double>(h >> 11) / 9007199254740992.0; }

double distance(double ax, double az, double bx, double bz) {
    const double dx = ax - bx, dz = az - bz;
    return std::sqrt(dx * dx + dz * dz);
}

} // namespace

Encroachment::Encroachment(const tuning::EncroachmentDef& def, uint64_t seed) : def_(def), seed_(seed) {}

uint64_t Encroachment::hash(uint64_t salt) const { return mix(seed_ ^ (salt * 0x9E3779B97F4A7C15ull)); }

const Nest* Encroachment::find(int id) const {
    for (const auto& n : nests_)
        if (n.id == id) return &n;
    return nullptr;
}

const std::vector<std::string>& Encroachment::packFor(int tier) const {
    static const std::vector<std::string> none;
    if (def_.tiers.empty()) return none;
    const int index = std::clamp(tier, 1, static_cast<int>(def_.tiers.size())) - 1;
    return def_.tiers[static_cast<size_t>(index)];
}

bool Encroachment::spotFree(double x, double z, double now) const {
    for (const auto& n : nests_)
        if (distance(x, z, n.x, n.z) < def_.spacingM) return false;
    for (const auto& s : scars_)
        if (s.until > now && distance(x, z, s.x, s.z) < def_.spacingM) return false;
    return true;
}

std::vector<Nest> Encroachment::tick(double now, bool hasHome, double homeX, double homeZ) {
    std::vector<Nest> born;
    // Scars heal.
    scars_.erase(std::remove_if(scars_.begin(), scars_.end(), [&](const Scar& s) { return s.until <= now; }),
                 scars_.end());
    // Growth: a standing nest gains a tier every growth_seconds, to the cap.
    const int maxTier = static_cast<int>(def_.tiers.size());
    for (auto& n : nests_) {
        while (n.tier < maxTier && now - n.lastGrowthAt >= def_.growthSeconds) {
            n.tier += 1;
            n.lastGrowthAt += def_.growthSeconds;
        }
    }
    if (!hasHome) {
        started_ = false;
        return born;
    }
    // The settle clock runs only while there is a home to encroach on.
    if (!started_) {
        started_ = true;
        lastSettleAt_ = now;
    }
    if (static_cast<int>(nests_.size()) >= def_.maxNests || now - lastSettleAt_ < def_.settleSeconds) return born;
    lastSettleAt_ = now;
    // A spot on the fringe ring, deterministic per nest, skipping spots too
    // close to another nest or a fresh scar.
    for (int attempt = 0; attempt < 12; ++attempt) {
        const uint64_t h = hash(static_cast<uint64_t>(nextId_) * 131 + static_cast<uint64_t>(attempt));
        const double angle = unit(h) * 6.283185307179586;
        const double radius = def_.fringeMinM + unit(mix(h)) * (def_.fringeMaxM - def_.fringeMinM);
        const double x = homeX + std::cos(angle) * radius;
        const double z = homeZ + std::sin(angle) * radius;
        if (!spotFree(x, z, now)) continue;
        Nest n;
        n.id = nextId_++;
        n.x = x;
        n.z = z;
        n.tier = 1;
        n.bornAt = now;
        n.lastGrowthAt = now;
        nests_.push_back(n);
        born.push_back(n);
        break;
    }
    return born;
}

double Encroachment::restMultiplierAt(double x, double z) const {
    for (const auto& n : nests_)
        if (distance(x, z, n.x, n.z) <= def_.blightRadiusM) return def_.uneasyRestMultiplier;
    return 1.0;
}

bool Encroachment::clear(int id, double now) {
    auto it = std::find_if(nests_.begin(), nests_.end(), [&](const Nest& n) { return n.id == id; });
    if (it == nests_.end()) return false;
    scars_.push_back(Scar{it->x, it->z, now + def_.scarSeconds});
    nests_.erase(it);
    return true;
}

bool Encroachment::killDrops(uint64_t killSeed) const {
    return unit(mix(killSeed ^ 0x5EEDBA5Eull)) < def_.nestLootFraction;
}

int Encroachment::pressure() const {
    int top = 0;
    for (const auto& n : nests_) top = std::max(top, n.tier);
    return top;
}

} // namespace wroughtwild::encroachment
