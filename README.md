# NISC
A single instruction set processor architecture  
This is my first time using Github.  
Currently only specifications are given and may be further refined.  
Suggestions and requests are welcome.  
When I figure out how I would like to list proposals and have a vote on which to implement.  
Implementing this might be a good project for a processor design course.  
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
    <td>Addr</td><td>Width</td><td>Name</td><td>Read</td><td>Write</td><td>DMA Rd</td><td>DMA Wr</td><td>NOTES</td>
    </tr>
<tr>
<td>0000</td><td>64</td><td>AP</td><td>AP</td><td>Jump</td><td>AP</td><td>AP</td><td> </td>
</tr>
<tr>
<td>0001</td><td>64</td><td>APX</td><td>(AP++)</td><td>Call</td><td>0</td><td>no effect</td><td> </td>
</tr>
<tr>
<td>0002</td><td>64</td><td>RND</td><td>Random</td><td>Rel Jump</td><td>RND</td><td>no effect</td><td> </td>
</tr>
<tr>
<td>0003</td><td>64</td><td>CTR</td><td>Count</td><td> Rel Call</td><td>CTR</td><td>no effect</td><td> </td>
</tr>
<tr>
<td>0004</td><td>64</td><td>IAR</td><td>Int Addr Reg</td><td>Int Addr</td><td>IAR</td><td>IAR</td><td> </td>
</tr>
<tr>
<td>0005</td><td>64</td><td>ICR</td><td>Int Ctrl Reg</td><td>Int Ctrl Reg</td><td>ICR</td><td>ICR</td><td> </td>
</tr>
<tr>
<td>0006</td><td>64</td><td>DMACR</td><td>DMA Ctrl Reg</td><td>DMA Ctrl Reg</td><td>DMACR</td><td>DMACR</td><td> </td>
</tr>
<tr>
<td>0007</td><td>64</td><td>BLKCNT</td><td> BLKCNT Reg</td><td>BLKCNT Reg</td><td>0</td><td>no effect</td><td> </td>
</tr>
<tr>
<td>0008</td><td>64</td><td>BLKCTRL</td><td>BLKCTRL Reg</td><td> BLKCTRL Reg</td><td>0</td><td>no effect</td><td> </td>
</tr>
<tr>
<td>0009</td><td>64</td><td>ACC</td><td>ACC</td><td> ACC</td><td> ACC</td><td>ACC</td><td> </td>
</tr>
<tr>
<td>000A</td><td>64</td><td>AND</td><td>CF</td><td> TMP AND ACC=>ACC</td><td>CF</td><td>CF</td><td> </td>
</tr>
<tr>
<td>000B</td><td>64</td><td>OR</td><td>ZF</td><td> TMP OR ACC=>ACC</td><td>ZF</td><td>ZF</td><td> </td>
</tr>
<tr>
<td>000C</td><td>64</td><td>XOR</td><td>BITCNT</td><td> TMP XOR ACC=>ACC</td><td>BITCNT</td><td>BITCNT</td><td> </td>
</tr>
<tr>
<td>000D</td><td>64</td><td>ADD</td><td>BCRZ</td><td> TMP + ACC=>ACC</td><td>BCRZ</td><td>BCRZ</td><td> </td>
</tr>
<tr>
<td>000E</td><td>64</td><td>ADC</td><td>BCRO</td><td> TMP + ACC + C=>ACC</td><td>BCRO</td><td>BCRO</td><td> </td>
</tr>
<tr>
<td>000F</td><td>64</td><td>SUB</td><td>BCLZ</td><td> ACC - TMP=>ACC</td><td>BCLZ</td><td>BCLZ</td><td> </td>
</tr>
<tr>
<td>0010</td><td>64</td><td>SBB</td><td>BCLO</td><td> ACC - TMP - C=>ACC</td><td>BCLO</td><td>BCLO</td><td> </td>
</tr>
<tr>
<td>0011</td><td>64</td><td>Z</td><td>Z/NZ Value</td><td>Z Value</td><td> Z Val</td><td>Z Val</td><td> </td>
</tr>
<tr>
<td>0012</td><td>64</td><td>NZ</td><td> Z/NZ Value</td><td>NZ Value</td><td>NZ Val</td><td> NZ Val</td><td> </td>
</tr>
<tr>
<td>0013</td><td>64</td><td>C</td><td>C/NC Value</td><td>C Value</td><td> C Val</td><td>C Val</td><td> </td>
</tr>
<tr>
<td>0014</td><td>64</td><td>NC</td><td> C/NC Value</td><td>NC Value</td><td>NC Val</td><td> NC Val</td><td> </td>
</tr>
<tr>
<td>0020</td><td>64</td><td>WReg0</td><td>WReg0</td><td> WReg0</td><td> WReg0</td><td>WReg0</td>
</tr>
<tr>
<td>0021</td><td>64</td><td>WReg1</td><td>WReg1</td><td> WReg1</td><td> WReg1</td><td>WReg1</td>
</tr>
<tr>
<td>0022</td><td>64</td><td>WReg2</td><td>WReg2</td><td> WReg2</td><td> WReg2</td><td>WReg2</td>
</tr>
<tr>
<td>0023</td><td>64</td><td>WReg3</td><td>WReg3</td><td> WReg3</td><td> WReg3</td><td>WReg3</td>
</tr>
<tr>
<td>0024</td><td>64</td><td>WReg4</td><td>WReg4</td><td> WReg4</td><td> WReg4</td><td>WReg4</td>
</tr>
<tr>
<td>0025</td><td>64</td><td>WReg5</td><td>WReg5</td><td> WReg5</td><td> WReg5</td><td>WReg5</td>
</tr>
<tr>
<td>0026</td><td>64</td><td>WReg6</td><td>WReg6</td><td> WReg6</td><td> WReg6</td><td>WReg6</td>
</tr>
<tr>
<td>0027</td><td>64</td><td>WReg7</td><td>WReg7</td><td> WReg7</td><td> WReg7</td><td>WReg7</td>
</tr>
<tr>
<td>0028</td><td>64</td><td>WReg8</td><td>WReg8</td><td> WReg8</td><td> WReg8</td><td>WReg8</td>
</tr>
<tr>
<td>0029</td><td>64</td><td>WReg9</td><td>WReg9</td><td> WReg9</td><td> WReg9</td><td>WReg9</td>
</tr>
<tr>
<td>002A</td><td>64</td><td>WRegA</td><td>WRegA</td><td> WRegA</td><td> WRegA</td><td>WRegA</td>
</tr>
<tr>
<td>002B</td><td>64</td><td>WRegB</td><td>WRegB</td><td> WRegB</td><td> WRegB</td><td>WRegB</td>
</tr>
<tr>
<td>002C</td><td>64</td><td>WRegC</td><td>WRegC</td><td> WRegC</td><td> WRegC</td><td>WRegC</td>
</tr>
<tr>
<td>002D</td><td>64</td><td>WRegD</td><td>WRegD</td><td> WRegD</td><td> WRegD</td><td>WRegD</td>
</tr>
<tr>
<td>002E</td><td>64</td><td>WRegE</td><td>WRegE</td><td> WRegE</td><td> WRegE</td><td>WRegE</td>
</tr>
<tr>
<td>002F</td><td>64</td><td>WRegF</td><td>WRegF</td><td> WRegF</td><td> WRegF</td><td>WRegF</td>
</tr>
</table>

NOTES:
1. DMA Read and Write must be different to avoid triggering the TTA effects.
2. Only the 4 lowest hex digits of address are shown. The high 12 digits are all 0's.
3. Addresses not shown (skipped) are undefined and should Read as 0. Write should have no effect.
