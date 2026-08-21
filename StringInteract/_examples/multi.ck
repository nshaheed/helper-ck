@import "../KSInteract2"
@import "Rec"

SinOsc s1 => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => String str1 => GainDB g1(-18) => dac;
SinOsc s2(441) => ADSR e2(1::ms, 1::ms, 0.9, 1::second) => String str2 => GainDB g2(-18) => dac.right;
SinOsc s3(441.3) => ADSR e3(3000::ms, 800::ms, 0.9, 0.2::second) => String str3 => GainDB g3(-18) => dac.left;

3 * 1.5 * 250::samp => str2.inter._delay.delay;

0.5 * 1.7 * 250::samp => str3.inter._delay.delay;

str1 => str2.inter.mod;
str2 => str1.inter.mod;

str3.inter.mod(str2, 125::samp);
str2.inter.mod(str3, 48::samp);

-0.9 => str1.inter.offset;
0.9 => str2.inter.offset;
-0.9 => str3.inter.offset;

Rec.stereo(dac, "mutli.wav");

// e3.keyOn(); 8.01::second => now; e3.keyOff();
// env2.keyOn(); 0.01::second => now; env2.keyOff();
e3.keyOn(); e2.keyOn(); e1.keyOn(); 6::second => now; e2.keyOff();e1.keyOff(); e3.keyOff();
// e3.keyOn(); e2.keyOn(); e1.keyOn(); 1::second => now; e2.keyOff();e1.keyOff(); e3.keyOff();

100::second => now;