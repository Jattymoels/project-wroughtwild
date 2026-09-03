#include "wroughtwild/lattice.h"

#include <algorithm>
#include <cmath>
#include <set>
#include <stdexcept>

namespace wroughtwild::lattice {

namespace {

// How far a hit point is pushed along its normal before the cell it lies in
// is read: enough to leave the surface it sits on, small enough that a
// piece's own thin face (a panel is 0.125 m off its plane) still reads as
// the plane's near side.
constexpr double kNudge = 0.02;

int floorDiv(double v, double g) { return static_cast<int>(std::floor(v / g)); }

double distanceSquared(const Vec3& a, const Vec3& b) {
    const double dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z;
    return dx * dx + dy * dy + dz * dz;
}

int cellComponent(const Cell& c, int axis) { return axis == 0 ? c.x : (axis == 1 ? c.y : c.z); }

void setCellComponent(Cell& c, int axis, int value) {
    if (axis == 0) c.x = value;
    else if (axis == 1) c.y = value;
    else c.z = value;
}

Cell cellOf(const Vec3& p, double g) { return Cell{floorDiv(p.x, g), floorDiv(p.y, g), floorDiv(p.z, g)}; }

// The two planes of `axis` boxing the nudged point in: lattice indices
// floor and floor + 1 on that axis, cell indices on the other two.
void addFaces(std::vector<Element>& out, int axis, const Cell& base) {
    for (int step = 0; step < 2; ++step) {
        Element e;
        e.kind = ElementKind::Face;
        e.axis = axis;
        e.cell = base;
        setCellComponent(e.cell, axis, cellComponent(base, axis) + step);
        out.push_back(e);
    }
}

// The four lattice lines along `axis` around the nudged point.
void addEdges(std::vector<Element>& out, int axis, const Cell& base) {
    const int a1 = (axis + 1) % 3, a2 = (axis + 2) % 3;
    for (int s1 = 0; s1 < 2; ++s1) {
        for (int s2 = 0; s2 < 2; ++s2) {
            Element e;
            e.kind = ElementKind::Edge;
            e.axis = axis;
            e.cell = base;
            setCellComponent(e.cell, a1, cellComponent(base, a1) + s1);
            setCellComponent(e.cell, a2, cellComponent(base, a2) + s2);
            out.push_back(e);
        }
    }
}

// Which axes a piece of this element kind extends along (its footprint
// grows along these).
void spannedAxes(const Element& e, bool spans[3]) {
    for (int a = 0; a < 3; ++a) {
        switch (e.kind) {
        case ElementKind::Volume: spans[a] = true; break;
        case ElementKind::Face: spans[a] = a != e.axis; break;
        case ElementKind::Edge: spans[a] = a == e.axis; break;
        }
    }
}

} // namespace

Slot slotFromName(const std::string& name) {
    if (name == "block") return Slot::Block;
    if (name == "wall") return Slot::Wall;
    if (name == "floor") return Slot::Floor;
    if (name == "post") return Slot::Post;
    if (name == "beam") return Slot::Beam;
    throw std::runtime_error("lattice: unknown element slot '" + name + "' (block, wall, floor, post or beam)");
}

const char* slotName(Slot slot) {
    switch (slot) {
    case Slot::Block: return "block";
    case Slot::Wall: return "wall";
    case Slot::Floor: return "floor";
    case Slot::Post: return "post";
    case Slot::Beam: return "beam";
    }
    return "block";
}

bool slotAccepts(Slot slot, const Element& e) {
    switch (slot) {
    case Slot::Block: return e.kind == ElementKind::Volume;
    case Slot::Wall: return e.kind == ElementKind::Face && e.axis != 1;
    case Slot::Floor: return e.kind == ElementKind::Face && e.axis == 1;
    case Slot::Post: return e.kind == ElementKind::Edge && e.axis == 1;
    case Slot::Beam: return e.kind == ElementKind::Edge && e.axis != 1;
    }
    return false;
}

Vec3 centre(const Element& e, double g) {
    Vec3 c{(e.cell.x + 0.5) * g, (e.cell.y + 0.5) * g, (e.cell.z + 0.5) * g};
    switch (e.kind) {
    case ElementKind::Volume: break;
    case ElementKind::Face:
        // On the plane, centred on the cell in the other two axes.
        if (e.axis == 0) c.x = e.cell.x * g;
        else if (e.axis == 1) c.y = e.cell.y * g;
        else c.z = e.cell.z * g;
        break;
    case ElementKind::Edge:
        // On the line, halfway along the cell in the edge's own axis.
        if (e.axis != 0) c.x = e.cell.x * g;
        if (e.axis != 1) c.y = e.cell.y * g;
        if (e.axis != 2) c.z = e.cell.z * g;
        break;
    }
    return c;
}

int yawTurns(const Element& e) {
    if (e.kind == ElementKind::Face) return e.axis == 0 ? 1 : 0;
    if (e.kind == ElementKind::Edge) return e.axis == 2 ? 1 : 0;
    return 0;
}

std::vector<Element> candidates(Slot slot, Vec3 point, Vec3 normal, double gridSize) {
    const double g = gridSize;
    const Vec3 nudged{point.x + normal.x * kNudge, point.y + normal.y * kNudge, point.z + normal.z * kNudge};
    const Cell base = cellOf(nudged, g);

    std::vector<Element> out;
    switch (slot) {
    case Slot::Block: {
        Element e;
        e.kind = ElementKind::Volume;
        e.cell = base;
        out.push_back(e);
        return out; // a block has one honest answer: the cell you are looking into
    }
    case Slot::Wall:
        addFaces(out, 0, base);
        addFaces(out, 2, base);
        break;
    case Slot::Floor:
        addFaces(out, 1, base);
        break;
    case Slot::Post:
        addEdges(out, 1, base);
        break;
    case Slot::Beam:
        addEdges(out, 0, base);
        addEdges(out, 2, base);
        break;
    }
    std::stable_sort(out.begin(), out.end(), [&](const Element& a, const Element& b) {
        return distanceSquared(centre(a, g), point) < distanceSquared(centre(b, g), point);
    });
    return out;
}

Element scaled(const Element& element, int factor) {
    Element e = element;
    e.cell = Cell{element.cell.x * factor, element.cell.y * factor, element.cell.z * factor};
    return e;
}

std::vector<Element> footprint(const Element& anchor, int span, int tall, int longCells) {
    bool spans[3];
    spannedAxes(anchor, spans);
    int extent[3];
    for (int a = 0; a < 3; ++a) extent[a] = spans[a] ? span : 1;
    if (spans[1]) extent[1] = span * std::max(1, tall);
    if (anchor.kind == ElementKind::Edge) extent[anchor.axis] = span * std::max(1, longCells);
    std::vector<Element> out;
    for (int dx = 0; dx < extent[0]; ++dx)
        for (int dy = 0; dy < extent[1]; ++dy)
            for (int dz = 0; dz < extent[2]; ++dz) {
                Element e = anchor;
                e.cell = Cell{anchor.cell.x + dx, anchor.cell.y + dy, anchor.cell.z + dz};
                out.push_back(e);
            }
    return out;
}

std::vector<Element> withInterior(const std::vector<Element>& footprint) {
    std::vector<Element> out = footprint;
    if (footprint.empty()) return out;
    std::set<Cell> cells;
    for (const auto& e : footprint) cells.insert(e.cell);
    auto has = [&](int x, int y, int z) { return cells.count(Cell{x, y, z}) > 0; };
    const Element& first = footprint.front();
    if (first.kind == ElementKind::Volume) {
        for (const auto& c : cells) {
            // Faces between this volume and the next along each axis: the
            // min-side face of the farther cell.
            if (has(c.x + 1, c.y, c.z)) out.push_back(Element{ElementKind::Face, 0, Cell{c.x + 1, c.y, c.z}});
            if (has(c.x, c.y + 1, c.z)) out.push_back(Element{ElementKind::Face, 1, Cell{c.x, c.y + 1, c.z}});
            if (has(c.x, c.y, c.z + 1)) out.push_back(Element{ElementKind::Face, 2, Cell{c.x, c.y, c.z + 1}});
            // Edges leaving this cell's max corner along each axis, when the
            // four volumes around that edge are all covered.
            const Cell m{c.x + 1, c.y + 1, c.z + 1};
            if (has(c.x, m.y, m.z) && has(c.x, c.y, m.z) && has(c.x, m.y, c.z))
                out.push_back(Element{ElementKind::Edge, 0, Cell{c.x, m.y, m.z}});
            if (has(m.x, c.y, m.z) && has(c.x, c.y, m.z) && has(m.x, c.y, c.z))
                out.push_back(Element{ElementKind::Edge, 1, Cell{m.x, c.y, m.z}});
            if (has(m.x, m.y, c.z) && has(c.x, m.y, c.z) && has(m.x, c.y, c.z))
                out.push_back(Element{ElementKind::Edge, 2, Cell{m.x, m.y, c.z}});
        }
    } else if (first.kind == ElementKind::Face) {
        const int n = first.axis;
        const int b = n == 0 ? 1 : 0;
        const int c2 = n == 2 ? 1 : 2;
        for (const auto& c : cells) {
            // The edge between two faces adjacent along axis b runs along the
            // third axis at the farther face's cell, and the other way round.
            Cell nb = c;
            if (b == 0) nb.x += 1; else if (b == 1) nb.y += 1; else nb.z += 1;
            if (cells.count(nb)) out.push_back(Element{ElementKind::Edge, c2, nb});
            Cell nc = c;
            if (c2 == 0) nc.x += 1; else if (c2 == 1) nc.y += 1; else nc.z += 1;
            if (cells.count(nc)) out.push_back(Element{ElementKind::Edge, b, nc});
        }
    }
    return out;
}

Vec3 footprintCentre(const Element& anchor, int span, int tall, double registryGrid, int longCells) {
    bool spans[3];
    spannedAxes(anchor, spans);
    Vec3 c = centre(anchor, registryGrid);
    const double half = registryGrid * 0.5;
    int extent[3] = {span, span, span};
    if (spans[1]) extent[1] = span * std::max(1, tall);
    if (anchor.kind == ElementKind::Edge) extent[anchor.axis] = span * std::max(1, longCells);
    if (spans[0]) c.x += (extent[0] - 1) * half;
    if (spans[1]) c.y += (extent[1] - 1) * half;
    if (spans[2]) c.z += (extent[2] - 1) * half;
    return c;
}

bool Structure::occupied(const Element& element) const { return owner_.count(element) > 0; }

bool Structure::bounds(Cell& lo, Cell& hi) const {
    if (owner_.empty()) return false;
    bool first = true;
    for (const auto& [element, anchor] : owner_) {
        (void)anchor;
        const Cell& c = element.cell;
        if (first) { lo = hi = c; first = false; continue; }
        lo.x = std::min(lo.x, c.x); lo.y = std::min(lo.y, c.y); lo.z = std::min(lo.z, c.z);
        hi.x = std::max(hi.x, c.x); hi.y = std::max(hi.y, c.y); hi.z = std::max(hi.z, c.z);
    }
    return true;
}

const Piece* Structure::at(const Element& element) const {
    auto owner = owner_.find(element);
    if (owner == owner_.end()) return nullptr;
    auto it = pieces_.find(owner->second);
    return it == pieces_.end() ? nullptr : &it->second;
}

bool Structure::place(const Piece& piece) {
    if (piece.footprint.empty()) return false;
    for (const auto& e : piece.footprint)
        if (occupied(e)) return false;
    pieces_[piece.anchor] = piece;
    for (const auto& e : piece.footprint) owner_[e] = piece.anchor;
    return true;
}

bool Structure::remove(const Element& element) {
    auto owner = owner_.find(element);
    if (owner == owner_.end()) return false;
    const Element anchor = owner->second;
    auto it = pieces_.find(anchor);
    if (it != pieces_.end()) {
        for (const auto& e : it->second.footprint) owner_.erase(e);
        pieces_.erase(it);
    } else {
        owner_.erase(owner);
    }
    return true;
}

void Structure::clear() {
    pieces_.clear();
    owner_.clear();
}

bool Structure::near(const std::vector<Element>& footprint, int margin) const {
    if (footprint.empty() || owner_.empty()) return false;
    Cell lo = footprint.front().cell, hi = lo;
    for (const auto& e : footprint) {
        lo.x = std::min(lo.x, e.cell.x); lo.y = std::min(lo.y, e.cell.y); lo.z = std::min(lo.z, e.cell.z);
        hi.x = std::max(hi.x, e.cell.x); hi.y = std::max(hi.y, e.cell.y); hi.z = std::max(hi.z, e.cell.z);
    }
    // One cell either side: the neighbour below shares this box's low
    // boundary, and faces and edges are keyed by the cell on their positive
    // side, so the one on the high boundary is keyed one step up.
    for (int x = lo.x - margin - 1; x <= hi.x + margin + 1; ++x)
        for (int y = lo.y - margin - 1; y <= hi.y + margin + 1; ++y)
            for (int z = lo.z - margin - 1; z <= hi.z + margin + 1; ++z) {
                const Cell c{x, y, z};
                if (occupied(Element{ElementKind::Volume, 0, c})) return true;
                for (int axis = 0; axis < 3; ++axis) {
                    if (occupied(Element{ElementKind::Face, axis, c})) return true;
                    if (occupied(Element{ElementKind::Edge, axis, c})) return true;
                }
            }
    return false;
}

std::vector<const Piece*> Structure::wallsAt(const Element& edge) const {
    std::vector<const Piece*> walls;
    if (edge.kind != ElementKind::Edge || edge.axis != 1) return walls;
    const Cell& c = edge.cell;
    // The plane x = c.x holds faces spanning z in [c.z - 1, c.z] and [c.z, c.z + 1];
    // the plane z = c.z holds faces spanning x likewise.
    const Element around[4] = {
        {ElementKind::Face, 0, Cell{c.x, c.y, c.z}},
        {ElementKind::Face, 0, Cell{c.x, c.y, c.z - 1}},
        {ElementKind::Face, 2, Cell{c.x, c.y, c.z}},
        {ElementKind::Face, 2, Cell{c.x - 1, c.y, c.z}},
    };
    for (const auto& face : around) {
        const Piece* p = at(face);
        if (p != nullptr && p->slot == Slot::Wall) walls.push_back(p);
    }
    return walls;
}

std::vector<Element> Structure::trimEdges() const {
    std::set<Element> edges;
    for (const auto& [element, anchor] : owner_) {
        if (element.kind != ElementKind::Face || element.axis == 1) continue;
        auto piece = pieces_.find(anchor);
        if (piece == pieces_.end() || piece->second.slot != Slot::Wall) continue;
        // The two vertical edges bounding this wall face's bottom.
        const Cell& c = element.cell;
        Element a{ElementKind::Edge, 1, c};
        Element b{ElementKind::Edge, 1, c};
        if (element.axis == 0) b.cell.z += 1;
        else b.cell.x += 1;
        edges.insert(a);
        edges.insert(b);
    }
    std::vector<Element> trims;
    for (const auto& edge : edges) {
        if (occupied(edge)) continue; // a real post stands here
        // Faces, not pieces: a two-cell-wide piece counts per face it covers.
        const Cell& c = edge.cell;
        const Element around[4] = {
            {ElementKind::Face, 0, Cell{c.x, c.y, c.z}},
            {ElementKind::Face, 0, Cell{c.x, c.y, c.z - 1}},
            {ElementKind::Face, 2, Cell{c.x, c.y, c.z}},
            {ElementKind::Face, 2, Cell{c.x - 1, c.y, c.z}},
        };
        int count = 0, alongX = 0;
        for (const auto& face : around) {
            const Piece* p = at(face);
            if (p == nullptr || p->slot != Slot::Wall) continue;
            ++count;
            if (face.axis == 0) ++alongX;
        }
        if (count == 0) continue;
        if (count == 2 && (alongX == 2 || alongX == 0)) continue; // straight run
        trims.push_back(edge);
    }
    return trims;
}

Enclosure enclosure(const Structure& structure, const Element& start, int maxVolumes,
                    const std::function<WorldCell(const Cell&)>& world) {
    Enclosure result;
    if (start.kind != ElementKind::Volume || maxVolumes < 1) return result;
    Element origin = start;
    origin.axis = 0;
    const WorldCell at = world(origin.cell);
    if (structure.occupied(origin) || (at != WorldCell::Open && at != WorldCell::Sky)) return result;

    // The house's own footprint, one registry cell of margin: sky met
    // beyond it is the open air outside, and the volume the fill left
    // through is the gap a builder wants marked. Caves below the surface
    // keep filling (a dug-out hollow under a slab is a shelter).
    Cell lo{0, 0, 0}, hi{0, 0, 0};
    if (!structure.bounds(lo, hi)) return result;
    lo.x -= 1; lo.y -= 1; lo.z -= 1;
    hi.x += 1; hi.y += 1; hi.z += 1;
    auto inBox = [&](const Cell& c) {
        return c.x >= lo.x && c.x <= hi.x && c.y >= lo.y && c.y <= hi.y && c.z >= lo.z && c.z <= hi.z;
    };

    std::set<Cell> seen;
    std::vector<Cell> frontier;
    seen.insert(origin.cell);
    frontier.push_back(origin.cell);
    const int steps[6][3] = {{1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}, {0, 0, 1}, {0, 0, -1}};
    while (!frontier.empty()) {
        const Cell here = frontier.back();
        frontier.pop_back();
        for (const auto& step : steps) {
            const Cell next{here.x + step[0], here.y + step[1], here.z + step[2]};
            if (seen.count(next)) continue;
            // The face between here and next: the min-side face of whichever
            // of the two is further along the step's axis.
            const int axis = step[0] != 0 ? 0 : (step[1] != 0 ? 1 : 2);
            const bool forward = step[axis] > 0;
            Element face{ElementKind::Face, axis, forward ? next : here};
            if (structure.occupied(face)) continue;
            const WorldCell cell = world(next);
            if (cell == WorldCell::Solid) continue;
            if (cell == WorldCell::Outside || (cell == WorldCell::Sky && !inBox(next))) {
                result.volumes = static_cast<int>(seen.size());
                result.leak = here;
                result.leakReason = "sky";
                return result; // open to the sky or the world's edge
            }
            if (structure.occupied(Element{ElementKind::Volume, 0, next})) continue;
            seen.insert(next);
            if (static_cast<int>(seen.size()) > maxVolumes) {
                result.volumes = static_cast<int>(seen.size());
                result.leak = next;
                result.leakReason = "cap";
                return result; // too big to be a room
            }
            frontier.push_back(next);
        }
    }
    result.enclosed = true;
    result.volumes = static_cast<int>(seen.size());
    return result;
}

} // namespace wroughtwild::lattice
