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

Windows binary 3.1.1 at https://www.dropbox.com/s/f34zwu3oek0rj4m/cgminer.exe
Dependancies (DLL) at https://www.dropbox.com/s/xa01f9hhakpsexv/cgminer-3.1.1-blakefpga.zip
To use, unzip the dependancies then move cgminer.exe into the folder.
Copy the bitstream folder from an official cgminer-3.1.1 distribution.
Replace ztex_ufm1_15y1.bit with the BlakeCoin bitstream.
Edit the RUNBLAKE.BAT script to set the username/password.
Do not use this for GPU mining as it will not work (requires --disable-gpu).
The --debug switch may crash in windows, use -T to work around (disables curses).

NB The 3.4.3 version was an early experimental build. DO NOT USE.