"""Single versioned selection contract shared by compile and preview tools."""
import hashlib,json
from pathlib import Path
SOURCE=Path(__file__).resolve().parents[2]/'art/campus_layered'
def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()
def load_current():
    author=json.loads((SOURCE/'authoring.json').read_text())
    registry_path=SOURCE/'active_selection.json'
    if not registry_path.is_file():raise ValueError('Missing canonical active_selection.json; never fall back to a preview snapshot')
    registry=json.loads(registry_path.read_text())
    assert registry['revision']==author['selectionRevision'],'Selection revision drift'
    assert len({r['id']for r in author['layers']})==len(author['layers']),'Duplicate layer id'
    layers={r['id']:r for r in author['layers']}
    assert set(layers)==set(registry['allowedLayerIds']), 'Layer inventory differs from canonical selection'
    for prefix in registry.get('excludedLayerIdPrefixes',[]):
        assert not any(layer.startswith(prefix) for layer in layers),('Excluded draft active',prefix)
    for item in registry['activeSelections']:
        row=layers[item['layerId']]
        for field in ['sourceSha256','origin','scale']:
            assert row[field]==item[field],(item['layerId'],field,'selection drift')
        assert sha(SOURCE/row['source'])==row['sourceSha256']
        assert item['status'] in ['user_selected','user_temporarily_retained','user_accepted_prior_version']
    for item in registry.get('technicalLayers',[]):
        row=layers[item['layerId']]
        for field in ['sourceSha256','origin','scale']: assert row[field]==item[field],(item['layerId'],field)
        assert sha(SOURCE/row['source'])==row['sourceSha256']
    for retired in registry['retiredLayerIds']:assert retired not in layers,('Retired layer returned',retired)
    for excluded in registry.get('excludedSourceSha256',[]):
        assert all(row['sourceSha256']!=excluded for row in layers.values()),'Rejected source active'
    return author,registry,sha(registry_path)
