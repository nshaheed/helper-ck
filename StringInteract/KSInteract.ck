// plucked string filter, different excitation
@import "StringInteract"
@import "Rec"

Rec.auto();

// feedforward
SndBuf buffy => blackhole;
SinOsc interactor(80) => blackhole;
SinOsc s1(330) => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => blackhole;

// 1.5 => interactor.gain;

StringInteract inter(e1, interactor) => GainDB g(-12) => PoleZero block => OneZero lowpass => blackhole;

1.5 => inter._offset;
// 0.0 => inter._offset;

// inter.mod => dac;
// inter.carr => dac;

// feedback
lowpass => Delay delay => lowpass;

// our radius
.99999 => float R;
// our delay order
250 => float L;
// set delay
L::samp => delay.delay;
// set dissipation factor
Math.pow( R, L ) => delay.gain;
// take out DC and neighborhood
.999 => block.blockZero;
// place zero
-1 => lowpass.zero;

// fire excitation (try other sounds too)
"special:mand1" => buffy.read;

// spork~ interact();

0.5::second => now;
e1.keyOn();

while(1.1::second => now) {
  <<< inter.mod.last() >>>;
}

// advance time
(Math.log(.0001) / Math.log(R))::samp => now;

// fun interact() {
//   while(samp => now) {

//   }
// }