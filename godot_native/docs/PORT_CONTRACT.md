# Native Godot migration contract
Base: 39ccde029b0cd25a6011739a4e4f98f8c898b2c3. Latest user explicitly requested full Godot migration. Original web source remains unmodified. Tested local commits are authorized; the requested GitHub Draft PR is pending write approval. No merge or deployment is included.

Godot4.6.3, Compatibility renderer. No browser/WebView/React/Phaser runtime.
State autoload owns `d: Dictionary` initialized from exact source createInitialGameState serialized to data/initial_state.json, plus `native` {chapter:1, page:"alarm", scene:"", mode:"light", player:{}, settings:{}, log:[], completed:[], selected_item:""}.
Source assets and JSON retained under `res://assets/` and `res://data/source/`; asset paths strip `src/assets/` prefix. `State.asset(path)` returns resource path. `State.content(name)` reads JSON from data/source.

Each chapter implementation extends RefCounted and defines:
- `func pages(s: Dictionary) -> Array`: entries {id,label}; filtered unlocked pages, never locked buttons.
- `func view(page: String, s: Dictionary) -> Dictionary`: {title,body,art?} with source prose; return {} if not handled.
- `func actions(page: String, s: Dictionary) -> Array`: {id,label,input?:"text"|"number"|"choice",placeholder?,options?:Array,disabled?:bool}; no answer leakage in labels.
- `func dispatch(s: Dictionary, action: String, value: Variant = null) -> Dictionary`: mutate s only after validated action. Returns {} if unhandled; otherwise {handled:true,message:String,game?:Dictionary,scene?:String,page?:String}. Native scene transitions write s.native.scene, s.native.page; returning scene/page also supported.
- `func objective(s: Dictionary) -> String`: current objective or "" when outside owned chapter.
- `func targets(scene: String, s: Dictionary) -> Array`: {id,label,position:[x,y],radius?:float,action:String,item?:String,mode?:"light"|"dark"}; optional, [] default. Shared RPG renderer validates distance/mode/item before dispatch; modules recheck story facts.
Game requests {type:"interception"|"chase"|"rhythm"|"spotlight"|"stairs"|"kayak"|"hold", on_success: action_id, title, instructions, ...}. The Main minigame host passes verified result dictionary via State.act(on_success,result); never expose a direct success action in page actions. Each chapter controller validates success result fields, not just truthiness. More specialized game implementation can be supplied as separate Control script and request {script:"res://scripts/...",on_success,...}.
Dialogs / choice inputs not inherently puzzle results. Source exact answers can appear as input validation, not button labels that auto-solve.

Integration API State.act(id,value), State.open_page(page), State.open_scene(scene), State.save_game(), State.get_actions(page), State.get_view(page), State.get_pages(), State.get_targets(scene), State.objective(); State.changed and State.feedback(message) signals. Main handles game_requested(config), narrative_requested(config).
Story authority native State only; audio, view switches, animation and developer previews never auto-complete story. Explicit DEV isolation. Preserve source initial facts/save shape where possible; imported legacy save must validate/version migrate instead of stamping success.

Each module documents implemented parity and gaps with tests and Godot parse checks. A reduced approximation is not full parity. Chapter modules are independent; Main integrates presentation, State owns persistence/dispatch and world owns spatial rendering/input. Remote publication remains separate from local verification.
