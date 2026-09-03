#pragma once

// The building lattice (Wave 4, docs/systems/construction.md): every placed
// piece occupies one ELEMENT of the cubic grid - a volume (cell), a face
// shared by two cells, or an edge shared by four. Pieces are addressed by
// element, never by "which cell and where inside it", so a wall on the
// boundary between two cells belongs to neither, a post on an edge lines up
// with the walls on the faces around it, and the only placement rule is
// "the nearest free element of the piece's kind to where you look".
//
// Engine-neutral: the engine host converts a camera hit into a point and a
// surface normal, asks for ranked candidates, filters them by what its own
// world knows (terrain solidity, props), and renders the chosen pose.

#include <map>
#include <string>
#include <vector>

namespace wroughtwild::lattice {

enum class ElementKind { Volume = 0, Face = 1, Edge = 2 };

struct Cell {
    int x = 0, y = 0, z = 0;
    bool operator==(const Cell& o) const { return x == o.x && y == o.y && z == o.z; }
    bool operator!=(const Cell& o) const { return !(*this == o); }
    bool operator<(const Cell& o) const {
        if (x != o.x) return x < o.x;
        if (y != o.y) return y < o.y;
        return z < o.z;
    }
};

// A canonical lattice element.
//   Volume: the cell itself (axis unused, 0).
//   Face:   normal along `axis`, lying on the cell's MIN side of that axis -
//           the face this cell shares with its neighbour one step down `axis`.
//   Edge:   runs along `axis` from the cell's min corner (the corner shared
//           with the three neighbours down the other two axes).
// Every face and edge therefore has exactly one representation, which is
// what makes occupancy a plain set lookup.
struct Element {
    ElementKind kind = ElementKind::Volume;
    int axis = 0; // 0 = x, 1 = y, 2 = z
    Cell cell;

    bool operator==(const Element& o) const { return kind == o.kind && axis == o.axis && cell == o.cell; }
    bool operator!=(const Element& o) const { return !(*this == o); }
    bool operator<(const Element& o) const {
        if (kind != o.kind) return kind < o.kind;
        if (axis != o.axis) return axis < o.axis;
        return cell < o.cell;
    }
};

// What a shape may occupy (construction.json "element"):
//   block -> a volume;             floor -> a horizontal face (axis y);
//   wall  -> a vertical face (x/z); post  -> a vertical edge (axis y);
//   beam  -> a horizontal edge (x/z).
enum class Slot { Block, Wall, Floor, Post, Beam };
// Throws std::runtime_error for anything but the five names above.
Slot slotFromName(const std::string& name);
const char* slotName(Slot slot);
// True when the element is one the slot may occupy.
bool slotAccepts(Slot slot, const Element& element);

struct Vec3 {
    double x = 0.0, y = 0.0, z = 0.0;
};

// World-space centre of an element (cell centre, face centre, edge midpoint).
Vec3 centre(const Element& element, double gridSize);

// Quarter turns about y that take a shape authored "thin along z / long
// along x" onto this element: 1 for faces normal to x and edges along z,
// 0 otherwise. Volumes turn by the player's own rotation step instead.
int yawTurns(const Element& element);

// Elements of `slot` around a surface hit, nearest first (distance from
// `point` to the element centre). `normal` is the hit surface's normal: the
// point is nudged a little along it so that a hit on a floor or a wall face
// resolves to the cells on the open side of that surface. A block gets one
// candidate (the cell on the open side); faces get the four planes that box
// the point in; edges the four lines around it per allowed axis.
std::vector<Element> candidates(Slot slot, Vec3 point, Vec3 normal, double gridSize);

// One placed piece.
struct Piece {
    Element element;
    std::string shapeId;
    std::string family;
    int rotationStep = 0; // quarter turns, meaningful for oriented blocks only
};

// The player's structure: what occupies which element. Rules, not
// presentation - the host mirrors it with scene nodes.
class Structure {
public:
    bool occupied(const Element& element) const;
    const Piece* at(const Element& element) const;
    // False (and no change) when the element is taken.
    bool place(const Piece& piece);
    // False when nothing stood there.
    bool remove(const Element& element);
    void clear();
    const std::map<Element, Piece>& pieces() const { return pieces_; }

    // Vertical faces (walls) touching a vertical edge: up to four.
    std::vector<const Piece*> wallsAt(const Element& verticalEdge) const;
    // Vertical edges that want a corner post drawn: where walls end or
    // meet at an angle (a T, an L, a lone panel's two ends) and no real post
    // stands. A straight run's interior edges carry two collinear walls
    // and get nothing, so a long wall stays a wall and a corner reads as
    // a corner without the player placing the post.
    std::vector<Element> trimEdges() const;

private:
    std::map<Element, Piece> pieces_;
};

} // namespace wroughtwild::lattice
