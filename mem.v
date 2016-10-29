`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    mem
// Project Name:   SammingCPU
//
// MEM module
// Currently load/store operation is not supported, so this module only sends signals to next module now
// Or it will execute read and write from RAM operation
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem(
	input wire					rst,
	
	// from EX stage
	input wire[`RegAddrBus]		wd_i,
	input wire					wreg_i,
	input wire[`RegBus]			wdata_i,
	
	// to WB stage
	output reg[`RegAddrBus]		wd_o,
	output reg					wreg_o,
	output reg[`RegBus]			wdata_o
);

	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			// treat as NOP when rst == 1
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			wdata_o <= `ZeroWord;
		end else
		begin
			wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
		end
	end

endmodule
