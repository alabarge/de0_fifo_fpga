library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_top is
   generic (
      C_DWIDTH             : integer              := 32;
      C_NUM_REG            : integer              := 9
   );
   port (
      clk                  : in    std_logic;
      reset_n              : in    std_logic;
      irq                  : out   std_logic;
      read_n               : in    std_logic;
      write_n              : in    std_logic;
      address              : in    std_logic_vector(10 downto 0);
      readdata             : out   std_logic_vector(31 downto 0);
      writedata            : in    std_logic_vector(31 downto 0);
      m1_read              : out   std_logic;
      m1_rd_address        : out   std_logic_vector(31 downto 0);
      m1_readdata          : in    std_logic_vector(31 downto 0);
      m1_rd_waitreq        : in    std_logic;
      m1_rd_burstcount     : out   std_logic_vector(8 downto 0);
      m1_rd_datavalid      : in    std_logic;
      head_addr            : in    std_logic_vector(15 downto 0);
      tail_addr            : out   std_logic_vector(15 downto 0);
      clkin                : in    std_logic;
      dat                  : inout std_logic_vector(7 downto 0);
      rxf_n                : in    std_logic;
      txe_n                : in    std_logic;
      rd_n                 : out   std_logic;
      wr_n                 : out   std_logic;
      oe_n                 : out   std_logic;
      siwu_n               : out   std_logic;
      pwrsav_n             : out   std_logic;
      test_bit             : out   std_logic;
      debug                : out   std_logic_vector(3 downto 0)
   );
end entity sync_top;

architecture rtl of sync_top is

--
-- SIGNAL DECLARATIONS
--
   signal sync_CONTROL     : std_logic_vector(31 downto 0);
   signal sync_INT_REQ     : std_logic_vector(4 downto 0);
   signal sync_INT_ACK     : std_logic_vector(4 downto 0);
   signal sync_STATUS      : std_logic_vector(31 downto 0);
   signal sync_ADR_BEG     : std_logic_vector(31 downto 0);
   signal sync_ADR_END     : std_logic_vector(31 downto 0);
   signal sync_PKT_CNT     : std_logic_vector(31 downto 0);
   signal sync_PKT_XFER    : std_logic_vector(7 downto 0);
   signal syncInt          : std_logic_vector(4 downto 0);

   signal cpu_DIN          : std_logic_vector(31 downto 0);
   signal cpu_DOUT         : std_logic_vector(31 downto 0);
   signal cpu_ADDR         : std_logic_vector(9 downto 0);
   signal cpu_RE           : std_logic;
   signal cpu_WE           : std_logic;

--
-- MAIN CODE
--
begin

   --
   -- REGISTER FILE
   --
   FIFO_REGS_I: entity work.sync_regs
   generic map (
      C_DWIDTH             => C_DWIDTH,
      C_NUM_REG            => C_NUM_REG
   )
   port map (
      clk                  => clk,
      reset_n              => reset_n,
      read_n               => read_n,
      write_n              => write_n,
      address              => address,
      readdata             => readdata,
      writedata            => writedata,
      cpu_DIN              => cpu_DIN,
      cpu_DOUT             => cpu_DOUT,
      cpu_ADDR             => cpu_ADDR,
      cpu_RE               => cpu_RE,
      cpu_WE               => cpu_WE,
      sync_CONTROL         => sync_CONTROL,
      sync_INT_REQ         => sync_INT_REQ,
      sync_INT_ACK         => sync_INT_ACK,
      sync_STATUS          => sync_STATUS,
      sync_ADR_BEG         => sync_ADR_BEG,
      sync_ADR_END         => sync_ADR_END,
      sync_PKT_CNT         => sync_PKT_CNT,
      sync_PKT_XFER        => sync_PKT_XFER,
      sync_TEST_BIT        => test_bit
   );

   --
   -- 245 FIFO STATE MACHINE
   --
   FIFO_CTL_I: entity work.sync_ctl
   port map (
      clk                  => clk,
      reset_n              => reset_n,
      m1_read              => m1_read,
      m1_rd_address        => m1_rd_address,
      m1_readdata          => m1_readdata,
      m1_rd_waitreq        => m1_rd_waitreq,
      m1_rd_burstcount     => m1_rd_burstcount,
      m1_rd_datavalid      => m1_rd_datavalid,
      cpu_DIN              => cpu_DIN,
      cpu_DOUT             => cpu_DOUT,
      cpu_ADDR             => cpu_ADDR,
      cpu_RE               => cpu_RE,
      cpu_WE               => cpu_WE,
      sync_CONTROL         => sync_CONTROL,
      sync_STATUS          => sync_STATUS,
      sync_ADR_BEG         => sync_ADR_BEG,
      sync_ADR_END         => sync_ADR_END,
      sync_PKT_CNT         => sync_PKT_CNT,
      sync_PKT_XFER        => sync_PKT_XFER,
      sync_int             => syncInt,
      head_addr            => head_addr,
      tail_addr            => tail_addr,
      clkin                => clkin,
      dat                  => dat,
      rxf_n                => rxf_n,
      txe_n                => txe_n,
      rd_n                 => rd_n,
      wr_n                 => wr_n,
      oe_n                 => oe_n,
      siwu_n               => siwu_n,
      pwrsav_n             => pwrsav_n,
      debug                => debug
   );

   --
   -- INTERRUPTS
   --
   FIFO_IRQ_I: entity work.sync_irq
   generic map (
      C_NUM_INT            => 5
   )
   port map (
      clk                  => clk,
      reset_n              => reset_n,
      int_req              => sync_INT_REQ,
      int_ack              => sync_INT_ACK,
      int                  => syncInt,
      irq                  => irq
   );

end rtl;
