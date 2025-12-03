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
	mix(0.5);
        10::second => sampler.duration;
        sampler.bi(0, false);
        sampler.loop(0, true);
        sampler.play(0, true);
        true => sampler.record;

        0.02 => attack_speed;
        0.8 => release_speed;
        0.2 => threshold;
        spork~ update_speed();
    }

    fun @construct(float atk_speed, float rel_speed) {
	atk_speed => attack_speed;
	rel_speed => release_speed;

	mix(0.5);
	10::second => sampler.duration;
	sampler.bi(0, false);
	sampler.loop(0, true);
	sampler.play(0, true);
	true => sampler.record;

	0.2 => threshold;
	spork~ update_speed();
    }

    // TODO make a constructor that loads an audio file and doesn't turn on
    // recording.

    @doc "get package version number"
    fun static string version() {
	return "1.0.0";
    }

    @doc "set the mix level (1.0 - wet, 0.0 - dry)"
    fun float mix(float balance) {
	if (balance > 1.0) {
	    cherr <= "[SideWarp]: mix should between [0,1]" <= IO.newline();
	    1.0 => balance;
	}
	if (balance < 0.0) {
	    cherr <= "[SideWarp]: mix should between [0,1]" <= IO.newline();
	    0.0 => balance;
	}
	Math.map(balance, 0, 1, 0, Math.PI / 2) => float theta;

	// -4.5 dB Pan Law (https://www.cs.cmu.edu/~music/cmp/archives/icm-online/readings/panlaws/)
	Math.sqrt(((Math.PI / 2) - theta) * (2.0 / Math.PI) * Math.cos(theta)) => dry.gain;
	Math.sqrt(theta * (2.0 / Math.PI) * Math.sin(theta)) => wet.gain;

	// <<< dry.gain(), wet.gain() >>>;
	return balance;
    }

    @doc "(hidden)"
    fun update_speed() {
        while(true) {
            // attack or release?
            sampler.rate() => float val;

            if (avg.average() > threshold) {
                (-1.0 - val) * attack_speed + val => sampler.rate;
	    } else if (sampler.rate() < 0.99) {
		(1.0 - val) * release_speed + val => sampler.rate;

		// when we get close to 1.0 playback rate, reset to 1.0, and
		// ramp down during the switchover to prevent a pop
		if (sampler.rate() > 0.99) {
		    10::samp => sampler.rampDown;
		    10::samp => now;
		    10::samp => sampler.rampUp;

		    1.0 => sampler.rate;
		    (sampler.recPos() - samp) % sampler.duration() => sampler.playPos;
		}
	    } else {
		1.0 => sampler.rate;
	    }

	    10::ms => now;
	}
    }
}

/* <<<"beginning" >>>; */
// our patch
// adc => Average avg(500::ms);
SndBuf pyramid(me.dir() + "_examples/pyramid.wav") => SideWarp s => dac;


0.0 => s.dry.gain;
1.0 => s.wet.gain;

// 10::second + 5::samp =>now;
// me.exit();

// <<< s.sampler.playPos() >>>;
/* 4::second => now; */

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

minute / 77 => dur qn;

16::qn => now;
10::ms => now;

2000::ms => now;

SndBuf kick(me.dir() + "kick.wav") => dac;
kick => s.sidechain;
false => kick.loop;

/* 0.4 => s.release_speed; */

/* eon => now; */

/* 6970::ms => now; */
/* 8000.5::ms => now; */
/* 718::ms => now; */
/* me.exit(); */
3::second => now;

now + 20::second => time later;

<<< "about to loop" >>>;

while( now < later ) {
    0 => kick.pos;

    2::qn => now;
}
0.3 => s.release_speed;
now + 20::second => later;
while (now < later) {
    0 => kick.pos;

    qn => now;
}

now + 20::second => later;
0.8 => s.release_speed;
while (now < later) {
    0 => kick.pos;

    0.5::qn => now;
}

0 => kick.pos;
0.1 => kick.rate;
0.01 => s.release_speed;

/*
0.05 => s.release_speed;
while (true) {
    0 => kick.pos;

    0.25::qn => now;
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
