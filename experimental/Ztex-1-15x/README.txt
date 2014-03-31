Blakeminer Ztex 1.15x/1.15d port

Bitstreams courtesy of BitcoinTalk member hal7
Copy the bitstream file over bitstreams/ztex_ufm1_15d4.bit

Initial test version ...
https://www.dropbox.com/s/71308c5jmd5964j/hal7_ztex_ufm1_15d4_2core_test.bit
Use --ztex-clock 128:128 for 250MHash/sec. It will probably clock faster (YMMV).

Faster version ...
https://www.dropbox.com/s/4nnquv6z66an6c5/hal7_ztex_ufm1_15d4_2core_v02.bit
Results (min. 1h tests):
Ztex 1.15x clone - grade 2 chip: 144MHz stable with 0 HW, 6.2W power with 40mm fan
Ztex 1.15x       - grade 3 chip: 152MHz stable with 0 HW, 7.0W power with 40mm fan (>300MH/s)

Faster version ...
https://www.dropbox.com/s/polv7bu899w4bmi/hal7_ztex_ufm1_15d4_2core_v03.bit
Results:
Ztex 1.15x clone - grade 2 chip: 168MHz stable with 0 HW, 7.6W power with 40mm fan
Ztex 1.15x       - grade 3 chip: 180MHz stable with 0 HW, 8.7W power with 40mm fan (360MH/s).

Faster version (approx 20MHz gain) ...
https://www.dropbox.com/s/0ngqeeoehul6x8h/hal7_ztex_ufm1_15d4_2core_v04.bit

You will need the patched version of cgminer from
https://github.com/kramble/FPGA-Blakecoin-Miner/tree/master/cgminer/cgminer-3.1.1

WARNING This is experimental code which may DAMAGE YOUR ZTEX BOARD.
Use at your own risk and monitor the board for overheating (automatic shutdown is
disabled due to problems compiling the 2nd PLL which has currently been omitted).
