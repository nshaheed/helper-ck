// string theory - tiff (possible name ? )

// plucked string filter, different excitation
// @import "StringInteract"
@import "Rec"
@import "DelayB"

public class Interference extends Chugen {
  UGen @ _mod[0];
  Step _step => DelayB _delay => blackhole;

  0.75 => float _offset;

  "" => string name;
  true => int print_col;

  dur _delay_idx[0];

  // our radius
  .99999 => float R;
  // our delay order
  250 => float L;
  // 8 => float L;
  // set delay
  L::samp => _delay.delay;
  // set dissipation factor
  Math.pow( R, L ) => _delay.gain;
  // Math.pow( R, L ) => _delay.feedback;

  // if needed this should maybe be moved to a chugin, seems like a weird
  // mix of chugin and chugraph happening rn
  fun float tick(float in) {
    in => _step.next;
    if (_mod.size() == 0) return _delay.last();

    // <<< "Past" >>>;

    for (int i; i < _mod.size(); i++) {
      _mod[i] @=> UGen mod;
      _delay_idx[i] => dur idx;
      _delay.valueAt(idx) => float val;

      mod.last() + _offset => float mod_pos_offset;

      _delay.valueAt(idx) => float carr_pos;

      "note3" => string debug;

      if (print_col) {
	chout <= "name\tval\tmod\tmod_po\tmod_po2\tcurr_p\tout\tplay\trec" <= IO.nl();
	false => print_col;
      }

      time later;
      // 508::samp + later => later;
      // 100::ms + later => later;
      30::samp + later => later;
      // if (true) {
      // 	chout <= "name, in, mod, mod_pos_off\n";
      // }
      if (now < later && name == debug) {
	chout <= name <= "\t" <= Std.ftoa(val, 4) <= "\t" <= Std.ftoa(mod.last(), 4) <= "\t" <= mod_pos_offset <= "\t";
	// <<< name, in, _mod.last(), mod_pos_offset >>>;
      }

      // if (mod_pos_offset > in) {
      //   mod_pos_offset => carr_pos;
      // }
      if (_offset >= 0. && mod_pos_offset < val) {
	mod_pos_offset => carr_pos;
      }
      if (_offset < 0. && mod_pos_offset > val) {
	mod_pos_offset => carr_pos;
      }

      if (now < later && name == debug) {
	chout <= Std.ftoa(mod_pos_offset, 4) <= "\t" <= Std.ftoa(carr_pos, 4) <= "\t" <= Std.ftoa(_delay.last(), 4) <= "\t" <= _delay._l.playPos() / samp <= "\t" <= _delay._l.recPos() / samp <= IO.nl();
      }

      _delay.valueAt(idx, carr_pos);
    }

    // return carr_pos; // no longer do this?
    // <<< _delay.last() >>>;
    return _delay.last();
  }

  // TODO be able to remove a modulator
  fun UGen mod(UGen mod) {
    _mod << mod;
    _delay_idx << 4::samp;

    return mod;
  }

  fun UGen mod(UGen mod, dur idx) {
    _mod << mod;
    _delay_idx << idx;

    return mod;
  }

  fun float offset(float off) {
    off => _offset;
    return off;
  }
}

public class String extends Chugraph {
  inlet => Gain hold => PoleZero block => OneZero lowpass => GainDB g(0) => outlet;
  lowpass => Interference inter => hold;

  -1 => lowpass.zero;
  0.999 => block.blockZero;

  @doc "get length of delay line"
  fun dur delay() {
    return inter._delay._delay;
  }

  @doc "set length of delay line"
  fun dur delay(dur d) {
    return inter._delay.delay(d);
  }
}

// SinOsc s3(220) => ADSR e3(1::ms, 1::ms, 0.9, 1::second) => String str1 => dac;
// Noise s3 => ADSR e3(1::ms, 1::ms, 0.9, 1::second) => String str1 => GainDB g(-18) => dac.left;
// Noise noise2 => ADSR env2(1::ms, 1::ms, 0.9, 1::second) => String str2 => dac.right;

SinOsc s3 => ADSR e3(1::ms, 1::ms, 0.9, 1::second) => String str1 => GainDB g(-18) => dac.left;
SinOsc noise2(441) => ADSR env2(1::ms, 1::ms, 0.9, 1::second) => String str2 => dac.right;

// 3 * 1.5 * 250::samp => str2.inter._delay.delay;

str1 => str2.inter.mod;
str2 => str1.inter.mod;

-0.9 => str1.inter.offset;
0.9 => str2.inter.offset;

// e3.keyOn(); 0.01::second => now; e3.keyOff();
// env2.keyOn(); 0.01::second => now; env2.keyOff();
env2.keyOn(); e3.keyOn(); 6::second => now; env2.keyOff();e3.keyOff();

Rec.stereo(dac, "KSInterac2.wav");

4::second => now;
<<< "Exiting! (don't forget to remove this when you update your code" >>>;
me.exit();

/* Reworking signal chain to allow for DelayB to B used */

// Noise s3 => ADSR e3(1::ms, 1::ms, 0.9, 1::second) => blackhole;

// Impulse e3 => blackhole;

// Interference
Gain hold3 => PoleZero block3 => OneZero lowpass3 => GainDB g3(0) => blackhole;

// need to pair up delay3 with interference? Interference should have a delay in it ithinks yeah that's right
lowpass3 => Interference inter3 => hold3;
e3 => hold3;

// place zero
-1 => lowpass3.zero;


// Noise s2 => ADSR e2(1::ms, 1::ms, 0.9, 1::second) => blackhole;
SinOsc s2(220) => ADSR e2(1::ms, 1::ms, 0.9, 1::second) => dac.left;

// Interference
Gain hold2 => PoleZero block2 => OneZero lowpass2 => GainDB g2(0) => dac.right;

// need to pair up delay2 with interference? Interference should have a delay in it ithinks yeah that's right
lowpass2 => Interference inter2 => hold2;
e2 => hold2;

// take out DC and neighborhood
0.999 => block2.blockZero;
0.999 => block3.blockZero;

// place zero
-1 => lowpass2.zero;

hold3 => inter2.mod;
hold2 => inter3.mod;

// 1.9 => inter2.offset;
// -1.9 => inter3.offset;

-0.9 => inter2.offset;
0.9 => inter3.offset;

// 0 => inter2.offset => inter3.offset;

// 3 * 1.5 * inter2.L::samp => inter2._delay.delay;

"inter3" => inter3.name;
"inter2" => inter2.name;

/* End of rework attempt */


/*
// SinOsc s1(320) => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => blackhole;
Noise s1 => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => blackhole;
Impulse imp => blackhole;

// feedforward
SndBuf buffy => Gain hold1 => Interference inter1 => PoleZero block1 => OneZero lowpass1 => GainDB g1(-12) => blackhole;
e1 => hold1;

imp => hold1;
// feedback
lowpass1 => DelayB delay1 => hold1;

Gain hold2 => Interference inter2 => PoleZero block2 => OneZero lowpass2 => GainDB g2(-24) => dac;
// feedback
lowpass2 => DelayB delay2 => hold2;

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
*/

// fire excitation (try other sounds too)
// "special:mand1" => buffy.read;

// 0.15::second => now;

// 1. => imp.next;
// SinOsc s(120) => hold1;

Rec.auto();

// e1.keyOn(); 0.01::second => now; e1.keyOff();

e2.keyOn(); 0.01::second => now; e2.keyOff();
e3.keyOn(); 0.01::second => now; e3.keyOff();
// 1 => e3.next;

// e2.keyOn(); samp => now; e2.keyOff();

// advance time
// (Math.log(.0001) / Math.log(R))::samp => now;

8::second => now;