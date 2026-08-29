@import "../SideWarpMulti"

// Here we have SideWarp being sidechained with itself!

me.dir() + "pyramid.wav" => string file;
SndBuf pyramid(file) => SideWarpMulti s(file) => Pan2 left => dac;
pyramid => SideWarpMulti r(file) => Pan2 right => dac;

// 30::second => s.sampler.duration => r.sampler.duration;
s.setPos(0::second, 10::second);
r.setPos(0::second, 10::second);

-0.5 => left.pan;
0.5 => right.pan;

// 1.0 => s.mix => r.mix;

// pyramid => dac;
1. => s.mix => r.mix;
0.001 => s.threshold => r.threshold;

0.9 => r.attack_speed;
0.1 => r.release_speed;

// We only want the bass to trigger the sidechain
pyramid => LPF lpf => s.sidechain;
lpf => r.sidechain;

100 => lpf.freq;

eon => now;