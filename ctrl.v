`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.5
// Module Name:    ctrl
// Project Name:   SammingCPU
//
// Pipeline pause controller module
// stall[0]=1 : PC module keep stall
// stall[1]=1 : IF stage keep stall
// stall[2]=1 : ID stage keep stall
// stall[3]=1 : EX stage keep stall
// stall[4]=1 : MEM stage keep stall
// stall[5]=1 : WB stage keep stall
//
// Stall mainly implemented in inter-module registers
// At stall border, next stage emitted NOP instruction and pre stage keeps stall
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ctrl(
	input wire 					rst,
	input wire					stallreq_from_id,
		// pause request from ID
	input wire					stallreq_from_ex,
		// pause request from EX
	input wire					stallreq_from_mem,
		// pause request from MEM
	output reg[5:0]				stall
		// output stall array
);

	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			stall <= 6'b000000;
		end else
		if (stallreq_from_ex == `Stop)
		begin
			stall <= 6'b001111;
		end else
		if (stallreq_from_id == `Stop)
		begin
			stall <= 6'b000111;
		end else
		if (stallreq_from_mem == `Stop)
		begin
			stall <= 6'b011111;
		end else
		begin
			stall <= 6'b000000;
		end
	end

endmodule
