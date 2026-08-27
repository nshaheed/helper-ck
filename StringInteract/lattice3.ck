@import "KSInteract3"
@import "PlinkyRev"

GainDB master(-12)[2] => Dyno comp[2] => HPF hpf(20)[2] => PlinkyRev rev => dac;
0.1 => rev.mix;
comp[0].compress(); comp[1].compress();

16 => int size;

String strs[2][size];
Pan2 pans[2][size];


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

    // 0.9 => str.offset;

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

    String.link(col, prop_col * mod_line_col+samp, row, prop_row * mod_line_row+samp, 0.9);
    // String.link(col, prop_row * mod_line_row, row, prop_col * mod_line_col, 0.9);    

    // row.inter.mod(col, prop_row * mod_line_row);
    // col.inter.mod(row, prop_col * mod_line_col);
  }
}

// connect lattice
for (int i; i < 2; i++) {
  for (int j; j < size; j++) {
    strs[i][j].connect();
  }
}

fun atk() {
  SinOsc s(220) => ADSR e(1::ms, 1::ms, 0.9, 1::second);
  // Noise s => ADSR e(0.1::ms, 0.1::ms, 0.9, 0.1::second);

  0.1 => e.gain; // this changes the sound a lot - can def use this

  Math.random2(0,1) => int i;
  Math.random2(0,size-1) => int j;

  // 0 => i;
  // 0 => j;

  e => strs[i][j];

  <<< "delay", strs[i][j].delay(), strs[i][j].collect.gain() >>>;

  e.keyOn(); 1::second => now; e.keyOff();
}

fun run() {
  while (true) {
    spork~ atk();

    Math.random2(1,4) => int beats;
    // 2 => beats;
    <<< beats >>>;
    1 * beats * 0.25::second => now;
    // 8 * beats * 0.25::second => now;
  }
}
spork~ run();

// 30::second => now;
eon => now;

