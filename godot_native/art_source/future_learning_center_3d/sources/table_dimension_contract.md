# Tabletop versus wheeled-frame dimensions

The 600 mm design is the **tabletop depth**, not the overall caster footprint.
`pipeline/refine_table.py` preserves the provider's caster/frame geometry, shifts
end assemblies in X for width variants, and creates a separately named
`Rounded flat tabletop`. Its `edit_receipt.json` explicitly records
`tabletopDepthM`: 0.60 for 120/125/135 variants and 0.65 for 150.

The actual 125 source board bounds are X ±0.625 m, Z ±0.300 m, Y
0.945…1.000 m. Its retained caster geometry extends to Z
−0.344788…0.312235 m (657.023 mm overall before runtime centering).
This is not evidence that the tabletop design should change to 657 mm.

`build_scene.py`'s `mobile_display` already assigns a distinct caster collision
rectangle: depth = tabletop depth ×0.96 +0.13 m. Thus 600 mm tabletops use a
706 mm collision depth, and 650 mm tabletops use 754 mm. No collision/model or
floor layout changes are required for this correction.

The old test mixed these contracts and permitted 108 mm extra depth while its
label said 7 mm. That exception is removed. `pipeline/test_table_dimensions.mjs`
now measures the editable board's real GLB vertices through glTF bounds, checks
its declared design dimensions, independently decodes each runtime Draco LOD,
and compares both signed horizontal edges at the actual scene placement to the
existing collision rectangle with only 1 mm encoding tolerance. LOD envelope
drift is separately bounded to 7 mm. Negative fixtures ensure a translated mesh
or an oversized caster assembly cannot pass by retaining the same nominal size.

These checks validate this review model's explicit source contract. They are not
survey measurements, physical furniture certification, or browser/touch testing.
