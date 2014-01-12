Blakeminer Ztex 1.15y port

This is at an early stage however an experimental bitstream is available at
https://www.dropbox.com/s/vk3k5sb64b8641o/ztex_ufm1_15y1-v06ad-2core-ucf-140MHz-fmax-147-fixed.bit

Slightly faster version ...
https://www.dropbox.com/s/1ffqdaj1dowkd0j/ztex_ufm1_15y1-v06ad-t6-ucf-150MHz-fmax-157.bit

Copy the bitfile over bitstreams/ztex_ufm1_15y1.bit

You will need the patched version of cgminer from
https://github.com/kramble/FPGA-Blakecoin-Miner/tree/master/cgminer/cgminer-3.1.1

WARNING This is experimental code which may DAMAGE YOUR ZTEX BOARD.
Use at your own risk and monitor the board for overheating (automatic shutdown is
disabled due to problems compiling the 2nd PLL which has currently been omitted).
