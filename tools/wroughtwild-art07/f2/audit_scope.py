"""Compare the installed review copy with its exact archived native/game base."""
import hashlib,json,zipfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[3];BUILD=ROOT/'build/art07/f2';game=BUILD/'game01'
allowed={'game/project.godot','game/scripts/strange_resource_art.gd'}
modified=[];unchanged=0;import_metadata=[]
with zipfile.ZipFile(game/'frozen.zip') as z:
    for entry in z.infolist():
        if entry.is_dir():continue
        expected=z.read(entry);p=game/entry.filename;actual=p.read_bytes()
        if actual!=expected:
            if p.suffix=='.import':
                import_metadata.append(entry.filename)
                continue # Godot regenerates per-machine import metadata; never packaged.
            assert entry.filename in allowed,entry.filename
            modified.append({'path':entry.filename,'base_sha256':hashlib.sha256(expected).hexdigest(),'review_sha256':hashlib.sha256(actual).hexdigest()})
        else:unchanged+=1
assert {v['path'] for v in modified}==allowed
data={'base':'4b5d89b376765fbf4d46049aa099e0bb154a82da','unchanged_base_files':unchanged,'changed_copy_files':modified,'regenerated_import_metadata_excluded_from_package':import_metadata,'frozen_archive_sha256':hashlib.sha256((game/'frozen.zip').read_bytes()).hexdigest(),'native_provenance':json.loads((BUILD/'v01/native/provenance.json').read_text(encoding='utf-8-sig'))}
(BUILD/'scope-audit.json').write_text(json.dumps(data,indent=2)+'\n')
print('F2_COPY_SCOPE_OK',unchanged,'unchanged base files;',len(modified),'isolated presentation/project files changed')
