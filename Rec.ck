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

@doc "A class that provides helper functionality for recording to audio files."
public class Rec {

    @doc "Return Rec version as a string"
    fun static string version() {
        return "1.2.0";
    }

    @doc "Automatically record the DAC to a stereo file and store in specified directory. Will prepend the datetime to the file."
    fun static void auto(string dir) {

        // pull samples from the dac
        dac => WvOut2 w => blackhole;

        // set the prefix, which will prepended to the filename
        // do this if you want the file to appear automatically
        // in another directory.  if this isn't set, the file
        // should appear in the directory you run chuck from
        // with only the date and time.
        dir + "/session" => w.autoPrefix;

        // this is the output file name
        "special:auto" => w.wavFilename;
        // optionally specify bit depth
        // ("special:auto", IO.INT24) => w.wavFilename;

        // print it out
        <<<"writing to file: ", w.filename()>>>;

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;
    }

    @doc "(hidden)"
    fun static int validateSpork() {
    	if (me.ancestor().id() == me.id()) {
            cherr <= "You need to spork Rec functions (i.e. spork~ Rec.auto())" <= IO.nl();
	    return false;
        } else {
	    return true;
        }
    }

    @doc "Automatically record the DAC to a stereo file and store in the current directory. Will prepend the datetime to the file."
    fun static void auto() {
        if (validateSpork()) {
            auto(me.ancestor().dir());
        }
    }

    @doc "Automatically record a mono UGen and store in specified directory. Will prepend the datetime to the file."
    fun static void autoMono(UGen @ ugen, string dir) {
    	if (!validateSpork()) return;
        ugen => WvOut w => blackhole;
        dir + "/session" => w.autoPrefix;

        "special:auto" => w.wavFilename;

        <<<"writing UGen to file:", w.filename()>>>;

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;
    }

    @doc "Automatically record a mono UGen and store in specified filepath. Will prepend the datetime to the file."
    fun static autoMonoFilepath(UGen @ ugen, string filepath) {
	// provide a filename to append the timestamp to i.e. /path/to/file
	if (!validateSpork()) return;
        ugen => WvOut w => blackhole;
        filepath => w.autoPrefix;

        "special:auto" => w.wavFilename;

        <<<"writing UGen to file:", w.filename()>>>;

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;    }

    @doc "Automatically record a stereo UGen and store in specified directory. Will prepend the datetime to the file."
    fun static void autoStereo(UGen @ ugen, string dir) {
    	if (!validateSpork()) return;
        ugen => WvOut2 w => blackhole;
        dir + "/session" => w.autoPrefix;

        "special:auto" => w.wavFilename;

        <<< "writing UGen to file:", w.filename()>>>;

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;
    }

    @doc "Automatically record a multichannels UGen and store in specified directory. Will prepend the datetime to the files (one file per channel)."
    fun static void autoMulti(UGen @ ugen, string dir) {
        if (!validateSpork()) return;
        ugen.channels() => int chans;

        ugen => WvOut ws[chans];

        for (int i: Std.range(chans)) {
            ws[i] @=> WvOut w;
            w => blackhole;
            dir + "/session-" + i => w.autoPrefix;
            "special:auto" => w.wavFilename;
            <<< "writing UGen chan", i, "to file: ", w.filename()>>>;
        }

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;
    }

    @doc "Automatically record a UGen and store in the current directory. Will prepend the datetime to the file and handle different numbers of channels automatically."
    fun static void auto(UGen @ ugen) {
        if (!validateSpork()) return;

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

    @doc "Automatically record an array of UGens and store in the current directory. Will prepend the datetime to the files (one file per UGen)."
    fun static void auto(UGen @ ugen[]) {
        // this doesn't handle arrays of multi-channel ugens, but that's so
        // edge-case-y that I can't be bothered.
	if (!validateSpork()) return;

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
            dir + "/session-" + i => w.autoPrefix;
            "special:auto" => w.wavFilename;
            <<< "writing UGen chan", i, "to file: ", w.filename()>>>;
        }

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;
    }

    @doc "(hidden)"
    fun static void autoMono(string dir) {
        // pull samples from the dac
	if (!validateSpork()) return;
        dac => Gain g => WvOut2 w => blackhole;

        // set the prefix, which will prepended to the filename
        // do this if you want the file to appear automatically
        // in another directory.  if this isn't set, the file
        // should appear in the directory you run chuck from
        // with only the date and time.
        dir + "/session" => w.autoPrefix;

        // this is the output file name
        "special:auto" => w.wavFilename;
        // optionally specify bit depth
        // ("special:auto", IO.INT24) => w.wavFilename;

        // print it out
        <<<"writing to file: ", w.filename()>>>;

        // any gain you want for the output
        1.0 => g.gain;

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;

    }

    @doc "Record stereo UGen to a specified file."
    fun static void stereo(UGen @ ugen, string filepath) {
        if (!validateSpork()) return;
        ugen => WvOut2 w => blackhole;

        filepath => w.wavFilename;

        <<< "writing UGen to file:", w.filename()>>>;

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;
    }

    @doc "Record mono UGen to a specified file."
    fun static void mono(UGen @ ugen, string filepath) {
        if (!validateSpork()) return;
        ugen => WvOut w => blackhole;

        filepath => w.wavFilename;

        <<< "writing UGen to file:", w.filename()>>>;

        // infinite time loop...
        // ctrl-c will stop it
        while( true ) 1::second => now;
    }
}