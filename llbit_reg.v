`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.13
// Module Name:    LLbit_reg
// Project Name:   SammingCPU
//
// Implements LLbit register, which similar to HI/LO registers
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module llbit_reg(

	input wire					clk,
	input wire					rst,
	
	input wire					flush,
		// whether exception occurred
		
	// write operations
	input wire					llbit_i,
	input wire					we,
	
	// register value of LLbit
	output reg					llbit_o
);

	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			llbit_o <= 1'b0;
		end else
		if ((flush == 1'b1))
		begin
			llbit_o <= 1'b0;
		end else
		if ((we == `WriteEnable))
		begin
			llbit_o <= llbit_i;
		end
	end

endmodule
