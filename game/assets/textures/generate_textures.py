#!/usr/bin/env python3
"""Generates the 16x16 pixel textures (committed as PNGs next to this
script). Deterministic: rerunning reproduces identical files. Pure standard
library, so no image dependencies are needed to tweak the look.

Every colour comes from the master palette in docs/art/art-direction.md
(D-013 "Bright frontier, dark thresholds"): one base tone + one accent per
surface, brightness jitter only. Edit PALETTE, not the call sites."""

import random
import struct
import zlib
from pathlib import Path

SIZE = 16
OUT = Path(__file__).parent

# Master palette (docs/art/art-direction.md). Keep in sync with the biome
# mood table in game/scripts/biome_mood.gd.
PALETTE = {
    "meadow_grass": (98, 150, 62),
    "meadow_grass_light": (140, 188, 86),
    "forest_floor": (46, 84, 41),
    "forest_loam": (86, 60, 38),
    "stone": (116, 116, 122),
    "stone_dark": (86, 88, 96),
    "dirt": (106, 76, 48),
    "dirt_dark": (82, 58, 38),
    "bark": (92, 64, 38),
    "bark_dark": (64, 44, 26),
    "leaf": (48, 106, 42),
    "leaf_dark": (32, 76, 28),
    "ash": (52, 46, 46),
    "ember": (236, 110, 30),
    "iron_rust": (196, 116, 44),
}


def write_png(name: str, pixels: list) -> None:
    raw = b""
    for y in range(SIZE):
        raw += b"\x00" + bytes(c for x in range(SIZE) for c in pixels[y][x])

    def chunk(kind: bytes, payload: bytes) -> bytes:
        return (struct.pack(">I", len(payload)) + kind + payload +
                struct.pack(">I", zlib.crc32(kind + payload) & 0xFFFFFFFF))

    png = (b"\x89PNG\r\n\x1a\n" +
           chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0)) +
           chunk(b"IDAT", zlib.compress(raw, 9)) +
           chunk(b"IEND", b""))
    (OUT / name).write_bytes(png)
    print("wrote", name)


def clamp(v: float) -> int:
    return max(0, min(255, int(v)))


def speckle(base, jitter, rng, accents=None):
    """A base colour with per-pixel brightness jitter and rare accent pixels."""
    pixels = []
    for _ in range(SIZE):
        row = []
        for _ in range(SIZE):
            if accents and rng.random() < accents[1]:
                row.append(tuple(clamp(c) for c in accents[0]))
            else:
                k = 1.0 + rng.uniform(-jitter, jitter)
                row.append(tuple(clamp(c * k) for c in base))
        pixels.append(row)
    return pixels


def main() -> None:
    rng = random.Random(31)  # fixed seed: identical textures every run
    p = PALETTE

    # Surfaces: base tone + one accent, per the art-direction texture rules.
    write_png("grass.png", speckle(p["meadow_grass"], 0.13, rng, (p["meadow_grass_light"], 0.07)))
    write_png("forest_floor.png", speckle(p["forest_floor"], 0.15, rng, (p["forest_loam"], 0.08)))
    write_png("rock.png", speckle(p["stone"], 0.11, rng, (p["stone_dark"], 0.08)))
    # The wastes stay near-greyscale so the ember accent is the only thing
    # alive in the frame - danger accents are earned (D-013).
    write_png("ash.png", speckle(p["ash"], 0.17, rng, (p["ember"], 0.035)))
    write_png("dirt.png", speckle(p["dirt"], 0.13, rng, (p["dirt_dark"], 0.08)))

    # Props and nodes.
    write_png("stone_node.png", speckle(tuple(c + 14 for c in p["stone"]), 0.10, rng, (p["stone_dark"], 0.10)))
    write_png("iron_vein.png", speckle(p["stone"], 0.10, rng, (p["iron_rust"], 0.13)))
    write_png("bark.png", speckle(p["bark"], 0.10, rng, (p["bark_dark"], 0.16)))
    write_png("leaves.png", speckle(p["leaf"], 0.17, rng, (p["leaf_dark"], 0.12)))

    # Building families (construction.json materials): each family reads
    # as its own surface at a glance. Planks: bark tones with a dark seam
    # every four rows. Masonry: stone with mortar lines. Iron plate: dark
    # steel with rivet accents in rust.
    write_png("planks.png", banded(speckle(tuple(c + 26 for c in p["bark"]), 0.08, rng), p["bark_dark"], 4, 0))
    write_png("masonry.png", banded(speckle(p["stone"], 0.09, rng), p["stone_dark"], 8, 4, brick=True))
    write_png("iron_plate.png", speckle(tuple(c - 10 for c in p["stone_dark"]), 0.06, rng, (p["iron_rust"], 0.04)))
    # Bronze: warm alloy with a green patina fleck (era two's family).
    write_png("bronze.png", speckle((176, 118, 62), 0.07, rng, ((92, 128, 96), 0.05)))
    # The fen: wet dark ground with standing-water glints.
    write_png("marsh.png", speckle((58, 78, 46), 0.14, rng, ((44, 58, 70), 0.12)))
    # Era three's metals: blued steel with rivets, bright silver with a tarnish fleck.
    write_png("steel.png", speckle((96, 104, 118), 0.05, rng, ((60, 64, 74), 0.05)))
    # Fieldstone (D-021): rounded grey-brown stones with dark joints, laid dry.
    write_png("fieldstone.png", banded(speckle((124, 116, 104), 0.12, rng, ((150, 140, 124), 0.1)), (58, 52, 46), 5, 2, brick=True))
    write_png("silver.png", speckle((206, 210, 218), 0.05, rng, ((140, 136, 128), 0.04)))


def banded(pixels: list, seam, period: int, offset: int, brick: bool = False) -> list:
    """Dark seam rows every `period` rows (plank edges); with brick=True,
    vertical seams too, staggered per course, for masonry."""
    seam = tuple(clamp(c) for c in seam)
    for y in range(SIZE):
        course = (y + offset) // period
        for x in range(SIZE):
            if (y + offset) % period == 0:
                pixels[y][x] = seam
            elif brick and (x + (course % 2) * (period // 2)) % period == 0:
                pixels[y][x] = seam
    return pixels


if __name__ == "__main__":
    main()
