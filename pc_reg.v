`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.24
// Module Name:    pc_reg 
// Project Name:   SammingCPU
//
// Implementation of PC module, can be viewed as PC register
// When rst disabled, ce disabled, pc set to 0. 
// Or PC add 4 every rising edge of clk.
//
// PC and CE then send to instruction ROM, and inst(instruction) will be given by ROM
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module pc_reg(
	input wire 					clk,
	input wire 					rst,
	output reg[`InstAddrBus]	pc,
	output reg					ce
);

	always @(posedge clk)
	begin
		// when rst == 1, instruction RAM CE is set to 0
		// Otherwise RAM CE set to 1
		if (rst == `RstEnable) 
		begin
			ce <= `ChipDisable;
		end else
		begin
			ce <= `ChipEnable;
		end
	end
	
	always @(posedge clk)
	begin
		if (ce == `ChipDisable)
		begin
			pc <= 32'h00000000;
		end else
		begin
			pc <= pc + 4'h4;
		end
	end

endmodule
