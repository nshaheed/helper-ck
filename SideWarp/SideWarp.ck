@import "Average"
@import "Waveform"

public class SideWarp extends Chugraph {
    // takes in a threshold, an attack speed, a release speed, and mix,
    // and buffer len, and a sidechain, and gets right on to it
    inlet => Gain dry => outlet;
    inlet => LiSa sampler => Gain wet => outlet;
    Gain sidechain => Average avg(10::ms) => blackhole;

    float attack_speed;
    float release_speed;
    1 => float max_speed;
    float threshold;
    0.00001 => float reset_point;
    // at what point does the playback rate cross over from being positive to negative?
    // this controls lower bounds of frequency
    0 => float crossover_rate;

    // the current voice that's being played back
    0 => int m_voice;
    // ramp duration when turning off lisa voice
    10::ms => dur m_ramp_dur;

    // ~~~~~ ChuGL interface ~~~~~
    Math.floor(10::second / samp / 1024.0) $ int => int bufsize;
    inlet => Waveform m_waveform(bufsize);
    true => m_waveform.scroll;
    // ~~~~~~~~~~~~~~~~~~~~~~~~~~~

    fun @construct() {
	mix(0.5);
        10::second => sampler.duration;
        sampler.bi(m_voice, false);
        sampler.loop(m_voice, true);
        sampler.play(m_voice, true);
        true => sampler.record;

        0.02 => attack_speed;
        0.8 => release_speed;
        0.2 => threshold;

	m_waveform.addLine();
        spork~ update_speed();
    }

    fun @construct(float atk_speed, float rel_speed) {
	atk_speed => attack_speed;
	rel_speed => release_speed;

	mix(0.5);
	10::second => sampler.duration;
	sampler.bi(m_voice, false);
	sampler.loop(m_voice, true);
	sampler.play(m_voice, true);
	true => sampler.record;

	0.2 => threshold;

	m_waveform.addLine();
	spork~ update_speed();
    }

    @doc "get waveform scroll mode state (1=scrolling, 0=fixed)"
    fun int scroll() {
	return m_waveform.scroll;
    }

    @doc "set waveform scroll mode state (1=scrolling, 0=fixed)"
    fun int scroll(int scroll_state) {
	scroll_state => m_waveform.scroll;
	return scroll_state;
    }

    // TODO make a constructor that loads an audio file and doesn't turn on
    // recording.

    @doc "get package version number"
    fun static string version() {
	return "1.1.0";
    }

    @doc "ChuGL interface for SideWarp"
    fun GGen inter() {
	return m_waveform;
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

	return balance;
    }

    @doc "(hidden)"
    fun setPos() {
	// set position of playhead for waveform GGen
	m_waveform.size() => dur bufsize;
	sampler.playPos(m_voice) / sampler.duration() => float headpos;

	sampler.recPos() / sampler.duration() => float recpos;

	// playhead pos is only used if scroll is not enabled
	m_waveform.playheadPos() => float playheadpos;
	if (m_waveform.scroll) 1. => playheadpos;


	recpos - headpos => float diff;

	// playheadpos is relative to the position gotten from
	// m_waveform because otherwise error builds up because
	// the m_waveform buffer differs from the lisa buffer.
	playheadpos - diff => float realpos;

	// if realpos is negative, need to wrap around
	if (realpos < 0.) {
	    1. + realpos => realpos;
	}
	m_waveform.setLinePos(0, realpos);
    }

    fun runPos() {
	while (true) {
	    // hacky way to check if there's an actual ChuGL window
	    // open: if fps is 0. then we assume that chugl isn't open
	    if (GG.fc() > 0) {
		setPos();
		GG.nextFrame() => now;
	    } else {
		100::ms => now;
	    }
	}
    } spork~ runPos();

    false => int is_ramp;

    @doc "(hidden)"
    fun update_speed() {
	false => int reset;
	max_speed => float curr_max_speed;
	10::ms => dur tick;

        while(true) {
            // attack or release?
            sampler.rate(m_voice) => float val;

	    // while the threshold is met, go backwards
            if (avg.average() > threshold) {
		// zoom towards towards -1.0 playback
                sampler.rate(m_voice, (-1.0 - val) * attack_speed + val);

		// When the playback rate reaches crossover_rate, ramp down
		// the current lisa voice and spawn a new one going at the same rate, but negative.
		// This avoid any clicking/popping that can result from the reversing forming
		// weird peaks in the waveform.
		if (sampler.rate(m_voice) > 0 && Math.fabs(sampler.rate(m_voice)) < crossover_rate) {
		    sampler.rate(m_voice) => float old_rate;
		    m_voice => int old_voice;
		    sampler.rampDown(m_voice, m_ramp_dur);

		    // get new voice (not handling error case atm)
		    sampler.getVoice() => m_voice;

		    sampler.rate(m_voice, -1 * old_rate);
		    sampler.rampUp(m_voice, m_ramp_dur);
		    sampler.bi(m_voice, false);
		    sampler.loop(m_voice, true);
		    sampler.playPos(m_voice, sampler.playPos(old_voice));
		}
		true => is_ramp;
	    }
	    // when it's not at threshold, it will zip towards max_speed
	    else if (is_ramp) {
		sampler.rate(m_voice, (max_speed - val) * release_speed * release_speed + val);
		sampler.rate(m_voice, Math.min(sampler.rate(m_voice), max_speed));

		// Cross over into forward playback
		if (sampler.rate(m_voice) < 0 && Math.fabs(sampler.rate(m_voice)) < crossover_rate) {
		    sampler.rate(m_voice) => float old_rate;
		    sampler.rampDown(m_voice, m_ramp_dur);

		    // get new voice (not handling error case atm
		    m_voice => int old_voice;
		    sampler.getVoice() => m_voice;

		    sampler.rate(m_voice, -1 * old_rate);
		    sampler.rampUp(m_voice, m_ramp_dur);
		    sampler.bi(m_voice, false);
		    sampler.loop(m_voice, true);
		    sampler.playPos(m_voice, sampler.playPos(old_voice));
		}
	    }

	    // when max_speed doesn't exceed one, the playpos can never
	    // catch up to the recpos, so we jump it when it gets close enough
	    if (max_speed <= 1.0) {
		// when we get close to 1.0 playback rate, reset to 1.0, and
		// ramp down during the switchover to prevent a pop
		if (is_ramp && sampler.rate(m_voice) > max_speed - reset_point) {
		    true => reset;
		}
	    } else if (max_speed > 1 && is_ramp) {
		// here we check whether the sampler passes the recording head
		// and intervene accordingly
		sampler.playPos(m_voice) => dur playPos;
		sampler.recPos() => dur recPos;

		if (playPos > recPos) sampler.duration() +=> recPos;

		recPos + tick => dur nextRecPos;
		playPos + sampler.rate(m_voice) * tick => dur nextPlayPos;

		if (nextPlayPos > nextRecPos) {
		    true => reset;
		}
	    }

	    if (reset) {
		sampler.rate(m_voice) => float old_rate;
		sampler.rampDown(m_voice, 3::tick);
		sampler.rate(m_voice, 1.);

		// get new voice (not handling error case atm
		m_voice => int old_voice;
		sampler.getVoice() => m_voice;
		sampler.rampUp(m_voice, 3::tick);
		sampler.rate(m_voice, 1.);
		sampler.bi(m_voice, false);
		sampler.loop(m_voice, true);
		sampler.playPos(m_voice, (sampler.recPos() - samp) % sampler.duration());

		false => is_ramp;
		false => reset;
	    }
	    tick => now;
	}
    }

    @doc "(hidden)"
    fun int ramp() {
	return is_ramp;
    }
}

SndBuf buf("/Users/nshaheed/Documents/audio_stuff/low-freq/audio/bass-spectral2.wav");
// SndBuf buf("/Users/nshaheed/Documents/audio_stuff/low-freq/audio/bass-clarinet.wav");
// adc @=> UGen buf;
true => buf.loop;

TriOsc osc(330) => blackhole;
buf => SideWarp s => HPF hpf(20) => Dyno limiter => dac.left;
// osc => SideWarp s => HPF hpf(20) => Dyno limiter => dac.left;
buf => GainDB sidechainGain(-3) => s.sidechain;
// adc => GainDB sidechainGain(-6) => s.sidechain;
// osc => GainDB oscDB(-6) => dac;
buf => GainDB bufDB(-6) => dac;

buf => SideWarp s2 => dac.right;
limiter.limit();

// 1.005 => s.max_speed;
// 0.995 => s.crossover_rate;

1.1 => s.max_speed;
0.9 => s.crossover_rate;

// 1.1 => s.max_speed;

1.01 => s2.max_speed;
0.99 => s2.crossover_rate;


1. => s.mix;
// 0.0 => s.dry.gain;
// 1.0 => s.wet.gain;

0.001 => s.threshold => s2.threshold;

// 0.999 => s.attack_speed;
0.001 => s.attack_speed;
0.05 => s.release_speed;

0.99 => s2.attack_speed;
// 0.05 => s2.release_speed;
0.05 => s2.release_speed;

s.inter() --> GG.scene();
2 => s.inter().sca;
1.5 => s.inter().posX;

// UI render/update function
fun void updateUI()
{
    UI_Float rate;

    while (true) {
	GG.nextFrame() => now;
	// set UI window size
	UI.setNextWindowSize(@(400, 600), UI_Cond.Once);

	if (UI.begin("Controls", null, 0)) {
	    UI.text("Playback Rate:" + s.sampler.rate());
	    UI.text("Rec Pos: " + (s.sampler.recPos() / samp));
	    UI.text("Play Pos:" + (s.sampler.playPos(s.m_voice) / samp));
	    UI.text("Rate:    " + (s.sampler.rate(s.m_voice)));
	    UI.text("Ramping: " + (s.ramp()));
	    // UI.text("" + s.sampler.recPos() / samp);

	    for (int i: Std.range(s.sampler.maxVoices())) {
		if (s.sampler.playing(i)) {
		    UI.text("Voice " + i);
		}
	    }

	    UI.end();
	}
    }
} spork~ updateUI();

// control loop
while( true )
{
    GG.nextFrame() => now;
}
