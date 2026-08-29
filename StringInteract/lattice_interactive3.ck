@import "KSInteract3"
@import "Rec"
@import "PlinkyRev"
@import "Waveform3"

Rec.stereo(dac, "lattice.wav");

// SinOsc s1 => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => String str1 => GainDB g1(-18) => dac.left;
// SinOsc s2(441) => ADSR e2(1::ms, 1::ms, 0.9, 1::second) => String str2 => GainDB g2(-18) => dac.right;

GainDB master(-12)[2] => Dyno comp[2] => HPF hpf(20)[2] => PlinkyRev rev => dac;
0.1 => rev.mix;
comp[0].compress(); comp[1].compress();

// set release time to be quite long to enhance sustain
2000::ms => comp[0].releaseTime => comp[1].releaseTime;
// set threshold to be a bit lower for more pronounced effect.
0.2 => comp[0].thresh => comp[1].thresh;
// set slope (in dB) above the threshold to 1/3 of what it would naturally be
0.33 => comp[0].slopeAbove => comp[1].slopeAbove;
// compensate for the gain reduction
2 => comp[0].gain => comp[1].gain;

3 => int size;

String strs[2][size];
Pan2 pans[2][size];
[1,2,3,4] @=> int rhythms[];

// ["00", "01", "02", "10", "11", "12"] @=> string onstrings[];
["00", "10"] @=> string onstrings[];
// ["00", "01", "02", "10", "11", "12"] @=> string onstrings2[];
string onstrings2[0];

// [1., 1.5, 1 + 6./5.] @=> float ratios[];
[1., 0.5 * 3./4, 0.5 * 5./6.] @=> float ratios[];

TextBox letters[2][size];
Waveform wvfrms[2][size];

// strings 2 declarations
3 => int size2;
String strs2[2][size2];
Pan2 pans2[2][size];
[1., 0.5 * 3./4, 0.5 * 5./6.] @=> float ratios2[];

TextBox letters2[2][size2];
Waveform wvfrms2[2][size2];


// set up strings
for (int i; i < 2; i++) {
  for (int j; j < size; j++) {
    //
    strs[i][j] @=> String str;

    // this is the original
    (1+i) * (1.5 * (j+1)) * 50::samp => str.delay;

    // this is good with the minor chord above
    // 1 * 1.5 * (1+i) * (ratios[j]) * 50::samp => str.delay;

    // // set mods respectively
    // i / (size $ float) => float prop_i;
    // j / (size $ float) => float prop_j;

    // 0.9 => str.inter.offset;

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

    <<< i, j, pan.pan() >>>;

    str => pan => master;
    // strsdur mod_line_i;
  }
}

// connect lattice
for (int i; i < size; i++) {
  for (int j; j < size; j++) {
    strs[0][i] @=> String row;
    strs[1][j] @=> String col;

    row.delay() => dur mod_line_row;
    col.delay() => dur mod_line_col;

    i / (size $ float) => float prop_row;
    j / (size $ float) => float prop_col;

    // row.inter.mod(col, prop_row * mod_line_row);
    // col.inter.mod(row, prop_col * mod_line_col);

    String.link(col, prop_col * mod_line_col+samp, row, prop_row * mod_line_row+samp, 0.9);
  }
}

// connect lattice
for (int i; i < 2; i++) {
  for (int j; j < size; j++) {
    strs[i][j].connect();
  }
}

// activate/deactivate initial conditions
for (int i; i < 2; i++) {
  for (int j; j < size; j++) {
    false => int contains;
    for (string s: onstrings) {
      i => Std.itoa => string pos;
      j => Std.itoa +=> pos;
      if (s == pos) {
	true => contains;
      }

      if (contains) {
	letters[i][j].activate();
      } else {
	letters[i][j].deactivate();
      }
    }
  }
}


// set up strings2
for (int i; i < 2; i++) {
  for (int j; j < size2; j++) {
    //
    strs2[i][j] @=> String str;

    // this is the original
    // (1+i) * (1.5 * (j+1)) * 50::samp => str.delay;

    // this is good with the minor chord above
    0.5 * 1.5 * (1+i) * (ratios2[j]) * 50::samp => str.delay;

    // // set mods respectively
    // i / (size $ float) => float prop_i;
    // j / (size $ float) => float prop_j;

    // 0.9 => str.inter.offset;

    pans2[i][j] @=> Pan2 pan;

    if (size == 1) 0 => pan.pan;
    else {
      // set panning
      j / ( (size-1) $ float) => float p;
      2*p - 1 => p;
      0.9 * p => p;
      // offset slightly for second row
      if (i == 0) 0.75 * p => p;

      // compress a little
      0.9 * p => pan.pan;
    }

    <<< i, j, pan.pan() >>>;

    str => pan => master;
    // strsdur mod_line_i;
  }
}

// connect lattice
for (int i; i < size2; i++) {
  for (int j; j < size2; j++) {
    strs2[0][i] @=> String row;
    strs2[1][j] @=> String col;

    row.delay() => dur mod_line_row;
    col.delay() => dur mod_line_col;

    i / (size $ float) => float prop_row;
    j / (size $ float) => float prop_col;

    // row.inter.mod(col, prop_row * mod_line_row);
    // col.inter.mod(row, prop_col * mod_line_col);

    String.link(col, prop_col * mod_line_col+samp, row, prop_row * mod_line_row+samp, 0.9);
  }
}

// connect lattice
for (int i; i < 2; i++) {
  for (int j; j < size2; j++) {
    strs2[i][j].connect();
  }
}

fun atk() {
  if (onstrings.size() == 0) return;

  // I'm using 220hz
  SinOsc s => ADSR e(1::ms, 1::ms, 0.9, 1::second);
  // Noise s => ADSR e(0.1::ms, 0.1::ms, 0.9, 0.1::second);

  // 0.1 => e.gain; // this changes the sound a lot - can def use this

  // Math.random2(0,1) => int i;
  // Math.random2(0,size-1) => int j;

  Math.random2(0, onstrings.size()-1) => int idx;
  onstrings[idx] => string pos;
  posX(pos) => int i;
  posY(pos) => int j;

  // jump around the gain a little
  Math.random2f(0.95, 1.05) => e.gain;
  // move the phase a bit, this gets a little more plucky so maybe make
  // it a variable
  // Math.random2f(0, 0.1) => s.phase;

  // 1 => i;
  // 2 => j;

  e => strs[i][j];

  wvfrms[i][j].highlight();
  e.keyOn(); 1::second => now; e.keyOff();
  wvfrms[i][j].unhighlight();

  // need to let the envelope keyoff before
  // it gets cleaned up. However, the glitch
  // actually adds some cool stuff so I'm leaving
  // it unhighlighted
  // second => now;
}

fun atk2() {
  // don't run case
  if (onstrings2.size() == 0) return;

  // I'm using 220hz
  SinOsc s(330) => ADSR e(1::ms, 1::ms, 0.9, 1::second);
  // Noise s => ADSR e(0.1::ms, 0.1::ms, 0.9, 0.1::second);

  // 0.1 => e.gain; // this changes the sound a lot - can def use this

  // Math.random2(0,1) => int i;
  // Math.random2(0,size2-1) => int j;

  Math.random2(0, onstrings2.size()-1) => int idx;
  onstrings2[idx] => string pos;
  pos.charAt2(0) => Std.atoi => int i;
  pos.charAt2(1) => Std.atoi => int j;

  // jump around the gain a little
  Math.random2f(0.95, 1.05) => e.gain;
  // move the phase a bit, this gets a little more plucky so maybe make
  // it a variable
  // Math.random2f(0, 0.1) => s.phase;

  // 1 => i;
  // 2 => j;



  e => strs2[i][j];

  // wvfrms[i][j].highlight();
  e.keyOn(); 1::second => now; e.keyOff();
  // wvfrms[i][j].unhighlight();

  // need to let the envelope keyoff before
  // it gets cleaned up. However, the glitch
  // actually adds some cool stuff so I'm leaving
  // it unhighlighted
  // second => now;
}

fun run() {
  0.25::second => now;
  while (true) {
    // for (int i: rhythms) {
    //   chout <= i <= ", ";
    // }
    // chout <= IO.nl();

    // with empty rhythm, skip attack
    if (rhythms.size() == 0) {
      0.25::second => now;
      continue;
    }

    spork~ atk();

    Math.random2(0,rhythms.size()-1) => int beats_idx;
    rhythms[beats_idx] => int beats;

    1 * beats * 0.25::second => dur duration;
    spork~ highlight(beats,duration - 0.125::second);
    duration => now;
    // 8 * beats * 0.25::second => now;
  }
}

fun run2() {
  0.25::second => now;
  while (true) {
    // for (int i: rhythms) {
    //   chout <= i <= ", ";
    // }
    // chout <= IO.nl();

    // with empty rhythm, skip attack
    if (rhythms.size() == 0) {
      0.25::second => now;
      continue;
    }

    spork~ atk2();

    Math.random2(0,rhythms.size()-1) => int beats_idx;
    rhythms[beats_idx] => int beats;

    1 * beats * 0.25::second => dur duration;
    // spork~ highlight(beats,duration - 0.125::second);
    duration => now;
    // 8 * beats * 0.25::second => now;
  }
}

fun highlight(int i, dur amnt) {
  rboxes.highlight(i-1);
  amnt => now;
  rboxes.unhighlight(i-1);
}

// window title
GWindow.title( "lattice" );
// uncomment to fullscreen
// GWindow.fullscreen();
// position camera
GG.scene().camera().posZ(8.0);

class RhythmBoxes extends GGen {
  // GText rhythms[4] --> this;
  // GPlane planes[4];
  // GPlane highlights[4];

  TextBox texts[4] --> this;

  "1" => texts[0].text;
  "2" => texts[1].text;
  "3" => texts[2].text;
  "4" => texts[3].text;

  for (int i; i < 4; i++) {
  //   highlights[i] --> planes[i] --> rhythms[i];
  //   0.9 => planes[i].sca;
  //   Color.GRAY => planes[i].color;

  //   Color.YELLOW => highlights[i].color;
  //   0.95 => highlights[i].sca;
  //   0. => highlights[i].alpha;

    -1.5 + i => texts[i].posX;
  }

  fun activate(int i) {
    texts[i].activate();
  }

  fun deactivate(int i) {
    texts[i].deactivate();
  }

  fun highlight(int i) {
    texts[i].highlight();
  }

  fun unhighlight(int i) {
    texts[i].unhighlight();
  }
}

class TextBox extends GGen {
  GPlane _highlight --> GPlane _plane --> GText txt --> this;
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

class Test extends GGen {
  GPlane rp[4];
  GText rs[4] --> this;

  for (int i; i < 4; i++) {
    rp[i] --> rs[i];
    i => rs[i].posX;
  }
}

RhythmBoxes rboxes --> GG.scene();
0.3 => rboxes.sca;
@(-3.7, 3, 0) => rboxes.pos;

// GG.camera().orthographic();

2 => float WAVEFORM_Y;


[["Q","W","E"],["D","S","A"]] @=> string letter_keys[][];

// set up waveform/string visuals
for (int i; i < 2; i++) {
  for (int j; j < size; j++) {
    // 1 => i;
    // 2 => j;
    Waveform wvfrm(strs[i][j]) --> GG.scene();
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

fun updateLetters() {
  for (int i; i < 2; i++) {
    for (int j; j < size; j++) {
      wvfrms[i][j].positions[-1] + @(0.25, 0) => letters[i][j].pos;
    }
  }
}

// SinOsc s => GainDB g(6) => wvfrm.input;
// adc => wvfrm.input;

// fun run2() {
//   0.25::second => now;
//   while(true) {
//     SinOsc s => ADSR e(1::ms, 1::ms, 0.9, 1::second) => wvfrm.input;
//     e.keyOn(); 1::second => now; e.keyOff();

//     8::second => now;
//   }
// } spork~ run2();

spork~ run();
spork~ run2();
// spork~ input();

// graphics render loop
while( true )
{
  // next graphics frame
  GG.nextFrame() => now;

  // <<< "positions", wvfrms[0][0].positions[-1] >>>;

      // camera movement
  if (GWindow.key(GWindow.KEY_LEFT)) GG.camera().rotateY(GG.dt());
  if (GWindow.key(GWindow.KEY_RIGHT)) GG.camera().rotateY(-GG.dt());

  if (GWindow.key(GWindow.KEY_UP)) GG.camera().rotateX(GG.dt());
  if (GWindow.key(GWindow.KEY_DOWN)) GG.camera().rotateX(-GG.dt());

  if (GWindow.keyUp(GWindow.KEY_1)) toggleRhythm(1);
  if (GWindow.keyUp(GWindow.KEY_2)) toggleRhythm(2);
  if (GWindow.keyUp(GWindow.KEY_3)) toggleRhythm(3);
  if (GWindow.keyUp(GWindow.KEY_4)) toggleRhythm(4);

  // if (GWindow.keyUp(GWindow.KEY_1)) toggleRhythm(1);
  // if (GWindow.keyUp(GWindow.KEY_2)) toggleRhythm(2);
  // if (GWindow.keyUp(GWindow.KEY_3)) toggleRhythm(3);
  // if (GWindow.keyUp(GWindow.KEY_4)) toggleRhythm(4);

  if (GWindow.keyUp(GWindow.KEY_Q)) toggleOnstrings("00", onstrings, letters);
  if (GWindow.keyUp(GWindow.KEY_W)) toggleOnstrings("01", onstrings, letters);
  if (GWindow.keyUp(GWindow.KEY_E)) toggleOnstrings("02", onstrings, letters);
  if (GWindow.keyUp(GWindow.KEY_D)) toggleOnstrings("10", onstrings, letters);
  if (GWindow.keyUp(GWindow.KEY_S)) toggleOnstrings("11", onstrings, letters);
  if (GWindow.keyUp(GWindow.KEY_A)) toggleOnstrings("12", onstrings, letters);

  if (GWindow.keyUp(GWindow.KEY_I)) toggleOnstrings("00", onstrings2, null);
  if (GWindow.keyUp(GWindow.KEY_O)) toggleOnstrings("01", onstrings2, null);
  if (GWindow.keyUp(GWindow.KEY_P)) toggleOnstrings("02", onstrings2, null);
  if (GWindow.keyUp(GWindow.KEY_J)) toggleOnstrings("10", onstrings2, null);
  if (GWindow.keyUp(GWindow.KEY_K)) toggleOnstrings("11", onstrings2, null);
  if (GWindow.keyUp(GWindow.KEY_L)) toggleOnstrings("12", onstrings2, null);

  updateLetters();
}

fun int posX(string p) {
  p.charAt2(0) => Std.atoi => int x;
  return x;
}

fun int posY(string p) {
  p.charAt2(1) => Std.atoi => int y;
  return y;
}

fun void toggleRhythm(int r) {
  false => int contains;
  -1 => int idx;

  for (int i; i < rhythms.size(); i++) {
    if (rhythms[i] == r) {
      true => contains;
      i => idx;
      break;
    }
  }

  if (contains) {
    rhythms.erase(idx);
    rboxes.deactivate(r-1);
  } else {
    rhythms << r;
    rboxes.activate(r-1);
  }

  // for (int i: rhythms) {
  //   chout <= i <= ", ";
  // }
  // chout <= IO.nl();
}

fun void toggleOnstrings(string pos, string ons[], TextBox txts[][]) {
  false => int contains;
  -1 => int idx;

  for (int i; i < ons.size(); i++) {
    if (ons[i] == pos) {
      true => contains;
      i => idx;
      break;
    }
  }

  posX(pos) => int i;
  posY(pos) => int j;

  if (contains) {
    ons.erase(idx);
    if (txts != null) txts[i][j].deactivate();
    // rboxes.deactivate(r-1);
  } else {
    ons << pos;
    if (txts != null) txts[i][j].activate();
    // rboxes.activate(r-1);
  }
}

// keyboard input
// fun input() {
//   // the event
//   KBHit kb;

//   // time-loop
//   while( true ) {
//     // wait on kbhit event
//     kb =p> now;

//     // potentially more than 1 key at a time
//     while( kb.more() )
//     {
//       // print key value
//       <<< "ascii: ", kb.getchar() >>>;
//     }
//   }
// }



// 30::second => now;
eon => now;