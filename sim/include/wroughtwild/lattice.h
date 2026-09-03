#pragma once

// The building lattice (Wave 4, docs/systems/construction.md, D-017): every
// placed piece occupies ELEMENTS of the cubic grid - volumes (cells), faces
// shared by two cells, or edges shared by four. Pieces are addressed by
// element, never by "which cell and where inside it", so a wall on the
// boundary between two cells belongs to neither, a post on an edge lines up
// with the walls on the faces around it, and the only placement rule is
// "the nearest free element of the piece's kind to where you look".
//
// The occupancy registry runs at a finer resolution than the build grid
// (construction.json lattice_divisions, 2 = half cells): a full-size piece
// occupies a FOOTPRINT of registry elements (a cube eight fine volumes, a
// wall four fine faces, a post two fine edges; a door two cells tall twice
// that), so half-scale pieces and full-size pieces conflict through the
// same set lookup with no second rulebook.
//
// Engine-neutral: the engine host converts a camera hit into a point and a
// surface normal, asks for ranked candidates, filters them by what its own
// world knows (terrain solidity, props), and renders the chosen pose.

#include <functional>
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

// World-space centre of a single element (cell centre, face centre, edge
// midpoint) on a lattice of `gridSize`.
Vec3 centre(const Element& element, double gridSize);

// Quarter turns about y that take a shape authored "thin along z / long
// along x" onto this element: 1 for faces normal to x and edges along z,
// 0 otherwise. Oriented blocks add the player's own rotation step.
int yawTurns(const Element& element);

// Elements of `slot` around a surface hit, nearest first (distance from
// `point` to the element centre), on a lattice of `gridSize` (the piece's
// own grid: the build grid for full-size pieces, a fraction of it for fine
// ones). `normal` is the hit surface's normal: the point is nudged a little
// along it so that a hit on a floor or a wall face resolves to the cells on
// the open side of that surface. A block gets one candidate (the cell on
// the open side); faces get the four planes that box the point in; edges
// the four lines around it per allowed axis.
std::vector<Element> candidates(Slot slot, Vec3 point, Vec3 normal, double gridSize);

// The same element expressed on a lattice `factor` times finer (a full-size
// piece's anchor in registry coordinates).
Element scaled(const Element& element, int factor);

// The registry elements a piece covers from its anchor (in registry
// coordinates): `span` registry cells per piece cell along every spanned
// axis, `tall` piece cells stacked upward. A volume spans all three axes, a
// face the two in its plane, an edge its own axis; `tall` stacks along y
// (a horizontal edge cannot be tall).
std::vector<Element> footprint(const Element& anchor, int span, int tall);

// World-space centre of a whole footprint on a registry lattice of
// `registryGrid`: what the engine poses the piece at.
Vec3 footprintCentre(const Element& anchor, int span, int tall, double registryGrid);

// One placed piece.
struct Piece {
    Element anchor;                 // registry coordinates; the footprint's min element
    Slot slot = Slot::Block;
    std::vector<Element> footprint; // every registry element it covers, anchor included
    std::string shapeId;
    std::string family;
    int rotationStep = 0; // quarter turns, meaningful for oriented shapes only
};

// The player's structure: what occupies which registry element. Rules,
// not presentation - the host mirrors it with scene nodes.
class Structure {
public:
    bool occupied(const Element& element) const;
    // The piece covering an element, or nullptr.
    const Piece* at(const Element& element) const;
    // False (and no change) when any element of the footprint is taken.
    bool place(const Piece& piece);
    // Removes the piece covering the element. False when nothing stood there.
    bool remove(const Element& element);
    void clear();
    // Pieces by anchor.
    const std::map<Element, Piece>& pieces() const { return pieces_; }

    // Wall-slot pieces on the vertical faces touching a vertical registry
    // edge: up to four (a piece counts once per face it covers).
    std::vector<const Piece*> wallsAt(const Element& verticalEdge) const;
    // True when some placed piece lies within `margin` registry cells of
    // the footprint's bounding box: the piece would touch the structure.
    // Placement uses it to let a beam or wall continue out into empty air
    // from what is already built, rather than only onto surfaces.
    bool near(const std::vector<Element>& footprint, int margin) const;
    // Vertical registry edges that want a corner post drawn: where walls
    // end or meet at an angle (a T, an L, a lone panel's two ends) and no
    // real post stands. A straight run's interior edges carry two
    // collinear wall faces and get nothing, so a long wall stays a wall
    // and a corner reads as a corner without the player placing the post.
    std::vector<Element> trimEdges() const;

private:
    std::map<Element, Piece> pieces_;     // by anchor
    std::map<Element, Element> owner_;    // covered element -> anchor
};

// What the world (not the structure) says about a registry volume.
enum class WorldCell { Open = 0, Solid = 1, Outside = 2 };

struct Enclosure {
    bool enclosed = false;
    int volumes = 0; // registry volumes reached (the room's size, or the cap)
};

// Is the registry volume `start` inside a shelter? Flood-fills open
// registry volumes six ways from it; a step is blocked by an occupied
// volume, an occupied face between the two volumes, or a world cell the
// callback calls Solid. The room is a shelter when the fill finishes
// before `maxVolumes` without ever reaching a cell the callback calls
// Outside (past the world's top or edge: open sky). A closed door counts
// as a wall - it is a piece on its face - and so does an open one, which
// is the rule Valheim uses and the one that lets you rest with the door
// ajar. Terrain is the world's business: a dug-out hollow with a slab
// over its mouth is as much a shelter as a hut.
Enclosure enclosure(const Structure& structure, const Element& start, int maxVolumes,
                    const std::function<WorldCell(const Cell&)>& world);

} // namespace wroughtwild::lattice
