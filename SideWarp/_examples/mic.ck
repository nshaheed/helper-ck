@import "../SideWarp"

// An example of using a mic in SideWarp, with the mic also sidechaining the input.

// Have two SideWarps - with different paramters to create a more complex,
// mildly spatialized effect.
adc => SideWarp l => Pan2 left => dac;
adc => SideWarp r => Pan2 right => dac;

-0.5 => left.pan;
0.5 => right.pan;

// Set wet/dry balance
0.7 => l.mix => r.mix;

// Set trigger threshold (RMS) of sidechain effect
0.001 => l.threshold => r.threshold;

// When the sidechain input is above the threshold, begining
// moving the playback rate backwards, with the speed
// set by attack_speed. When then threshold is not met, move
// towards a positive playback rate set by relase_speed
0.9 => r.attack_speed;
0.3 => r.release_speed;

0.8 => l.attack_speed;

// Setting the sidechains. For s, we will run the mic input
// through a lowpass filter so it's bass-triggered.
adc => r.sidechain;
adc => LPF lpf => l.sidechain;
2.0 => lpf.gain;
300 => lpf.freq;

// display waveform visualization with chugl
GText lText --> l.inter() --> GG.scene();
GText rText --> r.inter() --> GG.scene();

@(2,1) => l.inter().sca;
@(2,1) => r.inter().sca;

0.6 => l.inter().posY;
-0.6 => r.inter().posY;

lText.text("Left");
rText.text("Right");

@(0.1, 0.2) => lText.sca;
@(0.1, 0.2) => rText.sca;

0.75 => lText.alpha => rText.alpha;


while( true )
{
    GG.nextFrame() => now;
}
