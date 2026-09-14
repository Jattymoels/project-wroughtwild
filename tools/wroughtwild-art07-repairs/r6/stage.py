"""Verify prepared G1 bytes, then apply only the R6 presentation delta."""
import hashlib
import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
TOOLS = Path(__file__).resolve().parent
OUT = ROOT / 'build/art07-repairs/r6/v01'
GAME = OUT / 'runtime/game'

def sha(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()

def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8', newline='\n')

def main():
    prepared = json.loads((OUT / 'prepared.json').read_text(encoding='utf-8-sig'))
    report = OUT / 'verification/prepared-hashes.json'
    if not report.exists():
        for name, row in prepared['original_files'].items():
            path = OUT / 'runtime' / name
            assert path.stat().st_size == row['bytes'] and sha(path) == row['sha256'], name
        write(report, json.dumps({'files': prepared['files'], 'bytes': prepared['bytes'], 'result': 'every prepared runtime entry hashes before mutation'}, indent=2))
    source = Path(json.loads((ROOT / 'docs/prototype/art07-repairs/2026-09-14/inputs.json').read_text(encoding='utf-8-sig'))['runtime_source']['path'])
    adapter = (source / 'game/c5/native_resource.gd').read_text(encoding='utf-8-sig')
    adapter = adapter.replace('var art:Node3D', 'var ribbon_material: ShaderMaterial\nvar art:Node3D')
    adapter = adapter.replace('if _terrain()!=null and _terrain().faceted_surface:return', '''if _terrain()!=null and _terrain().faceted_surface:
\t\tvar cfg_surface: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://c5/kit.json"))
\t\tvar kind := "ember_iron_vein" if visual == &"ember_vein" else String(visual)
\t\tfor candidate in cfg_surface.ores:
\t\t\tif candidate.id == kind: row = candidate
\t\tif not row.is_empty():
\t\t\tribbon_material = preload("res://r6/surface.gd").attach(self, row)
\t\t\t_refresh_state_look()
\t\treturn''')
    adapter = adapter.replace('func sync_state()->void:\n', '''func refresh_surface()->void:
\tsuper.refresh_surface()
\tif ribbon_material != null:
\t\tvar mesh: MeshInstance3D = get_node("MeshInstance3D")
\t\tmesh.material_override = ribbon_material
\t\tif remaining_units <= 0: mesh.visible = false
func sync_state()->void:
\tif ribbon_material != null:
\t\tribbon_material.set_shader_parameter("remaining_fraction", clampf(float(remaining_units)/float(row.units), 0.0, 1.0))
\t\tribbon_material.set_shader_parameter("native_cracked", cracked)
\t\tribbon_material.set_shader_parameter("heat_active", hot_level > 0)
\t\tdisplayed_state = "surface-u%d-%s" % [remaining_units, "cracked" if cracked else "cold"]
\t\t# Native depletion scales its retiring node; hide the surface immediately so
\t\t# that animation cannot detach a ribbon from its retained slope.
\t\tif remaining_units <= 0: get_node("MeshInstance3D").visible = false
''')
    adapter = adapter.replace('## A current terrain ribbon has no solid envelope: retain it exactly for separate adoption.', '## R6 adds material detail on exact native ribbon vertices; fallback source stays retained.')
    write(GAME / 'c5/native_resource.gd', adapter)
    dispatch = (source / 'game/g1/art.gd').read_text(encoding='utf-8-sig')
    dispatch = dispatch.replace('"ember_iron_vein","silver_vein"]:script=', '"ember_iron_vein","ember_vein","silver_vein"]:script=')
    dispatch = dispatch.replace('# C5\'s raised bodies are only for the source\'s fallback review. The native\n\t# faceted ore ribbon remains exact in this game\'s generated geography.', '# C5 retains fallback bodies; R6 shades the exact native faceted ribbon.')
    write(GAME / 'g1/art.gd', dispatch)
    for name in ['surface.gd', 'surface.gdshader', 'surface.json', 'review.gd', 'review.tscn']:
        if (TOOLS / name).exists():
            write(GAME / 'r6' / name, (TOOLS / name).read_text(encoding='utf-8-sig'))
    if (OUT/'projection-v01/c5-surface-fields.png').exists():
        shutil.copy2(OUT/'projection-v01/c5-surface-fields.png',GAME/'r6/c5-surface-fields.png')
        shutil.copy2(OUT/'projection-v01/projection.json',GAME/'r6/projection.json')
    print('R6_STAGED exact native geometry retained; isolated surface material and ember visual dispatch')

if __name__ == '__main__':
    main()
