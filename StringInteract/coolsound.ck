@import "KSInteract3"

SinOsc sA => ADSR eA(1::ms, 1::ms, 0.9, 1::second) => String strA(250::samp) => GainDB gA(-18) => dac.left;

SinOsc sB(441) => ADSR eB(1::ms, 1::ms, 0.9, 1::second) => String strB(3*1.5*250::samp) => GainDB gB(-18) => dac.right;

// change this over time
// String.link(strA, 4::samp, strB, 4::samp, 8.1);

strA.connect();
strB.connect();

strA.printDelays();
strB.printDelays();

// this sounds cools af
eA.keyOn(); eB.keyOn(); 3::second => now; eA.keyOff(); eB.keyOff();
0.1::second => now;
eA.keyOn(); 3::second => now; eA.keyOff();

4::second => now;

