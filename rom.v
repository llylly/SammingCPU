`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.23
// Module Name:    rom
// Project Name:   SammingCPU
//
// ROM
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module rom(
	input wire 					clk,
	input wire					rst,
	
	// output
	output reg[`ROMBus]			rom_data_o,
	output reg					rom_ready_o,
	
	// input
	input wire[`ROMAddrBus]		rom_addr_i,
	input wire					rom_we_i,
	input wire					rom_ce_i
);

	reg[`ROMBus] romSet[0 : `ROMNum - 1];

	initial $readmemh("I:\\CPU\\SammingCPU\\booter.mem", romSet);

	always @(posedge clk)
	begin
		if ((rst == `RstEnable) || (rom_ce_i == 1'b0))
		begin
			rom_data_o <= `ZeroWord;
			rom_ready_o <= 1'b0;
		end else
		begin
			if (rom_we_i == 1'b0)
			begin
				rom_data_o <= romSet[rom_addr_i[11:2]];
				rom_ready_o <= 1'b1;
			end
		end
	end

endmodule
