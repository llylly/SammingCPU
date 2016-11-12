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
	input wire[5:0]				stall,
	
	// for branch, when branch_flag = 1 and not stop, then pc = branch target address
	input wire					branch_flag_i,
	input wire[`RegBus]			branch_target_address_i,
	
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
		if (stall[0] == `NoStop)
		begin
			if (branch_flag_i == `Branch)
			begin
				pc <= branch_target_address_i;
			end else
			begin
				pc <= pc + 4'h4;
			end
		end
	end

endmodule
