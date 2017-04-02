# NISC
A single instruction set processor architecture  
This is my first time using Github.  
Currently only specifications are given and may be further refined.  
VHDL code to follow when specs are firm.
## About NISC
NISC is my particular brand of One Instruction Set Computer (OISC) with Transport Triggered Architecture (TTA).  
The operation it performs is Move.  
I call it NISC for Null Instruction Set Computer because the set of all opcodes is the null set.  
There is no instruction which tells it to Move. It just Moves.  
It is not related to [No Instruction Set Computing](https://en.wikipedia.org/wiki/No_instruction_set_computing).  
I didn't want to call it SISC for Single Instruction Set Computer because SISC sounds like CISC and I like to avoid confusion. I wasn't sure how to pronounce OISC. I also ruled out Mono-Instuction Set Computer (MISC) because I didn't want it filed under Misc.  
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
- The memory is not byte addressable like many processors. Each address holds a 64 bit Word.
- It is Little Endian where applicable.
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
## Address Definitions
### Overview
Processor addresses start at the beginning of memory.  
ROM is expected at the highest part of memory.  
Peripherals should be mapped following the processor addresses.  
RAM is mapped after the peripherals and before ROM.  
### Processor Addresses
<table>
    <tr>
    <td>Addr</td><td>Width</td><td>Name</td><td>Read</td><td>Write</td><td>DMA Rd</td><td>DMA Wr</td>
    </tr>
<tr>
<td>0000</td><td>64</td><td>AP</td><td>AP</td><td>Jump</td><td>AP</td><td>AP</td>
</tr>
<tr>
<td>0001</td><td>64</td><td>APX</td><td>(AP++)</td><td>Call</td><td>0</td><td>no effect</td>
</tr>
<tr>
<td>0002</td><td>64</td><td>RND</td><td>Random</td><td>Rel Jump</td><td>RND</td><td>no effect</td>
</tr>
<tr>
<td>0003</td><td>64</td><td>CTR</td><td>Count</td><td> Rel Call</td><td>CTR</td><td>no effect</td>
</tr>
<tr>
<td>0004</td><td>64</td><td>IAR</td><td>Int Addr Reg</td><td>Int Addr</td><td>IAR</td><td>IAR</td>
</tr>
<tr>
<td>0005</td><td>64</td><td>ICR</td><td>Int Ctrl Reg</td><td>Int Ctrl Reg</td><td>ICR</td><td>ICR</td>
</tr>
<tr>
<td>0006</td><td>64</td><td>DMACR</td><td>DMA Ctrl Reg</td><td>DMA Ctrl Reg</td><td>DMACR</td><td>DMACR</td>
</tr>
<tr>
<td>0007</td><td>64</td><td>BLKCNT</td><td> BLKCNT Reg</td><td>BLKCNT Reg</td><td>0</td><td>no effect</td>
</tr>
<tr>
<td>0008</td><td>64</td><td>BLKCTRL</td><td>BLKCTRL Reg</td><td> BLKCTRL Reg</td><td>0</td><td>no effect</td>
</tr>
<tr>
<td>0009</td><td>64</td><td>ACC</td><td>ACC</td><td> ACC</td><td> ACC</td><td>ACC</td>
</tr>
<tr>
<td>000A</td><td>64</td><td>AND</td><td>ACC</td><td> TMP AND ACC=>ACC</td><td> ACC</td><td>no effect</td>
</tr>
<tr>
<td>000B</td><td>64</td><td>OR</td><td> ACC</td><td> TMP OR ACC=>ACC</td><td> ACC</td><td> no effect</td>
</tr>
</table>
NOTES:
  1. DMA Read and Write must be different to avoid triggering the TTA effects.
  2. Only the 4 lowest hex digits of address are shown. The high 12 digits are all 0's.
  
