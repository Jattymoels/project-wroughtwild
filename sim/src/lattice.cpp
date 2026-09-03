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

bool Structure::occupied(const Element& element) const { return pieces_.count(element) > 0; }

const Piece* Structure::at(const Element& element) const {
    auto it = pieces_.find(element);
    return it == pieces_.end() ? nullptr : &it->second;
}

bool Structure::place(const Piece& piece) {
    if (occupied(piece.element)) return false;
    pieces_[piece.element] = piece;
    return true;
}

bool Structure::remove(const Element& element) { return pieces_.erase(element) > 0; }

void Structure::clear() { pieces_.clear(); }

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
    for (const auto& face : around)
        if (const Piece* p = at(face)) walls.push_back(p);
    return walls;
}

std::vector<Element> Structure::trimEdges() const {
    std::set<Element> edges;
    for (const auto& [element, piece] : pieces_) {
        if (element.kind != ElementKind::Face || element.axis == 1) continue;
        // The two vertical edges bounding this wall's bottom.
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
        const auto walls = wallsAt(edge);
        if (walls.empty()) continue;
        if (walls.size() == 2 && walls[0]->element.axis == walls[1]->element.axis) continue; // straight run
        trims.push_back(edge);
    }
    return trims;
}

} // namespace wroughtwild::lattice
