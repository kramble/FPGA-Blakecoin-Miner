Blakeminer port for X6500 - DOES NOT WORK, USE X6500-Robust instead

Based on https://github.com/fpgaminer/Open-Source-FPGA-Bitcoin-Miner/tree/master/projects/X6000_ztex_comm4

Thanks and credits to fpgaminer et al (see top level README)

This will require a modified blake algorithm version of either of

https://github.com/TheSeven/Modular-Python-Bitcoin-Miner
https://github.com/fizzisist/x6500-miner

The latter is depreciated, but may be simpler to modify (work in progress - watch this space)

Bitstream [REDACTED does not work, use X6500-Robust instead]

NB This is an initial test bitstream so it may not work. Default clock is 50MHz.
Overclocking potential is limited, perhaps fmax plus up to 25% may be OK depending
on the actual device manufacturing and operating temperature.

Build notes: Use planahead and ensure you include golden_nonce_fifo.ngc in the sources.
Default strategy should be OK (mine was slightly modified, vis resourcesharing no, -xe c)
You will also need to set the bitgen option -g UserID:0x42240402

While the current code does not work, perhaps reducing SYNTHESIS_FREQUENCY from 150MHz
to 100MHz will. Its on my do list, but I'm currently working from X6500-Robust.