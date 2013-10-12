An Open Source FPGA Blakecoin Miner

This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY;
without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

Project includes code from https://github.com/progranism/Open-Source-FPGA-Bitcoin-Miner
Also http://www.rcis.aist.go.jp/files/special/SASEBO/SHA3-ja/BLAKE.zip which quotes free
license for research purposes, http://www.rcis.aist.go.jp/special/SASEBO/SHA3-en.html

See https://bitcointalk.org/index.php?topic=306894.0 for forum discussion.

Special thanks to fpgaminer for the original bitcoin mining code, teknohog for his
LX150 code, also OrphanedGland, udif, TheSeven, makomk, and newMeat1 as credited on
the fpgaminer bitcoin thread https://bitcointalk.org/index.php?topic=9047.0 and ngzhang
for his Icarus/Lancelot boards and github. Not forgetting bluedragon747 for blakecoin!

The code is at a very early stage of development, but currently achieves around 44MHash/s
on the dual-LX150 lancelot board with 8 cores per fpga, clocked at 50MHz.

Considerable improvement should be possible with additional cores (for which there is
plenty of spare LUT resource, but useage is currently restricted by the need for ISE
build optimisation) and/or altenative pipelining schemes.