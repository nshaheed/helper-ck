@import "KSInteract3"

@doc "adapted from the sndpeek example"
public class Waveform extends GGen {
  // window size
  1024 => int WINDOW_SIZE;
  // width of waveform and spectrum display
  10 => float DISPLAY_WIDTH;

  GLines waveform --> this;
  waveform.width(.01);

  // color0
  @(.4, .4, 1) => vec3 _color;
  // @(1, .4, .4) => vec3 _highlight_color;
  Color.YELLOW => vec3 _highlight_color;  
  Color.RED => vec3 _clip_color;
  waveform.color( _color );

  String input;
  (input.delay() / samp) $ int => WINDOW_SIZE;

  // get a reference for our window for visual tapering of the waveform
  // Windowing.hann(WINDOW_SIZE) @=> float window[];
  // Windowing.hamming(WINDOW_SIZE) @=> float window[];
  Windowing.rectangle(WINDOW_SIZE) @=> float window[];

  // sample array
  float samples[WINDOW_SIZE];
  // FFT response
  complex response[0];
  vec2 positions[WINDOW_SIZE];
  vec3 colors[WINDOW_SIZE];

  fun @construct(String s) {
    s @=> input;

    (input.delay() / samp) $ int => WINDOW_SIZE;
    Windowing.rectangle(WINDOW_SIZE) @=> window;
    
    float samps[WINDOW_SIZE] @=> samples;
    vec2 poses[WINDOW_SIZE] @=> positions;
    vec3 cols[WINDOW_SIZE] @=> colors;

    if (window.size() != samples.size()) {
      <<< "BADBADBAD" >>>;
      while (true) {

      }
    }
    
  }

  @doc "Set width of waveform lines"
  fun float width(float w) {
    w => waveform.width;
    return w;
  }

  @doc "Get width of waveform lines"
  fun float width() {
    return waveform.width();
  }

  @doc "Set color of waveform"
  fun vec3 color(vec3 color) {
    color => _color;
    return color;
  }

  @doc "Get color of waveform"
  fun vec3 color() {
    return _color;
  }  

  // map String delay line to 3D positions
  fun void map2waveform( float in[], vec2 out[], vec3 out_color[] )
  {
    if( in.size() != out.size() || in.size() != out_color.size())
    {
      cherr <= "size mismatch in map2waveform()" <= IO.nl();
      return;
    }
    
    // mapping to xyz coordinate
    DISPLAY_WIDTH => float width;
    for (int i; i < in.size(); i++)
    {
      // space evenly in X
      -width/2 + width/WINDOW_SIZE*i => out[i].x;
      // map y, using window function to taper the ends
      // <<< i, input.inter._delay._delay, in.size(), window.size(), out.size() >>>;
      // in[i] * 2 * window[i] => out[i].y;
      in[i] * 2 => out[i].y;

      if (in[i] <= 1. && in[i] >= -1.) {
	_color => out_color[i];
      } else {
	_clip_color => out_color[i];
      }
    }
  }

  // fun void doAudio()
  // {
  //   while( true )
  //   {
  //     // upchuck to process accum
  //     accum.upchuck();
  //     // get the last window size samples (waveform)
  //     accum.output( samples );
  //     // upchuck to take FFT, get magnitude response
  //     fft.upchuck();
  //     // get spectrum (as complex values)
  //     fft.spectrum( response );
  //     // jump by samples
  //     WINDOW_SIZE::samp/2 => now;
  //   }
  // }

  fun void doAudio() {
    // update audio from String buffer
    (input.delay() / samp) $ int => int bufsize;
    for (int i; i < bufsize; i++) {
      input.valueAt(i::samp) => samples[i];
    }
  }

  @doc "internal render loop to update waveform state"
  fun update(float dt) {
    doAudio();
    // map to interleaved format
    map2waveform( samples, positions, colors );
    // set the mesh position
    waveform.positions( positions ); // chugl
    waveform.colors( colors );

    // letter positions
  }

  fun void highlight() {
    _highlight_color => waveform.color;
  }

  fun void unhighlight() {
    _color => waveform.color;
  }
}

// window title
GWindow.title( "sndpeek (minimal (minimal version))" );
// uncomment to fullscreen
// GWindow.fullscreen();
// position camera
GG.scene().camera().posZ(8.0);

2 => float WAVEFORM_Y;

Waveform wvfrm --> GG.scene();
wvfrm.waveform.posY(0. * WAVEFORM_Y);

wvfrm.input => dac;

0.1 => wvfrm.scaY;
0.6 => wvfrm.scaX;
0.1 => wvfrm.waveform.width;

// SinOsc s => GainDB g(6) => wvfrm.input;
// adc => wvfrm.input;

fun run() {
  0.25::second => now;
  while(true) {
    SinOsc s => ADSR e(1::ms, 1::ms, 0.9, 1::second) => wvfrm.input;
    e.keyOn(); 1::second => now; e.keyOff();

    8::second => now;
  }
} spork~ run();

// graphics render loop
while( true )
{
  // next graphics frame
  GG.nextFrame() => now;
}