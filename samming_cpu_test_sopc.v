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
	
	always @(posedge clk_3)
	begin
		clk_4 <= ~clk_4;
	end
	
	// SRAM simulator
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
	
	// ROM
	wire[`ROMBus] rom_data_i;
	wire rom_ready_i;
	wire[`ROMAddrBus] rom_addr_o;
	wire rom_we_o;
	wire rom_ce_o;
	
	rom rom0(
		.clk(clk), .rst(rst),
		.rom_data_o(rom_data_i), .rom_ready_o(rom_ready_i),
		.rom_addr_i(rom_addr_o), .rom_we_i(rom_we_o), .rom_ce_i(rom_ce_o)
	);

	// Flash
	wire[`FlashBus] flash_data_i;
	wire flash_ready_i;
	wire[`FlashAddrBus] flash_addr_o;
	wire flash_ce_o;
	wire flash_we_o;
	wire[`FlashBus] flash_data_o;
	
	`ifdef SIMULATE
	test_flash test_flash0(
		.clk(clk), .rst(rst),
		.flash_data_o(flash_data_i), .flash_ready_o(flash_ready_i),
		.flash_addr_i(flash_addr_o), .flash_ce_i(flash_ce_o), .flash_we_i(flash_we_o), .flash_data_i(flash_data_o)
	);
	`endif
	
	// Serail
	wire[`RAMBus] serail_data_i;
	wire serail_ready_i;
	wire[`SerailAddrBus] serail_addr_o;
	wire[`RAMBus] serail_data_o;
	wire[`RAMBus] serail_we_o;
	wire[`RAMBus] serail_ce_o;
	
	`ifdef SIMULATE
	test_serail test_serail0(
		.clk(clk), .rst(rst),
		.serail_data_o(serail_data_i), .serail_ready_o(serail_ready_i),
		.serail_addr_i(serail_addr_o), .serail_data_i(serail_data_o),
		.serail_we_i(serail_we_o), .serail_ce_i(serail_ce_o)
	);
	`endif
		
	wire[5:0] int_i;
	wire timer_int;
	
	// int_i:   [0] - sysclock
	//			[1] - keyboard
	//			[3] - com2
	//			[4] - com1
	assign int_i = {1'b0, com1_in, com2_in, 1'b0, keyboard_in, timer_int};
		// construct outer interrupt vector
	
	samming_cpu samming_cpu0(
		.clk(clk_4), .busclk(clk), .rst(rst),
		.int_i(int_i), .timer_int_o(timer_int),
		// sram
		.base_ram_data(base_ram_data), .ext_ram_data(ext_ram_data),
		.base_ram_addr(base_ram_addr), .base_ram_ce(base_ram_ce),
		.base_ram_oe(base_ram_oe), .base_ram_we(base_ram_we),
		.ext_ram_addr(ext_ram_addr), .ext_ram_ce(ext_ram_ce),
		.ext_ram_oe(ext_ram_oe), .ext_ram_we(ext_ram_we),
		// ROM
		.rom_data_i(rom_data_i), .rom_ready_i(rom_ready_i),
		.rom_addr_o(rom_addr_o), .rom_we_o(rom_we_o), .rom_ce_o(rom_ce_o),
		// Flash
		.flash_data_i(flash_data_i), .flash_ready_i(flash_ready_i),
		.flash_addr_o(flash_addr_o), .flash_ce_o(flash_ce_o), .flash_we_o(flash_we_o), .flash_data_o(flash_data_o),
		// Serail
		.serail_data_i(serail_data_i), .serail_ready_i(serail_ready_i),
		.serail_addr_o(serail_addr_o), .serail_data_o(serail_data_o),
		.serail_we_o(serail_we_o), .serail_ce_o(serail_ce_o),
		
		.test_signal(test_signal)
	);


endmodule
