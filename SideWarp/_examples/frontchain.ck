@import "../SideWarp"

// Here we have SideWarp being sidechained with itself!

SndBuf pyramid(me.dir() + "pyramid.wav") => SideWarp s => Pan2 left => dac;
pyramid => SideWarp r => Pan2 right => dac;

-0.5 => left.pan;
0.5 => right.pan;

0.7 => s.mix => r.mix;

0.001 => s.threshold => r.threshold;

0.9 => r.attack_speed;
0.3 => r.release_speed;

// We only want the bass to trigger the sidechain
pyramid => LPF lpf => s.sidechain;
lpf => r.sidechain;

100 => lpf.freq;

eon => now;