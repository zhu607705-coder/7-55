extends RefCounted
## Small deterministic PCM effects made in code, no downloaded voice/audio assets.
## Deliberately muted shoe taps, cloth/torch click and breath-like filtered noise.
const RATE:=22050
static func make(kind:String,variant:int=0)->AudioStreamWAV:
	var duration:=.17
	if kind=="inhale":duration=.38
	elif kind=="exhale":duration=.75
	elif kind=="click":duration=.075
	var count:=int(duration*RATE)
	var bytes:=PackedByteArray();bytes.resize(count*2)
	var rng:=RandomNumberGenerator.new();rng.seed=755300+variant*83+kind.hash()
	var low:=0.0
	var smooth:=0.0
	for i in count:
		var t:=float(i)/RATE
		var u:=float(i)/count
		var noise:=rng.randf_range(-1,1)
		low=lerpf(low,noise,.12)
		smooth=lerpf(smooth,low,.07)
		var value:=0.0
		if kind=="step":
			var body:=sin(TAU*(105+variant*8)*t)*exp(-t*28)*.36
			var heel:=noise*exp(-t*155)*.18
			var sole:=low*exp(-t*25)*.30
			value=(body+heel+sole)*minf(t/.003,1)
		elif kind=="click":
			value=(noise*.25+sin(TAU*740*t)*.12)*exp(-t*95)*minf(t/.002,1)
		else:
			var envelope:=pow(sin(PI*u),1.3)
			if kind=="inhale":envelope*=.6+.4*u
			else:envelope*=1-.45*u
			value=(low-smooth)*envelope*(1.5 if kind=="inhale" else 1.15)
		var sample:=clampi(int(value*32767),-32768,32767)
		bytes.encode_s16(i*2,sample)
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=RATE
	stream.stereo=false
	stream.data=bytes
	return stream
