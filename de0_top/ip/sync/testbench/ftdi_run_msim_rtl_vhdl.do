transcript on
if {[file exists rtl_work]} {
	vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vcom -2008 -work work {../../../packages/lib_pkg.vhd}
vcom -2008 -work work {../../../packages/PCK_tb.vhd}
vcom -2008 -work work {../../../packages/PCK_print_utilities.vhd}
vcom -2008 -work work {../../../packages/PCK_FIO_1993.vhd}
vcom -2008 -work work {../../../packages/PCK_FIO_1993_BODY.vhd}
vcom -2008 -work work {../fifo_4k.vhd}
vcom -2008 -work work {../fifo_16k.vhd}
vcom -2008 -work work {../fifo_dqio.vhd}
vcom -2008 -work work {../fifo_ioOut.vhd}
vcom -2008 -work work {../fifo_ctl.vhd}
vcom -2008 -work work {../fifo_irq.vhd}
vcom -2008 -work work {../fifo_regs.vhd}
vcom -2008 -work work {../fifo_top.vhd}
