# Building & Running
This repo has a sequencer I've made that controls two grids of strings that are close enough to 
bang into each other.

`git clone` this repo and then `cd` into `StringInteract` (this dir). Then you need to build the chugin `Interference` that handles the nonlinearities:

```
cd helper-ck/StringInteract
make mac
# make linux
chuck lattice_interactive3 # this runs the chuck program
```

# Controls
`lattice_interactive3.ck` is a randomized sequencer where you can
control what rhythms can be chosen and what strings can be excited:

They keys '1','2','3','4' control the set of rhythms that can be selected (1-4 beats long long where a beat is 0.25 seconds)

The keys 'q','w','e','a','s','d' control which strings are excitable on the first grid.

The keys 'i','o','p','j','k','l' control which strings are excitable on the second grid.

The GUI highlights which options are enabled and which are disabled.
