Blakeminer patches for https://github.com/ckolivas/cgminer

I don't think its appropriate to fork the repository in this case so I will
just supply patches to specific release versions.

To use: open the official repository (link above) in your browser, click the
"branches" dropdown menu in the middle left of the page, select the "tags" tab
and scroll down to the version required and select it. Now download the zip
(right side of page).

Unzip the archive, then copy my files into the folder, replacing existing
files as necessary. Build as normal (this probably only works on linux as
windows build is more complicated, I'll try to produce windows binaries at
some point in the future).

NB While it works for ztex, the cainsmore CM1 is not correctly detected,
this was also the case when I built the bitcoin version.