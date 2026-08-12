@import "Rec"

public class DelayB extends Chugraph {
  dur _delay;

  inlet => LiSa _l => outlet;
  1::second => _l.duration;
  
  true => _l.record;
  samp => _l.playPos;
  samp => _l.rampUp;

  fun dur delay(dur d) {
    // if the new delay is greater than the buffer, reallocate;
    if (d > _l.duration()) {
      // an extra samp is needed because 
      d+samp => _l.duration;
    }

    // set playpos depending on desired delay duration
    _getDelay(d) => _l.playPos;
    
    // _l.playPos() - d => dur diff;
    // <<< diff / second, _l.playPos() / second, d / second >>>;

    // if (diff < 0::samp) _l.duration() + diff => _l.playPos;
    // else diff => _l.playPos;
    
    // <<< _l.playPos() / second >>>;
    // // (_l.playPos() - d) % duration => _l.playPos;

    d => _delay;
    return d;
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
}

// Rec.auto();

Impulse i => DelayB del => dac;
i => dac;

// 1. => i.next;
// 2::second => now;

2::second => del.delay;
1. => i.next;
3::second => now;

samp => del.delay;
1. => i.next;
1::second => now;
