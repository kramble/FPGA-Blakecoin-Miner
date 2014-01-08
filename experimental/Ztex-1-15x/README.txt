Blakeminer Ztex 1.15x/1.15d port

Initial test bitstream courtesy of BitcoinTalk member hal7 ...
https://www.dropbox.com/s/71308c5jmd5964j/hal7_ztex_ufm1_15d4_2core_test.bit
Copy this over bitstreams/ztex_ufm1_15d4.bit
Use --ztex-clock 128:128 for 250MHash/sec. It will probably clock faster (YMMV).

You will need the patched version of cgminer from
https://github.com/kramble/FPGA-Blakecoin-Miner/tree/master/cgminer/cgminer-3.1.1

WARNING This is experimental code which may DAMAGE YOUR ZTEX BOARD.
Use at your own risk and monitor the board for overheating (automatic shutdown is
disabled due to problems compiling the 2nd PLL which has currently been omitted).
