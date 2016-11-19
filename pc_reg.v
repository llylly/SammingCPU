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
	
	input wire					flush,
	input wire[`RegBus]			new_pc,
		// for interrupt
	
	input wire[5:0]				stall,
	
	// for branch, when branch_flag = 1 and not stop, then pc = branch target address
	input wire					branch_flag_i,
	input wire[`RegBus]			branch_target_address_i,
	
	// to ram
	output reg[`InstAddrBus]	pc,
	output reg					ce,
	
	// from ram
	input wire[`RegBus]			pc_data_i,
	input wire					pc_ready_i,
	
	// to if-id
	output reg[`InstAddrBus]	pc_o,
	output reg[`InstBus]		inst_o,
	
	output reg					stallreq
);
	
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			pc <= 32'h00000000;
			ce <= 1'b1;
		end else 
		if (stall[0] == `NoStop)
		begin
			if (flush == 1'b1) 
			begin
				pc <= new_pc;
				ce <= 1'b1;
			end else
			if (branch_flag_i == `Branch)
			begin
				pc <= branch_target_address_i;
				ce <= 1'b1;
			end else
			begin
				pc <= pc + 4'h4;
				ce <= 1'b1;
			end
		end else
		begin
			ce <= 1'b0;
		end
	end
	
	always @(*)
	begin
		stallreq <= ~pc_ready_i;
		pc_o <= pc;
		inst_o <= pc_data_i;
	end

endmodule
