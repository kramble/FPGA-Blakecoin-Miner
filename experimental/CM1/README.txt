Cainsmore CM1 port of blakecoin miner

This code is derived from the HashVoodoo FPGA Bitcoin Miner Project
https://github.com/pmumby/hashvoodoo-fpga-bitcoin-miner

Licensed under GPL. My thanks to Paul Mumby (Glasswalker), makomk and TheSeven.

Bitstream https://www.dropbox.com/s/bbevqb8792emll9/CM1-hv-v04a-175MHz-ucf-150-fmax-161.bit

This will typically clock at around 200MHz for 400MHash/sec per FPGA device (the default
is 175MHz, use cgminer switch --cainsmore-clock to override this). Performance differs
between devices and depends on ambient temperature so tweak the clock for best results
(blancing maximum hash with hardware error rate), ideally per-FPGA, see cgminer README.

Instructions for programming (flashing) the CM1 for blakecoin using a Windows PC and
the Enterpoint programming tools via VirtualBox.

You can instead use Xilinx Impact with a download cable, but this is rather more advanced
and I won't cover it here (the CM1 manual explains the procedure quite well).

First read through the CM1 manual 
http://www.enterpoint.co.uk/cairnsmore/CAIRNSMORE1_MANUAL_ISSUE1.pdf

There is also a useful guide at
https://en.bitcoin.it/wiki/CM1Quickstart

These guides assume you are going to use the Enterpoint bitcoin mining firmware, however
blakecoin uses the hashvoodo firmware instead, so it's a little more complicated.

Read more about hashvoodo at https://bitcointalk.org/index.php?topic=94317.0
Also the main CM1 thread https://bitcointalk.org/index.php?topic=78239.0

First download the required files.

https://www.virtualbox.org/wiki/Downloads (for virtualbox installation)

http://www.enterpoint.co.uk/cairnsmore/cm_ftdi_drivers.zip

http://www.enterpoint.co.uk/cairnsmore/CairnsmoreProgramming.zip

http://www.enterpoint.co.uk/cairnsmore/CAIRNSMORE1_CONTROLLER_SHARING_V1_5.zip

http://www.enterpoint.co.uk/cairnsmore/cairnsmore.ova (500MB)

https://github.com/downloads/pmumby/hashvoodoo-fpga-bitcoin-miner/hashvoodoo_release_09_23_2012.zip

https://www.dropbox.com/s/bbevqb8792emll9/CM1-hv-v04a-175MHz-ucf-150-fmax-161.bit (the blakecoin bitstream)

Unzip CairnsmoreProgramming.zip and hashvoodoo_release_09_23_2012.zip

We won't be using much from these, just xc6lx150.bit and hashvoodoo_controller_25.bit
but the hashvoodo README is worth reading.

Follow the instructions in the CM1 manual to install VirtualBox then import the virtual
machine (VM) from cairnsmore.ova (this only needs to be done once). Start it up and log
in as root, the password is "password". Copy the files xc6lx150.bit and
CM1-hv-v04a-175MHz-ucf-150-fmax-161.bit from the windows PC to the VM. The CM1 manual
suggests using a USB stick to do this, but you can alternatively copy via the host network
using ftp (passive mode) or netcat (nc) if you have the requisite skill (and a local
ftp server for the former). Shut the VM down using "shutdown -h now" or "init 0" (zero).

Unzip cm_ftdi_drivers.zip and CAIRNSMORE1_CONTROLLER_SHARING_V1_5.zip

Plug in the CM1 board and follow the instructions in the CM1 manual for driver installation.

Update the controller firmware to hashvoodo using spiprog.exe hashvoodoo_controller_25.bit

BEWARE, you can brick your board by (mis)using this utility. Be sure to read and understand
section 1.3 of the CM1 manual before proceeding! I'm not giving any help here as I've not
used the utility myself (my CM1 board already had hashvoodo loaded so I didn't need it and
since I only had the board on loan, I didn't want to risk this step just to test it).
NB You MUST use the hashvoodoo_controller_25.bit firmware. The blakecoin bitstream will
NOT work with the default firmware.

Now flash the blakecoin bitstream. First unplug the CM1 USB cable and power it off.

Set the dip switch SW3 to OFF, this the is bitstream programming mode. All other switches
should be on. See the diagram at section 2.4 of the CM1 manual.

Power it on and wait a couple of minutes for the board to initialize. The central red LED
should be on steady, not flashing (else check the SW3 setting).

While you are waiting, start up the VirtualBox Cairnsmore VM and log on as root.

Plug in the CM1 USB cable. Once windows has recognised the device, set the Virtualbox
VM to capture it via the menu Devices / Usb Devices / FTDI Cairnsmore1.

Run the command
xc3sprog -c cm1 -v -j
Confirm that the JTAG chain is listed correctly (see section 2.3 of the CM1 manual)

Erase each of the four devices in turn (each takes around 3 minutes), note that
the command is case sensitive (all lowercase except the -I).
xc3sprog -c cm1 -v -p0 -Ixc6lx150.bit -e
xc3sprog -c cm1 -v -p1 -Ixc6lx150.bit -e
xc3sprog -c cm1 -v -p2 -Ixc6lx150.bit -e
xc3sprog -c cm1 -v -p3 -Ixc6lx150.bit -e

If the erase succeeds, the FPGA leds will dim, (the blue colour dominates).

Program each of the four devices in turn (each takes around 7 minutes)
xc3sprog -c cm1 -v -p3 -Ixc6lx150.bit CM1-hv-v04a-175MHz-ucf-150-fmax-161.bit
xc3sprog -c cm1 -v -p2 -Ixc6lx150.bit CM1-hv-v04a-175MHz-ucf-150-fmax-161.bit
xc3sprog -c cm1 -v -p1 -Ixc6lx150.bit CM1-hv-v04a-175MHz-ucf-150-fmax-161.bit
xc3sprog -c cm1 -v -p0 -Ixc6lx150.bit CM1-hv-v04a-175MHz-ucf-150-fmax-161.bit

On successful programming, the FPGA red led will go bright and the other leds off.
Programming can be a bit temperamental (failure indicated by the leds remaining dim
and blue overall), so you may need to repeat the erase/programming cycle on one or
more of the devices. Reverse order seems best for programming, hence -p3 first.

Shutdown the VM. Power off the CM1, disconnect the USB and switch SW3 back ON.

Power on. Wait for initialization: the central red led will flash continuously
and the FPGA leds will light red, then change to red+yellow. Connect the USB cable.

Now follow the instructions in the blakecoin cgminer README to configure for mining.
https://github.com/kramble/FPGA-Blakecoin-Miner/tree/master/cgminer/cgminer-3.1.1

On running cgminer you should see all four FPGA leds flash blue as they are
detected, then random blue flashes as shares are mined. Green indicates new work
being sent to the FPGA, while yellow is idle (this should not happen under normal
use). Red just indicates the bitstream is running, so should always be on.