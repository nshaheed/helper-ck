
// Read audacity label files
// ref: https://manual.audacityteam.org/man/importing_and_exporting_labels.html
public class AudLabels {
    dur startTimes[0], stopTimes[0], lengths[0];
    string labels[0];
    float lowFreqs[0], highFreqs[0];

    fun @construct(string filename) {
      	FileIO fio;

	// open a file
	fio.open( filename, FileIO.READ );

	// ensure it's ok
	if( !fio.good() )
	{
	    cherr <= "ERROR: can't open file: " <= filename <= " for reading, exiting..."
	    <= IO.newline();
            return;
        }

	// The audacity label format consists of 3 or 5 tab-separated columns:
	// [start time] [stop_time] [label] [low freq] [high freq]
	// [low freq] and [high freq] are optional and refer to a label's spectral selection
	dur time_start, time_stop;
	float freq_low, freq_high;

	string line;

	// parse the file
	while (fio.more()) {
	    fio.readLine() => line;
	    StringTokenizer tok(line, "\t");

	    // Detect an improperly formatted file
	    // sometimes if the label is blank, it will be 2 columns
	    if (tok.size() != 2 && tok.size() != 3 && tok.size() != 5) {
		cherr <= "[AudLabels] ERROR: label file \"" <= filename <= "\" does not have the correct number of columns," <= IO.nl();
		cherr <= "                   expecting 3 or 5 tab-separated columns, exiting..." <= IO.nl();
		return;
	    }

	    tok.next().toFloat()::second => time_start;
	    tok.next().toFloat()::second => time_stop;

	    string label;

	    // if the number of tokens is 2, there is a chance the
	    // label is blank. string.toFloat() returns 0 if it's
	    // invalid so if time_stop is 0 then time_start must also
	    // be 0 (i.e. a point-label at the beginning of a file),
	    // otherwise we know this is an error.
	    if (tok.size() == 2) {
		if (time_stop != 0::samp) {
		    // success condition 1: time_stop is a non-zero number so
		    // the label must have been blank and StringTokenizer just
		    // ate the last tab.
		    "" => label;
		} else if (time_start == 0::samp && time_stop == 0::samp) {
		    // success condition 2: there is a point-label at the start of the timeline
		    "" => label;
		} else if (time_stop == 0::samp) {
		    // failure condition: time_start isn't 0, but time_stop is.
		    cherr <= "[AudLabels] ERROR: label file \"" <= filename <= "\" does not have the correct number of columns," <= IO.nl();
		    cherr <= "                   expecting 3 or 5 tab-separated columns, exiting..." <= IO.nl();
		    return;		    
		}
	    }

	    // validate sensible start/stop times
	    if (time_start > time_stop) {
		cherr <= "[AudLabels] ERROR: Invalid start time (" <= time_start / second <= ") and end time (" <= time_stop / second <= ")" <= IO.nl();
		cherr <= "                   Label ending time must be at or after the start time" <= IO.nl();
		return;
	    }
	    
	    startTimes << time_start;
	    stopTimes << time_stop;
	    lengths << time_stop - time_start;
	    labels << label;

	    // if the spectral selection is enabled also parse those values
	    if (tok.size() == 5) {
		tok.next().toFloat() => freq_low;
		tok.next().toFloat() => freq_high;

		lowFreqs << freq_low;
		highFreqs << freq_high;
	    }
	}
    }

    fun int size() {
      	return labels.size();
    }
}


// test
AudLabels test("audacity_labels.txt");
AudLabels test2("point_blank.txt");

chout <= "\nexpecting test to fail here:\n";
AudLabels test_failure("audacity_labels_bad.txt");
AudLabels test_failure2("audacity_labels_bad2.txt");