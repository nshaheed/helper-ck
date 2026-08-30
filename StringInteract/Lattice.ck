@import "KSInteract3"
@import "Waveform3"

public class Lattice extends GGen {
  3 => int size; // default size

  String strs[][];
  Pan2 pans[][];
  UGen_Stereo output;
  0.9 => float _offset;

  string onstrings[0];

  TextBox letters[][];
  Waveform wvfrms[][];
  string letter_keys[][];

  int _flip_letters;

  Attack attack;

  fun @construct() {
    dur ratios[2][3];

    for (int i; i < 2; i++) {
      for (int j; j < 3; j++) {
	(1+i) * (1.5 * (j+1)) * 50::samp => ratios[i][j];
      }
    }
    // my defaults
    init(3, ratios, [["Q","W","E"],["D","S","A"]]);
  }

  fun @construct(int sz, dur delays[][]) {
    init(sz, delays, [["","",""],["","",""]]);
  }

  fun @construct(int sz, dur delays[][], string lttrkeys[][]) {
    init(sz, delays, lttrkeys);
  }

  fun init(int sz, dur delays[][], string lttrkeys[][]) {
    sz => size;

    new String[2][size] @=> strs;
    new Pan2[2][size] @=> pans;
    new TextBox[2][size] @=> letters;
    new Waveform[2][size] @=> wvfrms;
    lttrkeys @=> letter_keys;


    // set up strings
    for (int i; i < 2; i++) {
      for (int j; j < size; j++) {
	//
	strs[i][j] @=> String str;

	// this is the original
	// (1+i) * (1.5 * (j+1)) * 50::samp => str.delay;
	delays[i][j] => str.delay;

	pans[i][j] @=> Pan2 pan;

	if (size == 1) 0 => pan.pan;
	else {
	  // set panning
	  j / ( (size-1) $ float) => float p;
	  2*p - 1 => p;
	  0.9 * p => p;
	  // offset slightly for second row
	  if (i == 0) 0.75 * p => p;
	  p => pan.pan;
	}

	str => pan => output;
      }
    }

    // link lattice
    for (int i; i < size; i++) {
      for (int j; j < size; j++) {
	strs[0][i] @=> String row;
	strs[1][j] @=> String col;

	row.delay() => dur mod_line_row;
	col.delay() => dur mod_line_col;

	i / (size $ float) => float prop_row;
	j / (size $ float) => float prop_col;

	String.link(col, prop_col * mod_line_col+samp, row, prop_row * mod_line_row+samp, _offset);
      }
    }

    // connect lattice
    for (int i; i < 2; i++) {
      for (int j; j < size; j++) {
	strs[i][j].connect();
      }
    }

    // deactivate letters
    for (int i; i < 2; i++) {
      for (int j; j < size; j++) {
	letters[i][j].deactivate();
      }
    }

    // set up waveform/string visuals
    for (int i; i < 2; i++) {
      for (int j; j < size; j++) {
	// 1 => i;
	// 2 => j;
	Waveform wvfrm(strs[i][j]) --> this;
	wvfrm @=> wvfrms[i][j];

	letters[i][j] @=> TextBox letter;
	letter_keys[i][j] => letter.text;
	letter --> wvfrm;

	if (i == 0) {
	  wvfrm.rotZ(Math.PI / 2);
	  wvfrm.posX(-2 + 2*j);
	} else {
	  // wvfrm.posX(j);
	  // wvfrm.posX(-2 * i);
	  // wvfrm.posX(-300);
	  wvfrm.posY(-2 + 2*j);
	}
	// wvfrm.waveform.posY(i * 8 + 0. * WAVEFORM_Y);
	0.1 => wvfrm.scaY;
	0.6 => wvfrm.scaX;
	0.1 => wvfrm.waveform.width;

	0.25 => float scale;

	scale * 10 => letter.scaY;
	scale * 1./.6 => letter.scaX;

	if (i == 0) {
	  letter.rotZ(-1. * (Math.PI / 2));
	  scale * 10 => letter.scaX;
	  scale * 1./.6 => letter.scaY;
	  // -1 => letter.posZ;
	}
      }
    }
  }

  fun flipLetters() {
    // flip letter positions of horizontal strings
    !_flip_letters => _flip_letters;
  }

  fun updateLetters() {
    for (int i; i < 2; i++) {
      for (int j; j < size; j++) {
	wvfrms[i][j].positions[-1] + @(0.25, 0) => letters[i][j].pos;

	if (i == 1 & _flip_letters) {
	  wvfrms[i][j].positions[0] + @(-0.25, 0) => letters[i][j].pos;
	}
      }
    }
  }

  fun static int posX(string p) {
    p.charAt2(0) => Std.atoi => int x;
    return x;
  }

  fun static int posY(string p) {
    p.charAt2(1) => Std.atoi => int y;
    return y;
  }

  fun void toggleOnstrings(string pos) {
    false => int contains;
    -1 => int idx;

    for (int i; i < onstrings.size(); i++) {
      if (onstrings[i] == pos) {
	true => contains;
	i => idx;
	break;
      }
    }

    posX(pos) => int i;
    posY(pos) => int j;

    if (contains) {
      onstrings.erase(idx);
      if (letters != null) letters[i][j].deactivate();
      // rboxes.deactivate(r-1);
    } else {
      onstrings << pos;
      if (letters != null) letters[i][j].activate();
      // rboxes.activate(r-1);
    }
  }

  fun atk() {
    attack.atk(this);
  }

  fun offset(float off) {
    off => _offset;
    for (int i; i < 2; i++) {
      for (int j; j < size; j++) {
	off => strs[i][j].offset;
      }
    }
  }
}

public class TextBox extends GGen {
  // GPlane _highlight --> GPlane _plane --> GText txt --> this;
  GPlane _plane --> GPlane _highlight --> GText txt --> this;  
  Color.GRAY => vec3 plane_color;
  Color.YELLOW => vec3 highlight_color;

  0.9 => _plane.sca;
  highlight_color => _highlight.color;
  0.95 => _highlight.sca;
  0. => _highlight.alpha;

  fun @construct(string text) {
    text => txt.text;
  }

  fun string text(string text) {
    text => txt.text;
    return text;
  }

  fun string text() {
    return txt.text();
  }

  fun activate() {
    1. => _plane.alpha;
    Color.BLACK => txt.color;
  }

  fun deactivate() {
    0. => _plane.alpha;
    Color.WHITE => txt.color;
  }

  fun highlight() {
    1. => _highlight.alpha;
  }

  fun unhighlight() {
    0. => _highlight.alpha;
  }
}

public class Attack {
  fun atk(Lattice l) {
    if (l.onstrings.size() == 0) return;

    // I'm using 220hz
    SinOsc s => ADSR e(1::ms, 1::ms, 0.9, 1::second);
    // Noise s => ADSR e(0.1::ms, 0.1::ms, 0.9, 0.1::second);

    // 0.1 => e.gain; // this changes the sound a lot - can def use this

    // Math.random2(0,1) => int i;
    // Math.random2(0,size-1) => int j;

    Math.random2(0, l.onstrings.size()-1) => int idx;
    l.onstrings[idx] => string pos;
    l.posX(pos) => int i;
    l.posY(pos) => int j;

    // jump around the gain a little
    Math.random2f(0.95, 1.05) => e.gain;
    // move the phase a bit, this gets a little more plucky so maybe make
    // it a variable
    // Math.random2f(0, 0.1) => s.phase;

    // 1 => i;
    // 2 => j;

    e => l.strs[i][j];

    l.wvfrms[i][j].highlight();
    e.keyOn(); 1::second => now; e.keyOff();
    l.wvfrms[i][j].unhighlight();

    // need to let the envelope keyoff before
    // it gets cleaned up. However, the glitch
    // actually adds some cool stuff so I'm leaving
    // it unhighlighted
    // second => now;
  }
}

public class Attack2 extends Attack {
  // todo - scale sine pitch based off of frequency ratios
  fun atk(Lattice l) {
    if (l.onstrings.size() == 0) return;

    // I'm using 220hz
    SinOsc s(330) => ADSR e(1::ms, 1::ms, 0.9, 1::second);
    // Noise s => ADSR e(0.1::ms, 0.1::ms, 0.9, 0.1::second);

    // 0.1 => e.gain; // this changes the sound a lot - can def use this

    // Math.random2(0,1) => int i;
    // Math.random2(0,size-1) => int j;

    Math.random2(0, l.onstrings.size()-1) => int idx;
    l.onstrings[idx] => string pos;
    l.posX(pos) => int i;
    l.posY(pos) => int j;

    l.strs[0][0].delay() => dur base;
    l.strs[i][j].delay() => dur val;

    base / val => float ratio;

    // 330 * ratio * 0.8 => s.freq;

    // jump around the gain a little
    Math.random2f(0.95, 1.05) => e.gain;
    // move the phase a bit, this gets a little more plucky so maybe make
    // it a variable
    // Math.random2f(0, 0.1) => s.phase;

    // 1 => i;
    // 2 => j;

    e => l.strs[i][j];

    l.wvfrms[i][j].highlight();
    e.keyOn(); 1::second => now; e.keyOff();
    l.wvfrms[i][j].unhighlight();

    // need to let the envelope keyoff before
    // it gets cleaned up. However, the glitch
    // actually adds some cool stuff so I'm leaving
    // it unhighlighted
    // second => now;
  }
}