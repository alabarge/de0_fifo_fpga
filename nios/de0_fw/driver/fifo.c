/*-----------------------------------------------------------------------------

   1  ABSTRACT

   1.1 Module Type

      Synchronous 245 FIFO I/O Driver

   1.2 Functional Description

      The FIFO I/O Interface routines are contained in this module.

      Steps for adding this driver to the main application :

         1. Call fifo_init() from main
         2. Call fifo_revision() in cp_msg() version request
         3. Adjust the ADC sample rates per interface speed
         4. Call fifo_pipe() from daq_hal_run()
         5. Change baudrate in fw_cfg.h, CFG_BAUD_RATE
         6. Set ADC_POOL_CNT for interface speed
         7. Disable ADC PKT and DONE interrupts

   1.3 Specification/Design Reference

      See fw_cfg.h under the share directory.

   1.4 Module Test Specification Reference

      None

   1.5 Compilation Information

      See fw_cfg.h under the share directory.

   1.6 Notes

      NONE

   2  CONTENTS

      1 ABSTRACT
        1.1 Module Type
        1.2 Functional Description
        1.3 Specification/Design Reference
        1.4 Module Test Specification Reference
        1.5 Compilation Information
        1.6 Notes

      2 CONTENTS

      3 VOCABULARY

      4 EXTERNAL RESOURCES
        4.1  Include Files
        4.2  External Data Structures
        4.3  External Function Prototypes

      5 LOCAL CONSTANTS AND MACROS

      6 MODULE DATA STRUCTURES
        6.1  Local Function Prototypes
        6.2  Local Data Structures

      7 MODULE CODE
         7.1   fifo_init()
         7.2   fifo_isr()
         7.3   fifo_intack()
         7.4   fifo_tx()
         7.5   fifo_cmio()
         7.6   fifo_msgtx()
         7.7   fifo_pipe()
         7.8   fifo_version()

-----------------------------------------------------------------------------*/

// 3 VOCABULARY

// 4 EXTERNAL RESOURCES

// 4.1  Include Files

#include "main.h"

// 4.2   External Data Structures

// 4.3 External Function Prototypes

// 5 LOCAL CONSTANTS AND MACROS

// 6 MODULE DATA STRUCTURES

// 6.1  Local Function Prototypes

// 6.2  Local Data Structures

   static   uint8_t        cm_port = CM_PORT_NONE;

   static   fifo_txq_t     txq;
   static   uint8_t        tx_head;
   static   uint8_t        rx_tail;

   static   volatile pfifo_regs_t   regs = (volatile pfifo_regs_t)FIFO_BASE;

// 7 MODULE CODE

// ===========================================================================

// 7.1

uint32_t fifo_init(uint32_t baudrate, uint8_t port) {

/* 7.1.1   Functional Description

   The FIFO Interface is initialized in this routine.

   7.1.2   Parameters:

   baudrate Serial Baud Rate
   port     COM Port

   7.1.3   Return Values:

   result   CFG_ERROR_OK

-----------------------------------------------------------------------------
*/

// 7.1.4   Data Structures

   uint32_t    result = CFG_ERROR_OK;
   uint32_t    j;

   fifo_ctl_reg_t ctl;
   fifo_sta_reg_t sta;

// 7.1.5   Code

   // Reset Control
   ctl.i = 0;
   regs->ctl = ctl.i;
   utick(10);

   // Enable the hardware
   ctl.b.enable = 1;
   regs->ctl = ctl.i;
   utick(10);

   // Init Control register
   ctl.b.tx_head     = 0;
   ctl.b.rx_tail     = 0;
   ctl.b.bypass      = 0;
   ctl.b.clk_int     = 0;
   ctl.b.pipe_int    = 0;
   ctl.b.rx_int      = 0;
   ctl.b.tx_int      = 0;
   ctl.b.pipe_run    = 0;
   ctl.b.fifo_run    = 0;
   regs->ctl         = ctl.i;

   // Init Circular Address
   regs->addr_beg    = 0;
   regs->addr_end    = 0;

   // Enable the state machines
   ctl.b.pipe_run = 0;
   ctl.b.fifo_run = 1;
   regs->ctl = ctl.i;

   // Clear the hardware TX Buffer
   for (j=0;j<(FIFO_TX_BUFFER_LEN>>2);j++) {
      regs->tx_buf[j] = 0;
   }

   // Clear the hardware RX Buffer
   for (j=0;j<(FIFO_RX_BUFFER_LEN>>2);j++) {
      regs->rx_buf[j] = 0;
   }

   // Initialize the TX Queue
   memset(&txq, 0, sizeof(fifo_txq_t));
   for (j=0;j<FIFO_TX_QUE;j++) {
      txq.buf[j] = NULL;
   }
   txq.head  = 0;
   txq.tail  = 0;
   txq.slots = FIFO_TX_QUE;
   tx_head   = 0;
   rx_tail   = 0;

   // Clear ALL Pending Interrupts
   fifo_intack(FIFO_INT_ALL);

   // Register the interrupt ISRs
   alt_ic_isr_register(FIFO_IRQ_INTERRUPT_CONTROLLER_ID,
                       FIFO_IRQ, fifo_isr, NULL, NULL);

   // Register the I/O Interface callback for CM
   cm_ioreg(fifo_cmio, port, CM_MEDIA_FIFO);

   // Update CM Port
   cm_port = port;

   // Enable the RX, TX & CLK Interrupts
   ctl.b.clk_int   = 1;
   ctl.b.pipe_int  = 0;
   ctl.b.tx_int    = 1;
   ctl.b.rx_int    = 1;
   regs->ctl       = ctl.i;

   // Report H/W Details
   if (gc.trace & CFG_TRACE_ID) {
      xlprint("%-13s base:rev:irq %08X:%d:%d\n", FIFO_NAME, FIFO_BASE, regs->version, FIFO_IRQ);
      xlprint("%-13s rate:   %d.%d Mbps\n", FIFO_NAME, baudrate / 1000000, baudrate % 1000000);
      xlprint("%-13s port:   %d\n", FIFO_NAME, cm_port);
   }

   // Report FTDI CLKIN is not running
   sta.i = regs->sta;
   if (sta.b.clkin_off == 1) {
      xlprint("%-13s FTDI clock is not running\n", FIFO_NAME);
      gc.status |= CFG_STATUS_FTDI_CLOCK;
   }

   return result;

}  // end fifo_init()


// ===========================================================================

// 7.2

void fifo_isr(void *arg) {

/* 7.2.1   Functional Description

   This routine will service the FIFO Interrupt.

   7.2.2   Parameters:

   arg     IRQ arguments

   7.2.3   Return Values:

   NONE

-----------------------------------------------------------------------------
*/

// 7.2.4   Data Structures

   uint32_t    i;
   uint16_t    msglen;
   uint8_t     slotid = 0;
   pcmq_t      slot   = NULL;

   volatile pcm_msg_t  msg;

   fifo_int_reg_t irq;
   fifo_ctl_reg_t ctl;
   fifo_sta_reg_t sta;

// 7.2.5   Code

   // process all interrupt signals, receive has priority
   while ((irq.i = regs->irq) != 0) {
      // report interrupt request
      if (gc.trace & CFG_TRACE_IRQ) {
         xlprint("fifo_isr() irq = %02X\n", irq.i);
      }
      //
      // CLK STOPPED INTERRUPT
      //
      if (irq.b.clk_stop == 1) {
         xlprint("fifo_thread() FTDI clock stopped\n");
         // clear selected interrupts
         fifo_intack(FIFO_INT_CLK_STOP);
         // indicate FTDI clock stopped
         gc.status |= CFG_STATUS_FTDI_CLOCK;
      }
      //
      // CLK STARTED INTERRUPT, RESET HARDWARE
      //
      else if (irq.b.clk_start == 1) {
         xlprint("fifo_thread() FTDI clock started\n");
         // Init Control register
         ctl.i          = regs->ctl;
         ctl.b.tx_head  = 0;
         ctl.b.rx_tail  = 0;
         ctl.b.pipe_run = 0;
         regs->ctl      = ctl.i;
         // Clear the hardware TX Buffer
         for (i=0;i<(FIFO_TX_BUFFER_LEN>>2);i++) {
            regs->tx_buf[i] = 0;
         }
         // Clear the hardware RX Buffer
         for (i=0;i<(FIFO_RX_BUFFER_LEN>>2);i++) {
            regs->rx_buf[i] = 0;
         }
         // Initialize the TX Queue
         memset(&txq, 0, sizeof(fifo_txq_t));
         for (i=0;i<FIFO_TX_QUE;i++) {
            txq.buf[i] = NULL;
         }
         txq.head  = 0;
         txq.tail  = 0;
         txq.slots = FIFO_TX_QUE;
         tx_head   = 0;
         rx_tail   = 0;
         // clear selected interrupts
         fifo_intack(FIFO_INT_CLK_START);
         // indicate FTDi clock stopped
         gc.status &= ~CFG_STATUS_FTDI_CLOCK;
      }
      //
      // RX INTERRUPT
      //
      else if (irq.b.rx == 1) {
         // show activity
         gpio_set_val(GPIO_LED_COM, GPIO_LED_ON);
         // allocate slot from cmq
         slot = cm_alloc();
         if (slot != NULL) {
            sta.i = regs->sta;
            if (sta.b.rx_head != rx_tail) {
               msg = (volatile pcm_msg_t)slot->buf;
               // preserve q slot id
               slotid = msg->h.slot;
               // uint32_t boundary, copy multiple of 32-bits
               // account for rx_tail buffer position
               // always read CM header + parms in order
               // to determine message length
               for (i=0;i<sizeof(cm_msg_t) >> 2;i++) {
                  slot->buf[i] = regs->rx_buf[i + (rx_tail * FIFO_MSGLEN_UINT32)];
               }
               slot->msglen = msg->h.msglen;
               // read rest of CM message body, uint32_t per cycle
               if (slot->msglen > sizeof(cm_msg_t) && (slot->msglen <= FIFO_MSGLEN_UINT8)) {
                  for (i=0;i<(slot->msglen + 3 - sizeof(cm_msg_t)) >> 2;i++) {
                     slot->buf[i + (sizeof(cm_msg_t) >> 2)] =
                           regs->rx_buf[i + (rx_tail * FIFO_MSGLEN_UINT32) + (sizeof(cm_msg_t) >> 2)];
                  }
               }
               // restore q slot id
               msg->h.slot = slotid;
               // report message content
               if ((gc.trace & CFG_TRACE_UART) && (slot != NULL)) {
                  xlprint("fifo_isr() msglen:slotid = %d:%d\n", msg->h.msglen, msg->h.slot);
                  msglen = (slot->msglen <= FIFO_MSGLEN_UINT8) ? slot->msglen : sizeof(cm_msg_t);
                  dump((uint8_t *)slot->buf, msglen, LIB_ASCII, 0);
               }
            }
            // advance the h/w tail pointer
            if (++rx_tail == FIFO_RX_SLOTS) rx_tail = 0;
            ctl.i         = regs->ctl;
            ctl.b.rx_tail = rx_tail;
            regs->ctl     = ctl.i;
         }
      }
      // queue the message
      if (irq.b.rx == 1) {
         // clear the interrupt if head = tail
         sta.i = regs->sta;
         if (sta.b.rx_head == rx_tail)
               fifo_intack(FIFO_INT_RX);
         if ((slot != NULL) && (slot->msglen <= FIFO_MSGLEN_UINT8)) {
            cm_qmsg((pcm_msg_t)slot->buf);
         }
         slot = NULL;
      }
      // check tx queue
      if (irq.b.tx == 1) {
         // clear the interrupt
         fifo_intack(FIFO_INT_TX);
         fifo_msgtx();
      }
      // send interrupt indication
      if (irq.b.pipe == 1) {
         // clear the interrupt
         fifo_intack(FIFO_INT_PIPE);
         cm_local(CM_ID_DAQ_SRV, DAQ_INT_IND, DAQ_INT_FLAG_PIPE, DAQ_OK);
      }
   }

} // end fifo_isr()


// ===========================================================================

// 7.3

void fifo_intack(uint8_t int_type) {

/* 7.3.1   Functional Description

   This routine will Acknowledge specific FIFO Interrupts, or ALL.

   7.3.2   Parameters:

   intType  FIFO_INT_RX:  FIFO Receive Interrupt
            FIFO_INT_TX:  FIFO Transmit Interrupt
            FIFO_INT_ALL: All FIFO Interrupts

   7.3.3   Return Values:

   NONE

-----------------------------------------------------------------------------
*/

// 7.3.4   Data Structures

   fifo_int_reg_t irq = {0};

// 7.3.5   Code

   if (int_type & FIFO_INT_RX) {
      irq.b.rx   = 1;
   }

   if (int_type & FIFO_INT_TX) {
      irq.b.tx   = 1;
   }

   if (int_type & FIFO_INT_PIPE) {
      irq.b.pipe = 1;
   }

   if (int_type & FIFO_INT_CLK_STOP) {
      irq.b.clk_stop  = 1;
   }

   if (int_type & FIFO_INT_CLK_START) {
      irq.b.clk_start = 1;
   }

   if (int_type & FIFO_INT_ALL) {
      irq.b.rx        = 1;
      irq.b.tx        = 1;
      irq.b.clk_stop  = 1;
      irq.b.clk_start = 1;
      irq.b.pipe      = 1;
   }

   regs->irq = irq.i;

} // end fifo_intack()


// ===========================================================================

// 7.4

void fifo_tx(pcm_msg_t msg) {

/* 7.4.1   Functional Description

   This routine will transmit the message. The txq_mutex is used to prevent
   corruption of status and control registers. This routine may be called
   by different threads.

   7.4.2   Parameters:

   pMsg     Message to send.

   7.4.3   Return Values:

   NONE

-----------------------------------------------------------------------------
*/

// 7.4.4   Data Structures

   uint32_t    i;
   uint8_t     tail;
   uint32_t   *out = (uint32_t *)msg;

   fifo_ctl_reg_t ctl;
   fifo_sta_reg_t sta;

// 7.4.5   Code

   // Disable FIFO ISR
   alt_ic_irq_disable(FIFO_IRQ_INTERRUPT_CONTROLLER_ID, FIFO_IRQ);

   // Trace Entry
   if (gc.trace & CFG_TRACE_UART) {
      xlprint("fifo_tx() srvid:msgid:msglen:msg = %02X:%02X:%d:%08X\n",
               msg->p.srvid, msg->p.msgid, msg->h.msglen, (uint32_t)msg);
      dump((uint8_t *)msg, msg->h.msglen, LIB_ASCII, 0);
   }

   // h/w transmit tail
   sta.i = regs->sta;
   tail  = (sta.b.tx_tail + 1) & (FIFO_TX_SLOTS - 1);

   // Validate message, drop if NULL
   if (msg == NULL) {
      // advance the tx queue
      if (++txq.tail == txq.slots) txq.tail = 0;
   }
   // check for h/w slot availability?
   else if (tx_head != tail) {
      // copy message to hardware
      for (i=0;i<(msg->h.msglen + 3) >> 2;i++) {
         regs->tx_buf[i + (tx_head * FIFO_MSGLEN_UINT32)] = out[i];
      }
      // clear the msg pointer
      txq.buf[txq.tail] = NULL;
      // advance the tx queue
      if (++txq.tail == txq.slots) txq.tail = 0;
      // advance the h/w tx queue
      if (++tx_head == FIFO_TX_SLOTS) tx_head = 0;
      // transmit, read-modify-write control
      ctl.i = regs->ctl;
      ctl.b.tx_head  = tx_head;
      regs->ctl      = ctl.i;
      // show activity
      gpio_set_val(GPIO_LED_COM, GPIO_LED_ON);
      // release message
      cm_free(msg);
   }

   // Enable FIFO ISR
   alt_ic_irq_enable(FIFO_IRQ_INTERRUPT_CONTROLLER_ID, FIFO_IRQ);

} // end fifo_tx()


// ===========================================================================

// 7.5

void fifo_cmio(uint8_t op_code, pcm_msg_t msg) {

/* 7.5.1   Functional Description

   OPCODES

   CM_IO_TX : The transmit queue index will be incremented,
   this causes the top of the queue to be transmitted.

   7.5.2   Parameters:

   msg     Message Pointer
   opCode  CM_IO_TX

   7.5.3   Return Values:

   NONE

-----------------------------------------------------------------------------
*/

// 7.5.4   Data Structures

// 7.5.5   Code

   if (gc.trace & CFG_TRACE_UART) {
      xlprint("fifo_cmio() op_code:msg = %02X:%08X\n", op_code, (uint32_t)msg);
   }

   // place in transmit queue
   txq.buf[txq.head] = (uint32_t *)msg;
   if (++txq.head == txq.slots) txq.head = 0;

   // try to transmit message
   fifo_msgtx();

} // end fifo_cmio()


// ===========================================================================

// 7.6

void fifo_msgtx(void) {

/* 7.6.1   Functional Description

   This routine will check for outgoing messages and route them to the
   transmitter fifoTx().

   7.6.2   Parameters:

   NONE

   7.6.3   Return Values:

   NONE

-----------------------------------------------------------------------------
*/

// 7.6.4   Data Structures

// 7.6.5   Code

   // Check for message in Queue
   if (txq.head != txq.tail) {
      fifo_tx((pcm_msg_t)txq.buf[txq.tail]);
   }

} // end fifo_msgtx()


// ===========================================================================

// 7.7

void fifo_pipe(uint32_t opcode, uint32_t addr_beg, uint32_t addr_end, uint32_t pktcnt) {

/* 7.7.1   Functional Description

   This routine will start the master read state machine and stream pipe messages
   through the FIFO. The txq.mutex is used to prevent corruption of status
   and control registers.

   7.7.2   Parameters:

   opcode     Operation Codes
   addr_beg   Begin address of FIFO in Memory, On Chip or SDRAM
   addr_end   Ending address of FIFO
   pktcnt     Specific Pipe Message Count

   7.7.3   Return Values:

   NONE

-----------------------------------------------------------------------------
*/

// 7.7.4   Data Structures

   fifo_ctl_reg_t ctl;

// 7.7.5   Code

   if (gc.trace & CFG_TRACE_UART) {
      xlprint("fifo_pipe() opcode:addr_beg:addr_end:pktcnt = %02X:%08X:%08X:%08X\n",
            opcode, addr_beg, addr_end, pktcnt);
   }

   // Disable FIFO ISR
   alt_ic_irq_disable(FIFO_IRQ_INTERRUPT_CONTROLLER_ID, FIFO_IRQ);

   ctl.i = regs->ctl;

   if (opcode & FIFO_OP_START) {
      // begin-end memory address of pipe message FIFO
      regs->addr_beg = addr_beg;
      regs->addr_end = addr_end;
      // pipe message (packet) count, zero for continuous
      regs->pkt_cnt  = pktcnt;
      // packets per pipe message transfer
      regs->pkt_xfer = FIFO_PKTS_PER_XFER;
      // run request
      ctl.b.pipe_run = 1;
      ctl.b.pipe_int = 1;
      regs->ctl      = ctl.i;
   }
   else if (opcode & FIFO_OP_STOP) {
      // stop request
      ctl.b.pipe_run = 0;
      ctl.b.pipe_int = 0;
      regs->ctl      = ctl.i;
   }

   // Enable FIFO ISR
   alt_ic_irq_enable(FIFO_IRQ_INTERRUPT_CONTROLLER_ID, FIFO_IRQ);

} // end fifo_pipe()


// ===========================================================================

// 7.8

uint32_t fifo_version(void) {

/* 7.8.1   Functional Description

   This routine will return the FIFO VERSION register value.

   7.8.2   Parameters:

   NONE

   7.8.3   Return Values:

   return   VERSION register

-----------------------------------------------------------------------------
*/

// 7.8.4   Data Structures

// 7.8.5   Code

   return regs->version;

} // end fifo_version()
