Blakeminer port for X6500

Based on https://github.com/fpgaminer/Open-Source-FPGA-Bitcoin-Miner/tree/master/projects/X6000_ztex_comm4

Thanks and credits to fpgaminer et al (see top level README)

This will require a modified blake algorithm version of either of

https://github.com/TheSeven/Modular-Python-Bitcoin-Miner
https://github.com/fizzisist/x6500-miner

Do NOT use the above directly, my modified forks are at

https://github.com/kramble/Modular-Python-Bitcoin-Miner
https://github.com/kramble/x6500-miner

Both should work for solo mining and pool mining, however driver installation may be problematic.
You must use a getwork pool. Stratum is not supported.
This is discussed on the bitcointalk thread https://bitcointalk.org/index.php?topic=306894.msg5255046#msg5255046
(Further updates will follow once I get some feedback)

Beware that the x6500-miner url parameter must NOT be prefixed http:// and you should experiment
with the --overclock parameter on mine.py (start at 120 and work up until you see shares rejected,
then back off slightly). FMAX plus up to 25% or perhaps slightly more may be achievable.

Bitstreams ...

https://www.dropbox.com/s/yai3qyklwqy0tny/X6500-Robust-v05-2core-100MHz-fmax-103MHz.bit

NB Default clock is 100MHz and gives 400Mhash/sec for the dual-fpga board.
Overclocking is recommended, perhaps fmax plus up to 25% may be achievable depending
on the actual device manufacturing and operating temperature. Fmax will increase in
future builds (work in progress).

Build notes: Use planahead
Default strategy should be OK (mine was slightly modified, vis resourcesharing no, -xe c)
You will also need to set the bitgen option -g UserID:0x42240402