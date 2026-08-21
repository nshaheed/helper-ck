@import "../KSInteract2"
@import "Rec"

Rec.stereo(dac, "single.wav");

SinOsc s1 => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => String str1 => GainDB g1(-18) => dac;

e1.keyOn(); 2::second => now; e1.keyOff();

10::second => now;