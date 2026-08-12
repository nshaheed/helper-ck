// plucked string filter, different excitation
// @import "StringInteract"
@import "Rec"

class Interference extends Chugen {
  UGen @ _mod;

  0.75 => float _offset;

  "" => string name;
  
  fun float tick(float in) {
    if (_mod == null) return in;
    
    _mod.last() + _offset => float mod_pos_offset;

    in => float carr_pos;

    time later;
    // 508::samp + later => later;
    5::samp + later => later;    
    if (now < later) {
      chout <= name <= ", " <= in <= ", " <= _mod.last() <= ", " <= mod_pos_offset <= ", ";
      // <<< name, in, _mod.last(), mod_pos_offset >>>;
    }

    // if (mod_pos_offset > in) {
    //   mod_pos_offset => carr_pos;
    // }

    if (_offset >= 0. && mod_pos_offset < in) {
      mod_pos_offset => carr_pos;
    }
    if (_offset < 0. && mod_pos_offset > in) {
      mod_pos_offset => carr_pos;
    }

    if (now < later) {
      chout <= carr_pos <= IO.nl();
    }
    return carr_pos;
  }

  fun UGen mod(UGen mod) {
    mod @=> _mod;
    return mod;
  }

  fun float offset(float off) {
    off => _offset;
    return off;
  }
}

// SinOsc s1(320) => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => blackhole;
Noise s1 => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => blackhole;
Impulse imp => blackhole;

// feedforward
SndBuf buffy => Gain hold1 => Interference inter1 => PoleZero block1 => OneZero lowpass1 => GainDB g1(-12) => blackhole;
e1 => hold1;

imp => hold1;
// feedback
lowpass1 => Delay delay1 => hold1;

Gain hold2 => Interference inter2 => PoleZero block2 => OneZero lowpass2 => GainDB g2(-24) => dac;
// feedback
lowpass2 => Delay delay2 => hold2;

hold1 => inter2.mod;
hold2 => inter1.mod;

0.9 => inter1.offset;
-0.9 => inter2.offset;

"inter1" => inter1.name;
"inter2" => inter2.name;

// buffy =< inter1;
// e1 =< hold1;

// Rec.auto(g1);
// Rec.auto(g2);

// our radius
.99999 => float R;
// our delay order
250 => float L;
// set delay
L::samp => delay1.delay;
3 * 1.5 * L::samp => delay2.delay;
// set dissipation factor
Math.pow( R, L ) => delay1.gain => delay2.gain;
// take out DC and neighborhood
.999 => block1.blockZero => block2.blockZero;
// place zero
-1 => lowpass1.zero => lowpass2.zero;

// fire excitation (try other sounds too)
// "special:mand1" => buffy.read;

// 0.15::second => now;

// 1. => imp.next;
// SinOsc s(120) => hold1;

e1.keyOn(); 0.1::second => now; e1.keyOff();

// advance time
// (Math.log(.0001) / Math.log(R))::samp => now;

8::second => now;