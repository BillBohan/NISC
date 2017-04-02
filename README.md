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
<td>0000</td><td>64</td><td>AP</td><td>AP</td><td>Jump</td><td>AP</td><td>AP</td><td>4</td>
</tr>
<tr>
<td>0001</td><td>64</td><td>APX</td><td>(AP++)</td><td>Call</td><td>0</td><td>no effect</td><td>5</td>
</tr>
<tr>
<td>0002</td><td>64</td><td>RND</td><td>Random</td><td>Rel Jump</td><td>RND</td><td>no effect</td><td>6</td>
</tr>
<tr>
<td>0003</td><td>64</td><td>CTR</td><td>Count</td><td> Rel Call</td><td>CTR</td><td>no effect</td><td>7</td>
</tr>
<tr>
<td>0004</td><td>64</td><td>IAR</td><td>Int Addr Reg</td><td>Int Addr</td><td>IAR</td><td>IAR</td><td>8, 9</td>
</tr>
<tr>
<td>0005</td><td>64</td><td>ICR</td><td>Int Ctrl Reg</td><td>Int Ctrl Reg</td><td>ICR</td><td>ICR</td><td>10</td>
</tr>
<tr>
<td>0006</td><td>64</td><td>DMACR</td><td>DMA Ctrl Reg</td><td>DMA Ctrl Reg</td><td>DMACR</td><td>DMACR</td><td>11</td>
</tr>
<tr>
<td>0007</td><td>64</td><td>BLKCNT</td><td> BLKCNT Reg</td><td>BLKCNT Reg</td><td>0</td><td>no effect</td><td>12</td>
</tr>
<tr>
<td>0008</td><td>64</td><td>BLKCTRL</td><td>BLKCTRL Reg</td><td> BLKCTRL Reg</td><td>0</td><td>no effect</td><td>13</td>
</tr>
<tr>
<td>0009</td><td>64</td><td>ACC</td><td>ACC</td><td> ACC</td><td> ACC</td><td>ACC</td><td>14</td>
</tr>
<tr>
<td>000A</td><td>64</td><td>AND</td><td>CF</td><td> TMP AND ACC=>ACC</td><td>CF</td><td>CF</td><td>15, 18</td>
</tr>
<tr>
<td>000B</td><td>64</td><td>OR</td><td>ZF</td><td> TMP OR ACC=>ACC</td><td>ZF</td><td>ZF</td><td>16, 18</td>
</tr>
<tr>
<td>000C</td><td>64</td><td>XOR</td><td>BITCNT</td><td> TMP XOR ACC=>ACC</td><td>BITCNT</td><td>BITCNT</td><td>17, 18</td>
</tr>
<tr>
<td>000D</td><td>64</td><td>ADD</td><td>BCRZ</td><td> TMP + ACC=>ACC</td><td>BCRZ</td><td>BCRZ</td><td>19</td>
</tr>
<tr>
<td>000E</td><td>64</td><td>ADC</td><td>BCRO</td><td> TMP + ACC + C=>ACC</td><td>BCRO</td><td>BCRO</td><td>20</td>
</tr>
<tr>
<td>000F</td><td>64</td><td>SUB</td><td>BCLZ</td><td> ACC - TMP=>ACC</td><td>BCLZ</td><td>BCLZ</td><td>21</td>
</tr>
<tr>
<td>0010</td><td>64</td><td>SBB</td><td>BCLO</td><td> ACC - TMP - C=>ACC</td><td>BCLO</td><td>BCLO</td><td>22</td>
</tr>
<tr>
<td>0011</td><td>64</td><td>C</td><td>C/NC Value</td><td>C Value</td><td> C Val</td><td>C Val</td><td>23 </td>
</tr>
<tr>
<td>0012</td><td>64</td><td>NC</td><td> C/NC Value</td><td>NC Value</td><td>NC Val</td><td> NC Val</td><td>24 </td>
</tr>
<tr>
<td>0013</td><td>64</td><td>Z</td><td>Z/NZ Value</td><td>Z Value</td><td> Z Val</td><td>Z Val</td><td>25</td>
</tr>
<tr>
<td>0014</td><td>64</td><td>NZ</td><td> Z/NZ Value</td><td>NZ Value</td><td>NZ Val</td><td> NZ Val</td><td>26</td>
</tr>
<tr>
<td> </td><td> </td><td> </td><td> </td><td> </td><td> </td><td> </td><td> </td>
</tr>
<tr>
<td>0020</td><td>64</td><td>WReg0</td><td>WReg0</td><td> WReg0</td><td> WReg0</td><td>WReg0</td><td>27</td>
</tr>
<tr>
<td>0021</td><td>64</td><td>WReg1</td><td>WReg1</td><td> WReg1</td><td> WReg1</td><td>WReg1</td><td>27</td>
</tr>
<tr>
<td>0022</td><td>64</td><td>WReg2</td><td>WReg2</td><td> WReg2</td><td> WReg2</td><td>WReg2</td><td>27</td>
</tr>
<tr>
<td>0023</td><td>64</td><td>WReg3</td><td>WReg3</td><td> WReg3</td><td> WReg3</td><td>WReg3</td><td>27</td>
</tr>
<tr>
<td>0024</td><td>64</td><td>WReg4</td><td>WReg4</td><td> WReg4</td><td> WReg4</td><td>WReg4</td><td>27</td>
</tr>
<tr>
<td>0025</td><td>64</td><td>WReg5</td><td>WReg5</td><td> WReg5</td><td> WReg5</td><td>WReg5</td><td>27</td>
</tr>
<tr>
<td>0026</td><td>64</td><td>WReg6</td><td>WReg6</td><td> WReg6</td><td> WReg6</td><td>WReg6</td><td>27</td>
</tr>
<tr>
<td>0027</td><td>64</td><td>WReg7</td><td>WReg7</td><td> WReg7</td><td> WReg7</td><td>WReg7</td><td>27</td>
</tr>
<tr>
<td>0028</td><td>64</td><td>WReg8</td><td>WReg8</td><td> WReg8</td><td> WReg8</td><td>WReg8</td><td>27</td>
</tr>
<tr>
<td>0029</td><td>64</td><td>WReg9</td><td>WReg9</td><td> WReg9</td><td> WReg9</td><td>WReg9</td><td>27</td>
</tr>
<tr>
<td>002A</td><td>64</td><td>WRegA</td><td>WRegA</td><td> WRegA</td><td> WRegA</td><td>WRegA</td><td>27</td>
</tr>
<tr>
<td>002B</td><td>64</td><td>WRegB</td><td>WRegB</td><td> WRegB</td><td> WRegB</td><td>WRegB</td><td>27</td>
</tr>
<tr>
<td>002C</td><td>64</td><td>WRegC</td><td>WRegC</td><td> WRegC</td><td> WRegC</td><td>WRegC</td><td>27</td>
</tr>
<tr>
<td>002D</td><td>64</td><td>WRegD</td><td>WRegD</td><td> WRegD</td><td> WRegD</td><td>WRegD</td><td>27</td>
</tr>
<tr>
<td>002E</td><td>64</td><td>WRegE</td><td>WRegE</td><td> WRegE</td><td> WRegE</td><td>WRegE</td><td>27</td>
</tr>
<tr>
<td>002F</td><td>64</td><td>WRegF</td><td>WRegF</td><td> WRegF</td><td> WRegF</td><td>WRegF</td><td>27</td>
</tr>
</table>

NOTES:
1. DMA Read and Write must be different to avoid triggering the TTA effects.
2. Only the 4 lowest hex digits of address are shown. The high 12 digits are all 0's.
3. Addresses not shown (skipped) are undefined and should Read as 0. Write should have no effect.
4. Argument Pointer is the same as a Program Counter.
5. Reading APX reads from memory pointed to by AP and increments AP. Writing APX pushes AP onto the stack and loads AP (Call).
6. RND is an LFSR (Read only) which shifts on each clock. Writing adds to AP (Relative Jump).
7. CTR is an up-counter incremented on every clock. Writing CTR pushes AP onto the stack and adds to AP (Relative Call).
8. Interrupt Address Register holds the address of the ISR (Interrupt Service Routine) called during Interrupt Acknowledge.
9. Only one interrupt is implemented in processor. External interrupt controller may expand this.
10. Interrupt Control Register is a work in progress. Enable/Disable Bit is a minimum.
11. DMA Control defaults to enabled and can be used for debugging, allowing a single processor cycle then reading all registers.
12. BLKCNT is a counter with the number of times to repeat an instruction, counts after Write cycle when enabled.
13. BLKCTRL controls block operation. When loaded, the next instruction is a block instruction.
  - Bit 0 - Setting this bit starts a Block Instruction
  - Bit 1 - 0 = decrement Block Counter, 1 = increment Block Counter
  - Bit 2 - 1 = increment SAR
  - Bit 3 - 1 = decrement SAR, when Bit 2 and Bit 3 are the same SAR is unchanged
  - Bit 4 - 1 = increment DAR
  - Bit 5 - 1 = decrement DAR, when Bit 4 and Bit 5 sre the same DAR is unchanged
  - Bit 6 - 1 = read only once, write using same data. Bits 2 and 3 are ignored. Typically used for block fill.
14. Accumulator is affected by writes to this and the following 7 addresses.
15. Write to AND causes data to be ANDed with ACC. Reading returns CF (Carry Flag).
16. Write to OR causes data to be ORed with ACC. Reading returns ZF (Zero Flag).
17. Write to XOR causes data to be XORed with ACC. Reading returns BITCNT (Count of set bits in ACC) from 0 to 64.
18. Write clears Carry Flag. Zero Flag is set if all ACC bits are zero, cleared otherwise.
19. Write to ADD adds data to ACC. CF and ZF are adjusted appropriately. BCRZ is bit count from right (LSB) to first zero.
20. Write to ACD adds data and CF to ACC. CF and ZF are adjusted. BCRO is bit count from right to first 1 (0 to 64).
21. Write to SUB subtracts data from ACC. CF and ZF are adjusted. BCLZ is bit count from left (MSB) to first zero.
22. Write to SBB subtracts data and CF from ACC. CF and ZF are adjusted. BCLZ is bit count from left to first 1 bit.
23. Write to C sets the value returned when reading either C or NC if CF is set when reading.
24. Write to NC sets the value returned when reading either C or NC if CF is clear when reading.
25. Write to Z sets the value returned when reading either Z or NZ if ZF is set when reading.
26. Write to NZ sets the value returned when reading either Z or NZ if ZF is clear when reading.
27. Working Registers. These 16 registers do nothing special. They are just like RAM except they never generate wait states.
