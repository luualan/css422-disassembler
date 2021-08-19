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

The disassemblers capabilities:
Below is a table of all of the opcodes that our disassembler can handle.
![image](https://user-images.githubusercontent.com/59902126/130012495-99776d67-42d6-4e04-bd05-7c72850454b2.png)

## Implementation
![image](https://user-images.githubusercontent.com/59902126/130012864-dd061794-551b-4168-94ff-0d2dc3b2a8ef.png)

## Internal Implementation:
In the beginning of our program, it prompts the user for a starting and ending address. The
addresses are converted to ASCII and are stored into address registers if they are even. Also, the
ending address does another check and stores it’s address if it is greater or equal to the starting
address. Once both inputs are stored, the program moves to the START_DECODING function,
which begins it’s operation by jumping to the subroutine called DECODING_ MEMORY.

In DECODING_MEMORY, the program clears the decode buffer, grabs the first nibble of our
current address’s word value, and uses it to jump to a specific code number function inside our
OP_TABLE function. In this function, the program checks specific bits of the current address’s
hex values to determine which opcode to jump to. Once determined, it jumps to one of the
opcode decoder functions. This function stores the opcode instruction text into the decode buffer.
For example, if it jumps to opcode MOVE, it will store the text M O V E into the buffer.

Immediately afterwards, the program stores a EA type variable into the data register called D1,
which tells the program which EA calculation to jump to in the EA_START table. This table is
then called afterwards, which begins the effective address calculation for that given opcode.
In EA_START, we generally begin by finding the size whether it is a byte, word, or long. After
this, we then get the source mode and source register and we check if it is valid or not for a given
op code.

If it is valid, the program then goes to the EA_GEN_TABLE_SRC, which stores the
correct effective address type into the decode buffer. We then check the destination mode and
destination register and complete the same activity. This effective address calculation is also
dependent upon the particular op code. If the source and destination are not valid, we will jump
to EA_ERROR, which will clear the entire buffer except for the current address that we are at.
After this we will store the word DATA and we will then put the current address’s word value
into the decode buffer.

If EA_ERROR is not called, we will then call EA_FINISH, which will jump back to the opcode
decoder function, which will then call OP_FINISH. OP_FINISH will then RTS back to
DECODE_ITERATION, which will first print out the decode buffer by using task #13 from
trap, and then it will check if the ending address has been reached. If it has not, then it will jump
back to DECODE_ITERATION, which will then jump back to DECODE_MEMORY, and this
will clear the buffer and store the next address into D0 to repeat the process over and over again
until the ending address has been reached. 

If the ending address has not been reached, then thelines per screen will be checked and if the lines 
per screen has been met then the user will beprompted to press continue; if not, the execution will 
continue to DECODE_ITERATION. Once the ending address has been reached, the program will prompt the user 
if they would like to continue or not. If the user types y / Y, then they will be prompted to enter another 
starting and ending address, which will be decoded. If they enter n / N, then the program execution will halt
and the program will end.
