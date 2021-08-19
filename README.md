# CSS422-Project
Implemented a disassembler for Easy68k.

## How to run the disassembler
The first screen that you will see when you run the program:
![image](https://user-images.githubusercontent.com/59902126/130011252-7645548b-3879-4dcd-9ec3-5e38354836cd.png)

When assembling the Disassembler.X68 source code, press execute and then click file -> open 
data in the Disassembler.S68 to place the desired testfile.X68 into memory. Our program is
ORG’d at $1000 so the test file must be stored between 00000000 and 00000998 so that the
memory of our existing Disassembler.X68 is not overwritten. Once the test file has been stored,
click run and enter the address range that is desired to test, not putting zeros in front of the
desired address for example if you want to test 00000400 - 00000512 enter 400 for the starting
address and 512 for the ending address. If there are alphabet hex characters in the starting or
ending address (A-F) they must be capitalized to be considered valid. If you enter a lowercase
for (A-F) you will be prompted to re-enter either the starting or ending address accordingly.

Once the disassembler begins printing the buffer to the screen and the screen fills, you will be
prompted to press enter to continue visualizing the output. Once the program has reached the
ending address and completed the opcodes and effective address calculations, you will be
prompted to either end the program or continue using the keyboard input (y/n) for yes or no. If
you choose yes, the program will prompt the user for another starting and ending address. If you
choose no, the program will exit.

## The disassemblers capabilities:
Below is a table of all of the opcodes that our disassembler can handle.
![image](https://user-images.githubusercontent.com/59902126/130013331-9d1ba984-0bf9-44f8-82dc-a3193bb62fd6.png)


## Implementation
![image](https://user-images.githubusercontent.com/59902126/130013644-1ee76e3b-0d85-4f05-8cc4-327c6134c4bb.png)
