Blakeminer port for X6500

Based on https://github.com/fpgaminer/Open-Source-FPGA-Bitcoin-Miner/tree/master/projects/X6000_ztex_comm4

Thanks and credits to fpgaminer et al (see top level README)

This will require a modified blake algorithm version of either of

https://github.com/TheSeven/Modular-Python-Bitcoin-Miner
https://github.com/fizzisist/x6500-miner

The latter is depreciated, but may be simpler to modify (work in progress - watch this space)

Bitstream https://www.dropbox.com/s/ean7rbweij40oh1/X6500-Basic-v01-fmax-150MHz.bit

NB This is an initial test bitstream so it may not work. Default clock is 50MHz.
Overclocking potential is limited, perhaps fmax plus up to 25% may be OK depending
on the actual device manufacturing and operating temperature.

Build notes: Use planahead and ensure you include golden_nonce_fifo.ngc in the sources.
Default strategy should be OK (mine was slightly modified, vis resourcesharing no, -xe c)
You will also need to set the bitgen option -g UserID:0x42240402