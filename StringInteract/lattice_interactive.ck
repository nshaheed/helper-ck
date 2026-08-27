@import "KSInteract2"
@import "Rec"
@import "PlinkyRev"
@import "Waveform"

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

// [1., 1.5, 1 + 6./5.] @=> float ratios[];
[1., 0.5 * 3./4, 0.5 * 5./6.] @=> float ratios[];

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

    0.9 => str.inter.offset;

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

    row.inter.mod(col, prop_row * mod_line_row);
    col.inter.mod(row, prop_col * mod_line_col);
  }
}

fun atk() {
  // I'm using 220hz
  SinOsc s => ADSR e(1::ms, 1::ms, 0.9, 1::second);
  // Noise s => ADSR e(0.1::ms, 0.1::ms, 0.9, 0.1::second);

  // 0.1 => e.gain; // this changes the sound a lot - can def use this

  Math.random2(0,1) => int i;
  Math.random2(0,size-1) => int j;

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
  GText rhythms[4] --> this;
  GPlane planes[4];
  GPlane highlights[4];
  
  "1" => rhythms[0].text;
  "2" => rhythms[1].text;
  "3" => rhythms[2].text;
  "4" => rhythms[3].text;

  for (int i; i < 4; i++) {
    highlights[i] --> planes[i] --> rhythms[i];
    0.9 => planes[i].sca;
    Color.GRAY => planes[i].color;
    
    Color.YELLOW => highlights[i].color;
    0.95 => highlights[i].sca;
    0. => highlights[i].alpha;
    
    -1.5 + i => rhythms[i].posX;
  }

  fun activate(int i) {
    1. => planes[i].alpha;
  }

  fun deactivate(int i) {
    0. => planes[i].alpha;
  }

  fun highlight(int i) {
    1. => highlights[i].alpha;
  }

  fun unhighlight(int i) {
    0. => highlights[i].alpha;
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

Waveform wvfrms[2][size];
  
for (int i; i < 2; i++) {
  for (int j; j < size; j++) {
    // 1 => i;
    // 2 => j;
    Waveform wvfrm(strs[i][j]) --> GG.scene();
    wvfrm @=> wvfrms[i][j];

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
// spork~ input();

// graphics render loop
while( true )
{
  // next graphics frame
  GG.nextFrame() => now;

      // camera movement
  if (GWindow.key(GWindow.KEY_LEFT)) GG.camera().rotateY(GG.dt());
  if (GWindow.key(GWindow.KEY_RIGHT)) GG.camera().rotateY(-GG.dt());

  if (GWindow.key(GWindow.KEY_UP)) GG.camera().rotateX(GG.dt());
  if (GWindow.key(GWindow.KEY_DOWN)) GG.camera().rotateX(-GG.dt());

  if (GWindow.keyUp(GWindow.KEY_1)) toggleRhythm(1);
  if (GWindow.keyUp(GWindow.KEY_2)) toggleRhythm(2);
  if (GWindow.keyUp(GWindow.KEY_3)) toggleRhythm(3);
  if (GWindow.keyUp(GWindow.KEY_4)) toggleRhythm(4);
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

// keyboard input
// fun input() {
//   // the event
//   KBHit kb;

//   // time-loop
//   while( true ) {
//     // wait on kbhit event
//     kb => now;

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