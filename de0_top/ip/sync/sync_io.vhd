-- megafunction wizard: %ALTDDIO_BIDIR%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: ALTDDIO_BIDIR 

-- ============================================================
-- File Name: sync_io.vhd
-- Megafunction Name(s):
-- 			ALTDDIO_BIDIR
--
-- Simulation Library Files(s):
-- 			altera_mf
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 18.1.1 Build 646 04/11/2019 SJ Standard Edition
-- ************************************************************


--Copyright (C) 2019  Intel Corporation. All rights reserved.
--Your use of Intel Corporation's design tools, logic functions 
--and other software and tools, and any partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Intel Program License 
--Subscription Agreement, the Intel Quartus Prime License Agreement,
--the Intel FPGA IP License Agreement, or other applicable license
--agreement, including, without limitation, that your use is for
--the sole purpose of programming logic devices manufactured by
--Intel and sold by Intel or its authorized distributors.  Please
--refer to the applicable agreement for further details, at
--https://fpgasoftware.intel.com/eula.


LIBRARY ieee;
USE ieee.std_logic_1164.all;

LIBRARY altera_mf;
USE altera_mf.altera_mf_components.all;

ENTITY sync_io IS
	PORT
	(
		aclr		: IN STD_LOGIC ;
		datain_h		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		datain_l		: IN STD_LOGIC_VECTOR (7 DOWNTO 0);
		inclock		: IN STD_LOGIC ;
		oe		: IN STD_LOGIC ;
		outclock		: IN STD_LOGIC ;
		dataout_h		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		dataout_l		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		padio		: INOUT STD_LOGIC_VECTOR (7 DOWNTO 0)
	);
END sync_io;


ARCHITECTURE SYN OF sync_io IS

	SIGNAL sub_wire0	: STD_LOGIC_VECTOR (7 DOWNTO 0);
	SIGNAL sub_wire1	: STD_LOGIC_VECTOR (7 DOWNTO 0);

BEGIN
	dataout_h    <= sub_wire0(7 DOWNTO 0);
	dataout_l    <= sub_wire1(7 DOWNTO 0);

	ALTDDIO_BIDIR_component : ALTDDIO_BIDIR
	GENERIC MAP (
		extend_oe_disable => "OFF",
		implement_input_in_lcell => "OFF",
		intended_device_family => "Cyclone IV E",
		invert_output => "OFF",
		lpm_hint => "UNUSED",
		lpm_type => "altddio_bidir",
		oe_reg => "UNREGISTERED",
		power_up_high => "OFF",
		width => 8
	)
	PORT MAP (
		aclr => aclr,
		datain_h => datain_h,
		datain_l => datain_l,
		inclock => inclock,
		oe => oe,
		outclock => outclock,
		dataout_h => sub_wire0,
		dataout_l => sub_wire1,
		padio => padio
	);



END SYN;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: LIBRARY: altera_mf altera_mf.altera_mf_components.all
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone IV E"
-- Retrieval info: CONSTANT: EXTEND_OE_DISABLE STRING "OFF"
-- Retrieval info: CONSTANT: IMPLEMENT_INPUT_IN_LCELL STRING "OFF"
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone IV E"
-- Retrieval info: CONSTANT: INVERT_OUTPUT STRING "OFF"
-- Retrieval info: CONSTANT: LPM_HINT STRING "UNUSED"
-- Retrieval info: CONSTANT: LPM_TYPE STRING "altddio_bidir"
-- Retrieval info: CONSTANT: OE_REG STRING "UNREGISTERED"
-- Retrieval info: CONSTANT: POWER_UP_HIGH STRING "OFF"
-- Retrieval info: CONSTANT: WIDTH NUMERIC "8"
-- Retrieval info: USED_PORT: aclr 0 0 0 0 INPUT NODEFVAL "aclr"
-- Retrieval info: CONNECT: @aclr 0 0 0 0 aclr 0 0 0 0
-- Retrieval info: USED_PORT: datain_h 0 0 8 0 INPUT NODEFVAL "datain_h[7..0]"
-- Retrieval info: CONNECT: @datain_h 0 0 8 0 datain_h 0 0 8 0
-- Retrieval info: USED_PORT: datain_l 0 0 8 0 INPUT NODEFVAL "datain_l[7..0]"
-- Retrieval info: CONNECT: @datain_l 0 0 8 0 datain_l 0 0 8 0
-- Retrieval info: USED_PORT: dataout_h 0 0 8 0 OUTPUT NODEFVAL "dataout_h[7..0]"
-- Retrieval info: CONNECT: dataout_h 0 0 8 0 @dataout_h 0 0 8 0
-- Retrieval info: USED_PORT: dataout_l 0 0 8 0 OUTPUT NODEFVAL "dataout_l[7..0]"
-- Retrieval info: CONNECT: dataout_l 0 0 8 0 @dataout_l 0 0 8 0
-- Retrieval info: USED_PORT: inclock 0 0 0 0 INPUT_CLK_EXT NODEFVAL "inclock"
-- Retrieval info: CONNECT: @inclock 0 0 0 0 inclock 0 0 0 0
-- Retrieval info: USED_PORT: oe 0 0 0 0 INPUT NODEFVAL "oe"
-- Retrieval info: CONNECT: @oe 0 0 0 0 oe 0 0 0 0
-- Retrieval info: USED_PORT: outclock 0 0 0 0 INPUT_CLK_EXT NODEFVAL "outclock"
-- Retrieval info: CONNECT: @outclock 0 0 0 0 outclock 0 0 0 0
-- Retrieval info: USED_PORT: padio 0 0 8 0 BIDIR NODEFVAL "padio[7..0]"
-- Retrieval info: CONNECT: padio 0 0 8 0 @padio 0 0 8 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL sync_io.vhd TRUE FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL sync_io.qip TRUE FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL sync_io.bsf FALSE TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL sync_io_inst.vhd FALSE TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL sync_io.inc FALSE TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL sync_io.cmp FALSE TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL sync_io.ppf TRUE FALSE
-- Retrieval info: LIB_FILE: altera_mf