NB These are no longer needed as blakeminer.py now uses blake8.py for hashing

These do not need a makefile, on linux just ...

make checkblake
make midstate

On windows they compile OK under VisualStudioExpress2008 using the
command line compiler (setup the compile environment first) ...

cl checkblake.c
cl midstate.c

Windows binaries are available on dropbox

https://www.dropbox.com/s/j3drv4flzuljywh/checkblake.exe
https://www.dropbox.com/s/o83n32w9i3l7w89/midstate.exe
