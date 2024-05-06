# Alchitry_Au_test
A program to exercize and test the Alchitry Au Main and I/O boards
Files on github:
	fpga1_top.bin
  fpga_top.xdc
 	Pin_Out.txt
  fpga1_top.vhd
  fpga1_top_uC16.vhd

 MasterControl.asm
 MasterControl.lst
 Opus1_isa.pdf
 Opus1_asm.pdf

fpga_top.xdc
It is the Xilinx Vivado constraints file for the Alchitry Au main board
Bridge and I/O board, the pin-out is fully described in Pin_Out.txt     attached to the project.

Pin_Out.txt
It is a full pin out description for the Alchitry Au main board, the Bridge and I/O boards. Perhaps this will help to create a custom pin-out quicker instead of reverse engineering.

fpga1_top.vhd 
The top file as a reference how I/Os are connected to the hardware.
The fpga1_top_uc16.vhd is the wrapper for the Opus1 16-bit custom processor and also contains the program memory 16kx16 in this case, one or two UARTs for communications to the xTerm or equivalent.
I recommend the use of Tera-Term a nice and easy to use terminal emulator.
The setup to communicate with the processor Opus1-16 on board is:

  baud rate       : 115,200
  data               :  8-bits
  parity            : none
  stop bits        :  1
  flow control : none
  
  Terminal (new line setup):
   receive     : auto
   transmit  : CR

MasterControl.asm  is the assembly code to program  the processor.
I'm attaching also the ISA (Instruction Set Architecture) to have a better idea of the processor capabilities
 
Opus1_ISA.pdf  is the instruction set architecture of the custom 16 bits integer processor
It gives the instructions used in the main program.
As a very important comment/note, the same board can handle up to five processors with inter-communication.
I'll commit that project later if there is enough interest. A multiprocessor design running at 100MHz
 

fpga1_top.bin
The bin file can be loaded using Alchitry program/loader
Connect the Alchitry_au  board USB to a laptop/PC. Verify the FTDI port is recognized by Windows. Check in Device Manager. Download the drivers if needed
 
A basic use of the interface and terminal commands:
Main Menu:

a = Applications
d = monitor and debugger
s = system setup
h = help
v = version number

Application Menu:

w = walking pattern, LEDs on I/O board, enter a 16 bit pattern

s = copy dip switches to LEDs

L = write value to LEDs, format xxL3,L2L1

p = print on xTerm the raw and hexadecimal values of the XADC
    vccint internal 1.0V and 1.8V
    vp/vn needs a circuitry on the bridge board

d = display on 7-seg the temperature of the chip and voltages
    in decimal:
    d=0 degree C, also pressing button right
    d=1 degree F, also pressing button left
    d=2 vccint 1.0V
    d=3 vccint 1.8V

r = read I/O registers, x0100 to x10F
    Outputs
    x0100 = LEDs bank 3 (left)
    x0101 = LEDs bank 2 (center) and bank 1 (right)
    x0102 to x0107 not connected

    Inputs
    x0108 = dip switch bank 3 (left)
    x0109 = dip switches bank 2 (center) and bank 1 (right)
    x010A = push buttons
    x010B = x0103 for test only
    x010C = x0104 for test only
    x010D = x0105 for test only
    x010E = x0106 for test only
    x010F = x0107 for test only

H = display Hours:Minutes on 7-seg the Real Time Clock RTC, must be initialized first in system setup. Also pressing button Up.

M = display Minutes:Seconds on 7-seg the Real Time Clock RTC, must be initialized first in system setup. Also pressing button Down.

h = Help of the current menu

x = Exit to previous menu


System Setup

Y = Enter the current year in decimal
M = Enter current month in decimal
D = Enter 0dDD in decimal, d=week day from 0(Monday) to 6(Sunday)
    DD=date from 1 to 28/29/30 or 31st
    Example 0123 = Tuesday 23rd
H = Enter current time (hours) 24 hours format
U = Enter current time (minutes)
S = Enter seconds

Note: a missing parameter is defaulted to zero, for example:
Enter Y,M,D and H default Minutes and Seconds to zero.

k = prints the entire clock and display H:M on 7-seg

h = Help of the current menu

x = Exit to previous menu

The rest of commands are for more advanced operations
You can experiment different values in debug mode.
