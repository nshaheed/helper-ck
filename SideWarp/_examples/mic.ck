@import "../SideWarp"

adc => SideWarp s => Pan2 left => dac;
adc => SideWarp r => Pan2 right => dac;

-0.5 => left.pan;
0.5 => right.pan;

0.7 => s.mix => r.mix;

0.001 => s.threshold => r.threshold;

0.9 => r.attack_speed;
0.3 => r.release_speed;



adc => LPF lpf => s.sidechain;
adc => r.sidechain;
300 => lpf.freq;

eon => now;