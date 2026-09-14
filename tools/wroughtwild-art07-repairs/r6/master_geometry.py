"""Hash mesh data and object poses across the additive Blender pack/reopen."""
import hashlib
import json
import bpy


def signatures():
    rows = {}
    for obj in bpy.data.objects:
        if obj.type != 'MESH':
            continue
        mesh = obj.data
        value = {
            'matrix': [list(row) for row in obj.matrix_world],
            'vertices': [list(vertex.co) for vertex in mesh.vertices],
            'polygons': [list(face.vertices) for face in mesh.polygons],
            'materials': [slot.material.name if slot.material else None for slot in obj.material_slots],
            'colours': {attr.name: [list(item.color) for item in attr.data] for attr in mesh.color_attributes},
        }
        rows[obj.name] = hashlib.sha256(json.dumps(value, sort_keys=True).encode()).hexdigest()
    return rows
