Edit config.tcl with your pool worker login data or if solo mining rpcusername
and rcppassword.

The error message "unexpected '<' in TOP mode" is a symptom
of a bad username/password when solo mining (the wallet daemon
sends a HTML page rather than the JSON data).

If running on windows you will need to download midstate.exe
from https://www.dropbox.com/s/o83n32w9i3l7w89/midstate.exe

On linux you should compile midstate from source at
https://github.com/kramble/FPGA-Blakecoin-Miner/tree/master/MiningSoftware/compile-midstate

