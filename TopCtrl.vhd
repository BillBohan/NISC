-- TopCtrl.vhdl
-- Version 2.0
-- Overall Machine State Controller for NISC
-- Word Size = Addr Size for this model
-- Interrupt Control
-- DMA Control
-- 4 cycle and block multi-cycle
-- Fetch Src Addr
-- Fetch Dst Addr
-- Read Src
-- Write Dest

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity TopCtrl is
    Port ( CLK       : in std_logic;      -- System Clock
           Reset_In  : in std_logic;      -- Reset Signal
           Ready     : in std_logic;      -- Ready Signal
           Rept      : in std_logic;      -- Block Repeat (repeats Read and Write)
           UseFSrc   : in std_logic;      -- Use First Source (Reads once and repeats Write)
           BUSRQ     : in std_logic;      -- DMA Bus Request
           INTRQ     : in std_logic;      -- Interrupt Request
           DMA_EN    : in std_logic;      -- DMA Enabled Status
           INT_EN    : in std_logic;      -- Interrupt Enabled Status
           Reset_Out : out std_logic;     -- System Reset
           BUSACK    : out std_logic;     -- Bus Grant Acknowledged
           INTACK    : out std_logic;     -- Interrupt Acknowledged
           Fetch     : out std_logic;     -- Instruction Fetch Cycle
           SorD      : out std_logic;     -- Fetch SrcAddr or DstAddr
           Mem_RD    : out std_logic;     -- Memory Read Cycle
           Mem_WR    : out std_logic);    -- Memory Write Cycle
end TopCtrl;

architecture Behavioral of TopCtrl is

type CycleCtrl_type is (State_Reset, State_BusGrant, State_IntStart, State_IntFinish, State_FetchSA, State_FetchDA, State_SourceRd, State_DestWr);

signal TopState : CycleCtrl_type := State_Reset;

signal reset_i   : std_logic;
signal busack_p  : std_logic;
signal intack_p  : std_logic;
signal fetch_p   : std_logic;
signal Mem_RD_p  : std_logic;
signal Mem_WR_p  : std_logic;
signal ready_i   : std_logic;
signal DMA_EN_i  : std_logic;
signal INT_EN_i  : std_logic;
signal SorD_i    : std_logic;

begin

TopCtrl_State : process (CLK, Reset_In) is

begin
   if rising_edge(CLK) then
      if Reset_In='1' then
         TopState <= State_Reset;
      else
         case TopState is
-- Reset
            when State_Reset =>
               if (Reset_In = '1') then
                  TopState <= State_Reset;
               elsif (BUSRQ = '1' AND DMA_EN_i = '1') then
                  TopState <= State_BusGrant;
               elsif (INTRQ = '1' AND INT_EN_i = '1') then
                  TopState <= State_IntStart;
               else
                  TopState <= State_FetchSA;
               end if;
-- DMA (External)
            when State_BusGrant =>
               if (BUSRQ = '1') then
                        TopState <= State_BusGrant;   -- continue bus grant
               elsif (BUSRQ = '0') then
                  if (INTRQ = '1' AND INT_EN_i = '1') then
                      TopState <= State_IntStart;  -- service interrupt
                  else
                      TopState <= State_FetchSA;  -- resume processing
                  end if; 
               end if;
-- INT
            when State_IntStart =>                -- PC --> Stack
               if (ready_i = '0') then
                  TopState <= State_IntStart;
               elsif (ready_i = '1') then
                  TopState <= State_IntFinish;
               end if;
               
            when State_IntFinish =>               -- ISR Addr --> PC
               if (ready_i = '0') then
                  TopState <= State_IntFinish;
               elsif (ready_i = '1') then
                  if (BUSRQ = '1' AND DMA_EN_i = '1') then
                     TopState <= State_BusGrant;  -- bus grant
                  else
                      TopState <= State_FetchSA;  -- resume processing
                  end if;
               end if;
-- Source Addr Fetch
            when State_FetchSA =>           -- Get Src Addr
               if (ready_i = '0') then
                  TopState <= State_FetchSA;
               elsif (ready_i = '1') then
                  TopState <= State_FetchDA;
               end if;

-- Dest Addr Fetch
            when State_FetchDA =>            -- Get Dest Addr
               if (ready_i = '0') then
                  TopState <= State_FetchDA;
               elsif (ready_i = '1') then
                  TopState <= State_SourceRd;
               end if;
-- Source RD
            when State_SourceRd =>             -- Read from Src Addr
               if (ready_i = '0') then
                  TopState <= State_SourceRd;
               elsif (ready_i = '1') then
                  TopState <= State_DestWr;
               end if;
-- Dest WR
            when State_DestWr =>                 -- Write to Dest Addr
               if (ready_i = '0') then
                  TopState <= State_DestWr;
               elsif (ready_i = '1') then
                  if (Rept = '1') then         -- Block Mode
                     if (UseFSrc = '1') then       -- Block Fill
                        TopState <= State_DestWr;
                     else
                        TopState <= State_SourceRd;
                     end if;
                  elsif (BUSRQ = '1' AND DMA_EN_i = '1') then
                      TopState <= State_BusGrant;
                  elsif (INTRQ = '1' AND INT_EN_i = '1') then
                      TopState <= State_IntStart;
                  else
                      TopState <= State_FetchSA;
                  end if;
               end if;
            when others =>
                    TopState <= State_Reset;
         end case;
      end if;
   end if;
end process;


ready_i <= Ready;
DMA_EN_i <= DMA_EN;
INT_EN_i <= INT_EN;

-- signal assignment statements for combinatorial outputs

reset_i <= '1' when (TopState = State_Reset) else
           '0';

busack_p <= '1' when (TopState = State_BusGrant) else
            '0';

intack_p <=  '1' when (TopState = State_IntStart) else
             '1' when (TopState = State_IntFinish) else
             '0';

fetch_p <= '1' when (TopState = State_FetchSA) or (TopState = State_FetchDA) else
           '0';

SorD_i <= '1' when (TopState = State_FetchDA) else
          '0';

Mem_RD_p <=  '1' when (TopState = State_SourceRd) else
             '0';

Mem_WR_p <= '1' when (TopState = State_DestWr) else
            '1' when (TopState = State_IntStart) else
            '0';

Reset_Out <= reset_i;
BUSACK <= busack_p;
INTACK <= intack_p;
Fetch <= fetch_p;
SorD <= SorD_i;
Mem_RD <= Mem_RD_p;
Mem_WR <= Mem_WR_p;

end Behavioral;
