`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.29
// Module Name:    samming_cpu_test_sopc
// Project Name:   SammingCPU
//
// Current top module of all project
// A testing SOPC for sammingCPU
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module samming_cpu_test_sopc(
	input wire					clk,
	input wire					rst,

	output wire[`RegBus]		test_signal
		// used only for testing

);

	wire[`InstAddrBus] inst_addr;
	wire[`InstBus] inst;
	wire rom_ce;
	
	samming_cpu samming_cpu0(
		.clk(clk), .rst(rst),
		.rom_addr_o(inst_addr), .rom_data_i(inst),
		.rom_ce_o(rom_ce),
		.test_signal(test_signal)
	);
	
	test_inst_rom test_inst_rom0(
		.ce(rom_ce),
		.addr(inst_addr), .inst(inst)
	);


endmodule
