# CSS422-Disassembler
This program is an inverse assembler (disassembler) that's written in Motorola 68000 Assembly Language.
It's purpose is to convert blocks of data back to Assembly code and display this code to the user.

## How to run the Disassembler
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

##Result
![image](https://user-images.githubusercontent.com/59902126/130018452-ccc3ffff-17ac-493a-b3f6-cd1230f8a654.png)


## The Disassembler's Capabilities:
Below is a table of all of the opcodes that our disassembler can handle.
![image](https://user-images.githubusercontent.com/59902126/130013331-9d1ba984-0bf9-44f8-82dc-a3193bb62fd6.png)

## Flow Diagram
![image](https://user-images.githubusercontent.com/59902126/130013644-1ee76e3b-0d85-4f05-8cc4-327c6134c4bb.png)

## Team Assignments
We worked on a majority of the disassembler jointly in person and spend most of the time
coding side by side working on the parts that we divided up upon one another. We pair coded for
some of the sections that were difficult and would ask one another questions if we were stuck on
a given part of the assignment.

Together:
- Implemented the ATOI and ITOA
- Store the starting and ending address
- Implemented effective calculations ea_move
- Took care of the error handling for the corresponding EA calculations that each of us
implemented

Avery:
- Implemented the welcome message and the starting and ending address prompts
- Implemented the decode_memory, start_decoding, and decoding_iteration
- Implemented the code to continue the program or end it
- Validate the starting and ending address
- Printed out all of the opcodes
- Did the extra credit for all of the Bcc Opcodes
- Implemented the EA calculation for ea_type_branch, ea_type_quick, ea_type_lea
- ea_type_movem, ea_type_move

Alan:
- Set up the process for starting the effective calculations
- Implemented the EA calculations for ea_immediate and ea_dstonly
- Created an ea_type_ext_table that handled all of the opcodes with an opmode
- Implemented the EA calculations for ea_shifts, ea_ext, and ea_movea
- Implemented the print outs for the given src and dst modes and registers
- Implemented helper functions for the EA_calculations
- Did the majority of the opcode decoding and the JMP tables
- Did a majority of setting up the error handling
