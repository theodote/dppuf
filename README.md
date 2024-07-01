# dppuf
This repository containts source files for the dPPUF experiment replication.

# HDL files and XDC constraints

`dppuf0.vhd` is an example generated dPPUF. All `.vhd` files should be imported as source files.

`Zedboard-Master.xdc` should be imported and *copied* as a constraint.

[Sara Fagin](https://youtu.be/aPDT0sPr4jE) has a great introductory tutorial on creating an HDL-only project in Vivado. [Dom](https://youtu.be/_odNhKOZjEo) has a great [two-part](https://youtu.be/AOy5l36DroY) tutorial on connecting the PS and PL sides in Vivado and its SDK.

# C application
[Phil's Lab #98](https://youtu.be/cmS0J4ZFhv4) shows the procedure of creating a composite ZYNQ application and uploading it to the on-board QSPI flash memory. The order of Boot image partitions is crucial, and should be as such (top to bottom):

1. FSBL (bootloader) [.elf]
2. FPGA bitstream [.bit]
3. Custom application (`helloworld.c`) [.elf]

**< ! >** Make sure to configure the Zedboard's mode jumpers properly before booting the board:

`[,,,,,]` for uploading to QSPI over JTAG

`[,',,,]` for loading and booting from QSPI

[The Zynq Book](http://www.zynqbook.com/) is a great reference material on Zedboard and the Zynq-7000 SoC. 

# Python scripts

The dependencies for the Python scripts are:

- PySerial
- NumPy
- MatPlotLib
- Pyperclip (can be omitted by choosing to save files instead of copying them to clipboard)