//-----------------------------------------------------------------------------
// name: game-of-life.ck
// desc: microphone input waveform as seeds for Conway's Game of Life
//
// author: Andrew Zhu Aday (https://ccrma.stanford.edu/~azaday/)
//   date: Fall 2024
//-----------------------------------------------------------------------------
/* Interesting observation:
The fragment shader invocation is not 1:1 with pixels on the quad.
This means at different resolutions (zoom levels / size of quad) different
cells will be updated. If the quad is close enough / resolution is high enough,
nevery pixel will cover a single cell and simulation will run "accurately".
However if the quad is very far away, and each screen pixel covers multiple
cells, not all cells will be updated. But kinda looks cool?

IDEA: wrap repeat, sample OFF the grid with scaling factor n*m for INFINITE conway!!
- requires doing as screen shader or pass clip space full-screen quad through custom geo */
//-----------------------------------------------------------------------------

@import "SideWarp"


// get max of mic input for window size
class Max extends Chugen {
    Waveform.WINDOW_SIZE => int window;

    float outputMax;
    float currentMax;
    int counter;

    fun float tick(float in) {
	if (counter % window == 0) {
	    currentMax => outputMax;
	    -Math.FLOAT_MAX => currentMax;
	}

	Math.max(currentMax, in) => currentMax;
	counter++;
	return currentMax;
    }
}

// get max of mic input for window size
class Min extends Chugen {
    Waveform.WINDOW_SIZE => int window;

    float outputMin;
    float currentMin;
    int counter;

    fun float tick(float in) {
	if (counter % window == 0) {
	    currentMin => outputMin;
	    Math.FLOAT_MAX => currentMin;
	}

	Math.min(currentMin, in) => currentMin;
	counter++;
	return currentMin;
    }
}

// get max of mic input for window size
class Average extends Chugen {
    Waveform.WINDOW_SIZE => int window;

    float outputAvg;
    float currentSum;
    int counter;

    fun float tick(float in) {
	if (counter % window == 0) {
	    currentSum / window => outputAvg;
	    0 => currentSum;
	}

	Math.fabs(in) +=> currentSum;
	counter++;
	return outputAvg;
    }
}

public class Waveform extends GGen {
    1024 => static int WINDOW_SIZE;
    // a waveform buffer that takes in an audio input and will generate a waveform texture
    Gain inlet => Max max => blackhole;
    inlet => Min min => blackhole;
    inlet => FFT fft =^ RMS rms => blackhole;
    inlet => Average avg => blackhole;

    WINDOW_SIZE => fft.size;
    Windowing.hann(WINDOW_SIZE) => fft.window;

    // length of waveform: bufsize * Max.maxWindow = # of samples being represented
    int m_bufsize;
    float maxbuf[];
    float minbuf[];
    float rmsbuf[];
    int count;
    time last_update;
    true => int scroll; // enable scrolling or not

    GG.scenePass().msaa(true);
    GG.outputPass().sampler(TextureSampler.linear());

    me.dir() + "waveform.frag" => string filename;
    FileIO fio;
    fio.open(filename, FileIO.READ);

    // ensure it's ok
    if( !fio.good() )
    {
	cherr <= "can't open file: " <= filename <= " for reading..." <= IO.nl();
    }

    string waveform_shader;

    while(fio.more()) {
	fio.readLine() +=> waveform_shader;
	"\n" +=> waveform_shader;
    }

    Material material;
    // PlaneGeometry plane_geo(1., 0.25, 1, 1);
    // PlaneGeometry plane_geo(1, 1, 1, 1);
    PlaneGeometry plane_geo;

    // <<< plane_geo.width(), plane_geo.height() >>>;
    // <<< plane_geo.widthSegments(), plane_geo.heightSegments() >>>;

    ShaderDesc shader_desc;
    waveform_shader => shader_desc.vertexCode;
    waveform_shader => shader_desc.fragmentCode;

    Shader custom_shader(shader_desc); // create shader from shader_desc
    custom_shader => material.shader; // connect shader to material

    GMesh mesh(plane_geo, material) --> this;

    // connect lines to mesh
    GLines playhead --> mesh;
    // array of vec2
    [ @(0,-0.5), @(0,0.5) ] @=> vec2 line_positions[];
    line_positions => playhead.positions;
    playhead.pos(@(-0.5, 0));
    0.001 => playhead.width;
    // 0.1 => lines.width;

    GLines extraPlayheads[0];

    // (initialize) write new audio data to shader
    // material.storageBuffer(1, samples);
    material.storageBuffer(1, maxbuf);
    material.storageBuffer(2, minbuf);
    material.uniformFloat(3, count $ float);
    material.uniformFloat(4, 2.0); // playhead width
    material.storageBuffer(5, rmsbuf);
    // scrolling enabled?
    material.uniformInt(6, scroll);

    fun @construct(int bufsize) {
	init(bufsize);
	spork~ populateBuffer();
    }

    fun @construct() {
	init(1024);
	spork~ populateBuffer();
    }

    // init function for constructors
    fun init(int bufsize) {
	bufsize => m_bufsize;
	// initialize all bufs
	new float[m_bufsize] @=> maxbuf;
	new float[m_bufsize] @=> minbuf;
	new float[m_bufsize] @=> rmsbuf;

	material.storageBuffer(1, maxbuf);
	material.storageBuffer(2, minbuf);
	// count?
	material.uniformFloat(3, count $ float);

	TextureDesc tex_desc;
	m_bufsize => tex_desc.width;
	WINDOW_SIZE => tex_desc.height;

	Texture tex(tex_desc);

	float texture_data[4 * bufsize * WINDOW_SIZE];
	// TODO need a better way to specify texture size
	tex.write(texture_data);
	material.texture(0, tex);
    }

    fun populateBuffer() {
	while (true) {
	    max.window::samp => now;
	    max.last() => maxbuf[count];
	    min.last() => minbuf[count];

	    // rms.upchuck() @=> UAnaBlob blob;
	    // blob.fval(0) => rmsbuf[count];
	    avg.last() => rmsbuf[count];
	    // <<< blob.fval(0), rmsbuf[count] >>>;

	    (count + 1) % m_bufsize => count;
	    now => last_update;
	}
    }

    // TODO rename 'Line' to 'Playhead'
    fun int addLine() {
	GLines line --> mesh;
	line_positions => line.positions;
	line.pos(@(-0.5, 0));
	0.001 => line.width;
	extraPlayheads << line;

	return extraPlayheads.size()-1; // return idx
    }

    // sets playhead position (from 0 to 1
    fun int setLinePos(int idx, float pos) {
	Math.map2(pos, 0, 1, -0.5, 0.5) => float posx;
	@(posx, 0) => extraPlayheads[idx].pos;
	return idx;
    }

    fun int removeLinePos(int idx) {
	// removes a line from scenegraph (but doesn't delete... for now)
	extraPlayheads[idx] --< mesh;
	return idx;
    }

    // get the total size of the waveform
    fun dur size() {
	return (WINDOW_SIZE * m_bufsize)::samp;
    }

    // got pos of main playhead
    fun float playheadPos() {
	(now - last_update) / WINDOW_SIZE::samp => float delta;
	return (count + delta) / WINDOW_SIZE;
    }

    fun update(float dt) {
	material.storageBuffer(1, maxbuf);
	material.storageBuffer(2, minbuf);
	material.storageBuffer(5, rmsbuf);
	// material.storageBuffer(5, maxbuf);
	material.uniformInt(6, scroll);


	// when scrolling is enabled, the playhead will always be on the right side
	if (scroll) {
	    @(0.5, 0) => playhead.pos;
	    // disappear it
	    0 => playhead.width;
	}
	else @(playheadPos() - 0.5, 0) => playhead.pos;

	material.uniformFloat(3, playheadPos() * WINDOW_SIZE);
    }
}

public UGen @operator =>(UGen in, Waveform wav) {
    in => wav.inlet;
    return wav.inlet;
}

GWindow.windowed(1250, 768);

GG.camera().orthographic();
GG.camera().viewSize(10.0 / 16);
GG.camera().posZ(1.0);

// audio stuff -----------------------------------------
// GWindow.fullscreen();

// adc => Waveform w(WINDOW_SIZE) => blackhole;
SndBuf snd(me.dir() + "pyramid.wav") => Waveform w(Waveform.WINDOW_SIZE) => blackhole;
snd => Gain sndGain(1.) => dac;

1 => snd.loop;

/* sidewarp test */
snd => SideWarp warpLeft => Pan2 left => dac;
snd => SideWarp warpRight => Pan2 right => dac;

-0.5 => left.pan;
0.5 => right.pan;

1. => warpRight.mix => warpLeft.mix;

0.001 => warpLeft.threshold => warpRight.threshold;

0.9 => warpRight.attack_speed;
0.3 => warpRight.release_speed;

snd => LPF lpf(100) => warpRight.sidechain;
lpf => warpLeft.sidechain;

0 => sndGain.gain => warpLeft.gain;

// w.pos(@(1.2,0,0.));

w --> GG.scene();

// fun scroll() {
//     2::second => now;
//     true => w.scroll;
    // } spork~ scroll();

// fun playHeadTest() {
//     w.addLine() => int idx;

//     0.0 => float pos;
//     0.01 => float delta;

//     while(true) {
// 	w.setLinePos(idx, pos);
// 	(pos + delta) % 1.0 => pos;
// 	<<< pos >>>;
// 	10::ms => now;
//     }
// } spork~ playHeadTest();

w.addLine() => int leftLine;
w.addLine() => int rightLine;

fun setPos(int idx, SideWarp side) {
    w.size() => dur bufsize;
    side.sampler.recPos() - side.sampler.playPos() => dur diff;

    if (diff < 0::samp) {
	-1. * diff + side.sampler.playPos() => diff; // for now
    }

    diff / bufsize => float pos;

    w.playheadPos() => float mainPlayheadPos;

    // todo there should be some mechanism for handling this in the class?
    if (w.scroll) 1.0 => mainPlayheadPos;

    mainPlayheadPos - pos => float relativePos;

    if (relativePos < 0) {
	1 + relativePos => relativePos;
	// <<< "NEGATIVE", relativePos >>>;

    }
    w.setLinePos(idx, relativePos);
}

// render loop
while (true)
{
    setPos(leftLine, warpLeft);
    setPos(rightLine, warpRight);
    // synchronize
    GG.nextFrame() => now;
}
