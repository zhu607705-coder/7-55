"""Build an isolated, self-contained Godot entrance preview; no saves/autoload."""
from pathlib import Path
import shutil, sys
root=Path(__file__).resolve().parents[1]
out=Path(sys.argv[1]).resolve()
files=[
 'scripts/presentation/qizhen_swan_hop_timeline.gd','scripts/presentation/qizhen_swan_hop_study.gd',
 'scenes/qizhen_swan_hop_study.tscn','tests/test_qizhen_swan_hop.gd','tests/capture_qizhen_swan_hop.gd',
 'assets/native/chapter3/black_swan_hop_keyframes_v3.png',
 'scripts/presentation/qizhen_swan_swim_visual.gd','scripts/presentation/qizhen_swan_swim_study.gd',
 'scenes/qizhen_swan_swim_study.tscn','tests/test_qizhen_swan_swim.gd','tests/capture_qizhen_swan_swim.gd',
 'assets/native/chapter3/black_swan_swim_atlas_v2.png',
 'scripts/games/qizhen_swan_entrance.gd','scripts/games/qizhen_swan_motion.gd','scripts/games/kayak_model.gd',
 'scripts/ui/kayak_visual.gd','scripts/presentation/qizhen_swan_entrance_preview.gd',
 'scripts/objects/kayak_rig.gd','scripts/objects/kayak_arm.gd','scripts/objects/kayak_paddle.gd','scripts/objects/kayak_wake.gd',
 'scenes/objects/kayak_rig.tscn','scenes/objects/kayak/kayak_arm.tscn','scenes/objects/kayak/kayak_wake.tscn',
 'scenes/objects/kayak/kayak_willow_paddle.tscn','scenes/objects/kayak/kayak_sign_paddle.tscn',
 'assets/native/kayak/hull.svg','assets/native/kayak/seated_player.svg',
 'scenes/qizhen_swan_entrance_preview.tscn',
 'tests/test_qizhen_swan_entrance.gd','tests/test_qizhen_swan_motion.gd','tests/capture_qizhen_swan_entrance.gd','tests/capture_qizhen_swan_compact.gd',
 'assets/rpg/interiors/qizhen_lake_swan_cove.png','assets/native/chapter3/black_swan_entrance_atlas.png','assets/native/chapter3/swan_cove_gate_cleanplate.png',
 'assets/rpg/qizhen/kayak_overhead_frame_a.png','assets/rpg/qizhen/kayak_overhead_frame_b.png',
 'assets/rpg/fonts/fusion_pixel_12px_proportional_zh_hans.ttf','assets/rpg/fonts/licenses/FUSION_PIXEL_FONT_OFL.txt','data/worlds.json',
 'assets/audio/chapter3-qizhen/sfx/fx_qizhen_paper_release.mp3','assets/audio/chapter3-qizhen/sfx/fx_qizhen_mist_spray.mp3',
 'docs/GODOT_ENGINE_LICENSE.txt','docs/GODOT_THIRDPARTY_NOTICES.txt','docs/QIZHEN_SWAN_ENTRANCE.md','docs/QIZHEN_SWAN_ENTRANCE_VALIDATION.json','docs/QIZHEN_SWAN_SWIM_STUDY.md','docs/QIZHEN_SWAN_HOP_STUDY.md']
for item in files:
 target=out/item;target.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(root/item,target)
(out/'project.godot').write_text('''config_version=5
[application]
config/name="7:55 · 启真湖黑天鹅出场验证"
run/main_scene="res://scenes/qizhen_swan_entrance_preview.tscn"
config/features=PackedStringArray("4.6", "GL Compatibility")
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="disabled"
[input_devices]
pointing/emulate_mouse_from_touch=false
[rendering]
textures/default_filters/use_nearest_mipmap_filter=false
textures/canvas_textures/default_texture_filter=0
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
''')
(out/'打开说明.txt').write_text('''《7:55》启真湖 · 黑天鹅出场验证

用 Godot 4.6.3 打开同目录 project.godot，导入完成后按 F6/F5。
过场长7.2秒；随后直接交还同一艘船的划桨操作。
新增展翅短扑：打开 scenes/qizhen_swan_hop_study.tscn 按 F6；7秒、16完整姿态的独立动作审看；2026-10-17用户认可该样片并要求上传PR。
新增游泳近景：打开 scenes/qizhen_swan_swim_study.tscn 按 F6；这是12秒动作审看循环，视觉待确认。
A/D或左右键：划桨。S/下键配合划桨：反划。
鼠标或触屏：左、右桨按钮，向上划前进，向下划反划。
空格/Enter或跳过按钮：跳过过场。
R或重播按钮：完全重置；P/Esc：暂停/继续。

这是独立原生验证工程，不读写正式存档，不代表完整追逐已集成。
继续驶出围栏南口仅验证交还操作；未替换正式钓纸条→河道接口。
原出场8姿态、平游方向图与短扑16姿态均由imagegen生成，分别保留；身体、水花、尾波、围栏门、船、纸条分别绘制。
地图及船来自原启真湖资产。围栏开口只使用生图清洁底板的局部小块，原图其他部分不变；门叶为独立原生物体。
''')
print(out)
