Blakeminer patches for https://github.com/ckolivas/cgminer version 3.1.1

I don't think its appropriate to fork the repository in this case so I will just supply
patches to specific release versions.

Compilation
Open the official repository (link above) in your browser, click the "branches"
dropdown menu in the middle left of the page, select the "tags" tab and scroll down
to the version required (3.1.1) and select it. Download the zip (right side of page)
and unzip the archive.

Copy my patch files (from this github folder) into the official cgminer 3.1.1 folder,
replacing existing files as necessary. Build as normal, see the README or windows-build.txt
NB Opencl should be disabled in the configuration (it may work, but I've not tested it)
./autogen.sh
CFLAGS="-O2" ./configure --enable-ztex --enable-icarus --disable-opencl

Prebuit windows binary at ...
Current third version at https://www.dropbox.com/s/51p61kk5rfjpkyz/cgminer.exe
Second version without cainsmore-clock at https://www.dropbox.com/s/6ydm22w7rclzhj2/cgminer.exe
First version without ztex-clock at https://www.dropbox.com/s/ak7jqi0mnd4j1zp/cgminer.exe
Dependancies (DLL) at https://www.dropbox.com/s/xa01f9hhakpsexv/cgminer-3.1.1-blakefpga.zip

To use the windows version, unzip the dependancies then move cgminer.exe into the folder.
Copy the bitstream folder from the official cgminer-3.1.1 distribution.
Replace ztex_ufm1_15y1.bit with the BlakeCoin bitstream.
Edit the RUNBLAKE.BAT script and set the username/password to be the same as the rpcuser
and rpcpassword set in your blakecoin.conf. Change localhost if running blakecoind on a
separate machine. You will need to install the WinUSB driver using zadig which is available
at http://sourceforge.net/projects/libwdi/files/zadig/

For linux users, run as follows (this is the same as RUNBLAKE.BAT)
sudo ./cgminer --disable-gpu --url localhost:8772 --userpass username:password 2>log.txt
You can probably change the UDEV rules to avoid the need for sudo.

Notes:
Should you have problems, redirect the stderr output to log.txt (this is automatic in
RUNBLAKE.BAT) and examine this for messages.
Do not use this for GPU mining as it will not work.
The --debug and --verbose switches may crash the program in windows. Using the -T switch
perhaps will work around this (it disables curses).

Ztex
Only the ztex 1.15y board is supported. Frequency management is automatic using the
same algorithm as bitcoin. It can be overriden by the --ztex-clock option as follows
--ztex-clock 180:200	sets initial clock of 180MHz, max of 200Mhz
--ztex-clock 204:204	fixed clock speed of 204MHz
--ztex-clock 180:192,184:196,180:204,192:212	set individual fpga device speeds
I don't know if this will work for multiple boards, but its done the same way as
the icarus options so with luck it will be OK.
The clock resolution is 4MHz (rounds down) and the valid range is 100MHz to 250MHz.
If --ztex-clock is not used the default range is 172MHz to 220MHz.

Cainsmore
Cainsmore CM1 will be detected as icarus
Use the -S option eg.  -S \\.\COM20 -S \\.\COM21 -S \\.\COM22 -S \\.\COM23 
It will not work for my current lancelot bitstream, use the python miner instead.
Clock speed can be set with --cainsmore-clock which takes a single value eg
--cainsmore-clock 200				sets all devices to 200MHz
--cainsmore-clock 200,210,190,195	sets individual device speeds
The clock resolution is 2.5MHz (rounds down) and the valid range is 50MHz to 220MHz.
If --cainsmore-clock is not used the default is 175MHz
