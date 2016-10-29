`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    if-id
// Project Name:   SammingCPU
//
// IF-ID module
// Save current PC and instruction, and send to ID level in next clock
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module if_id(
	input wire					clk,
	input wire					rst,
	
	// signals from IF
	input wire[`InstAddrBus]	if_pc,
	input wire[`InstBus]		if_inst,
	
	// singals to ID
	output reg[`InstAddrBus]	id_pc,
	output reg[`InstBus]		id_inst
);

	always @(posedge clk) 
	begin
		if (rst == `RstEnable)
		begin
			// When RST on, all signals sent is zero
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
		end else
		begin
			// Otherwise directly send
			id_pc <= if_pc;
			id_inst <= if_inst;
		end
	end

endmodule
