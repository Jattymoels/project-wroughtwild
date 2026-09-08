"""Retain INT-02C measurements and draw maps from native data (Pillow only).

Run with the existing bundled document Python; no package installation needed.
Inputs are isolated home_review outputs, never the owner's save directory.
"""
import argparse
import json
import math
from pathlib import Path
import shutil
from PIL import Image, ImageDraw, ImageFont


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", type=Path, default=Path("build/frontier-population"))
    parser.add_argument("--output", type=Path, default=Path("build/frontier-population/report"))
    args = parser.parse_args()
    args.output.mkdir(parents=True, exist_ok=True)
    font_path = "C:/Windows/Fonts/arial.ttf"
    font = ImageFont.truetype(font_path, 18)
    small = ImageFont.truetype(font_path, 15)
    title = ImageFont.truetype(font_path, 30)
    sheet = Image.new("RGB", (1450, 1730), "#faf8f2")
    draw = ImageDraw.Draw(sheet)
    draw.text((35, 22), "Wroughtwild / native population and the shellstone approach", fill="#17282b", font=title)
    draw.text((35, 69), "V6, seeds 1 / 77 / 193. Dots are pack anchors, not guaranteed visible enemies. Heights are runtime-corrected.", fill="#263a3b", font=font)
    colors = {"hostile": "#b54b23", "grazer": "#21764f", "cave": "#706582"}
    draw.text((35, 100), "Orange: surface hostiles   Green: grazers   Purple: caves   Blue: quarry / approach   Grey: elevation (lighter = higher)", fill="#263a3b", font=font)
    draw.text((35, 129), "Rings: 150m quiet catchment / 190m hostile route boundary. Local orange circles: 28m horizontal activation reach.", fill="#263a3b", font=font)
    retained = {"scope": "Native census at day and 17%, 50%, 82% of night, ordinary and foreign patrols. 3D activation also depends on height; maps show X/Z only.", "seeds": []}
    for row, seed in enumerate((1, 77, 193)):
        baseline = read(args.input / f"baseline/build/intensives/population-audit-{seed}.json")
        current = read(args.input / f"current/build/intensives/population-audit-{seed}.json")
        assert baseline["native_sha256"] == current["native_sha256"], f"Native identity changed: {seed}"
        assert baseline["dens"] == current["dens"], f"Den roster changed: {seed}"
        assert all(s["below_surface_2m"] == 0 and s["above_surface_2m"] == 0 for s in current["states"])
        quarry = next(h for h in current["habitats"] if h["id"] == "quarry_escarpment")
        detail = {"seed": seed, "native_sha256": current["native_sha256"], "packs": current["packs"],
                  "bands": current["bands"], "biomes": current["biomes"], "regions": current["regions"],
                  "quarry": {k: v for k, v in quarry.items() if k != "approach"},
                  "states": []}
        for old, new in zip(baseline["states"], current["states"]):
            assert all(abs(a[0]-b[0]) < .001 and abs(a[2]-b[2]) < .001 for a, b in zip(old["positions"], new["positions"])), "Horizontal patrols changed"
            detail["states"].append({"baseline": {k: v for k, v in old.items() if k != "positions"},
                                     "current": {k: v for k, v in new.items() if k != "positions"}})
        detail["grounding"] = read(args.input / f"current/build/intensives/population-grounding-{seed}.json")
        assert detail["grounding"]["failures"] == 0
        walk_root = args.input / f"current/build/intensives/population-walk-{seed}"
        detail["walk"] = read(walk_root / "manifest.json")
        assert detail["walk"]["failures"] == 0
        for name in ("quarry-day-0", "quarry-day-30", "quarry-day-59", "quarry-night-59", "native-hostiles-day", "native-hostiles-night"):
            shutil.copyfile(walk_root / f"{name}.png", args.output / f"seed-{seed}-{name}.png")
        retained["seeds"].append(detail)
        y0 = 180 + row * 510
        distance = math.hypot(quarry["x"] + .5-current["spawn"][0], quarry["z"] + .5-current["spawn"][2])
        draw.text((35, y0), f"Seed {seed} / {current['packs']} packs / quarry: {quarry['biome']}, {distance:.0f}m from spawn", fill="#17282b", font=font)
        for col, state_index in enumerate((0, 0, 1)):
            state = current["states"][state_index]
            x0, top, size = 35 + col * 475, y0 + 54, 420
            extent = (0, 0, 1024) if col == 0 else (quarry["x"]-150, quarry["z"]-150, 300)
            left, north, width = extent
            scale = size / width

            def point(x, z):
                return ((x-left)*scale, (z-north)*scale)

            panel = Image.new("RGB", (size, size), "#e1e4df")
            ink = ImageDraw.Draw(panel)
            for gz in range(64):
                for gx in range(64):
                    h = current["height_grid"][gz*64+gx]
                    shade = int(115 + min(h, 85)*1.35)
                    a, b = point(gx*16, gz*16), point((gx+1)*16, (gz+1)*16)
                    ink.rectangle((*a, *b), fill=(shade, shade+4, shade))
            sx, sz = point(current["spawn"][0], current["spawn"][2])
            for radius in (150, 190):
                r = radius*scale
                ink.ellipse((sx-r, sz-r, sx+r, sz+r), outline="#344a57", width=2)
            route = [point(p[0], p[2]) for p in quarry["approach"]]
            ink.line(route, fill="#155eae", width=3)
            for den, pos in zip(current["dens"], state["positions"]):
                x, z = point(pos[0], pos[2])
                category = "grazer" if den[4] else ("cave" if den[3] == "cave" else "hostile")
                color = colors[category]
                r = 1.6 if col == 0 else 3
                if col > 0 and category == "hostile":
                    reach = 28*scale
                    ink.ellipse((x-reach, z-reach, x+reach, z+reach), outline=color)
                ink.ellipse((x-r, z-r, x+r, z+r), fill=color)
            qx, qz = point(quarry["x"]+.5, quarry["z"]+.5)
            ink.rectangle((qx-5, qz-5, qx+5, qz+5), outline="#063c83", width=3)
            panel_title = ("Whole world / day (1 km)", "Quarry detail / day (300m)", "Quarry detail / 17% of night (300m)")[col]
            draw.text((x0, y0+27), panel_title, fill="#263a3b", font=small)
            sheet.paste(panel, (x0, top))
            draw.rectangle((x0, top, x0+size, top+size), outline="#697773")
    retained["baseline_grounding_seed_1"] = read(args.input / "baseline/build/intensives/population-grounding-1.json")
    (args.output / "measurements.json").write_text(json.dumps(retained, indent=2)+"\n", encoding="utf-8")
    sheet.save(args.output / "population-maps.png")
    print("POPULATION_REPORT: three native identities, rosters and horizontal routes match; corrected anchors and walks pass")
    print(args.output / "population-maps.png")


if __name__ == "__main__":
    main()
