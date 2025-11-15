@import "Chumpinate"
@import "Rec.ck"

// Our package version
Rec.version() => string version;

<<< "Generating Rec package release..." >>>;

// instantiate a Chumpinate package
Package pkg("Rec");

// Add our metadata...
["Nick Shaheed"] => pkg.authors;

"https://github.com/nshaheed/helper-ck" => pkg.homepage;
"https://github.com/nshaheed/helper-ck" => pkg.repository;

"tbd" => pkg.license;
"Helper functions for recording to audio files. Supports recording from dac, ugens, and arrays of ugens." => pkg.description;

["utility", "recording"] => pkg.keywords;

// generate a package-definition.json
// This will be stored in "Rec/package.json"
"./" => pkg.generatePackageDefinition;

<<< "Defining version " + version >>>;;

// Now we need to define a specific PackageVersion for test-pkg
PackageVersion ver("Rec", version);

"1.5.4.2" => ver.languageVersionMin; // what version?

"any" => ver.os;
"all" => ver.arch;

// all the files
ver.addFile("Rec.ck");
ver.addExampleFile("_examples/basic.ck");
ver.addExampleFile("_examples/ugen.ck");

"chugins/Rec/" + ver.version() + "/Rec.zip" => string path; // path?

// wrap up all our files into a zip file, and tell Chumpinate what URL
// this zip file will be located at.
ver.generateVersion("./", "Rec", "https://ccrma.stanford.edu/~nshaheed/" + path);

chout <= "Use the following commands to upload the package to CCRMA's servers:" <= IO.newline();
chout <= "ssh nshaheed@ccrma-gate.stanford.edu \"mkdir -p ~/Library/Web/chugins/Rec/"
      <= ver.version() <= "/\"" <= IO.newline();
chout <= "scp Rec.zip nshaheed@ccrma-gate.stanford.edu:~/Library/Web/" <= path <= IO.newline();

// Generate a version definition json file, stores this in "<PackageName/<VerNo>/Rec.json"
ver.generateVersionDefinition("Rec", "./" );