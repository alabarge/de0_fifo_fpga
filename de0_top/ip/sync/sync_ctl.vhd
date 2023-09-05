library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sync_ctl is
   port (
      clk                  : in    std_logic;
      reset_n              : in    std_logic;
      m1_read              : out   std_logic;
      m1_rd_address        : out   std_logic_vector(31 downto 0);
      m1_readdata          : in    std_logic_vector(31 downto 0);
      m1_rd_waitreq        : in    std_logic;
      m1_rd_burstcount     : out   std_logic_vector(8 downto 0);
      m1_rd_datavalid      : in    std_logic;
      cpu_DIN              : out   std_logic_vector(31 downto 0);
      cpu_DOUT             : in    std_logic_vector(31 downto 0);
      cpu_ADDR             : in    std_logic_vector(9 downto 0);
      cpu_RE               : in    std_logic;
      cpu_WE               : in    std_logic;
      head_addr            : in    std_logic_vector(15 downto 0);
      tail_addr            : out   std_logic_vector(15 downto 0);
      sync_CONTROL         : in    std_logic_vector(31 downto 0);
      sync_ADR_BEG         : in    std_logic_vector(31 downto 0);
      sync_ADR_END         : in    std_logic_vector(31 downto 0);
      sync_PKT_CNT         : in    std_logic_vector(31 downto 0);
      sync_PKT_XFER        : in    std_logic_vector(7 downto 0);
      sync_STATUS          : out   std_logic_vector(31 downto 0);
      sync_DEBUG           : out   std_logic_vector(31 downto 0);
      sync_int             : out   std_logic_vector(4 downto 0);
      clkin                : in    std_logic;
      dat                  : inout std_logic_vector(7 downto 0);
      rxf_n                : in    std_logic;
      txe_n                : in    std_logic;
      rd_n                 : out   std_logic;
      wr_n                 : out   std_logic;
      oe_n                 : out   std_logic;
      siwu_n               : out   std_logic;
      pwrsav_n             : out   std_logic;
      debug                : out   std_logic_vector(3 downto 0)
   );
end sync_ctl;

architecture rtl of sync_ctl is

--
-- TYPES
--
type   rd_state_t is (IDLE, WAIT_PKT, WAIT_SLOT, CYCLE_CHK, REQ, SLOT);
type   ft_state_t is (IDLE, FLUSH, WAIT_REQ, RX_CTL, RX_USB, RX_DELAY, TX_CTL, TX_USB,
                      TX_CHECK, TX_DELAY, PIPE_CTL, PIPE_USB, PIPE_INT,
                      PIPE_CHECK, PIPE_DELAY);

type  FT_SV_t is record
   state       : ft_state_t;
   rx_head     : unsigned(1 downto 0);
   rx_tail     : unsigned(1 downto 0);
   rx_ptr      : unsigned(8 downto 0);
   rx_int      : std_logic;
   tx_tail     : unsigned(1 downto 0);
   tx_head     : unsigned(1 downto 0);
   tx_ptr      : unsigned(9 downto 0);
   tx_int      : std_logic;
   pi_head     : std_logic;
   pi_tail     : std_logic;
   pi_ptr      : unsigned(13 downto 0);
   pi_cnt      : unsigned(31 downto 0);
   pi_int      : std_logic;
   pi_run      : std_logic;
   pipe        : std_logic;
   flush_cnt   : unsigned(15 downto 0);
   delay       : integer range 0 to 7;
   rd          : std_logic;
   wr          : std_logic;
   wr_txe      : std_logic;
   wr_oe       : std_logic;
   we          : std_logic;
   oe          : std_logic;
   busy        : std_logic;
   run         : std_logic;
end record FT_SV_t;

type  RD_SV_t is record
   state       : rd_state_t;
   addr        : unsigned(31 downto 0);
   pkt_cnt     : unsigned(31 downto 0);
   wrd_cnt     : unsigned(6 downto 0);
   cycle       : unsigned(4 downto 0);
   run         : std_logic;
   head        : std_logic;
   tail        : std_logic;
   pipe_int    : std_logic;
   master      : std_logic;
   burstcnt    : std_logic_vector(8 downto 0);
   tail_addr   : unsigned(15 downto 0);
   busy        : std_logic;
end record RD_SV_t;

--
-- CONSTANTS
--

-- FT State Vector Initialization
constant C_FT_SV_INIT : FT_SV_t := (
   state       => IDLE,
   rx_head     => (others => '0'),
   rx_tail     => (others => '0'),
   rx_ptr      => (others => '0'),
   rx_int      => '0',
   tx_tail     => (others => '0'),
   tx_head     => (others => '0'),
   tx_ptr      => (others => '0'),
   tx_int      => '0',
   pi_head     => '0',
   pi_tail     => '0',
   pi_int      => '0',
   pi_run      => '0',
   pi_ptr      => (others => '0'),
   pi_cnt      => (others => '0'),
   pipe        => '0',
   flush_cnt   => (others => '0'),
   delay       => 0,
   rd          => '0',
   wr          => '0',
   wr_txe      => '0',
   wr_oe       => '0',
   we          => '0',
   oe          => '0',
   busy        => '0',
   run         => '0'
);

-- RD State Vector Initialization
constant C_RD_SV_INIT : RD_SV_t := (
   state       => IDLE,
   addr        => (others => '0'),
   pkt_cnt     => (others => '0'),
   wrd_cnt     => (others => '0'),
   cycle       => (others => '0'),
   run         => '0',
   head        => '0',
   tail        => '0',
   pipe_int    => '0',
   master      => '0',
   burstcnt    => (others => '0'),
   tail_addr   => (others => '0'),
   busy        => '0'
);

--
-- SIGNAL DECLARATIONS
--

-- State Machine Data Types
signal ft               : FT_SV_t;
signal rd               : RD_SV_t;

-- 32-Bit Status Register
signal sync_stat        : std_logic_vector(31  downto 0);
alias  xl_TAIL_ADDR     : std_logic_vector(15 downto 0) is sync_stat(15 downto 0);
alias  xl_RX_HEAD       : std_logic_vector(1 downto 0) is sync_stat(17 downto 16);
alias  xl_TX_TAIL       : std_logic_vector(1 downto 0) is sync_stat(19 downto 18);
alias  xl_UNUSED        : std_logic_vector(6 downto 0) is sync_stat(26 downto 20);
alias  xl_CLKIN_OFF     : std_logic is sync_stat(27);
alias  xl_FT_BUSY       : std_logic is sync_stat(28);
alias  xl_RD_BUSY       : std_logic is sync_stat(29);
alias  xl_TX_INTR       : std_logic is sync_stat(30);
alias  xl_RX_INTR       : std_logic is sync_stat(31);

-- 32-Bit Control Register
alias  xl_TX_HEAD       : std_logic_vector(1 downto 0) is sync_CONTROL(1 downto 0);
alias  xl_RX_TAIL       : std_logic_vector(1 downto 0) is sync_CONTROL(3 downto 2);
alias  xl_BYPASS        : std_logic is sync_CONTROL(24);
alias  xl_CLK_INT       : std_logic is sync_CONTROL(25);
alias  xl_PIPE_INT      : std_logic is sync_CONTROL(26);
alias  xl_RX_INT        : std_logic is sync_CONTROL(27);
alias  xl_TX_INT        : std_logic is sync_CONTROL(28);
alias  xl_PIPE_RUN      : std_logic is sync_CONTROL(29);
alias  xl_FIFO_RUN      : std_logic is sync_CONTROL(30);
alias  xl_ENABLE        : std_logic is sync_CONTROL(31);

signal ft_rxf           : std_logic;
signal ft_txe           : std_logic;
signal ft_txe_r0        : std_logic;

signal clkin_rst        : std_logic;
signal clkin_rst_r0     : std_logic;
signal clkin_r0         : std_logic;
signal clkin_r1         : std_logic;
signal clkcnt           : integer range 0 to 127;
signal clkcnt_nxt       : integer range 0 to 3;
signal clkcnt_rst       : std_logic;
signal clkcnt_halt      : std_logic;
signal clk_start_int    : std_logic;
signal clkcnt_sam       : unsigned(7 downto 0);
signal clkcnt_on        : unsigned(7 downto 0);
signal clkcnt_off       : unsigned(7 downto 0);

-- Master Read Signals
signal readdata         : std_logic_vector(31 downto 0);
signal rd_waitreq       : std_logic;
signal rd_datavalid     : std_logic;
signal rd_we            : std_logic;

signal head_addr_i      : unsigned(15 downto 0);
signal ft_addr          : std_logic_vector(11 downto 0);
signal ft_tx_dat        : std_logic_vector(7 downto 0);
signal ft_tx_dat_r0     : std_logic_vector(7 downto 0);
signal ft_tx_dat_r1     : std_logic_vector(7 downto 0);
signal ft_pi_dat        : std_logic_vector(7 downto 0);

-- I/O Element (IOE) Signals
signal ctl_out          : std_logic_vector(2 downto 0);
signal ctl_in           : std_logic_vector(2 downto 0);
signal dq_in_dat        : std_logic_vector(7 downto 0);
signal dq_out_dat       : std_logic_vector(7 downto 0);

--
-- MAIN CODE
--
begin

   --
   -- COMBINATORIAL OUTPUTS
   --
   sync_int(0)          <= ft.rx_int  and xl_RX_INT;
   sync_int(1)          <= ft.tx_int  and xl_TX_INT;
   sync_int(2)          <= '0';
   sync_int(3)          <= clk_start_int and xl_CLK_INT;
   sync_int(4)          <= ft.pi_int  and xl_PIPE_INT;

   sync_STATUS          <= sync_stat;
   xl_CLKIN_OFF         <= clkcnt_rst;

   sync_DEBUG           <= head_addr_i & tail_addr;

   -- Master Read
   m1_rd_address        <= std_logic_vector(rd.addr);
   readdata             <= m1_readdata;
   rd_waitreq           <= m1_rd_waitreq;
   m1_read              <= rd.master;
   m1_rd_burstcount     <= rd.burstcnt;
   rd_datavalid         <= m1_rd_datavalid;

   -- Shared Packet Address
   tail_addr            <= std_logic_vector(rd.tail_addr);

   -- Debug
   debug(0)             <= '0';
   debug(1)             <= '0';
   debug(2)             <= '0';
   debug(3)             <= '0';

   --
   -- FT232 FIFO
   --
   rd_n                 <= ctl_out(0);
   wr_n                 <= ctl_out(1);
   oe_n                 <= ctl_out(2);
   siwu_n               <= '1';
   pwrsav_n             <= '1';

   ctl_in(0)            <= not ft.rd;
   ctl_in(1)            <= not (ft.wr or (ft.wr_txe and txe_n));
   ctl_in(2)            <= not ft.oe;

   ft_rxf               <= not rxf_n;
   ft_txe               <= not txe_n;

   -- FT232 8-Bit Bidirectional Data I/O
   -- Placed in IOE structure.
   SYNC_IO_I : entity work.sync_io
   port map (
      aclr        => not reset_n or clkin_rst_r0,
      datain_h    => dq_in_dat,
      datain_l    => dq_in_dat,
      inclock     => clkin,
      oe          => ft.wr_oe,
      outclock    => clkin,
      dataout_h   => dq_out_dat,
      dataout_l   => open,
      padio       => dat
   );

   -- FT232 Output Control Signals
   -- Placed in IO structure.
   SYNC_OUT_I : entity work.sync_out
   port map (
      aclr        => not reset_n or clkin_rst_r0,
      datain_h    => ctl_in,
      datain_l    => ctl_in,
      outclock    => clkin,
      dataout     => ctl_out
   );

   --
   --  ONLY USED FOR 512-BYTE CM MESSAGES
   --
   --
   --   4096x8 <==> 1024x32 Dual-Port BLOCK RAM
   --   BRAM_a[7:0] <==> FT232[7:0]
   --   CPU <==> BRAM_b[31:0]
   --
   --   CPU <==> BRAM <==> FT232 <==> USB, IN/OUT TRANSFER
   --
   SYNC_4K_I : entity work.sync_4k
      port map (
         -- FT232 read/write
         address_a         => std_logic_vector(ft_addr),
         clock_a           => clkin,
         data_a            => dq_out_dat,
         wren_a            => ft.we,
         q_a               => ft_tx_dat,
         -- CPU read/write
         address_b         => cpu_ADDR,
         clock_b           => clk,
         data_b            => cpu_DOUT,
         wren_b            => cpu_WE,
         q_b               => cpu_DIN
   );
   -- lower block when writing, upper block when reading
   ft_addr        <= "0" & std_logic_vector(ft.rx_head) & std_logic_vector(ft.rx_ptr(8 downto 0)) when ft.we = '1' else
                     "1" & std_logic_vector(ft.tx_tail) & std_logic_vector(ft.tx_ptr(8 downto 0));

   -- account for FT232 flow control oddities
   dq_in_dat      <= ft_tx_dat_r0 when (ft_txe  = '0' and ft_txe_r0 = '1') else
                     ft_tx_dat_r1 when (ft_txe  = '0' and ft_txe_r0 = '0') else
                     ft_tx_dat    when (ft.pipe = '0') else ft_pi_dat;

   --
   --  *** FTDI CLOCK DOMAIN, ~60 MHZ ***
   --

   --
   --  ONLY USED FOR 512-BYTE CM MESSAGES
   --
   --  The FIFO state machine emptys slots from the CPU circular
   --  buffer and sends the packets to the USB IN endpoint.
   --  The state machine also fills slots from the USB OUT
   --  transfers. These slots only contain CM control messages.
   --  Each slot is a 512-Byte packet. All CM control message
   --  transfers between the PC USB and the FT232 FIFO are 512-Byte
   --  packets.
   --
   --  Additionally, the state machine will send
   --  8K pipe messages from the 16K ping-pong buffer that is
   --  filled by the read burst state machine.
   --
   process(all) begin
      if (reset_n = '0' or xl_ENABLE = '0' or clkin_rst_r0 = '1') then

         -- Init the State Vector
         ft             <= C_FT_SV_INIT;

         -- status is shared by master write FSM
         xl_RX_HEAD     <= (others => '0');
         xl_TX_TAIL     <= (others => '0');
         xl_UNUSED      <= (others => '0');
         xl_FT_BUSY     <= '0';
         xl_TX_INTR     <= '0';
         xl_RX_INTR     <= '0';

      elsif (rising_edge(clkin)) then

         -- double-buffer async from "clk" domain
         ft.rx_tail     <= unsigned(xl_RX_TAIL);
         ft.tx_head     <= unsigned(xl_TX_HEAD);
         ft.run         <= xl_FIFO_RUN;
         ft.pi_head     <= rd.head;
         ft.pi_run      <= xl_PIPE_RUN;

         -- update status
         xl_RX_HEAD     <= std_logic_vector(ft.rx_head);
         xl_TX_TAIL     <= std_logic_vector(ft.tx_tail);
         xl_UNUSED      <= (others => '0');
         xl_FT_BUSY     <= ft.busy;
         xl_TX_INTR     <= ft.tx_int;
         xl_RX_INTR     <= ft.rx_int;

         case ft.state is
            when IDLE =>
               -- Begin USB IN/OUT Transfers
               if (ft.run = '1') then
                  ft.state    <= FLUSH;
                  ft.rx_head  <= (others => '0');
                  ft.rx_ptr   <= (others => '0');
                  ft.tx_tail  <= (others => '0');
                  ft.tx_ptr   <= (others => '0');
                  ft.flush_cnt <= X"1000";
                  ft.pi_tail  <= '0';
                  ft.pi_ptr   <= (others => '0');
                  ft.pi_cnt   <= (others => '0');
                  ft.delay    <= 0;
                  ft.rd       <= '0';
                  ft.wr       <= '0';
                  ft.wr_txe   <= '0';
                  ft.wr_oe    <= '0';
                  ft.we       <= '0';
                  ft.oe       <= '1';
                  ft.pipe     <= '0';
                  ft.busy     <= '1';
               else
                  ft.state    <= IDLE;
                  ft.busy     <= '0';
               end if;

            --
            -- ALWAYS FLUSH THE FTDI FIFO OUT OF IDLE
            -- ASSERT RD FOR 4K CLOCKS, ~275uS
            --
            when FLUSH =>
               if (ft.flush_cnt = 0) then
                  ft.state    <= WAIT_REQ;
                  ft.rd       <= '0';
                  ft.oe       <= '0';
               else
                  ft.state    <= FLUSH;
                  ft.flush_cnt <= ft.flush_cnt - 1;
                  ft.rd       <= '1';
               end if;

            --
            -- Wait for USB IN/OUT Transfer Requests
            --
            -- USB IN  : TRANSMIT DATA FROM FT232H TO PC
            -- USB OUT : RECEIVE DATA FROM PC TO FT232H
            --
            when WAIT_REQ =>
               ft.tx_int      <= '0';
               ft.rx_int      <= '0';
               ft.pi_int      <= '0';
               -- Abort USB IN/OUT Transfers
               if (ft.run = '0') then
                  ft.state    <= IDLE;
               -- The receive sync is not empty and there's
               -- room in the circular buffer.
               elsif (ft_rxf = '1' and ((ft.rx_head + 1) /= ft.rx_tail)) then
                  ft.state    <= RX_CTL;
                  ft.rx_ptr   <= (others => '0');
                  ft.delay    <= 2;
                  ft.oe       <= '1';
               -- The transmit sync is not full and there's
               -- a packet waiting to be transmitted.
               elsif (ft_txe = '1' and (ft.tx_head /= ft.tx_tail)) then
                  ft.state    <= TX_CTL;
                  ft.tx_ptr   <= (others => '0');
                  ft.wr_oe    <= '1';
                  ft.pipe     <= '0';
               -- The transmit sync is not full and there's
               -- a pipe message waiting to be transmitted.
               elsif (ft_txe = '1' and (ft.pi_head /= ft.pi_tail) and rd.run = '1') then
                  ft.state    <= PIPE_CTL;
                  ft.pi_ptr   <= (others => '0');
                  ft.wr_oe    <= '1';
                  ft.pipe     <= '1';
               -- clear pipe tail and count when Read Burst FSM is started
               elsif (xl_PIPE_RUN = '1' and rd.run = '0') then
                  ft.state    <= WAIT_REQ;
                  ft.pi_tail  <= '0';
                  ft.pi_cnt   <= (others => '0');
               else
                  ft.state    <= WAIT_REQ;
               end if;

            --
            -- Account for Data Latency
            --
            when RX_CTL =>
               if (ft.delay = 0) then
                  ft.state    <= RX_USB;
                  ft.we       <= '1';
               else
                  ft.state    <= RX_CTL;
                  ft.delay    <= ft.delay - 1;
                  ft.rd       <= '1';
               end if;

            --
            -- USB OUT Transfer
            -- PC USB -> FT232 recieve sync -> BRAM
            -- 512-Byte CM Control Message
            --
            when RX_USB =>
               if (ft.rx_ptr = 511) then
                  ft.state    <= RX_DELAY;
                  ft.rx_head  <= ft.rx_head + 1;
                  ft.delay    <= 2;
                  ft.we       <= '0';
                  ft.rx_int   <= '1';
               -- align read
               elsif (ft.rx_ptr = 509) then
                  ft.state    <= RX_USB;
                  ft.rx_ptr   <= ft.rx_ptr + 1;
                  ft.rd       <= '0';
               else
                  ft.state    <= RX_USB;
                  ft.rx_ptr   <= ft.rx_ptr + 1;
               end if;

            --
            -- Account for FT232H Flag Latency
            --
            when RX_DELAY =>
               if (ft.delay = 0) then
                  ft.state    <= WAIT_REQ;
                  ft.oe       <= '0';
               else
                  ft.state    <= RX_DELAY;
                  ft.delay    <= ft.delay - 1;
               end if;

            --
            -- Account for Data Latency, fill the Pipe
            --
            when TX_CTL =>
               ft.state    <= TX_USB;
               ft.tx_ptr   <= ft.tx_ptr + 1;

            --
            -- USB IN Transfer
            -- BRAM -> FT232 transmit sync -> PC USB
            -- 512-Byte CM Control Message
            --
            when TX_USB =>
               if (ft.tx_ptr = 513 and ft_txe = '1') then
                  ft.state    <= TX_CHECK;
                  ft.tx_tail  <= ft.tx_tail + 1;
                  ft.tx_ptr   <= ft.tx_ptr + 1;
                  ft.wr       <= '0';
                  ft.tx_int   <= '1';
               elsif (ft_txe = '1') then
                  ft.state    <= TX_USB;
                  ft.tx_ptr   <= ft.tx_ptr + 1;
                  ft.wr       <= '1';
               elsif (ft_txe = '0' and ft.tx_ptr = 3) then
                  ft.state    <= TX_USB;
               else
                  ft.state    <= TX_USB;
               end if;

            --
            -- Check ft_txe after ft.wr negate
            --
            when TX_CHECK =>
               if (ft_txe = '0') then
                  ft.state    <= TX_CHECK;
                  ft.wr_txe   <= '1';
               else
                  ft.state    <= TX_DELAY;
                  ft.wr_txe   <= '0';
                  ft.delay    <= 4;
               end if;

            --
            -- Account for FT232H Flag Latency
            --
            when TX_DELAY =>
               if (ft.delay = 0) then
                  ft.state    <= WAIT_REQ;
               else
                  ft.state    <= TX_DELAY;
                  ft.wr_oe    <= '0';
                  ft.delay    <= ft.delay - 1;
               end if;

            --
            -- Account for Data Latency, fill the Pipe
            --
            when PIPE_CTL =>
               ft.state    <= PIPE_USB;
               ft.pi_ptr   <= ft.pi_ptr + 1;

            --
            -- USB IN Transfer, 8K Pipe Message
            -- BRAM -> FT232 transmit sync -> PC USB
            -- 8192-Byte CM Pipe Message
            --
            when PIPE_USB =>
               if (ft.pi_ptr = 8193 and ft_txe = '1') then
                  ft.state    <= PIPE_CHECK;
                  ft.pi_tail  <= not ft.pi_tail;
                  ft.pi_ptr   <= ft.pi_ptr + 1;
                  -- account for packets per transfer
                  ft.pi_cnt   <= ft.pi_cnt + unsigned(sync_PKT_XFER);
                  ft.wr       <= '0';
               elsif (ft_txe = '1') then
                  ft.state    <= PIPE_USB;
                  ft.pi_ptr   <= ft.pi_ptr + 1;
                  ft.wr       <= '1';
               elsif (ft_txe = '0' and ft.pi_ptr = 3) then
                  ft.state    <= PIPE_USB;
               else
                  ft.state    <= PIPE_USB;
               end if;

            --
            -- Check ft_txe after ft.wr negate
            --
            when PIPE_CHECK =>
               if (ft_txe = '0') then
                  ft.state    <= PIPE_CHECK;
                  ft.wr_txe   <= '1';
               else
                  ft.state    <= PIPE_INT;
                  ft.wr_txe   <= '0';
                  ft.delay    <= 4;
               end if;

            --
            -- Transfer Complete Interrupt
            --
            when PIPE_INT =>
               -- Transfer Complete
               if (sync_PKT_CNT /= X"00000000" and
                   ft.pi_cnt = unsigned(sync_PKT_CNT)) then
                  ft.state    <= PIPE_DELAY;
                  ft.pi_int   <= '1';
                  ft.pi_cnt   <= (others => '0');
               else
                  ft.state    <= PIPE_DELAY;
               end if;

            --
            -- Account for FT232H Flag Latency
            --
            when PIPE_DELAY =>
               if (ft.delay = 0) then
                  ft.state    <= WAIT_REQ;
                  ft.pipe     <= '0';
               else
                  ft.state    <= PIPE_DELAY;
                  ft.wr_oe    <= '0';
                  ft.delay    <= ft.delay - 1;
               end if;

            when others =>
               ft.state       <= IDLE;

         end case;

      end if;
   end process;

   --
   --  CAPTURE ft_tx_data or ft_pi_data WHEN ft_txe IS DE-ASSERTED
   --  USED FOR FLOW CONTROL DATA ALIGNMENT
   --
   process(all) begin
      if (reset_n = '0' or xl_ENABLE = '0') then
         ft_tx_dat_r0   <= (others => '0');
         ft_tx_dat_r1   <= (others => '0');
         ft_txe_r0      <= '0';
      elsif (rising_edge(clkin)) then
         ft_txe_r0      <= ft_txe;
         if (ft.pipe = '0') then
            ft_tx_dat_r0   <= ft_tx_dat;
         else
            ft_tx_dat_r0   <= ft_pi_dat;
         end if;
         if (ft_txe_r0 = '1' and ft_txe = '0') then
            ft_tx_dat_r1  <= ft_tx_dat_r0;
         else
            ft_tx_dat_r1  <= ft_tx_dat_r1;
         end if;
      end if;
   end process;

   --
   --  FTDI 60MHZ CLOCK, THIS CLOCK ONLY
   --  RUNS WHEN THE D2XX DRIVER IS OPENED AND
   --  THE BIT MODE IS SET FOR SYNC 245
   --
   process(all) begin
      if (reset_n = '0') then
         clkin_rst      <= '0';
         clkin_rst_r0   <= '0';
      elsif (rising_edge(clkin)) then
         clkin_rst      <= clkcnt_rst;
         clkin_rst_r0   <= clkin_rst;
      end if;
   end process;

   --
   --  ONLY USED FOR 8K PIPE MESSAGES
   --
   --  16384x8 <==> 4096x32 Dual-Port BLOCK RAM
   --  m1_readdata -> BRAM_b[31:0]
   --  BRAM_a[7:0] -> FT232[7:0]
   --
   --  ON-CHIP/DDR -> BRAM -> FT232 -> USB, IN TRANSFER
   --  This RAM is used as a ping/pong buffer to store
   --  two 8K packets, the dual port allows filling and
   --  draining simultaneously.
   --
   SYNC_16K_I : entity work.sync_16k
      port map (
         -- master burst read
         wrclock           => clk,
         wrclocken         => '1',
         wraddress         => rd.head &
                              std_logic_vector(rd.cycle(3 downto 0)) &
                              std_logic_vector(rd.wrd_cnt),
         wren              => rd_we,
         data              => readdata,
         -- FT232 write
         rdclock           => clkin,
         rdclocken         => ft_txe,
         rdaddress         => ft.pi_tail & std_logic_vector(ft.pi_ptr(12 downto 0)),
         q                 => ft_pi_dat
   );
   rd_we          <= '1' when (rd.state = SLOT and rd_datavalid = '1') else '0';

   --
   --  *** FPGA CLOCK DOMAIN, 100 MHZ ***
   --

   --
   --  ONLY USED FOR 8K PIPE MESSAGES
   --
   --
   --  MASTER READ BURST TRANSFER, ON-CHIP OR DDR => USB
   --
   --  This state machine will transfer 16 512-Byte blocks from ON-CHIP/DDR
   --  into the local Block RAM. The 8K packet will then be available to the
   --  FIFO state machine for transfer to the PC as a single 8K pipe
   --  message. The 16K Block RAM can hold two pipe messages and
   --  is used as a ping/pong buffer. Each burst will require 128x32
   --  transfers at the system clock rate, so 1.28 microseconds per burst.
   --
   --
   --  NOTES:
   --    * Master read/write addresses are byte pointers.
   --    * Avalon transfers are always 32-Bits.
   --    * sync_PKT_CNT is the number of 1K  packets.
   --    * IN is the USB nomenclature with respect to the PC USB host,
   --      and refers to transfers from the FT232 device to the PC.
   --
   process(all) begin
      if (reset_n = '0' or xl_ENABLE = '0') then

         -- Init the State Vector
         rd             <= C_RD_SV_INIT;

         -- Status is shared by FIFO FSM
         xl_RD_BUSY     <= '0';
         xl_TAIL_ADDR   <= (others => '0');

      elsif (rising_edge(clk)) then

         -- double-buffer async
         rd.tail        <= ft.pi_tail;
         rd.run         <= xl_PIPE_RUN;

         -- update status
         xl_RD_BUSY     <= rd.busy;
         xl_TAIL_ADDR   <= std_logic_vector(rd.tail_addr);

         case rd.state is
            when IDLE =>
               -- Wait for xl_PIPE_RUN Assertion
               if (xl_PIPE_RUN = '1' and rd.run = '0') then
                  rd.state    <= WAIT_PKT;
                  -- Address must be on a 32-Bit boundary
                  rd.addr     <= unsigned(sync_ADR_BEG);
                  -- 128 32-Bit transfers
                  rd.burstcnt <= '0' & X"80";
                  rd.pkt_cnt  <= (others => '0');
                  rd.wrd_cnt  <= (others => '0');
                  rd.cycle    <= (others => '0');
                  rd.tail_addr <= (others => '0');
                  rd.head     <= '0';
              else
                  rd.state    <= IDLE;
                  rd.busy     <= '0';
                  rd.addr     <= (others => '0');
                  rd.pipe_int <= '0';
               end if;

            --
            -- Wait for 8K Packets or Bypass
            --
            when WAIT_PKT =>
               -- Abort Transfer
               if (xl_PIPE_RUN = '0') then
                  rd.state    <= IDLE;
               -- Transfer Complete
               elsif (unsigned(sync_PKT_CNT) /= 0 and
                      rd.pkt_cnt >= unsigned(sync_PKT_CNT)) then
                  rd.state    <= IDLE;
                  rd.pipe_int <= '1';
               -- Bypass Address throtle check, allows software to
               -- issue pipe messages, not just hardware
               elsif (xl_BYPASS = '1') then
                  rd.state    <= WAIT_SLOT;
               -- 8K Packets available to send
               elsif (head_addr_i /= 0 and (rd.tail_addr /= head_addr_i)) then
                  rd.state    <= WAIT_SLOT;
               else
                  rd.state    <= WAIT_PKT;
               end if;

            -- Wait for a Slot in the Circular Buffer
            -- Also check for Transfer Complete and Abort
            --
            when WAIT_SLOT =>
               -- Abort Transfer
               if (xl_PIPE_RUN = '0') then
                  rd.state    <= IDLE;
               -- Account for Circular Memory, Restart
               elsif (rd.addr >= unsigned(sync_ADR_END)) then
                  rd.state    <= WAIT_SLOT;
                  rd.addr     <= unsigned(sync_ADR_BEG);
               -- Continuous Send when room at the inn
               elsif (rd.head = rd.tail) then
                  rd.state    <= CYCLE_CHK;
               else
                  rd.state    <= WAIT_SLOT;
               end if;

            --
            -- 16 512-Byte Bursts per Request, Fill half
            -- the Ping/Pong Buffer
            --
            when CYCLE_CHK =>
               -- 16 bursts per cycle
               if (rd.cycle = 16) then
                  rd.state    <= WAIT_PKT;
                  rd.cycle    <= (others => '0');
                  -- account for packets per transfer
                  rd.pkt_cnt  <= rd.pkt_cnt + unsigned(sync_PKT_XFER);
                  rd.wrd_cnt  <= (others => '0');
                  rd.head     <= not rd.head;
                  rd.tail_addr <= rd.tail_addr + 1;
                  rd.busy     <= '0';
               else
                  rd.state    <= REQ;
                  rd.master   <= '1';
                  rd.busy     <= '1';
               end if;

            --
            -- Issue a single burst request of
            -- 128 32-Bit words, the m1_read signal
            -- is only asserted during this state.
            --
            when REQ =>
               if (rd_waitreq = '0') then
                  rd.state    <= SLOT;
                  rd.master   <= '0';
               else
                  rd.state    <= REQ;
               end if;

            --
            -- Wait for Burst Transfer to Complete
            --
            when SLOT =>
               if (rd.wrd_cnt = 127 and rd_datavalid = '1') then
                  rd.state    <= CYCLE_CHK;
                  rd.wrd_cnt  <= (others => '0');
                  rd.cycle    <= rd.cycle + 1;
                  rd.addr     <= rd.addr + X"200";
               elsif (rd_datavalid = '1') then
                  rd.state    <= SLOT;
                  rd.wrd_cnt  <= rd.wrd_cnt + 1;
               else
                  rd.state    <= SLOT;
               end if;

            when others =>
               rd.state       <= IDLE;

         end case;

      end if;
   end process;

   --
   --  CAPTURE head_addr
   --
   process(all) begin
      if (reset_n = '0' or xl_ENABLE = '0') then
         head_addr_i    <= (others => '0');
      elsif (rising_edge(clk)) then
         head_addr_i    <= unsigned(head_addr);
      end if;
   end process;

   --
   --  FTDI 60MHZ CLOCK MONITOR FROM FPGA CLK
   --  DOMAIN, IF CLOCK STOPS THEN FIFO FSM IS
   --  RESET WHEN IT STARTS AGAIN.
   --
   process(all) begin
      if (reset_n = '0') then
         clkcnt         <= 0;
         clkcnt_sam     <= (others => '0');
         clkcnt_nxt     <= 0;
         clkcnt_halt    <= '0';
         clkcnt_rst     <= '0';
         clk_start_int  <= '0';
         clkcnt_off     <= (others => '0');
         clkcnt_on      <= (others => '0');
         clkin_r0       <= '0';
         clkin_r1       <= '0';
      elsif (rising_edge(clk)) then
         -- double-buffer async clock
         clkin_r0       <= clkin;
         clkin_r1       <= clkin_r0;
         --
         -- check for clkin NOT running
         --
         if (clkcnt_sam = 0 and (clkcnt_on = X"FF" or clkcnt_off = X"FF")) then
            clkcnt_halt <= '1';
            clkcnt_sam  <= clkcnt_sam + 1;
            clkcnt_off     <= (others => '0');
            clkcnt_on      <= (others => '0');
         -- clear the counters every cycle
         elsif (clkcnt_sam = 0) then
            clkcnt_halt <= '0';
            clkcnt_sam  <= clkcnt_sam + 1;
            clkcnt_off     <= (others => '0');
            clkcnt_on      <= (others => '0');
         -- check for clkin always on
         elsif (clkin_r1 = '1') then
            clkcnt_on   <= clkcnt_on + 1;
            clkcnt_sam  <= clkcnt_sam + 1;
         -- else check for clkin always off
         elsif (clkin_r1 = '0') then
            clkcnt_off  <= clkcnt_off + 1;
            clkcnt_sam  <= clkcnt_sam + 1;
         end if;
         --
         -- wait here until clock starts
         --
         if (clkcnt_halt = '1') then
            clkcnt_rst  <= '1';
            clkcnt_nxt  <= 0;
         elsif (clkcnt_nxt = 0 and clkcnt_halt = '0') then
            clkcnt_nxt  <= 1;
         -- assert reset for 128 clocks
         -- generated interrupt when clock starts
         elsif (clkcnt_nxt = 1 and clkcnt = 127) then
            clkcnt_nxt  <= 2;
            clk_start_int <= '1';
            clkcnt      <= 0;
         -- count during reset
         elsif (clkcnt_nxt = 1) then
            clkcnt      <= clkcnt + 1;
         -- negate reset and wait here for clock stop
         elsif (clkcnt_nxt = 2) then
            clkcnt_rst  <= '0';
            clk_start_int <= '0';
         else
            clkcnt      <= clkcnt;
         end if;
      end if;
   end process;

end rtl;
