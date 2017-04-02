# NISC
A single instruction set processor architecture
This is my first time using Github.
Currently only specifications are given and may be further refined. VHDL code to follow when specs are firm.
## About NISC
NISC is my particular brand of One Instruction Set Computer (OISC) with Transport Triggered Architecture (TTA). The operation it performs is Move.
I call it NISC for Null Instruction Set Computer because the set of all opcodes is the null set.
There is no instruction which tells it to Move. It just Moves.
I didn't want to call it SISC for Single Instruction Set Computer because SISC sounds like CISC and I like to avoid confusion. I also ruled out Mono-Instuction Set Computer (MISC) because I didn't want it filed under Misc.
Although there is no opcode, instructions take two (or three) arguments.
The arguments are source address, destination address, and immediate data.
The source address and destination address are always present but the immediate data is optional.
NISC is an entire family with a scalable architecture.
What will be described is NISC6 because data and addresses are 2 to the 6th power (64 bits). NISC5 has 32 bit data and addresses. 
## The Controller
- There is a state machine which controls overall operation.
- There are 3 registers which are not directly visible to the programmer.
   1. SAR Source Address Register
   2. DAR Destination Address Register
   3. TMP Temporary Register
- Everything else is memory mapped starting at the beginning of memory. There is a single memory space.
- The memory is not byte addressable like many processors. Each address holds 64 bits. It is Little Endian where applicable.
- Peripherals should be memory mapped.
 
This is the VonNewman version with unified code and data address space.
Using a Harvard architecture with separate code and data spaces would double throughput but would require instruction invalidation for Jumps and Calls. I wanted to keep it simple.
Making data and address widths equal allows us to fetch an address in a single cycle. If the data width is less than address width then multiple cycles are needed to fetch an address. With a wider data width, both addresses may be read at once saving a cycle.

The state machine controller normally cycles through 4 states:
 1. Output AP, Fetch Source Address, Increment AP (Argument Pointer, same as a Program Counter)
 2. Output AP, Fetch Destination Address, Increment AP
 3. Read from Source Address into TMP
 4. Write TMP to Destination Address
and then it repeats.

Before it gets to state 1 the machine looks for Int and DMA Requests and will go to other states to acknowledge them. Once state 1 starts Int and DMA Requests will not be accepted again until state 4 finishes. Block instructions also alter this cycle by repeating state 3 and/or state 4 a counted number of times.
