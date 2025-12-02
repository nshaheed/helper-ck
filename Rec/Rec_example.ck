@import "Rec.ck"

SinOsc s => dac;

spork~ Rec.auto();

10::second => now;