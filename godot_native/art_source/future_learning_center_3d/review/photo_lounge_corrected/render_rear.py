# CPU modelling QA only. No scene edits or source saves.
import runpy
from pathlib import Path
import bpy
root=Path(__file__).resolve().parents[2]
d=runpy.run_path(str(root/'scripts/build_photo_lounge_corrected.py'),run_name='audit_helpers')
for asset in ['lounge_single_corrected','lounge_double_corrected']:
 bpy.ops.wm.open_mainfile(filepath=str(root/'sources/models/photo_lounge_corrected'/asset/(asset+'.blend')))
 d['render'](asset+'_rear')
