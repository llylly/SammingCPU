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
	input wire[5:0]				stall,
	input wire					flush,
	
	// signals from IF
	input wire[`InstAddrBus]	if_pc,
	input wire[`InstBus]		if_inst,
	input wire[`ExceptBus]		if_excepttype,
	
	// singals to ID
	output reg[`InstAddrBus]	id_pc,
	output reg[`InstBus]		id_inst,
	output reg[`ExceptBus]		id_excepttype
);

	always @(posedge clk) 
	begin
		if (rst == `RstEnable)
		begin
			// When RST on, all signals sent is zero
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
			id_excepttype <= `ZeroWord;
		end else
		if (flush == 1'b1) 
		begin
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
			id_excepttype <= `ZeroWord;
		end else
		if (stall[1] == `Stop && stall[2] == `NoStop) 
		begin
			// NOP added
			id_pc <= `ZeroWord;
			id_inst <= `ZeroWord;
			id_excepttype <= `ZeroWord;
		end else
		if (stall[1] == `NoStop)
		begin
			// Otherwise directly send
			id_pc <= if_pc;
			id_inst <= if_inst;
			id_excepttype <= if_excepttype;
		end
	end

endmodule
