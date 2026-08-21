@import "../KSInteract2"
@import "Rec"

Rec.stereo(dac, "double.wav");

SinOsc s1 => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => String str1 => GainDB g1(-18) => dac.left;
SinOsc s2(441) => ADSR e2(1::ms, 1::ms, 0.9, 1::second) => String str2 => GainDB g2(-18) => dac.right;

3 * 1.5 * 250::samp => str2.inter._delay.delay;

str1 => str2.inter.mod;
str2 => str1.inter.mod;

0.9 => str1.inter.offset;
0.9 => str2.inter.offset;

// e3.keyOn(); 8.01::second => now; e3.keyOff();
// env2.keyOn(); 0.01::second => now; env2.keyOff();
e2.keyOn(); e1.keyOn(); 3::second => now; e2.keyOff();e1.keyOff();

4::second => now;