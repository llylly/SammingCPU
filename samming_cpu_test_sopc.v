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

`define SIMULATE
//`define REALITY

module samming_cpu_test_sopc(
	input wire					clk,
	input wire					rst,
	
	input wire					com1_in,
	input wire 					com2_in,
	input wire					keyboard_in,
	
	`ifdef REALITY
	// from SRAM
	inout wire[`RAMBus]			base_ram_data,
	inout wire[`RAMBus]			ext_ram_data,
	
	// to SRAM
	output wire[`RAMAddrBus]	base_ram_addr,
	output wire					base_ram_ce,
	output wire					base_ram_oe,
	output wire					base_ram_we,
	
	output wire[`RAMAddrBus]	ext_ram_addr,
	output wire					ext_ram_ce,
	output wire					ext_ram_oe,
	output wire					ext_ram_we,
	`endif

	output wire[`RegBus]		test_signal
		// used only for testing

);

	/** slow frequency as cpu clock **/
	reg clk_1 = 1'b0, clk_2 = 1'b0, clk_3 = 1'b0, clk_4 = 1'b0;
	
	always @(posedge clk)
	begin
		clk_1 <= ~clk_1;
	end
	
	always @(posedge clk_1)
	begin
		clk_2 <= ~clk_2;
	end
	
	always @(posedge clk_2)
	begin
		clk_3 <= ~clk_3;
	end
	
	wire[`RegBus] ram_data_i;
	wire ram_ready_i;
	wire[`RegBus] ram_addr_o;
	wire ram_we_o;
	wire[3:0] ram_sel_o;
	wire[`RegBus] ram_data_o;
	wire ram_ce_o;
	
	wire[`RegBus] pc_ram_data_i;
	wire pc_ram_ready_i;
	wire[`InstAddrBus] pc_ram_o;
	
	`ifdef SIMULATE
	wire[`RAMBus] base_ram_data;
	wire[`RAMBus] ext_ram_data;
	wire[`RAMAddrBus] base_ram_addr;
	wire base_ram_ce;
	wire base_ram_oe;
	wire base_ram_we;
	wire[`RAMAddrBus] ext_ram_addr;
	wire ext_ram_ce;
	wire ext_ram_oe;
	wire ext_ram_we;
	
	test_ram test_ram0(
		.clk(clk),
		.base_ram_addr(base_ram_addr), .base_ram_ce(base_ram_ce),
		.base_ram_oe(base_ram_oe), .base_ram_we(base_ram_we),
		.ext_ram_addr(ext_ram_addr), .ext_ram_ce(ext_ram_ce),
		.ext_ram_oe(ext_ram_oe), .ext_ram_we(ext_ram_we),
		.base_ram_data(base_ram_data), .ext_ram_data(ext_ram_data)
	);
	`endif
	
	wire[5:0] int_i;
	wire timer_int;
	
	// int_i:   [0] - sysclock
	//			[1] - keyboard
	//			[3] - com2
	//			[4] - com1
	assign int_i = {1'b0, com1_in, com2_in, 1'b0, keyboard_in, timer_int};
	
	samming_cpu samming_cpu0(
		.clk(clk_3), .rst(rst),
		.ram_addr_o(ram_addr_o), .ram_we_o(ram_we_o),
		.ram_sel_o(ram_sel_o), .ram_data_o(ram_data_o), .ram_ce_o(ram_ce_o),
		.pc_ram_o(pc_ram_o),
		.ram_data_i(ram_data_i), .ram_ready_i(ram_ready_i),
		.pc_ram_data_i(pc_ram_data_i), .pc_ram_ready_i(pc_ram_ready_i),
		.int_i(int_i), .timer_int_o(timer_int),
		.test_signal(test_signal)
	);
	
	/* RAM adapter instantiate */
	ram_adapter ram_adapter0(
		.rst(rst), .clk(clk),
		.ram_addr_i(ram_addr_o), .ram_we_i(ram_we_o),
		.ram_sel_i(ram_sel_o), .ram_data_i(ram_data_o), .ram_ce_i(ram_ce_o),
		.ram_data_o(ram_data_i), .ram_ready_o(ram_ready_i),
		.pc_addr_i(pc_ram_o),
		.pc_data_o(pc_ram_data_i), .pc_ready_o(pc_ram_ready_i),
		.base_ram_data(base_ram_data), .ext_ram_data(ext_ram_data),
		.base_ram_addr(base_ram_addr), .base_ram_ce(base_ram_ce),
		.base_ram_oe(base_ram_oe), .base_ram_we(base_ram_we),
		.ext_ram_addr(ext_ram_addr), .ext_ram_ce(ext_ram_ce),
		.ext_ram_oe(ext_ram_oe), .ext_ram_we(ext_ram_we)
	);


endmodule
