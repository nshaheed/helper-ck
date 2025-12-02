@import "Rec"

// instantiate a CKDoc object
CKDoc doc; // documentation orchestra

doc.addGroup(
    // class names
    [
	"Rec"
    ],
    // group name
    "Rec Class",
    // file name
    "Rec",
    // group description
    "This Rec class provides helper functionality for recording to audio files. It supports recording from dac, ugens, and arrays of ugens."
);

// sort for now until order is preserved by CKDoc
doc.sort(true);

// generate
doc.outputToDir( "./ckdoc", "Rec API Reference" );
