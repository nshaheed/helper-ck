@import "Rec"

public class StringInteract extends Chugen {
 
  UGen @ _carr;
  UGen @ _mod;

  Step carr;
  Step mod;
 
  0.75 => float _offset;
 
  float _carr_prev, _mod_prev;
 
  fun @construct(UGen carr, UGen mod) {
    carr @=> _carr;
    mod @=> _mod;
  }
 
  fun float tick(float in) {
    _mod.last() + _offset => float mod_pos_offset;
    _carr.last() - _offset => float carr_pos_offset;
     
    _carr.last() => float carr_pos;
    _mod.last() => float mod_pos;
    
    // we get an intersection
    if (mod_pos_offset < _carr.last()) {
      // <<< mod_pos, _carr.last() >>>;
      // _mod.last() - _mod_prev => float mod_vel;
      // <<< mod_vel >>>;
         
      // _carr_prev + mod_vel => carr_pos;
      mod_pos_offset => carr_pos;
      carr_pos_offset => mod_pos;
      
    }
     
    _mod.last() => _mod_prev;
    _carr.last() => _carr_prev;

    carr_pos => carr.next;
    mod_pos => mod.next;
    
    
    return carr_pos;
  }
    
}

SinOsc s1(330) => blackhole;
SinOsc s2(1) => blackhole;

SndBuf buf("special:dope") => blackhole;
true => buf.loop;

// StringInteract inter(s1, buf) => dac;
StringInteract inter(s1, s2) => dac;

1.8 => inter._offset;

// Rec.auto();
2::second => now;
// eon => now;