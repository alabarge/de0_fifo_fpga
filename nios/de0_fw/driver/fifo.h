#pragma once

#include "cm.h"

#define  FIFO_INT_RX           0x01
#define  FIFO_INT_TX           0x02
#define  FIFO_INT_PIPE         0x04
#define  FIFO_INT_CLK_STOP     0x08
#define  FIFO_INT_CLK_START    0x10
#define  FIFO_INT_ALL          0x20

#define  FIFO_OK               0x00000000
#define  FIFO_ERROR            0x80000001
#define  FIFO_ERR_MSG_NULL     0x80000002
#define  FIFO_ERR_LEN_NULL     0x80000004
#define  FIFO_ERR_LEN_MAX      0x80000008
#define  FIFO_ERR_FRAMING      0x80000010
#define  FIFO_ERR_OVERRUN      0x80000020
#define  FIFO_ERR_PARITY       0x80000040
#define  FIFO_ERR_TX_DROP      0x80000080
#define  FIFO_ERR_RX_DROP      0x80000100
#define  FIFO_ERR_CRC          0x80000200
#define  FIFO_ERR_OPEN         0x80000400

#define  FIFO_OP_START         0x00000001
#define  FIFO_OP_STOP          0x00000002
#define  FIFO_OP_BYPASS        0x00000004

#define  FIFO_MSGLEN_UINT8     512
#define  FIFO_MSGLEN_UINT32    (FIFO_MSGLEN_UINT8 >> 2)

#define  FIFO_TX_BUFFER_LEN    2048
#define  FIFO_RX_BUFFER_LEN    2048

#define  FIFO_TX_QUE           8
#define  FIFO_RX_QUE           8

#define  FIFO_TX_SLOTS        (FIFO_TX_BUFFER_LEN / FIFO_MSGLEN_UINT8)
#define  FIFO_RX_SLOTS        (FIFO_RX_BUFFER_LEN / FIFO_MSGLEN_UINT8)

#define  FIFO_PKTS_PER_XFER    8

// Interrupt Register
typedef union _fifo_int_reg_t {
   struct {
      uint32_t rx             : 1;  // fifo_INT(0)
      uint32_t tx             : 1;  // fifo_INT(1)
      uint32_t clk_stop       : 1;  // fifo_INT(2)
      uint32_t clk_start      : 1;  // fifo_INT(3)
      uint32_t pipe           : 1;  // fifo_INT(4)
      uint32_t                : 27;
   } b;
   uint32_t i;
} fifo_int_reg_t, *pfifo_int_reg_t;

// Control Register
typedef union _fifo_ctl_reg_t {
   struct {
      uint32_t tx_head        : 2;  // fifo_CONTROL(1:0)
      uint32_t rx_tail        : 2;  // fifo_CONTROL(3:2)
      uint32_t                : 20; // fifo_CONTROL(23:4)
      uint32_t bypass         : 1;  // fifo_CONTROL(24)
      uint32_t clk_int        : 1;  // fifo_CONTROL(25)
      uint32_t pipe_int       : 1;  // fifo_CONTROL(26)
      uint32_t rx_int         : 1;  // fifo_CONTROL(27)
      uint32_t tx_int         : 1;  // fifo_CONTROL(28)
      uint32_t pipe_run       : 1;  // fifo_CONTROL(29)
      uint32_t fifo_run       : 1;  // fifo_CONTROL(30)
      uint32_t enable         : 1;  // fifo_CONTROL(31)
   } b;
   uint32_t i;
} fifo_ctl_reg_t, *pfifo_ctl_reg_t;

// Status Register
typedef union _fifo_ctl_sta_t {
   struct {
      uint32_t tail_addr      : 16; // fifo_STATUS(15:0)
      uint32_t rx_head        : 2;  // fifo_STATUS(17:16)
      uint32_t tx_tail        : 2;  // fifo_STATUS(19:18)
      uint32_t                : 7;  // fifo_STATUS(26:20)
      uint32_t clkin_off      : 1;  // fifo_STATUS(27)
      uint32_t ft_busy        : 1;  // fifo_STATUS(28)
      uint32_t rd_busy        : 1;  // fifo_STATUS(29)
      uint32_t tx_int         : 1;  // fifo_STATUS(30)
      uint32_t rx_int         : 1;  // fifo_STATUS(31)
   } b;
   uint32_t i;
} fifo_sta_reg_t, *pfifo_sta_reg_t;

// All Registers
typedef struct _fifo_regs_t {
   uint32_t       ctl;
   uint32_t       version;
   uint32_t       irq;
   uint32_t       sta;
   uint32_t       addr_beg;
   uint32_t       addr_end;
   uint32_t       pkt_cnt;
   uint32_t       pkt_xfer;
   uint32_t       test_bit;
   uint32_t       unused[1015];
   uint32_t       rx_buf[512];
   uint32_t       tx_buf[512];
} fifo_regs_t, *pfifo_regs_t;

// Transmit Queue
typedef struct _fifo_txq_t {
   uint32_t     *buf[FIFO_TX_QUE];
   uint8_t       tail;
   uint8_t       head;
   uint8_t       slots;
} fifo_txq_t, *pfifo_txq_t;

// Receive Queue
typedef struct _fifo_rxq_t {
   uint32_t     *buf[FIFO_RX_QUE];
   uint8_t       tail;
   uint8_t       head;
   uint8_t       slots;
} fifo_rxq_t, *pfifo_rxq_t;

uint32_t  fifo_init(uint32_t baudrate, uint8_t port);
void      fifo_isr(void *arg);
void      fifo_intack(uint8_t int_type);
void      fifo_tx(pcm_msg_t msg);
void      fifo_cmio(uint8_t op_code, pcm_msg_t msg);
void      fifo_msgtx(void);
void      fifo_pipe(uint32_t opcode, uint32_t addr_beg, uint32_t addr_end, uint32_t pktcnt);
uint32_t  fifo_version(void);

