`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.29
// Module Name:    test_inst_rom
// Project Name:   SammingCPU
//
// Temp instruction ROM only used for testing
// In final version this is implemented by chip RAM
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module test_inst_rom(
	input wire 					ce,
		// ROM enable signal
	input wire[`InstAddrBus]	addr,
		// ROM address input
	output reg[`InstBus]		inst
		// ROM instruction output
);

	reg[`InstBus] inst_mem[0: `InstMemNum-1];
	
	initial $readmemh("I:\\CPU\\SammingCPU\\inst_rom.mem", inst_mem);
	
	always @(*) 
	begin
		if (ce == `ChipDisable)
		begin
			inst <= `ZeroWord;
		end else
		begin
			// divide address by 4 then uses
			inst <= inst_mem[addr[`InstMemNumLog2 + 1 : 2]];
		end
	end

endmodule
