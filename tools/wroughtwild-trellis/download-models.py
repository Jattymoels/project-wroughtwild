"""Fetch pinned public weights with Hugging Face's resumable chunked downloader."""
import hashlib
import json
import os
from pathlib import Path

repository = Path(__file__).resolve().parents[2]
local = repository / 'build/trellis-local'
os.environ['HF_HOME'] = str(local / 'download-cache')
os.environ['HF_HUB_DISABLE_IMPLICIT_TOKEN'] = '1'
os.environ['HF_HUB_DISABLE_TELEMETRY'] = '1'
os.environ['HF_XET_NUM_CONCURRENT_RANGE_GETS'] = '8'
os.environ['HF_HUB_DOWNLOAD_TIMEOUT'] = '120'
from huggingface_hub import snapshot_download

manifest = json.loads((Path(__file__).parent / 'install-manifest.json').read_text())
snapshot_download(repo_id=manifest['model_repository'], revision=manifest['model_revision'],
                  allow_patterns=[entry['name'] for entry in manifest['weights']],
                  local_dir=str(local / 'models'), max_workers=2, token=False)
for entry in manifest['weights']:
    path = local / 'models' / entry['name']
    assert path.stat().st_size == entry['bytes'], path
    with path.open('rb') as source:
        digest = hashlib.file_digest(source, 'sha256').hexdigest()
    assert digest == entry['sha256'], f'Checksum mismatch: {path}'
    print(f"Verified {entry['name']}", flush=True)
print('TRELLIS_MODELS_VERIFIED', flush=True)
