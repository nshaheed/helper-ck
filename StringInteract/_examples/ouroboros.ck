// have two strings loop back onto each other
@import "../KSInteract2"
@import "Rec"

Rec.stereo(dac, "ouroboros.wav");

SinOsc s1(220) => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => String str1 => GainDB g1(-18) => dac;
SinOsc s2(223) => e1;


str1.inter.mod(str1, 3::samp);

str1.inter.mod(str1, str1.delay() - 34::samp);

0.9 => str1.inter.offset;

e1.keyOn(); 15::second => now; e1.keyOff();

4::second => now;

