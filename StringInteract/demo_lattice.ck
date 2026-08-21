@import "KSInteract2"
@import "Rec"
@import "PlinkyRev"

Rec.stereo(dac, "demo_lattice.wav");

// SinOsc s1 => ADSR e1(1::ms, 1::ms, 0.9, 1::second) => String str1 => GainDB g1(-18) => dac.left;
// SinOsc s2(441) => ADSR e2(1::ms, 1::ms, 0.9, 1::second) => String str2 => GainDB g2(-18) => dac.right;

GainDB master(-36)[2] => Dyno comp[2] => HPF hpf(20)[2] => PlinkyRev rev => dac;
0.1 => rev.mix;
comp[0].compress(); comp[1].compress();

3 => int size;

String strs[2][size];
Pan2 pans[2][size];

// set up strings
for (int i; i < 2; i++) {
  for (int j; j < size; j++) {
    //
    strs[i][j] @=> String str;
    (1+i) * (1.5 * (j+1)) * 50::samp => str.delay;

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
  SinOsc s => ADSR e(1::ms, 1::ms, 0.9, 1::second);

  Math.random2(0,1) => int i;
  Math.random2(0,size-1) => int j;

  e => strs[i][j];

  e.keyOn(); 1::second => now; e.keyOff();
}

while (true) {
  spork~ atk();

  Math.random2(1,4) * 0.25::second => now;
}

8::second => now;