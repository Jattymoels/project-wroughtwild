#!/usr/bin/env python3
"""Generates the 16x16 greybox pixel textures (committed as PNGs next to this
script). Deterministic: rerunning reproduces identical files. Pure standard
library, so no image dependencies are needed to tweak the look."""

import random
import struct
import zlib
from pathlib import Path

SIZE = 16
OUT = Path(__file__).parent


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

    write_png("grass.png", speckle((88, 140, 60), 0.14, rng, ((130, 180, 80), 0.06)))
    write_png("forest_floor.png", speckle((52, 92, 44), 0.16, rng, ((84, 62, 38), 0.08)))
    write_png("rock.png", speckle((120, 120, 124), 0.12, rng, ((90, 90, 96), 0.07)))
    write_png("ash.png", speckle((58, 52, 50), 0.18, rng, ((214, 96, 28), 0.03)))
    write_png("dirt.png", speckle((110, 80, 52), 0.14, rng, ((84, 60, 38), 0.08)))
    write_png("stone_node.png", speckle((136, 134, 130), 0.10, rng, ((104, 102, 100), 0.10)))
    write_png("iron_vein.png", speckle((122, 118, 114), 0.10, rng, ((186, 110, 48), 0.12)))
    write_png("bark.png", speckle((96, 68, 40), 0.10, rng, ((70, 48, 28), 0.16)))
    write_png("leaves.png", speckle((46, 104, 40), 0.18, rng, ((30, 74, 28), 0.12)))


if __name__ == "__main__":
    main()
