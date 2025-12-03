/*****************************
Rec - Recording utility class

This class provides helper functionality for recording to audio files. It supports
recording from dac, ugens, and arrays of ugens.

To install:
 - use ChuMP:
    - chump install Rec
 - if you don't have ChuMP, copy this file into your chugin search directory direction
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
        return "1.2.1";
    }

    @doc "Automatically record the DAC to a stereo file and store in specified directory & file prefix. Will prepend the datetime to the file."
    fun static void auto(string dir) {
	if (isSporked()) recordStereo(dac, dir, true);
	else spork~ recordStereo(dac, dir, true);
    }

    @doc "(hidden)"
    fun static int isSporked() {
        // check if a rec function has been sporked already.
        if (me.ancestor().id() == me.id()) {
            return false;
        } else {
            return true;
        }
    }

    @doc "Automatically record the DAC to a stereo file and store in the current directory. Will prepend the datetime to the file."
    fun static void auto() {
        auto(Rec.autoPrefix());
    }

    @doc "Automatically record a mono UGen and store in specified directory. Will prepend the datetime to the file."
    fun static void autoMono(UGen @ ugen, string dir) {
        dir + "/session" => string path;
	if (isSporked())
	recordMono(ugen, path, true);
	else
	spork~ recordMono(ugen, path, true);
    }

    @doc "Automatically record a mono UGen and store in specified filepath. Will prepend the datetime to the file."
    fun static autoMonoFilepath(UGen @ ugen, string filepath) {
	if (isSporked())
	recordMono(ugen, filepath, true);
	else
	spork~ recordMono(ugen, filepath, true);
    }

    @doc "Automatically record a stereo UGen and store in specified directory. Will prepend the datetime to the file."
    fun static void autoStereo(UGen @ ugen, string dir) {
	dir + "/session" => string path;
	if (isSporked())
	recordStereo(ugen, path, true);
	else
	spork~ recordStereo(ugen, path, true);
    }

    @doc "Automatically record a multichannels UGen and store in specified directory. Will prepend the datetime to the files (one file per channel)."
    fun static void autoMulti(UGen @ ugen, string dir) {
	ugen.channels() => int chans;

	for (int i: Std.range(chans)) {
            dir + "/session-" + i => string path;
            spork~ recordMono(ugen.chan(i), path, true);
	}
    }

    @doc "Automatically record a UGen and store in the current directory. Will prepend the datetime to the file and handle different numbers of channels automatically."
    fun static void auto(UGen @ ugen) {
	me.ancestor().dir() => string dir;

	if (ugen.channels() == 0) {
            chout <= ugen.typeOf().baseName() <= " has 0 output channels, not recording" <= IO.nl();
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

	me.ancestor().dir() => string dir;

	ugen.size() => int chans;

	if (chans == 0) {
            chout <= ugen.typeOf().baseName() <= " has 0 output channels, not recording" <= IO.nl();
            return;
	}

	for (int i: Std.range(chans)) {
            dir + "/session-" + i => string path;
            spork~ recordMono(ugen[i], path, true);
	}
    }

    @doc "Record stereo UGen to a specified file."
    fun static void stereo(UGen @ ugen, string filepath) {
	if (isSporked())
	recordStereo(ugen, filepath, false);
	else
	spork~ recordStereo(ugen, filepath, false);
    }

    @doc "Record mono UGen to a specified file."
    fun static void mono(UGen @ ugen, string filepath) {
	if (isSporked())
	recordMono(ugen, filepath, false);
	else
	spork~ recordMono(ugen, filepath, false);
    }

    @doc "(hidden)"
    fun static void recordMono(UGen @ ugen, string filename, int auto) {
	// helper function to record ugen to filename.
	// this is abstracted out so that it can be sporked.
	ugen => WvOut w => blackhole;

	if (auto) {
            filename => w.autoPrefix;
            "special:auto" => w.wavFilename;
	} else {
            filename => w.wavFilename;
	}
	cherr <= "writing UGen to file: " <= w.filename() <= IO.nl();

	// infinite time loop...
	// ctrl-c will stop it
	while( true ) 1::second => now;        
    }

    @doc "(hidden)"
    fun static void recordStereo(UGen @ ugen, string filename, int auto) {
	// helper function to record ugen to filename.
	// this is abstracted out so that it can be sporked.
	ugen => WvOut2 w => blackhole;

	if (auto) {
            filename => w.autoPrefix;
            "special:auto" => w.wavFilename;
	} else {
            filename => w.wavFilename;
	}
	cherr <= "writing UGen to file: " <= w.filename() <= IO.nl();

	// infinite time loop...
	// ctrl-c will stop it
	while( true ) 1::second => now;
    }

    @doc "(hidden)"
    fun static string autoPrefix() {
	// strip the file extension of the shred to get the prefix of the parent shred
	me.ancestor().sourcePath() => string path;
	"<compiled.code>" => string comp;
	
	<<< path >>>;
	
	// case 1: ends with <compiled code> in this case, we will just do session as the prefix
	if (path.substring(path.length() - comp.length()) == comp) {
            return me.ancestor().dir() + "session";
	}
	
	// case 2: ends with a file extension, strip this
	
	// get pos of last '/' and '.'
	path.rfind("/") => int slash_pos;
	path.rfind(".") => int ext_pos;

	// there is a file extension if the '.' is after the last '/'
	if (ext_pos > -1 && ext_pos > slash_pos) {
            path.erase(ext_pos, path.length() - ext_pos);
            return path;
	}

	// case 3: everything else failed
	return me.ancestor().dir() + "session";
    }
}

Rec.auto();
// spork~ Rec.auto();
SinOsc s => dac;
10::second => now;