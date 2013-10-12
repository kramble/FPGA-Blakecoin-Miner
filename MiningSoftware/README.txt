Mining software for blakeminer - SOLO mining against blakecoind

You will need to install python 2.7, then ...

From the fpgaminer/project/Verilog_Xilinx_Port/README.txt I quote ...
  It requires a few non-standard libraries, pyserial and json-rpc.
  http://pyserial.sourceforge.net/
  (also generally available in Linux distributions)
  http://json-rpc.org/wiki/python-json-rpc

Since these are open source, I have included them in the MiningSoftware folder, vis

pyserial-2.6 from http://pyserial.sourceforge.net
python-json-rpc from http://json-rpc.org/browser/trunk/python-jsonrpc/jsonrpc

To install them run "python setup.py install" in each folder (sudo if on linux)

You will also need to compile the midstate program (see folder compile-midstate)
and copy the resulting executable to this directory

NB This code has only been tested on linux (raspberry pi debian wheezy)

The scripts take a single (optional) parameter, the clock speed (in MHz) for use with
the dynamic clock PLL. The value is checked for validity in the FPGA, so not all values
will work (see SPEED_LIMIT and SPEED_MIN parameters in ltcminer_icarus.v). Use the
FLASHCLOCK feature (blinks the TxD led in time to the clock) to verify the clock speed
has been accepted.

Be careful of spaces/tabs in python as these are part of the syntax! If you run
into problems making changes, just copy a previous line EXACTLY, then modify the part
after the initial spaces/tabs. ADDENDUM. I have now tabbified the script with tabstop=4
(using Notepad++) which should make it much easier to edit.
