extends Line2D
## Deforms a generated raster strip along the exact model polyline. The texture
## is tiled, not stretched to the path length. No curve smoothing alters contact.
var source_region:=Rect2()
var source_texture:Texture2D
func configure(source:Texture2D,region:Rect2)->void:
 # Crop original pixels at runtime: Line2D repeats the texture RID, not atlas
 # margins. This keeps the transparent source canvas out of the repeated strip.
 source_texture=source;source_region=region
 texture=ImageTexture.create_from_image(source.get_image().get_region(Rect2i(region)));width=8.0
 texture_mode=Line2D.LINE_TEXTURE_TILE;texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 joint_mode=Line2D.LINE_JOINT_BEVEL;begin_cap_mode=Line2D.LINE_CAP_NONE;end_cap_mode=Line2D.LINE_CAP_NONE
 default_color=Color.WHITE
func present(path:PackedVector2Array)->void:points=path;visible=path.size()>1
