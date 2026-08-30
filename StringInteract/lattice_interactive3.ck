@import "KSInteract3"
@import "Rec"
@import "PlinkyRev"
@import "Waveform3"
@import "Lattice"

Rec.stereo(dac, "lattice.wav");

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

[1., 0.5 * 3./4, 0.5 * 5./6.] @=> float ratios2[];
dur delays2[2][3];

for (int i; i < 2; i++) {
  for (int j; j < 3; j++) {
    0.5 * 1.5 * (1+i) * (ratios2[j]) * 50::samp => delays2[i][j];
    <<< i, j, delays2[i][j] >>>;
  }
}

Lattice lattice1 --> GG.scene();
// Lattice lattice1;
lattice1.output => master;
"00" => lattice1.toggleOnstrings;
"10" => lattice1.toggleOnstrings;


Lattice lattice2(3, delays2, [["I","O","P"],["L","K","J"]]) --> GG.scene();
// Lattice lattice2(3, delays2, [["I","O","P"],["J","K","L"]]);
// Lattice lattice2(3, delays2) --> GG.scene();
lattice2.output => master;
1.01 => lattice2.offset;
lattice2.flipLetters();

new Attack2 @=> lattice2.attack;

// 1 => lattice2.posX;

// String strs[2][size];
// Pan2 pans[2][size];
[1,2,3,4] @=> int rhythms[];

fun run() {
  0.25::second => now;
  while (true) {
    // with empty rhythm, skip attack
    if (rhythms.size() == 0) {
      0.25::second => now;
      continue;
    }

    spork~ lattice1.atk();

    Math.random2(0,rhythms.size()-1) => int beats_idx;
    rhythms[beats_idx] => int beats;

    1 * beats * 0.25::second => dur duration;

    if (lattice1.onstrings.size() != 0) spork~ highlight(rboxes, beats, duration - 0.125::second);
    duration => now;
    // 8 * beats * 0.25::second => now;
  }
}

fun run2() {
  0.25::second => now;
  while (true) {
    // with empty rhythm, skip attack
    if (rhythms.size() == 0) {
      0.25::second => now;
      continue;
    }

    spork~ lattice2.atk();

    Math.random2(0,rhythms.size()-1) => int beats_idx;
    rhythms[beats_idx] => int beats;

    1 * beats * 0.25::second => dur duration;
    if (lattice2.onstrings.size() != 0) spork~ highlight(rboxes2, beats, duration - 0.125::second);
    duration => now;
    // 8 * beats * 0.25::second => now;
  }
}

fun highlight(RhythmBoxes r, int i, dur amnt) {
  r.highlight(i-1);
  amnt => now;
  r.unhighlight(i-1);
}

// window title
GWindow.title( "lattice" );
// uncomment to fullscreen
// GWindow.fullscreen();
// position camera



lattice2.posX(8);


class RhythmBoxes extends GGen {
  TextBox texts[4] --> this;

  "1" => texts[0].text;
  "2" => texts[1].text;
  "3" => texts[2].text;
  "4" => texts[3].text;

  for (int i; i < 4; i++) {
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

  fun highlightColor(vec3 color) {
    for (TextBox t: texts) {
      color => t._highlight.color;
    }
  }

  fun highlightSca(float sca) {
    for (TextBox t: texts) {
      sca => t._highlight.sca;
    }
  }

  fun planeAlpha(float alph) {
    for (TextBox t: texts) {
      alph => t._plane.alpha;
    }
  }
}


RhythmBoxes rboxes2 --> RhythmBoxes rboxes --> GG.scene();

0.3 => rboxes.sca;
@(-3.7, 3, 0) => rboxes.pos;

Color.BLUE => rboxes2.highlightColor;
1.1 => rboxes2.highlightSca;
0 => rboxes2.planeAlpha;

2 => float WAVEFORM_Y;


spork~ run();
spork~ run2();
spork~ updateCamera();
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

  if (GWindow.keyUp(GWindow.KEY_Q)) lattice1.toggleOnstrings("00");
  if (GWindow.keyUp(GWindow.KEY_W)) lattice1.toggleOnstrings("01");
  if (GWindow.keyUp(GWindow.KEY_E)) lattice1.toggleOnstrings("02");
  if (GWindow.keyUp(GWindow.KEY_D)) lattice1.toggleOnstrings("10");
  if (GWindow.keyUp(GWindow.KEY_S)) lattice1.toggleOnstrings("11");
  if (GWindow.keyUp(GWindow.KEY_A)) lattice1.toggleOnstrings("12");

  if (GWindow.keyUp(GWindow.KEY_I)) lattice2.toggleOnstrings("00");
  if (GWindow.keyUp(GWindow.KEY_O)) lattice2.toggleOnstrings("01");
  if (GWindow.keyUp(GWindow.KEY_P)) lattice2.toggleOnstrings("02");
  if (GWindow.keyUp(GWindow.KEY_L)) lattice2.toggleOnstrings("10");
  if (GWindow.keyUp(GWindow.KEY_K)) lattice2.toggleOnstrings("11");
  if (GWindow.keyUp(GWindow.KEY_J)) lattice2.toggleOnstrings("12");

  lattice1.updateLetters();
  lattice2.updateLetters();
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

fun void updateCamera() {
  // set initial camera position
  GG.scene().camera().posZ(8.0);
  GG.scene().camera().posX(0.0);
  @(-3.7, 3, 0) => rboxes.pos;

  // states:
  // 0: camera was zoomed in on left
  // 1: camera was zoomed out
  int zoomedOut;

  // camera was on left && no right playing -> camera stays on left
  // camera was on left && right starts playing -> camera zooms out;
  // camera was zoomed out && left is no longer playing -> camera stays zoomed out
  // camera was zoomed out && no one is playing -> camera stays zoomed out
  // camera was zoomed out && only left in playing -> camera zooms in


  while (true) {
    lattice1.onstrings.size() != 0 => int lattice1playing;
    lattice2.onstrings.size() != 0 => int lattice2playing;

    if (!zoomedOut && lattice2playing) {
      // zoomout
      GG.scene().camera().posZ(14.0);
      GG.scene().camera().posX(4.0);
      @(4.1, 3, 0) => rboxes.pos;
      true => zoomedOut;
    } else if (zoomedOut && lattice1playing && !lattice2playing) {
      // zoom in
      GG.scene().camera().posZ(8.0);
      GG.scene().camera().posX(0.0);
      @(-3.7, 3, 0) => rboxes.pos;
      false => zoomedOut;
    }
    0.25::second => now;
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