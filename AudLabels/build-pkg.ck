@import "Chumpinate"
@import "AudLabels.ck"

// Our package version
AudLabels.version() => string version;

<<< "Generating package release..." >>>;

"AudLabels" => string name;

// instantiate a Chumpinate package
Package pkg(name);

// Add our metadata...
["Nick Shaheed"] => pkg.authors;

"https://github.com/nshaheed/helper-ck" => pkg.homepage;
"https://github.com/nshaheed/helper-ck" => pkg.repository;

"MIT" => pkg.license;
"Provides AudLabels, a utility class to read Audacity label files" => pkg.description;

["Utility", "Audacity", "Labels"] => pkg.keywords;

// generate a package-definition.json
"./" => pkg.generatePackageDefinition;

<<< "Defining version " + version >>>;;

// Now we need to define a specific PackageVersion for test-pkg
PackageVersion ver(name, version);

"1.5.5.6" => ver.languageVersionMin; // what version?

"any" => ver.os;
"all" => ver.arch;

// all the files
ver.addFile("AudLabels.ck");

"chugins/" + name + "/" + ver.version() + "/" + name + ".zip" => string path; // path?

// wrap up all our files into a zip file, and tell Chumpinate what URL
// this zip file will be located at.
ver.generateVersion("./", name, "https://ccrma.stanford.edu/~nshaheed/" + path);;

chout <= "Use the following commands to upload the package to CCRMA's servers:" <= IO.newline();
chout <= "ssh nshaheed@ccrma-gate.stanford.edu \"mkdir -p ~/Library/Web/chugins/" <= name <= "/"
      <= ver.version() <= "/\"" <= IO.newline();
chout <= "scp " <= name <= ".zip nshaheed@ccrma-gate.stanford.edu:~/Library/Web/" <= path <= IO.newline();

// Generate a version definition json file, stores this in "<PackageName/<VerNo>/Rec.json"
ver.generateVersionDefinition(name, "./" );