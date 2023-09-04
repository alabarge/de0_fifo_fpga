# TCL File Generated by Component Editor 12.0sp2
# Sat Nov 03 18:01:28 EDT 2012
# DO NOT MODIFY


#
# sync "sync" v1.0
# A.E. LaBarge 2012.11.03.18:01:28
#
#

#
# request TCL package from ACDS 12.0
#
package require -exact qsys 12.0


#
# module sync
#
set_module_property NAME sync
set_module_property VERSION 22.1
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP Omniware
set_module_property AUTHOR "A.E. LaBarge"
set_module_property DISPLAY_NAME "FT232H 245 SYNC FIFO to USB"
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


#
# file sets
#
add_fileset quartus_synth QUARTUS_SYNTH "" "Quartus Synthesis"
set_fileset_property quartus_synth TOP_LEVEL sync_top
set_fileset_property quartus_synth ENABLE_RELATIVE_INCLUDE_PATHS true
add_fileset_file sync_top.vhd VHDL PATH sync_top.vhd
add_fileset_file sync_regs.vhd VHDL PATH sync_regs.vhd
add_fileset_file sync_ctl.vhd VHDL PATH sync_ctl.vhd
add_fileset_file sync_irq.vhd VHDL PATH sync_irq.vhd
add_fileset_file sync_4k.vhd VHDL PATH sync_4k.vhd
add_fileset_file sync_16k.vhd VHDL PATH sync_16k.vhd
add_fileset_file sync_io.vhd VHDL PATH sync_io.vhd
add_fileset_file sync_out.vhd VHDL PATH sync_out.vhd

add_fileset sim_vhdl SIM_VHDL "" "VHDL Simulation"
set_fileset_property sim_vhdl TOP_LEVEL sync_top
set_fileset_property sim_vhdl ENABLE_RELATIVE_INCLUDE_PATHS true
add_fileset_file sync_top.vhd VHDL PATH sync_top.vhd
add_fileset_file sync_regs.vhd VHDL PATH sync_regs.vhd
add_fileset_file sync_ctl.vhd VHDL PATH sync_ctl.vhd
add_fileset_file sync_irq.vhd VHDL PATH sync_irq.vhd
add_fileset_file sync_4k.vhd VHDL PATH sync_4k.vhd
add_fileset_file sync_16k.vhd VHDL PATH sync_16k.vhd
add_fileset_file sync_io.vhd VHDL PATH sync_io.vhd
add_fileset_file sync_out.vhd VHDL PATH sync_out.vhd

#
# parameters
#


#
# display items
#


#
# connection point s1
#
add_interface s1 avalon end
set_interface_property s1 addressUnits WORDS
set_interface_property s1 associatedClock clk
set_interface_property s1 associatedReset reset
set_interface_property s1 bitsPerSymbol 8
set_interface_property s1 burstOnBurstBoundariesOnly false
set_interface_property s1 burstcountUnits WORDS
set_interface_property s1 explicitAddressSpan 0
set_interface_property s1 holdTime 0
set_interface_property s1 linewrapBursts false
set_interface_property s1 maximumPendingReadTransactions 0
set_interface_property s1 readLatency 0
set_interface_property s1 readWaitTime 2
set_interface_property s1 setupTime 0
set_interface_property s1 timingUnits Cycles
set_interface_property s1 writeWaitTime 0
set_interface_property s1 ENABLED true

add_interface_port s1 read_n read_n Input 1
add_interface_port s1 write_n write_n Input 1
add_interface_port s1 address address Input 11
add_interface_port s1 readdata readdata Output 32
add_interface_port s1 writedata writedata Input 32
set_interface_assignment s1 embeddedsw.configuration.isFlash 0
set_interface_assignment s1 embeddedsw.configuration.isMemoryDevice 0
set_interface_assignment s1 embeddedsw.configuration.isNonVolatileStorage 0
set_interface_assignment s1 embeddedsw.configuration.isPrintableDevice 0

#
# connection point m1
#
add_interface m1 avalon start
set_interface_property m1 addressUnits SYMBOLS
set_interface_property m1 associatedClock clk
set_interface_property m1 associatedReset reset
set_interface_property m1 bitsPerSymbol 8
set_interface_property m1 burstOnBurstBoundariesOnly false
set_interface_property m1 burstcountUnits WORDS
set_interface_property m1 doStreamReads false
set_interface_property m1 doStreamWrites false
set_interface_property m1 holdTime 0
set_interface_property m1 linewrapBursts false
set_interface_property m1 maximumPendingReadTransactions 0
set_interface_property m1 readLatency 0
set_interface_property m1 readWaitTime 1
set_interface_property m1 setupTime 0
set_interface_property m1 timingUnits Cycles
set_interface_property m1 writeWaitTime 0
set_interface_property m1 ENABLED true

add_interface_port m1 m1_read read Output 1
add_interface_port m1 m1_rd_address address Output 32
add_interface_port m1 m1_readdata readdata Input 32
add_interface_port m1 m1_rd_waitreq waitrequest Input 1
add_interface_port m1 m1_rd_burstcount burstcount Output 9
add_interface_port m1 m1_rd_datavalid readdatavalid Input 1


#
# connection point irq
#
add_interface irq interrupt end
set_interface_property irq associatedAddressablePoint s1
set_interface_property irq associatedClock clk
set_interface_property irq associatedReset reset
set_interface_property irq ENABLED true

add_interface_port irq irq irq Output 1


#
# connection point clk
#
add_interface clk clock end
set_interface_property clk clockRate 0
set_interface_property clk ENABLED true

add_interface_port clk clk clk Input 1


#
# connection point reset
#
add_interface reset reset end
set_interface_property reset associatedClock clk
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true

add_interface_port reset reset_n reset_n Input 1


#
# connection point sync_export
#
add_interface sync_export conduit end
set_interface_property sync_export associatedClock clk
set_interface_property sync_export associatedReset reset
set_interface_property sync_export ENABLED true

add_interface_port sync_export head_addr export Input 16
add_interface_port sync_export tail_addr export Output 16

add_interface_port sync_export clkin export Input 1
add_interface_port sync_export dat export BiDir 8
add_interface_port sync_export rxf_n export Input 1
add_interface_port sync_export txe_n export Input 1
add_interface_port sync_export rd_n export Output 1
add_interface_port sync_export wr_n export Output 1
add_interface_port sync_export oe_n export Output 1
add_interface_port sync_export siwu_n export Output 1
add_interface_port sync_export pwrsav_n export Output 1
add_interface_port sync_export test_bit export Output 1
add_interface_port sync_export debug export Output 4

#
# DTS Entry
#
set_module_assignment embeddedsw.dts.vendor "omni"
set_module_assignment embeddedsw.dts.group "sync"
set_module_assignment embeddedsw.dts.name "sync"
set_module_assignment embeddedsw.dts.compatible "generic-uio"
