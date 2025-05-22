@doc "will take in an input signal, but no output signal? not sure yet"
public class Average extends Chugraph {
    inlet => FFT fft =^ RMS rms => blackhole;
    
    float samples[0];
    int max_samples;
    float _average;
    
    @doc "default maximum interval of 10ms"
    fun @construct() {
        // @construct(10::ms);
    }
    
    @doc "provide the maximum interval to measure average over"
    fun @construct(dur interval) {
        1024 => int window_size => fft.size;
        Windowing.hann(window_size) => fft.window;
        
        // this is the max interval
        // floor of interval / window size with 1 being the min
        (interval / samp) $ int => int interval_size;
        
        interval_size / window_size => int n_windows;
        
        Math.max(1, n_windows) => n_windows;
        
        n_windows => max_samples;
        
        spork~ analyze();
    }
    
    fun analyze() {
        while (true) {
            rms.upchuck() @=> UAnaBlob blob;
            samples << blob.fval(0);
            
            // clears out old samples (should only ever
            // be 1 sample too many, but just being safe).
            while (samples.size() > max_samples) {
                samples.popFront();
            }
            
            // calculate average [linear and not max-efficient]
            float total;
            for (float sample: samples) sample +=> total;
            
            total / samples.size() => _average;
            
            fft.size()::samp => now;
        }
    }
    
    @doc "Get the average of the signal"
    fun float average() {
        return _average;
    }
    
    fun dur window_size() {
        return fft.size()::samp;
    }
}
