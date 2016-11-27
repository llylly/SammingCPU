`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.23
// Module Name:    test_flash
// Project Name:   SammingCPU
//
// A simulate flash used for testing
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module test_flash(

	input wire					clk,
	input wire					rst,

	// output
	output reg[`FlashBus]		flash_data_o,
	output reg					flash_ready_o,
	
	// input
	input wire[`FlashAddrBus]	flash_addr_i,
	input wire					flash_ce_i,
	input wire					flash_we_i,
	input wire[`FlashBus]		flash_data_i
);

	reg[`FlashBus] flashSet[0 : `FlashNum - 1];
	
	initial $readmemh("I:\\CPU\\SammingCPU\\init_flash.mem", flashSet);
	
	always @(posedge clk)
	begin
		if ((rst == `RstEnable) || (flash_ce_i == 1'b0))
		begin
			flash_ready_o <= 1'b0;
		end else
		begin
			if (flash_we_i == 1'b0)
			begin
				flash_data_o <= flashSet[flash_addr_i[`FlashSimuBus]];
				flash_ready_o <= 1'b1;
			end else
			if (flash_we_i == 1'b1)
			begin
				flashSet[flash_addr_i[`FlashSimuBus]] <= flash_data_i;
				flash_ready_o <= 1'b1;
			end
		end
	
	end

endmodule
