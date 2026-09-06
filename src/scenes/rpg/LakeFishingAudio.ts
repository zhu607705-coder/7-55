import type { RhythmFishingJudgment } from "../../modules/RhythmFishingEngine";
function tone(context: AudioContext, at: number, type: OscillatorType, start: number, end: number, volume: number, duration: number): void {
    const osc = context.createOscillator(), gain = context.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(start, at);
    osc.frequency.exponentialRampToValueAtTime(Math.max(25, end), at + duration);
    gain.gain.setValueAtTime(.0001, at);
    gain.gain.exponentialRampToValueAtTime(volume, at + .004);
    gain.gain.exponentialRampToValueAtTime(.0001, at + duration);
    osc.connect(gain).connect(context.destination);
    osc.onended = () => { osc.disconnect(); gain.disconnect(); };
    osc.start(at);
    osc.stop(at + duration + .01);
}
/** Four audible beats: steady / let out / reel / lift; also supplies the four-beat count-in. */
export function scheduleLakeFishingBeat(context: AudioContext, beat: number, at: number): void {
    const step = ((beat % 4) + 4) % 4;
    tone(context, at, "sine", step === 0 ? 135 : 105, 45, step === 0 ? .17 : .095, .13);
    if (step === 1)
        tone(context, at, "triangle", 950, 480, .065, .055);
    if (step === 2)
        tone(context, at, "triangle", 340, 150, .105, .09);
    if (step === 3) {
        tone(context, at, "sine", 784, 760, .115, .15);
        tone(context, at + .035, "sine", 1175, 1100, .06, .12);
    }
    else
        tone(context, at + .3, "square", 1600, 1100, .012, .025);
}
export function scheduleLakeFishingJudgment(context: AudioContext, judgment: RhythmFishingJudgment, at: number): void {
    if (context.state !== "running")
        return;
    if (judgment === "miss") {
        tone(context, at, "triangle", 140, 65, .11, .2);
        return;
    }
    tone(context, at, "sine", judgment === "perfect" ? 1046 : 880, judgment === "perfect" ? 1046 : 880, .09, .13);
    if (judgment === "perfect")
        tone(context, at + .065, "sine", 1568, 1568, .055, .13);
}
