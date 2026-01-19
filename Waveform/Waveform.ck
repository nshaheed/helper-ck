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
every pixel will cover a single cell and simulation will run "accurately".
However if the quad is very far away, and each screen pixel covers multiple
cells, not all cells will be updated. But kinda looks cool?

IDEA: wrap repeat, sample OFF the grid with scaling factor n*m for INFINITE conway!!
- requires doing as screen shader or pass clip space full-screen quad through custom geo */
//-----------------------------------------------------------------------------

GWindow.windowed(1250, 768);

GG.camera().orthographic();
GG.camera().viewSize(10.0 / 16);
GG.camera().posZ(1.0);

// audio stuff -----------------------------------------
// GWindow.fullscreen();
1024  => int WINDOW_SIZE;
// accumulate samples from mic
adc => Flip accum => blackhole;
WINDOW_SIZE => accum.size;

float samples[WINDOW_SIZE];

fun void readMicInput()
{
    while( true )
    {
        // upchuck to process accum
        accum.upchuck();
        // get the last window size samples (waveform)
        accum.output( samples );
        // jump by samples
        WINDOW_SIZE::samp => now;
    }
}
spork ~ readMicInput();

// get max of mic input for window size
class Max extends Chugen {
    WINDOW_SIZE => int window;

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
    WINDOW_SIZE => int window;

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
    WINDOW_SIZE => int window;

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

class Waveform extends GGen {
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

    // ------- graphics stuff -----------
    // shader code string (does the GoL simulation)
    "
    #include FRAME_UNIFORMS
    #include DRAW_UNIFORMS
    #include STANDARD_VERTEX_INPUT
    #include STANDARD_VERTEX_OUTPUT
    #include STANDARD_VERTEX_SHADER

    // our custom material uniforms
    @group(1) @binding(0) var src: texture_2d<f32>;
    @group(1) @binding(1) var<storage> max_samples: array<f32>;
    @group(1) @binding(2) var<storage> min_samples: array<f32>;
    @group(1) @binding(3) var<uniform> playhead: i32;
    @group(1) @binding(4) var<uniform> playhead_width: i32;
    @group(1) @binding(5) var<storage> rms_samples: array<f32>;

    fn onWaveform(coords: vec2i, dim: vec2u) -> bool {
	return i32((0.5 + max_samples[coords.x] * 0.5) * f32(dim.y)) == coords.y;
    }

    fn waveformColor() -> vec4f {
	return vec4f(0.5, 0.5, 0.5, 1.0); // green
    }

    fn rmsColor() -> vec4f {
	return vec4f(0.25, 0.25, 0.95, 1.0); // green
    }

    fn playheadColor() -> vec4f {
	return vec4f(1.0, 1.0, 1.0, 0.5);
    }

    fn backgroundColor() -> vec4f {
	return vec4f(0.0, 0.0, 0.0, 1.0); // black
    }


    fn alive(coords: vec2i, dim: vec2u) -> vec4f {
	// these should all be > 50% height
	let pos_max : i32 = i32((0.5 + max_samples[coords.x] * 0.5) * f32(dim.y));
	// these  should all be < 50% height
	let pos_min : i32 = i32((0.5 + min_samples[coords.x] * 0.5) * f32(dim.y));
	let pos_rms : i32 = i32((0.5 + rms_samples[coords.x] * 0.5) * f32(dim.y));

	// this works
	// let on_waveform : bool = coords.y < pos_max && coords.y > i32(dim.y) - pos_max ;
	// let on_waveform : bool = coords.y < pos_min && coords.y > pos_min ;
	let on_waveform : bool = coords.y < pos_max && coords.y > pos_min ;

	let on_rms : bool = coords.y < pos_rms && coords.y > i32(dim.y) - pos_rms;
	// let on_rms : bool = coords.y < pos_rms;

	if (on_rms) {
	    return rmsColor();
	}

	if (on_waveform) {
	    return waveformColor();
	}

	if (coords.x >= playhead && coords.x <= playhead + playhead_width) {
	    return playheadColor();
	}

	let v = textureLoad(src, coords, 0);
	if (v.r < 0.5) {
	    return backgroundColor();
	}
	return vec4f(1.0);
    }

    @fragment
    fn fs_main(in : VertexOutput, @builtin(front_facing) is_front: bool) -> @location(0) vec4f
    {
	let dim : vec2u = textureDimensions(src);

	let coords = vec2i(in.v_uv * vec2f(dim));
	return alive(coords, dim);
	// var cell = vec4f(f32(alive(coords, dim)));

	// return vec4f(cell); // render current generation
    }"
    => string game_of_life_shader;

    Material material;
    PlaneGeometry plane_geo;

    ShaderDesc shader_desc;
    game_of_life_shader => shader_desc.vertexCode;
    game_of_life_shader => shader_desc.fragmentCode;

    Shader custom_shader(shader_desc); // create shader from shader_desc
    custom_shader => material.shader; // connect shader to material

    GMesh mesh(plane_geo, material) --> this;

    TextureDesc conway_tex_desc;
    WINDOW_SIZE => conway_tex_desc.width;
    WINDOW_SIZE => conway_tex_desc.height;

    Texture conway_tex_a(conway_tex_desc);

    float texture_data[4 * WINDOW_SIZE * WINDOW_SIZE];
    // TODO need a better way to specify texture size
    conway_tex_a.write(texture_data);
    material.texture(0, conway_tex_a);

    // (initialize) write new audio data to shader
    // material.storageBuffer(1, samples);
    material.storageBuffer(1, maxbuf);
    material.storageBuffer(2, minbuf);
    material.uniformInt(3, count);
    material.uniformInt(4, 2); // playhead width

    fun @construct(int bufsize) {
	material.storageBuffer(1, maxbuf);
	material.storageBuffer(2, minbuf);
	material.storageBuffer(5, minbuf);
	material.uniformInt(3, count);

	bufsize => m_bufsize;
	new float[m_bufsize] @=> maxbuf;
	new float[m_bufsize] @=> minbuf;
	new float[m_bufsize] @=> rmsbuf;
	spork~ populateBuffer();
    }

    fun @construct() {
	material.storageBuffer(1, maxbuf);
	material.storageBuffer(2, minbuf);
	material.uniformInt(3, count);

	1024 => m_bufsize;
	new float[m_bufsize] @=> maxbuf;
	new float[m_bufsize] @=> minbuf;
	new float[m_bufsize] @=> rmsbuf;
	spork~ populateBuffer();
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
	}
    }

    fun update(float dt) {
	material.storageBuffer(1, maxbuf);
	material.storageBuffer(2, minbuf);
	material.storageBuffer(5, rmsbuf);
	// material.storageBuffer(5, maxbuf);
	material.uniformInt(3, count);
    }
}

fun UGen @operator =>(UGen in, Waveform wav) {
    in => wav.inlet;
    return wav.inlet;
}

// adc => Waveform w(WINDOW_SIZE) => blackhole;
SndBuf snd(me.dir() + "pyramid.wav") => Waveform w(WINDOW_SIZE) => blackhole;
snd => dac;

1 => snd.loop;





// Material material;
// PlaneGeometry plane_geo;

// ShaderDesc shader_desc;
// game_of_life_shader => shader_desc.vertexCode;
// game_of_life_shader => shader_desc.fragmentCode;

// Shader custom_shader(shader_desc); // create shader from shader_desc
// custom_shader => material.shader; // connect shader to material

// GMesh mesh(plane_geo, material) --> GG.scene();

// TextureDesc conway_tex_desc;
// WINDOW_SIZE => conway_tex_desc.width;
// WINDOW_SIZE => conway_tex_desc.height;

// Texture conway_tex_a(conway_tex_desc);

// float texture_data[4 * WINDOW_SIZE * WINDOW_SIZE];
// // TODO need a better way to specify texture size
// conway_tex_a.write(texture_data);
// material.texture(0, conway_tex_a);

// // (initialize) write new audio data to shader
// // material.storageBuffer(1, samples);
// material.storageBuffer(1, w.buf);
// material.uniformInt(2, w.count);
// material.uniformInt(3, 2); // playhead width

w --> GG.scene();

// render loop
while (true)
{
    // synchronize
    GG.nextFrame() => now;
    // Write new audio data to shader
    // material.storageBuffer(1, samples);
    // material.storageBuffer(1, w.buf);
    // material.uniformInt(2, w.count);
}
