"""Small deterministic Blender-authored pixel surfaces; no third-party artwork.
All geometry remains in build_stair_sample.py. Nearest sampling, UVs in metres.
"""
import random
import bpy

def rgba(h):
    return tuple(int(h[i:i+2],16)/255.0 for i in (0,2,4))+(1,)

def make(name, palette, kind, output, seed=755):
    rng=random.Random(seed); n=64
    colors=[rgba(c) for c in palette]; pixels=[]
    for y in range(n):
        for x in range(n):
            r=rng.random(); index=0 if r<.65 else (1 if r<.89 else 2)
            if kind=='tile':
                # 0.5 m tile joint; small clusters rather than photograph noise.
                if x%32<2 or y%32<2:index=3
                elif x%32==2 or y%32==2:index=4
            elif kind=='wall':
                index=0 if r<.84 else (1 if r<.96 else 2)
            elif kind=='wood':
                index=(x//8)%3 if r<.94 else 3
                if x%16==0:index=3
            elif kind=='metal':
                index=0 if r<.96 else 1
            pixels.extend(colors[index])
    image=bpy.data.images.new('Pixel '+name,width=n,height=n,alpha=True)
    image.colorspace_settings.name='sRGB';image.pixels=pixels
    image.filepath_raw=str(output/(name+'.png'));image.file_format='PNG';image.save();image.pack()
    m=bpy.data.materials.new('Pixel '+name);m.use_nodes=True;m.diffuse_color=colors[0]
    nodes=m.node_tree.nodes; bsdf=nodes.get('Principled BSDF');bsdf.inputs['Roughness'].default_value=.95
    tex=nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest';tex.extension='REPEAT'
    m.node_tree.links.new(tex.outputs['Color'],bsdf.inputs['Base Color'])
    return m

def make_palette(output):
    output.mkdir(parents=True,exist_ok=True)
    return {
      'stone_lit':make('terrazzo_tiles',['999e94','858e87','b5b6a3','5c6762','bcc0aa'],'tile',output),
      'stone_back':make('stone_fascia',['6d7874','63706c','84918b','465550','919c8d'],'tile',output),
      'wall_lit':make('lime_plaster',['c0b9a4','ada992','d0c9b3','858d7e','e1d8bd'],'wall',output),
      'wainscot':make('school_green_paint',['647771','586b66','7a8a7e','354d48','8b9d88'],'wall',output),
      'structure':make('painted_iron',['283e43','435b5f','182c33','203137','607678'],'metal',output),
      'outline':make('dark_recess',['182b34','243c43','14252d','182b34','182b34'],'metal',output),
      'door':make('old_school_wood',['72523a','5c412f','846043','342e28','ab8555'],'wood',output),
      'glass':make('night_blue_glass',['173954','204964','0d2a43','193a55','193a55'],'metal',output),
      'nosing':make('worn_stone_edge',['bec0ad','a6ad9b','d3d0b7','67766a','d3d0b7'],'wall',output),
    }

def metric_uv(obj):
    mesh=obj.data
    if not mesh.uv_layers:mesh.uv_layers.new(name='Metre UV')
    uv=mesh.uv_layers.active.data
    for p in mesh.polygons:
        axis=max(range(3),key=lambda i:abs(p.normal[i])); indices=[i for i in range(3) if i!=axis]
        for li in p.loop_indices:
            co=mesh.vertices[mesh.loops[li].vertex_index].co
            uv[li].uv=(co[indices[0]],co[indices[1]])
