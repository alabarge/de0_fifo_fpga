library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library std;
use std.textio.all;

use work.pck_fio.all;
use work.pck_tb.all;

-- Test Bench Entity
entity ftdi_fifo_TB is
end ftdi_fifo_TB;

architecture tb_arch of ftdi_fifo_TB is

-- 32-Bit Control Register
signal fifo_CONTROL     : std_logic_vector(31  downto 0) := X"00000000";
alias  xl_TX_HEAD       : std_logic_vector(1 downto 0) is fifo_CONTROL(1 downto 0);
alias  xl_RX_TAIL       : std_logic_vector(1 downto 0) is fifo_CONTROL(3 downto 2);
alias  xl_BYPASS        : std_logic is fifo_CONTROL(25);
alias  xl_PIPE_INT      : std_logic is fifo_CONTROL(26);
alias  xl_RX_INT        : std_logic is fifo_CONTROL(27);
alias  xl_TX_INT        : std_logic is fifo_CONTROL(28);
alias  xl_PIPE_RUN      : std_logic is fifo_CONTROL(29);
alias  xl_FIFO_RUN      : std_logic is fifo_CONTROL(30);
alias  xl_ENABLE        : std_logic is fifo_CONTROL(31);

-- Stimulus signals - signals mapped to the input and inout ports of tested entity
signal clk                 : std_logic := '0';
signal reset_n             : std_logic := '0';
signal m1_rd_waitreq       : std_logic := '0';
signal m1_readdata         : std_logic_vector(31 downto 0);
signal m1_rd_datavalid     : std_logic := '1';
signal read_n              : std_logic := '1';
signal write_n             : std_logic := '1';
signal address             : std_logic_vector(10 downto 0) := "000" & X"00";
signal writedata           : std_logic_vector(31 downto 0) := X"00000000";
signal rxf_n               : std_logic := '1';
signal txe_n               : std_logic := '1';
signal dat                 : std_logic_vector(7 downto 0) := X"00";
signal clkin               : std_logic := '0';

-- Observed signals - signals mapped to the output ports of tested entity
signal m1_read             : std_logic;
signal m1_rd_address       : std_logic_vector(31 downto 0);
signal m1_rd_burstcount    : std_logic_vector(8 downto 0);
signal readdata            : std_logic_vector(31 downto 0);
signal irq                 : std_logic;
signal rd_n                : std_logic;
signal wr_n                : std_logic;
signal oe_n                : std_logic;
signal siwu_n              : std_logic;
signal pwrsav_n            : std_logic;
signal test_bit            : std_logic;
signal debug               : std_logic_vector(3 downto 0);

signal clk60M_mask         : std_logic := '0';

-- constants
constant C_CLK_100M:       TIME :=  10.000 ns;    -- 100 MHz
constant C_CLK_60M:        TIME :=  16.666 ns;    --  60 MHz

begin

   --
   -- Unit Under Test
   --
   FIFO_TOP_I : entity work.fifo_top
   port map (
      -- Avalon Memory-Mapped Slave
      clk                  => clk,
      reset_n              => reset_n,
      irq                  => irq,
      -- Avalon Memory-Mapped Slave
      read_n               => read_n,
      write_n              => write_n,
      address              => address,
      readdata             => readdata,
      writedata            => writedata,
      -- Avalon Memory-Mapped Read Master
      m1_read              => m1_read,
      m1_rd_waitreq        => m1_rd_waitreq,
      m1_rd_address        => m1_rd_address,
      m1_readdata          => m1_readdata,
      m1_rd_burstcount     => m1_rd_burstcount,
      m1_rd_datavalid      => m1_rd_datavalid,
      -- Memory Head-Tail Pointers
      head_addr            => X"0000",
      tail_addr            => open,
      -- Exported Signals
      clkin                => clkin,
      dat                  => dat,
      rxf_n                => rxf_n,
      txe_n                => txe_n,
      rd_n                 => rd_n,
      wr_n                 => wr_n,
      oe_n                 => oe_n,
      siwu_n               => siwu_n,
      pwrsav_n             => pwrsav_n,
      test_bit             => test_bit,
      debug                => debug
   );

   --
   -- Clocks
   --

   --
   -- 100 MHZ
   --
   process begin
      clk <= '1';
      wait for C_CLK_100M/2;
      clk <= '0';
      wait for C_CLK_100M/2;
   end process;

   --
   -- Hold-Off 60M Clock
   --
   process begin
      clk60M_mask <= '0';
      wait for 500*C_CLK_100M;
      clk60M_mask <= '1';
      wait for 1200 us;
      clk60M_mask <= '0';
      wait for 500*C_CLK_100M;
      clk60M_mask <= '1';
      wait;
   end process;

   --
   -- 60 MHZ
   --
   process begin
      clkin <= '1' and clk60M_mask;
      wait for C_CLK_60M/2;
      clkin <= '0';
      wait for C_CLK_60M/2;
   end process;

   --
   -- Reset
   --
   process begin
      reset_n <= '0';
      wait for 10*C_CLK_100M;
      reset_n <= '1';
      wait;
   end process;

   --
   -- Main Process
   --
   process

   procedure BUS_WR(addr: in std_logic_vector(10 downto 0);
                    data: in std_logic_vector(31 downto 0)) is
   begin
      wait until rising_edge(clk);
      wait for (1 ns);
      write_n     <= '0';
      address     <= addr(10 downto 0);
      writedata   <= data;
      wait until rising_edge(clk);
      wait for (1 ns);
      write_n     <= '1';
      address     <= (others => '0');
      writedata   <= (others => '0');
   end;

   procedure BUS_RD(addr: in std_logic_vector(10 downto 0)) is
   begin
      wait until rising_edge(clk);
      wait for (1 ns);
      read_n      <= '0';
      address     <= addr(10 downto 0);
      wait until rising_edge(clk);
      wait for (1 ns);
      read_n      <= '1';
      address     <= (others => '0');
   end;


   begin

      wait until reset_n = '1';

      -- Enable module
      xl_ENABLE       <= '1';
      BUS_WR("000" & X"00", fifo_CONTROL);  -- CONTROL
      wait for 100 ns;

      -- Register Setup
      xl_TX_HEAD      <= "00";
      xl_RX_TAIL      <= "00";
      xl_RX_INT       <= '1';
      xl_FIFO_RUN     <= '1';
      BUS_WR("000" & X"04", X"03000000");   -- ADDRESS BEGIN
      BUS_WR("000" & X"05", X"03007FFF");   -- ADDRESS END
      BUS_WR("000" & X"06", X"00000001");   -- BLOCK COUNT, 8 PACKETS
      BUS_WR("000" & X"00", fifo_CONTROL);  -- CONTROL

      BUS_RD("000" & X"01");                -- VERSION

      wait;

   end process;

end tb_arch;

