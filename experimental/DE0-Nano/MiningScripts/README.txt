Edit config.tcl with your pool worker login data or if solo mining rpcusername
and rcppassword. You may want to turn off the getwork/midstate messages by setting
verbose to 0 in mine.tcl once you've got it working.

The error message "unexpected '<' in TOP mode" is a symptom
of a bad username/password when solo mining (the wallet daemon sends a HTML page
rather than the JSON data).

If running on windows you will need to download midstate.exe
from https://www.dropbox.com/s/o83n32w9i3l7w89/midstate.exe

On linux you should compile midstate from source at
https://github.com/kramble/FPGA-Blakecoin-Miner/tree/master/MiningSoftware/compile-midstate

The speed statistics are only reported for one core, so multiply this by the number
of cores to get the total. The speed in brackets (supposedly average real hashrate)
is currently garbage.

Note on the blake getwork pool bug that caused some early problems ...
The getwork pool sends an additional byte of data after the nonce field, so sends
129 bytes rather than 128, which broke the original TCL mining script (this has
now been fixed via a workaround in the script).

Interestingly this byte (6B) together with the nonce (35303152) spell K105r
(the author of the pool software).

Another interesting bug is that the block header version byte is 2, compare 114 (0x70)
for solo mined blocks (this can be easily verified with the blockexplorer).