DE0-Nano port of BlakeMiner. The performance is quite poor so you are unlikely
to find mining profitable on this board.

This is quite old code and the FMax is rather disappointing (around 50MHz
compared with the 150MHz of the Xilinx LX150 ports), but since the main
limitation on the DE0-Nano seems to be power dissipation, I don't see much point
in doing any additional work on updating it.

Test bitstream https://www.dropbox.com/s/3dwl3yfsxwsr3nt/blakeminer-2core-50MHz.sof

This is configured for two cores at 50MHz giving around 4.5MHash/sec (note that
the TCL mining script reports just 2.2MH/s as it only gives speed statistics for
one of the cores). FMax (Slow 1200mV 85C) is 48.25MHz which should not be a problem.

+-------------------------------------------------------------------------------+
; Flow Summary                                                                  ;
+------------------------------------+------------------------------------------+
; Flow Status                        ; Successful - Tue Mar 18 14:05:34 2014    ;
; Quartus II Version                 ; 10.1 Build 153 11/29/2010 SJ Web Edition ;
; Revision Name                      ; blakeminer                               ;
; Top-level Entity Name              ; blakeminer                               ;
; Family                             ; Cyclone IV E                             ;
; Device                             ; EP4CE22F17C6                             ;
; Timing Models                      ; Final                                    ;
; Total logic elements               ; 10,712 / 22,320 ( 48 % )                 ;
;     Total combinational functions  ; 9,555 / 22,320 ( 43 % )                  ;
;     Dedicated logic registers      ; 3,609 / 22,320 ( 16 % )                  ;
; Total registers                    ; 3609                                     ;
; Total pins                         ; 9 / 154 ( 6 % )                          ;
; Total virtual pins                 ; 0                                        ;
; Total memory bits                  ; 0 / 608,256 ( 0 % )                      ;
; Embedded Multiplier 9-bit elements ; 0 / 132 ( 0 % )                          ;
; Total PLLs                         ; 1 / 4 ( 25 % )                           ;
+------------------------------------+------------------------------------------+

The code may clock faster, and support additional cores, but power dissipation
in the DE0-Nano voltage regulators will increase. These run quite hot already
with the test bistream so I'm not going to supply a faster one.

Should you compile your own faster/more cores, then additional cooling will be
required (eg point a fan at the board). DO SO AT YOUR OWN RISK!!