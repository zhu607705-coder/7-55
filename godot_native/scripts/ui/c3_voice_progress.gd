extends VBoxContainer
## Read-only source waveform and playhead. No synthetic amplitude or clock.
class WaveBand extends Control:
 var bins:Array=[]
 var position_ratio:float=0.0
 var phase:String="idle"
 var fallback:bool=false
 func _draw()->void:
  var width:float=maxf(1,size.x)
  var middle:float=22
  draw_line(Vector2(0,middle),Vector2(width,middle),Color("d6d9ce"),1)
  var count:int=maxi(1,bins.size())
  var step:float=width/count
  for i:int in range(bins.size()):
   var amplitude:float=float(bins[i])
   var height:float=clampf(amplitude*34 if amplitude<=1 else amplitude,4,34)
   var left:float=round(i*step+step*.22)
   var color:Color=Color("70979a")
   if phase!="idle" and float(i)/count<position_ratio:color=Color("c72f3a") if not fallback else Color("65747a")
   if phase=="paused" and float(i)/count<position_ratio:color=Color("8a5558")
   draw_rect(Rect2(left,round(middle-height/2),maxf(2,floor(step*.56)),round(height)),color)
  if phase!="idle":
   var x:float=round(clampf(position_ratio,0,1)*maxf(0,width-2))
   draw_line(Vector2(x,2),Vector2(x,42),Color("172e35"),2)
   draw_rect(Rect2(x-2,0,6,4),Color("172e35"))
var session:RefCounted
var recording:Dictionary
var duration_ms:float=5200
var band:WaveBand
var caption:Label
var position_ms:float=0
var reduced_motion:bool=false
func setup(value:RefCounted,source:Dictionary,generated:Dictionary={},reduce:bool=false)->void:
 session=value
 recording=source
 reduced_motion=reduce
 duration_ms=float(generated.get("durationMs",source.get("targetDurationMs",5200)))
 add_theme_constant_override("separation",2)
 band=WaveBand.new();band.name="SourceWaveform";band.bins=generated.get("waveform",generated.get("waveformBins",[])).duplicate()
 band.custom_minimum_size=Vector2(0,44);band.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(band)
 caption=Label.new();caption.name="PlaybackPosition";caption.custom_minimum_size.y=18
 caption.add_theme_font_size_override("font_size",14);caption.add_theme_color_override("font_color",Color("506267"));add_child(caption)
 refresh()
func _process(_delta:float)->void:
 if is_visible_in_tree():refresh()
func refresh()->void:
 if band==null:return
 var phase:String="idle"
 position_ms=0
 if session!=null:
  phase=str(session.phase);position_ms=clampf(float(session.position_ms),0,duration_ms)
 band.phase=phase
 band.position_ratio=position_ms/maxf(1,duration_ms)
 band.fallback=session!=null and session.fallback
 band.queue_redraw()
 caption.text=""
 if session!=null:
  var status:String={"playing":"播放中","paused":"已暂停","finished":"播放结束","stopped":"已停止"}.get(phase,"")
  caption.text="%.1f / %.1f 秒  ·  %s"%[position_ms/1000,duration_ms/1000,status]
  if session.fallback:
   caption.text="声音记录 · 音频暂不可用  %.1f / %.1f 秒"%[position_ms/1000,duration_ms/1000]
   for part:Dictionary in recording.get("soundEvents",[]):
    if position_ms>=float(part.startMs) and position_ms<=float(part.endMs):caption.text+="\n"+str(part.labelZh)
 caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
