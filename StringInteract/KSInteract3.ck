@import "Interference/Interference.chug"
@import "DelayB"

// in this one instead of having a tick function, define each string
// as a line of delays, where they're broken up by the intersection
// points of other strings. This should be a lot more efficient and
// mean that things can stay in chuck-land and I don't have to make a
// chugin (which would also not be that efficient anyway
//
// one future concert is changing the intersections of the strings on
// the fly (i.e. for an interactive version of the GUI). Doing that
// could be done with DelayB, but it would also be nice to be able to
// just concat two arrays in C++ land rather than through the VM.


// this will only handle the tick, not managing
// any of the indexing along the delay lines.
// this is so when it gets moved to a chugin
// it's the smallest footprint i can get
//
// TODO replace this with a chugin
// public class Interference extends Chugen {
//   UGen @ _mod;
//   // UGen @ _carr; // not sure about this? maybe just use inlet

//   0.75 => float _offset;

//   // fun @construct(UGen carr, UGen mod) {
//   //   carr @=> _carr;
//   //   mod @=> _mod;
//   // }

//   fun @construct(UGen mod) {
//     mod @=> _mod;
//   }

//   fun @construct(float offset) {
//     offset => _offset;
//   }

//   fun @construct(UGen mod, float offset) {
//     mod @=> _mod;
//     offset => _offset;
//   }

//   fun UGen mod() {
//     return _mod;
//   }

//   fun UGen mod(UGen md) {
//     md @=> _mod;
//     return _mod;
//   }

//   fun float offset() {
//     return _offset;
//   }

//   fun float offset(float o) {
//     o => _offset;
//     return _offset;
//   }

//   fun float tick(float in) {
//     if (!_mod) return in;

//     in => float carr_pos;
    
//     _mod.last() + _offset => float mod_pos_offset;

//     if (_offset >= 0. && mod_pos_offset < in) {
//       mod_pos_offset => carr_pos;
//     }
//     if (_offset < 0. && mod_pos_offset > in) {
//       mod_pos_offset => carr_pos;
//     }

//     return carr_pos;
//   }
// }

// TODO replace time finding linked list with a tree?
public class String extends Chugraph {
  // main line
  inlet => Gain hold => PoleZero block => OneZero lowpass => GainDB g(0) => outlet;

  -1 => lowpass.zero;
  0.999 => block.blockZero;

  // lowpass into hold;
  
  Gain collect => hold; // collect the delay line results

  // our radius
  .99999 => float R;
  // our delay order
  250 => float L;
  // 8 => float L;

  // define delay line
  LinkedList _delays(L::samp);

  // set dissipation factor
  // want to set dissapating factor in collect
  // Math.pow( R, L ) => _delays._delay.gain;
  Math.pow( R, L ) => collect.gain;

  fun @construct(dur d) {
    new LinkedList(d) @=> _delays;
    d / samp => L;
  }

  @doc "set string delay, clearing delay lines"
  fun dur delay(dur d) {
    new LinkedList(d) @=> _delays;
    d / samp => L;

    return d;
  }

  fun dur delay() {
    _delays @=> LinkedList curr;
    dur cumulative;

    while (curr) {
      curr.delayDur() +=> cumulative;
      curr.next() @=> curr;
    }

    return cumulative;
  }

  // Get the delay line that is outputting at a specific time. Split the
  // delay line up otherwise
  fun LinkedList getAt(dur idx) {
    if (idx < 0::samp || idx > L::samp) {
      cherr <= "[String] trying to add modulator outside of delay line size" <= IO.nl();
      <<< "idx", idx, "L", L >>>;
      return null;
    }

    // find node in _delays that contains point idx to split;
    _delays @=> LinkedList curr @=> LinkedList prev;
    curr.next() @=> LinkedList next;
    0::samp => dur cumulative;

    while(curr && cumulative + curr.delayDur() <= idx) {
      curr.delayDur() +=> cumulative;

      curr @=> prev;
      curr.next() @=> curr;
    }
    curr.next() @=> next;

    // yes this comparing floats, deal with it
    if (idx == cumulative) return prev;

    // split the delay line into two
    idx - cumulative => dur split1;
    curr.delayDur() - split1 => dur split2;

    LinkedList left(null, split1, prev);
    LinkedList right(curr.mod(), split2, left);

    if (next) {
      next => right.next;
    }
    // if the first element of the list is being replace,
    // set the member var properly
    if (curr == _delays) left @=> _delays;

    return left;
  }

  fun float valueAt(dur idx) {
    // TODO implement this

    if (idx < 0::samp || idx > L::samp) {
      cherr <= "[String] trying to add modulator outside of delay line size" <= IO.nl();
      <<< "idx", idx, "L", L >>>;
      return 0;
    }

    // find node in _delays that contains point idx to split;
    _delays @=> LinkedList curr @=> LinkedList prev;
    curr.next() @=> LinkedList next;
    0::samp => dur cumulative;

    while(curr && cumulative + curr.delayDur() <= idx) {
      curr.delayDur() +=> cumulative;

      curr @=> prev;
      curr.next() @=> curr;
    }
    curr.next() @=> next;

    // yes this comparing floats, deal with it
    if (idx == cumulative) return prev.delay().valueAt(0::samp);

    idx - cumulative => dur split_point;
    return curr.delay().valueAt(split_point);

    // // split the delay line into two
    // idx - cumulative => dur split1;
    // curr.delayDur() - split1 => dur split2;

    // LinkedList left(null, split1, prev);
    // LinkedList right(curr.mod(), split2, left);

    // if (next) {
    //   next => right.next;
    // }
    // // if the first element of the list is being replace,
    // // set the member var properly
    // if (curr == _delays) left @=> _delays;

    // return left;
  }

  @doc "connect two strings at specified indexes along the strings"
  fun static void link(String str1, dur idx1, String str2, dur idx2, float offset) {
    str1.getAt(idx1) @=> LinkedList ll1;
    str2.getAt(idx2) @=> LinkedList ll2;

    offset => ll1.offset;
    offset => ll2.offset;

    // set inter modulator
    ll2.delay() => ll1.mod;
    ll1.delay() => ll2.mod;
  }

  // add modulations to delay lines
  // right now this will completely clear the delay lines
  fun UGen mod(UGen mod, dur idx) {
    getAt(idx) @=> LinkedList ll;
    <<< "deldur", ll.delayDur() >>>;
    mod => ll.mod;

    return ll.delay();

    
    // if (idx <= 0::samp || idx > L::samp) {
    //   cherr <= "[String] trying to add modulator outside of delay line size" <= IO.nl();
    //   return mod;
    // }

    // // find node in _delays that contains point idx to split;
    // _delays @=> LinkedList curr @=> LinkedList prev;
    // curr.next() @=> LinkedList next;
    // 0::samp => dur cumulative;

    // while(curr && cumulative + curr.delayDur() < idx) {
    //   curr.delayDur() +=> cumulative;

    //   curr @=> prev;
    //   curr.next() @=> curr;
    // }
    // curr.next() @=> next;

    // // split the delay line into two
    // idx - cumulative => dur split1;
    // curr.delayDur() - split1 => dur split2;

    // LinkedList left(mod, split1, prev);
    // LinkedList right(curr.mod(), split2, left);

    // if (next) {
    //   next => right.next;
    // }
    // // if the first element of the list is being replace,
    // // set the member var properly
    // if (curr == _delays) left @=> _delays;

    // return left.delay();
  }

  @doc "connect all the delay lines into the string generation loop"
  fun connect() {
    // this shouldn't happen
    if(!_delays) {
      cherr <= "[String.connect()] No delays lines found at all, doing nothing" <= IO.nl();
    }
    
    lowpass @=> UGen prev;
    _delays @=> LinkedList del;

    while(del) {
      // prev => del.delay() => del.inter();
      prev => del.delay() => del.inter().chan(0);

      <<< "del mod", del.mod() >>>;
      // eon => now;
      if (del.mod() != null) del.mod() => del.inter().chan(1);
	
      del.inter() @=> prev;
      del.next() @=> del;
    }

    prev => collect;
  }

  @doc "Print sequence of delay lines"
  fun printDelays() {
    _delays @=> LinkedList curr;

    chout <= "++++++++++++++++++++++++" <= IO.nl();
    dur cumulative;
    int count; 
    while (curr != null) {
      chout <= Std.ftoa(curr.delayDur() / samp, 1) <= ",\t";
      if (curr.mod() != null) chout <= curr.mod().toString();
      else chout <= "null";
      chout <= IO.nl();
      
      curr.delayDur() +=> cumulative;
      curr.next() @=> curr;

      count++;
    }
    chout <= "++++++++++++++++++++++++" <= IO.nl();    
    chout <= "Cumulative delay: " <= cumulative / samp <= IO.nl() <= IO.nl();
  }

}

class Node {
  DelayB delay;
  Interference inter;
  null @=> UGen mod;
  
  null @=> LinkedList parent;

  fun @construct(LinkedList par, UGen md, DelayB del) {
    md @=> mod;
    del @=> delay;
    par @=> parent;
  }

  fun @construct(UGen md, DelayB del) {
    md @=> mod;
    del @=> delay;
  }
}

class LinkedList {
  null @=> Node _curr;
  null @=> Node _next;

  fun @construct(Node n) {
    this @=> n.parent;
    n @=> _curr;
  }

  fun @construct(UGen mod, DelayB delay) {
    new Node(this, mod, delay) @=> _curr;
  }

  fun @construct(UGen mod, DelayB delay, LinkedList prev) {
    // <<< "insdie construct" >>>;
    new Node(this, mod, delay) @=> _curr;
    this._curr @=> prev._next;
  }

  fun @construct(UGen mod, dur delay, LinkedList prev) {
    new Node(this, mod, new DelayB(delay)) @=> _curr;
    this._curr @=> prev._next;
  }  

  fun @construct(dur d) {
    new Node(this, null, new DelayB(d)) @=> _curr;
  }    

  fun LinkedList next() {
    if (!_next) return null;
    return _next.parent;
  }

  fun LinkedList next(LinkedList nxt) {
    nxt._curr @=> _next;
    return nxt;
  }

  fun DelayB delay() {
    return _curr.delay;
  }

  fun Interference inter() {
    return _curr.inter;
  }

  fun UGen mod() {
    return _curr.mod;
  }

  fun UGen mod(UGen m) {
    m @=> _curr.mod;
    return _curr.mod;
  }

  fun dur delayDur() {
    return _curr.delay.delay();
  }

  fun dur delayDur(dur d) {
    d => _curr.delay.delay;
    return _curr.delay.delay();
  }

  fun float offset(float o) {
    o => _curr.inter.offset;
    return 0;
  }

  fun float offset() {
    return _curr.inter.offset();
  }
}

String str1, str2;

// str1.printDelays();

// <<< "str1.delay", str1._delays.delayDur() >>>;
// str1.mod(str2, 5::samp);
// str1.mod(str2, 5::samp);

// str1.printDelays();


// <<< "!!!!!!!!" >>>;
// str1.mod(str2, 100::samp);
// str1.mod(str2, 1::samp);
// str1.mod(str2, 249::samp);
// <<< "????????" >>>;
// str2.mod(str1, 5::samp);
// <<< "........" >>>;
// str1.connect();
// str1.printDelays();

SinOsc sA => ADSR eA(1::ms, 1::ms, 0.9, 1::second) => String strA(250::samp) => GainDB gA(-18) => dac.left;

SinOsc sB(441) => ADSR eB(1::ms, 1::ms, 0.9, 1::second) => String strB(3*1.5*250::samp) => GainDB gB(-18) => dac.right;

String.link(strA, 4::samp, strB, 4::samp, 0.9);

strA.connect();
strB.connect();

strA.printDelays();
strB.printDelays();

// this sounds cools af
eA.keyOn(); eB.keyOn(); 3::second => now; eA.keyOff(); eB.keyOff();
0.1::second => now;
eA.keyOn(); 3::second => now; eA.keyOff();

4::second => now;

