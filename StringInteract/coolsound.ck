@import "KSInteract3"
@import "PlinkyRev"
@import "Tween"
@import "Rec"

Rec.stereo(dac, "coolsound.wav");

PlinkyRev rev => dac;
0 => rev.wobble;
0.25 => rev.mix;
0.1 => rev.shim;

SinOsc sA => ADSR eA(1::ms, 1::ms, 0.9, 1::second) => String strA(250::samp)
  => GainDB gA(-18) => Pan2 panA => rev;

SinOsc sB(441) => ADSR eB(1::ms, 1::ms, 0.9, 1::second) => String strB(3*1.5*250::samp)
  => GainDB gB(-18) => Pan2 panB => rev;

-0.8 => panA.pan;
0.8 => panB.pan;

SinOsc sIntro(440) => Gain intro => Envelope eIntro(0.1::second) => String strIntro(3*1.5*250::samp) => GainDB gIntro(-18) => rev;

// change this over time
// String.link(strA, 4::samp, strB, 4::samp, 8.1);

strA.connect();
strB.connect();
strIntro.connect();

strA.printDelays();
strB.printDelays();

// need to start a samp afterward for tween???
samp => now;
eIntro.keyOn();
0 => intro.db;
samp => now;
// 0 => sB.gain;
// 4::second => eB.attackTime;
// 0.1::second => eB.releaseTime;
// eB.keyOn();
// samp => now;
// 1 => sB.gain;

Tween introTween(5::ms) -> "db" -> intro;
introTween.ft(-300, -30).keyOn(2::second) => now;
1::second => now;
introTween.ft(-30, -20).keyOn(3::second) => now;
introTween.ft(-20, -10).keyOn(3::second) => now;
introTween.ft(-10, 0.1).keyOn(2::second) => now;
0.25::second => now;
introTween.ft(0.1, 6).keyOn(1::second) => now;
// introBtween.disconnect();
eIntro.keyOff();

// eB.keyOn(); 3.9::second => now;
eB.keyOff(); 0.1::second => now;

1::ms => eB.attackTime;
1::second => eB.releaseTime;

// this sounds cools af
eA.keyOn(); eB.keyOn(); 3::second => now; eA.keyOff(); eB.keyOff();
// 0.1::second => now;
eA.keyOn(); 3::second => now; eA.keyOff();

4.5::second => now;

eA.keyOn(); eB.keyOn(); 3::second => now; eA.keyOff(); eB.keyOff();
// 0.1::second => now;
eA.keyOn(); 3::second => now; eA.keyOff();

4.5::second => now;

4::second => eA.releaseTime => eB.releaseTime;
// this sounds cools af
0.5 => sA.gain => sB.gain;
eA.keyOn(); eB.keyOn(); 8::second => now; eA.keyOff(); eB.keyOff();

0.1::second => now;
// 1::second => eA.releaseTime => eB.releaseTime;
eA.keyOn(); 3::second => now; eA.keyOff();

4::second => now;

1.0 => sB.gain;
1.0 => sA.gain;
4::second => eA.releaseTime => eB.releaseTime;
eA.keyOn(); eB.keyOn(); 1::second => now; eA.keyOff();
100::ms => now;
0.5 => eA.gain;

// eA.keyOn(); eB.keyOn(); 1::second => now; eA.keyOff(); eB.keyOff();
eA.keyOn(); 900::ms => now; eA.keyOff();
100::ms => now;
eA.keyOn(); 900::ms => now; eA.keyOff();
100::ms => now;
eA.keyOn(); 900::ms => now; eA.keyOff();
100::ms => now;
eA.keyOn(); 900::ms => now; eA.keyOff();
eB.keyOff();
100::ms => now;
eA.keyOn(); 900::ms => now; eA.keyOff();
100::ms => now;
eB.keyOn();
eA.keyOn(); 900::ms => now; eA.keyOff();
100::ms => now;
eA.keyOn(); 900::ms => now; eA.keyOff();
100::ms => now;
eA.keyOn(); 900::ms => now; eA.keyOff();
100::ms => now;
eB.keyOff();
// eA.keyOn(); eB.keyOn(); 1::second => now; eA.keyOff(); eB.keyOff();
// 0.1::second => now;
// eA.keyOn(); 3::second => now; eA.keyOff();

7.5::second => now;

Machine.add(me.dir() + "coolsound2.ck");


15::second => now;

eA.keyOn(); eB.keyOn(); 3::second => now; eA.keyOff(); eB.keyOff();
// 0.1::second => now;
eA.keyOn(); 3::second => now; eA.keyOff();

10::second => now;

Machine.add(me.dir() + "coolsound3.ck");

60::second => now;

eA.keyOn(); eB.keyOn(); 3::second => now; eA.keyOff(); eB.keyOff();
// 0.1::second => now;
eA.keyOn(); 3::second => now; eA.keyOff();


2::minute => now;


// TOOD add another string that's expanding the harmony, but mimicing the first attack