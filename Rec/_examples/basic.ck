@import "../Rec.ck"

// auto-record the dac output
SinOsc s => dac;
Rec.auto(); // defaults to recording the dac
4::second => now;