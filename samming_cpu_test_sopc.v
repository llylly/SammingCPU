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

//`define SIMULATE
`define REALITY

module samming_cpu_test_sopc(
	input wire					clk,
	input wire					rst,
	
	`ifdef REALITY
	// serial
	output wire					rxd,
		// receive
	input wire					txd,
		// send
	
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
	
	// flash
	output wire[`FlashAddrBus]	flash_addr_o,
	inout wire[`FlashRealBus]	flash_data,
	output wire					flash_byte_o,
	output wire					flash_ce_o,
	output wire					flash_ce1_o,
	output wire					flash_ce2_o,
	output wire					flash_oe_o,
	output wire					flash_rp_o,
	input wire					flash_sys_i,
	output wire					flash_vpen_o,
	output wire					flash_we_o,
	
	input wire					ps2_clk_i,
	input wire					ps2_data_i,
	`endif

	// nixie
	output wire[0:6]			show1_o,
	output wire[0:6]			show0_o,
	
	// VGA
	output wire[8:0]			vga_color_o,
	output wire					vga_vhync_o,
	output wire					vga_hhync_o

);

	/** slow frequency as cpu clock **/
	wire clk50M, clk65M, clk325M;
	reg clk_1 = 1'b0, clk_2 = 1'b0, clk_3 = 1'b0, clk_4 = 1'b0, clk_5 = 1'b0;
	
	always @(posedge clk50M)
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
	
	always @(posedge clk_4)
	begin
		clk_5 <= ~clk_5;
	end
	
	// PLL
	`ifdef REALITY
	pll pll0(
		.CLK_IN1(clk),
		.CLK_OUT1(clk50M),
		.CLK_OUT2(clk65M),
		.CLK_OUT3(clk325M),
		.RESET(1'b0)
	);
	`endif
	`ifdef SIMULATE
		assign CLK50M = clk;
		assign CLK65M = clk;
	`endif
	
	// Nixie debug
	wire[7:0] nixie_o;
	
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
		.clk(clk50M),
		.base_ram_addr(base_ram_addr), .base_ram_ce(base_ram_ce),
		.base_ram_oe(base_ram_oe), .base_ram_we(base_ram_we),
		.ext_ram_addr(ext_ram_addr), .ext_ram_ce(ext_ram_ce),
		.ext_ram_oe(ext_ram_oe), .ext_ram_we(ext_ram_we),
		.base_ram_data(base_ram_data), .ext_ram_data(ext_ram_data)
	);
	`endif
	
	// SRAM
	wire sram_ready_i;
	wire[`RAMBus] sram_data_i;
	wire sram_we_o;
	wire sram_ce_o;
	wire[`RegBus] sram_addr_o;
	wire[`RAMBus] sram_data_o;
	wire[3:0] sram_sel_o;
	
	ram ram0(
		.rst(rst), .clk(clk50M),
		
		.we_i(sram_we_o), .ce_i(sram_ce_o),
		.addr_i(sram_addr_o), .data_i(sram_data_o), .sel_i(sram_sel_o),
		
		.ready_o(sram_ready_i), .data_o(sram_data_i),
		
		.base_ram_data(base_ram_data), .ext_ram_data(ext_ram_data),
		.base_ram_addr(base_ram_addr), .base_ram_ce(base_ram_ce),
		.base_ram_oe(base_ram_oe), .base_ram_we(base_ram_we),
		.ext_ram_addr(ext_ram_addr), .ext_ram_ce(ext_ram_ce),
		.ext_ram_oe(ext_ram_oe), .ext_ram_we(ext_ram_we)
	);
	
	// ROM
	wire[`ROMBus] rom_data_i;
	wire rom_ready_i;
	wire[`ROMAddrBus] rom_addr_o;
	wire rom_we_o;
	wire rom_ce_o;
	
	rom rom0(
		.clk(clk50M), .rst(rst),
		.rom_data_o(rom_data_i), .rom_ready_o(rom_ready_i),
		.rom_addr_i(rom_addr_o), .rom_we_i(rom_we_o), .rom_ce_i(rom_ce_o)
	);

	// Flash
	wire[`FlashBus] flashi_data_i;
	wire flashi_ready_i;
	wire[`FlashAddrBus] flashi_addr_o;
	wire flashi_ce_o;
	wire flashi_we_o;
	wire[`FlashBus] flashi_data_o;
	wire[3:0] flashi_sel_o;
	
	`ifdef SIMULATE
	test_flash test_flash0(
		.clk(clk50M), .rst(rst),
		.flash_data_o(flashi_data_i), .flash_ready_o(flashi_ready_i),
		.flash_addr_i(flashi_addr_o), .flash_ce_i(flashi_ce_o), .flash_we_i(flashi_we_o), .flash_data_i(flashi_data_o)
	);
	`endif
	
	`ifdef REALITY
	flash flash0(
		.clk(clk50M), .rst(rst),
		
		.data_o(flashi_data_i), .ready_o(flashi_ready_i),
		.addr_i(flashi_addr_o), .ce_i(flashi_ce_o), .we_i(flashi_we_o), .data_i(flashi_data_o), .sel_i(flashi_sel_o),
		
		.flash_addr_o(flash_addr_o), .flash_data(flash_data), .flash_byte_o(flash_byte_o), 
		.flash_ce_o(flash_ce_o), .flash_ce1_o(flash_ce1_o), .flash_ce2_o(flash_ce2_o),
		.flash_oe_o(flash_oe_o), .flash_rp_o(flash_rp_o), .flash_sys_i(flash_sys_i),
		.flash_vpen_o(flash_vpen_o), .flash_we_o(flash_we_o)
	);
	`endif
	
	// Serail
	wire[`RAMBus] serail_data_i;
	wire serail_ready_i;
	wire[`SerailAddrBus] serail_addr_o;
	wire[`RAMBus] serail_data_o;
	wire serail_we_o;
	wire serail_ce_o;
	wire[3:0] serail_sel_o;
	wire readEnable;
	wire writeBusy;
	wire[7:0] current_o;
	
	`ifdef SIMULATE
	test_serail test_serail0(
		.clk(clk50M), .rst(rst),
		.serail_data_o(serail_data_i), .serail_ready_o(serail_ready_i),
		.serail_addr_i(serail_addr_o), .serail_data_i(serail_data_o),
		.serail_we_i(serail_we_o), .serail_ce_i(serail_ce_o)
	);
	assign readEnable = 1'b0;
	assign writeBusy = 1'b0;
	assign current_o = 8'h00;
	`endif
	
	`ifdef REALITY
	serail serail0(
		.clk(clk50M), .rst(rst),
		.rxd(rxd), .txd(txd),
		
		.data_o(serail_data_i), .ready_o(serail_ready_i),
		.addr_i(serail_addr_o), .data_i(serail_data_o),
		.we_i(serail_we_o), .ce_i(serail_ce_o), .sel_i(serail_sel_o),
		
		.readEnable(readEnable), .writeBusy(writeBusy), .current_o(current_o),
		
		.ps2_clk_i(ps2_clk_i), .ps2_data_i(ps2_data_i)
	);
	`endif
	
	// vga display
	`ifdef REALITY
	vga vga0(
		.clk(clk65M), .rst(rst),
		.current_i(current_o), .writeBusy_i(writeBusy),
		.vga_color_o(vga_color_o), .vga_vhync_o(vga_vhync_o), .vga_hhync_o(vga_hhync_o),
		.debug(nixie_o)
	);
	`endif
	
	// nixie counter
	`ifdef REALITY
	reg[26:0] miclock = 26'h0;
	reg[7:0] mi = 8'h00;
	
	always @(posedge clk50M)
	begin
		if (miclock == 26'd50000000)
		begin
			miclock <= 26'd1;
			mi <= mi + 1;
		end else
			miclock <= miclock + 1;
	end
	
	nixie nixie0(
		.rst(rst), .data_i(mi), .show1_o(show1_o), .show0_o(show0_o)
	);
	`endif
	
	/*
	`ifdef REALITY
	nixie nixie0(
		.rst(rst), .data_i(nixie_o), .show1_o(show1_o), .show0_o(show0_o)
	);
	`endif
	*/
		
	wire[5:0] int_i;
	wire timer_int;
	
	// int_i:   [0] - sysclock
	//			[1] - keyboard
	//			[3] - com2
	//			[4] - com1
	assign int_i = {timer_int, 1'b0, 1'b0, readEnable, 1'b0, 1'b0};
		// construct outer interrupt vector

	samming_cpu samming_cpu0(
		.clk(clk_4), .busclk(clk50M), .rst(rst),
		.int_i(int_i), .timer_int_o(timer_int),
		// sram
		.sram_ready_i(sram_ready_i), .sram_data_i(sram_data_i),
		.sram_we_o(sram_we_o), .sram_ce_o(sram_ce_o),
		.sram_addr_o(sram_addr_o), .sram_data_o(sram_data_o),
		.sram_sel_o(sram_sel_o),
		// ROM
		.rom_data_i(rom_data_i), .rom_ready_i(rom_ready_i),
		.rom_addr_o(rom_addr_o), .rom_we_o(rom_we_o), .rom_ce_o(rom_ce_o),
		// Flash
		.flash_data_i(flashi_data_i), .flash_ready_i(flashi_ready_i),
		.flash_addr_o(flashi_addr_o), .flash_ce_o(flashi_ce_o), 
		.flash_we_o(flashi_we_o), .flash_data_o(flashi_data_o),
		.flash_sel_o(flashi_sel_o),
		
		// Serail
		.serail_data_i(serail_data_i), .serail_ready_i(serail_ready_i),
		.serail_addr_o(serail_addr_o), .serail_data_o(serail_data_o),
		.serail_we_o(serail_we_o), .serail_ce_o(serail_ce_o), .serail_sel_o(serail_sel_o)
	);

endmodule
