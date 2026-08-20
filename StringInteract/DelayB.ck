@import "Rec"

public class DelayB extends Chugraph {
  1::second => dur _delay;

  inlet => LiSa _l => outlet;
  1::second => _l.duration;

  true => _l.record;
  0::samp => _l.playPos;
  second - samp => _l.recPos;
  samp => _l.rampUp;

  fun dur delay(dur d) {
    <<< "Dealy!" >>>;
    d => _l.duration;
    d-samp => _l.recPos;
    d => _delay;
    return d;

    // TODO: determine if I need this dynamic buffer reallocation?

    // // if the new delay is greater than the buffer, reallocate;
    // if (d > _l.duration()) {
    //   // an extra samp is needed because
    //   d+samp => _l.duration;
    // }

    // // set playpos depending on desired delay duration
    // _getDelay(d) => _l.recPos;

    // _l.playPos() - d => dur diff;
    // <<< diff / second, _l.playPos() / second, d / second >>>;

    // if (diff < 0::samp) _l.duration() + diff => _l.playPos;
    // else diff => _l.playPos;

    // <<< _l.playPos() / second >>>;
    // // (_l.playPos() - d) % duration => _l.playPos;

    // d => _delay;
    // return d;
  }

  fun float feedback(float f) {
    f => _l.feedback;
    return f;
  }

  fun float feedback() {
    return _l.feedback();
  }

  @doc "(hidden)"
  fun dur _getDelay(dur del) {
    // get the position in the buffer that is del duration before the curent playhead
    _l.playPos() - del => dur diff;

    if (diff < 0::samp) return _l.duration() + diff;
    else return diff;
  }

  @doc "Get value of sample at point in delay line (0 is head, 1::ms is a ms behind head, etc)"
  fun float valueAt(dur index) {
    // edge case: if index is negative return head;
    if (index < 0::samp) return _l.valueAt(_l.playPos());

    // get buffer position that is index samples away
    _getDelay(index) => dur buf_pos;
    // edge case: if index is greater than delay, return last sample in delay line
    if(index > _delay) _getDelay(_delay) => buf_pos;

    return _l.valueAt(buf_pos);
  }

  // @doc "Set value of sample at point in delay line (0 is head, 1::ms is a ms behind head, etc)"
  // fun float valueAt(dur index, float val) {
  //   // edge case: if index is negative return head;
  //   if (index < 0::samp) return _l.valueAt(_l.playPos());

  //   // get buffer position that is index samples away
  //   _getDelay(index) => dur buf_pos;
  //   // edge case: if index is greater than delay, return last sample in delay line
  //   if(index > _delay) _getDelay(_delay) => buf_pos;

  //   return _l.valueAt(val, buf_pos);
  // }

  @doc "Set value of sample at point in delay line (0 is head, 1::ms is a ms behind head, etc)"
  fun float valueAt(dur index, float val) {
    // edge case: if index is negative return head;
    if (index < 0::samp) return _l.valueAt(_l.playPos());

    // get buffer position that is index samples away
    _getDelay(index) => dur buf_pos;
    // <<< "index", index, "bufpos", buf_pos, _delay >>>;
    // edge case: if index is greater than delay, return last sample in delay line
    if(index > _delay) _getDelay(_delay) => buf_pos;



    return _l.valueAt(val, buf_pos);
  }
}

Rec.stereo(dac, "DelayB.wav");

Impulse i => DelayB del => dac;
second => del.delay;

// 2::samp => del.delay;
i => dac;

// this is broken still!!!
// del.valueAt(samp, 1.0);
// del.valueAt(0.5::second, 1.0);


// del._l.valueAt(1.0, 0.5::second); // so this works
del.valueAt(0.5::second, 1.0); // okay now this works


samp => now;
// <<< "valat", del.valueAt(0.5::second + 1::samp) >>>;


// del._l.valueAt(1.0, 0.5::second);
// 1 => i.next;

// <<< del.last() >>>;
// samp => now;
// <<< del.last() >>>;
// samp => now;
// <<< del.last() >>>;
// samp => now;
// <<< del.last() >>>;
// samp => now;
// <<< del.last() >>>;
// samp => now;
// second => now;
<<< del._l.playPos(), del._l.recPos() >>>;

1. => i.next;
2::second => now;

// 2::second => del.delay;
// 1. => i.next;
// 3::second => now;

// samp => del.delay;
// 1. => i.next;
// 1::second => now;
