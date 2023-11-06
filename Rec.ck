/*****************************
Rec - Recording utility class

This class provides helper functionality for recording to audio files. It supports
recording from dac, ugens, and arrays of ugens.

To install:
 - copy this file into your chugin search directory direction
    - For windows: C:\Users\<USERNAME>\Documents\chuck\chugins
    - For linux: ~/.chuck/lib
    - For macOS: ~/.chuck/lib

That's it! Now Rec would automatically be added to chuck's global namespace on startup.

To use:


```
// auto-record the dac output
SinOsc s => dac;
spork~ Rec.auto(); // defaults to recording the dac
4::second => now;
```


```
// auto-record a specific ugen
SinOsc s => Bitcrusher b => dac;
spork~ Rec.auto(s); // just pass in the ugen and viola! it's recording
4::second => now;
```

etc., etc.
******************************/

public class Rec {
    fun static void auto(string dir) {

        // pull samples from the dac
        dac => WvOut2 w => blackhole;

        // set the prefix, which will prepended to the filename
        // do this if you want the file to appear automatically
        // in another directory.  if this isn't set, the file
        // should appear in the directory you run chuck from
        // with only the date and time.
        dir + "session" => w.autoPrefix;

        // this is the output file name
        "special:auto" => w.wavFilename;
        // optionally specify bit depth
        // ("special:auto", IO.INT24) => w.wavFilename;

        // print it out
        <<<"writing to file: ", w.filename()>>>;

        // temporary workaround to automatically close file on remove-shred
        null @=> w;

        // infinite time loop...
        // ctrl-c will stop it, or modify to desired duration
        while( true ) 1::second => now;
    }

    fun static void auto() {

        if (me.ancestor().id() == me.id()) {
            cherr <= "You need to spork Rec functions (i.e. spork~ Rec.auto())" <= IO.nl();
        } else {
            auto(me.ancestor().dir());
        }
    }

    fun static void autoMono(UGen @ ugen, string dir) {
        ugen => WvOut w => blackhole;
        dir + "session" => w.autoPrefix;

        "special:auto" => w.wavFilename;

        <<<"writing UGen to file:", w.filename()>>>;

        // temporary workaround to automatically close file on remove-shred
        null @=> w;

        // infinite time loop...
        // ctrl-c will stop it, or modify to desired duration
        while( true ) 1::second => now;
    }

    fun static void autoStereo(UGen @ ugen, string dir) {
        ugen => WvOut2 w => blackhole;
        dir + "session" => w.autoPrefix;

        "special:auto" => w.wavFilename;

        <<< "writing UGen to file:", w.filename()>>>;

        // temporary workaround to automatically close file on remove-shred
        null @=> w;

        // infinite time loop...
        // ctrl-c will stop it, or modify to desired duration
        while( true ) 1::second => now;
    }

    fun static void autoMulti(UGen @ ugen, string dir) {
        ugen.channels() => int chans;

        ugen => WvOut ws[chans];

        for (int i: Std.range(chans)) {
            ws[i] @=> WvOut w;
            w => blackhole;
            dir + "session-" + i => w.autoPrefix;
            "special:auto" => w.wavFilename;
            <<< "writing UGen chan", i, "to file: ", w.filename()>>>;
            null @=> w;
        }

        // infinite time loop...
        // ctrl-c will stop it, or modify to desired duration
        while( true ) 1::second => now;
    }

    fun static void auto(UGen @ ugen) {
        if (me.ancestor().id() == me.id()) {
            cherr <= "You need to spork Rec functions (i.e. spork~ Rec.auto())" <= IO.nl();
            return;
        }

        me.ancestor().dir() => string dir;

        if (ugen.channels() == 0) {
            <<< ugen.typeOf().baseName(), "has 0 output channels, not recording" >>>;
        } else if (ugen.channels() == 1) {
            autoMono(ugen, dir);
        } else if (ugen.channels() == 2) {
            autoStereo(ugen, dir);
        } else {
            autoMulti(ugen, dir);
        }
    }

    fun static void auto(UGen @ ugen[]) {
        // this doesn't handle arrays of multi-channel ugens, but that's so 
        // edge-case-y that I can't be bothered.
        if (me.ancestor().id() == me.id()) {
            cherr <= "You need to spork Rec functions (i.e. spork~ Rec.auto())" <= IO.nl();
            return;
        }

        me.ancestor().dir() => string dir;

        ugen.size() => int chans;


        if (chans == 0) {
            <<< ugen.typeOf().baseName(), "has 0 output channels, not recording" >>>;
            return;
        }


        ugen => WvOut ws[chans];

        for (int i: Std.range(chans)) {
            ws[i] @=> WvOut w;
            w => blackhole;
            dir + "session-" + i => w.autoPrefix;
            "special:auto" => w.wavFilename;
            <<< "writing UGen chan", i, "to file: ", w.filename()>>>;
            null @=> w;
        }

        // infinite time loop...
        // ctrl-c will stop it, or modify to desired duration
        while( true ) 1::second => now;
    }

    fun static void autoMono(string dir) {
        // pull samples from the dac
        dac => Gain g => WvOut2 w => blackhole;

        // set the prefix, which will prepended to the filename
        // do this if you want the file to appear automatically
        // in another directory.  if this isn't set, the file
        // should appear in the directory you run chuck from
        // with only the date and time.
        dir + "session" => w.autoPrefix;

        // this is the output file name
        "special:auto" => w.wavFilename;
        // optionally specify bit depth
        // ("special:auto", IO.INT24) => w.wavFilename;

        // print it out
        <<<"writing to file: ", w.filename()>>>;

        // any gain you want for the output
        1.0 => g.gain;

        // temporary workaround to automatically close file on remove-shred
        null @=> w;

        // infinite time loop...
        // ctrl-c will stop it, or modify to desired duration
        while( true ) 1::second => now;

    }
}