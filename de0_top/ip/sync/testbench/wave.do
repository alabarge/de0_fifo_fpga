onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/clk
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/clkin
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/reset_n
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/clkin_rst_r0
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/clkcnt_rst
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/xl_CLKIN_OFF
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/clkcnt_halt
add wave -noupdate -radix hexadecimal /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/clkcnt_sam
add wave -noupdate -radix hexadecimal /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/clkcnt_on
add wave -noupdate -radix hexadecimal /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/clkcnt_off
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft_rxf
add wave -noupdate /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft_txe
add wave -noupdate -radix hexadecimal -childformat {{/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.state -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rx_head -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rx_tail -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rx_ptr -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.tx_tail -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.tx_head -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.tx_ptr -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.flush_cnt -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.pi_head -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.pi_tail -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.pi_ptr -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.delay -radix hexadecimal} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rd -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.wr -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.wr_txe -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.wr_oe -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.we -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.oe -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.busy -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.tx_int -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rx_int -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.pipe -radix binary} {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.run -radix binary}} -expand -subitemconfig {/ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.state {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rx_head {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rx_tail {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rx_ptr {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.tx_tail {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.tx_head {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.tx_ptr {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.flush_cnt {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.pi_head {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.pi_tail {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.pi_ptr {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.delay {-height 15 -radix hexadecimal} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rd {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.wr {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.wr_txe {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.wr_oe {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.we {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.oe {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.busy {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.tx_int {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.rx_int {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.pipe {-height 15 -radix binary} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft.run {-height 15 -radix binary}} /ftdi_fifo_tb/FIFO_TOP_I/FIFO_CORE_I/FIFO_CTL_I/ft
add wave -noupdate /ftdi_fifo_tb/clk60M_mask
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {265185 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits us
update
WaveRestoreZoom {0 ps} {524288 ns}
