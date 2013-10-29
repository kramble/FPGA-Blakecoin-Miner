Blakeminer port for X6500

Based on https://github.com/fpgaminer/Open-Source-FPGA-Bitcoin-Miner/tree/master/projects/X6000_ztex_comm4

Thanks and credits to fpgaminer et al (see top level README)

This will require a modified blake algorithm version of either of

https://github.com/TheSeven/Modular-Python-Bitcoin-Miner
https://github.com/fizzisist/x6500-miner

The latter is depreciated, but may be simpler to modify (work in progress - watch this space)

Bitstreams ...

https://www.dropbox.com/s/58bkb5k4ts8k7j1/X6500-Robust-v02-fmax-100MHz.bit (single core)

https://www.dropbox.com/s/aalxmdbumare7ez/X6500-Robust-v04-2core-fmax-100MHz.bit (dual core)

NB This is an initial test bitstream which is tested and works. Default clock is 50MHz.
Overclocking potential is limited, perhaps fmax plus up to 25% may be OK depending
on the actual device manufacturing and operating temperature.

Build notes: Use planahead
Default strategy should be OK (mine was slightly modified, vis resourcesharing no, -xe c)
You will also need to set the bitgen option -g UserID:0x42240402