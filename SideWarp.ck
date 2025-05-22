@import "Average"

public class SideWarp extends Chugraph {
    // takes in a threshold, an attack speed, a release speed, and mix,
    // and buffer len, and a sidechain, and gets right on to it
    // 
    inlet => Gain dry => outlet;
    inlet => LiSa sampler => Gain wet => outlet;
    Gain sidechain => Average avg(10::ms) => blackhole;
    
    float attack_speed;
    float release_speed;
    float threshold;
    
    fun @construct() {
        0.5 => dry.gain => wet.gain;
        10::second => sampler.duration;
        sampler.bi(0, false);
        sampler.loop(0, true);
        sampler.play(0, true);
        true => sampler.record;
        
        0.999 => attack_speed;
        0.2 => release_speed;
        0.001 => threshold;
        // spork~ run_playback();
        spork~ update_speed();
    }
    
    /*
    fun sidechain(UGen u) {
        u @=> _sidechain;
    }
    */
    
    fun run_playback() {
        while(true) {
            // <<< avg.average(), sidechain.last() >>>;
            avg.window_size() => now;
        }
    }
    
    fun update_speed() {
        while(true) {
            // attack or release?
            sampler.rate() => float val;
            
            if (avg.average() > threshold) {
                // <<< "YES THRESHOLD" >>>;
                (-1.0 - val) * attack_speed + val => sampler.rate;
            } else {
                (1.0 - val) * release_speed + val => sampler.rate;
            }
            
            // <<< sampler.rate(), sampler.playPos() / second, avg.average()  >>>;
            // <<< target, val, attack_speed >>>;
            // <<< (target - val) * attack_speed + val >>>;
            10::ms => now;
        }
    }
}

// our patch
// adc => Average avg(500::ms);
SndBuf pyramid(me.dir() + "pyramid_song.wav") => SideWarp s => dac;


0.0 => s.dry.gain;
1.0 => s.wet.gain;

// <<< s.sampler.playPos() >>>;
// 4::second => now;

// 0.99 => s.sampler.rate;

// 1::second => now;
// <<< s.sampler.rate() >>>;
// eon => now;

// just make sidechain a gain and chuck into it?

/*
for (1000 => int i; i >= -1000; i--) {
    // <<< s.sampler.rate() - 0.01 >>>;
    // Math.max(-1.0, s.sampler.rate() - 0.01) => s.sampler.rate;
    // eon => now;
    <<< s.sampler.playPos() / second >>>;
    i / 1000.0 => s.sampler.rate;
    
    10::ms => now;
}

for (-1000 => int i; i < 1000; i++) {
    // <<< s.sampler.rate() - 0.01 >>>;
    // Math.max(-1.0, s.sampler.rate() - 0.01) => s.sampler.rate;
    // eon => now;
    <<< s.sampler.playPos() / second >>>;
    i / 1000.0 => s.sampler.rate;
    
    10::ms => now;
}
*/

// fun kick times

minute / 77 => dur bpm;

16::bpm => now;
10::ms => now;

SndBuf kick(me.dir() + "kick.wav") => dac;
kick => s.sidechain;
false => kick.loop;

now + 20::second => time later;

while( now < later ) {
    0 => kick.pos;
        
    2::bpm => now;
}
0.3 => s.release_speed;
now + 20::second => later;
while (now < later) {
    0 => kick.pos;
    
    bpm => now;
}

now + 20::second => later;
0.8 => s.release_speed;
while (now < later) {
    0 => kick.pos;
    
    0.5::bpm => now;
}

0 => kick.pos;
0.1 => kick.rate;
0.01 => s.release_speed;

/*
0.05 => s.release_speed;
while (true) {
    0 => kick.pos;
    
    0.25::bpm => now;
}
*/
// me.exit();


// control loop
while( true )
{
    // <<< s.sampler.playPos() / second, s.sampler.rate() >>>;
    100::ms => now;
    // <<< avg.average() >>>;
    // avg.window_size() => now;
    
}