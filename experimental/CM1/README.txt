Cainsmore CM1 port of blakecoin miner

This code is derived from the HashVoodoo FPGA Bitcoin Miner Project
https://github.com/pmumby/hashvoodoo-fpga-bitcoin-miner

Licensed under GPL. My thanks to Paul Mumby (Glasswalker), makomk and TheSeven.

NB This port requires the Hashvoodo controller firmware available at
https://github.com/pmumby/hashvoodoo-fpga-bitcoin-miner/downloads
Use hashvoodoo_controller_25.bit from any of the later releases, NOT the 08_04_2012.

Follow the instructions in the README for updating the firmware and bitstreams.

Test bitstream at https://www.dropbox.com/s/m901icq7pt9nl4l/CM1-hv-v04a-80MHz-ucf-75-fmax-78.bit
Now depreciated.
 
Much faster version ...
https://www.dropbox.com/s/bbevqb8792emll9/CM1-hv-v04a-175MHz-ucf-150-fmax-161.bit
This will clock at over 200MHz (though the default is 175MHz, use cgminer clock switch).
