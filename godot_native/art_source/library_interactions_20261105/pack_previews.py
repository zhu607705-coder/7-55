"""Pack exact Godot-normalized PNG frames as APNG; no raster recoloring."""
from pathlib import Path
import struct,zlib
base=Path(__file__).resolve().parent
runtime=base.parents[1]/'assets/native/library_interactions_20261105'
def chunk(kind,data):
    return struct.pack('>I',len(data))+kind+data+struct.pack('>I',zlib.crc32(kind+data)&0xffffffff)
def read(path):
    png=path.read_bytes();pos=8;header=None;parts=[]
    while pos<len(png):
        size=struct.unpack('>I',png[pos:pos+4])[0];kind=png[pos+4:pos+8];data=png[pos+8:pos+8+size];pos+=12+size
        if kind==b'IHDR':header=data
        if kind==b'IDAT':parts.append(data)
    return header,b''.join(parts)
for name,indices,ms in [('backpack',list(range(8))+[7]*6+list(reversed(range(8))),95),('paper',list(range(16))+[15]*6+list(reversed(range(16))),65),('staff',[0]*10+[1,2,3]+list(range(4,12))+[3,0],130)]:
    frames=[read(runtime/f'{name}_{i:02d}.png') for i in indices]
    header=frames[0][0];width,height=struct.unpack('>II',header[:8]);out=b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',header)+chunk(b'acTL',struct.pack('>II',len(frames),0));seq=0
    for index,(h,data) in enumerate(frames):
        assert h==header
        out+=chunk(b'fcTL',struct.pack('>IIIIIHHBB',seq,width,height,0,0,ms,1000,0,0));seq+=1
        if index==0:out+=chunk(b'IDAT',data)
        else:out+=chunk(b'fdAT',struct.pack('>I',seq)+data);seq+=1
    out+=chunk(b'IEND',b'');(base/f'preview_{name}.apng').write_bytes(out)
