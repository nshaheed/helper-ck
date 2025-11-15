@import "../Rec.ck"

// auto-record a specific ugen
SinOsc s => Bitcrusher b => dac;

// This will record the original sine wave, not the bitcrushed version
Rec.auto(s); // just pass in the ugen and viola! it's recording
4::second => now;