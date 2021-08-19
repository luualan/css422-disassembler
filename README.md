# CSS422-Disassembler
This program is an inverse assembler (disassembler) that's written in Motorola MC68000 Assembly 
Language. It's purpose is to convert blocks of data back to Assembly code and display this code 
to the user.

## How to run the Disassembler
The first screen that you will see when you run the program:
![image](https://user-images.githubusercontent.com/59902126/130018824-2b0f7561-e8b9-45b2-84f0-5ecee2e36afa.png)

When assembling the Disassembler.X68 source code, press execute and then click file -> open 
data in the Disassembler.S68 to place the desired test_file.S68 into memory. Our program is
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

## Result
![image](https://user-images.githubusercontent.com/59902126/130018596-28cc5827-b197-4c59-85cc-0f67c4385d12.png)

## The Disassembler's Capabilities:
Below is a table of all of the opcodes that our disassembler can handle.

| ------------- | ------------- |
| Content Cell  | Content Cell  |
| Content Cell  | Content Cell  |




## Flow Diagram
![image](https://user-images.githubusercontent.com/59902126/130013644-1ee76e3b-0d85-4f05-8cc4-327c6134c4bb.png)

## Testing
How we tested our disassembler:
When we implemented each of our effective address calculations for our opcodes, we tested each
effective address type that is permitted for our opcodes in the source operand and destination
operand. This involved using all eight of the effective address types: data register direct, address
register direct, address register indirect, address register indirect with post increment, address
register indirect with pre decrement, immediate addressing, absolute word, and absolute long in
our operands.

As a result, we generated many different combinations of operands for our opcodes and tested if
they worked for the instructions. We created these instructions in separate test files and ran them
in our disassembler program by selecting open data and loading our test files. Once they worked
for the scenarios we came up with, this indicated that we were permitted to move on to
implementing the next effective address calculation we were each assigned. Eventually, we
completed all our effective address calculations and we moved on to testing the professor’s test
file.

We tested the file called Test_dsasm.X68, and checked each address line of opcode to be certain
our outputs matched the professor’s disassembler outputs. We had some outputs that didn’t
match — specifically movem and all the branch types, so we went back to our disassembler code
and fixed those issues. After much time spent fixing our disassembler code, we got our code to
match the professor’s outputs for required opcodes and the extra credit for all branch types.
We then tested our dissassembler’s error handler. The objective was to ensure our error handler
was doing what it was designed to do. This meant our program doesn’t take odd starting or
ending addresses, the ending address doesn’t start decoding when it’s less than starting address,
and our program outputs an error message when decoding illegal instructions. This took some
time to fix, but eventually, we got the error handler to work properly.

Next, we tested our disassembler for bugs. We made a test file for the MOVE opcode. This
involved storing an address register into our destination operand for our MOVE instruction. The
goal was to ensure our disassembler handled this error by outputting the MOVEA opcode instead
of MOVE. As a result, we were successful in doing this. We also put 800 lines of random
opcodes and ran our disassembler to see if it could handle disassembling all those instructions.
Our disassembler handled this well and didn’t output anything irregular.

## Work Allocation
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

Alan:
- Set up the process for starting the effective calculations
- Implemented the EA calculations for ea_immediate and ea_dstonly
- Created an ea_type_ext_table that handled all of the opcodes with an opmode
- Implemented the EA calculations for ea_shifts, ea_ext, and ea_movea
- Implemented the print outs for the given src and dst modes and registers
- Implemented helper functions for the EA_calculations
- Did the majority of the opcode decoding and the JMP tables
- Did a majority of setting up the error handling

Avery:
- Implemented the welcome message and the starting and ending address prompts
- Implemented the decode_memory, start_decoding, and decoding_iteration
- Implemented the code to continue the program or end it
- Validate the starting and ending address
- Printed out all of the opcodes
- Did the extra credit for all of the Bcc Opcodes
- Implemented the EA calculation for ea_type_branch, ea_type_quick, ea_type_lea
- ea_type_movem, ea_type_move
