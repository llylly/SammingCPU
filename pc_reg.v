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
	
	// from ram
	input wire[`RegBus]			pc_data_i,
	input wire					pc_ready_i,
	
	// port for record elb exception
	input wire					tlb_err_i,
	
	// to if-id
	output reg[`InstAddrBus]	pc_o,
	output reg[`InstBus]		inst_o,
	
	// exception
	output wire[`ExceptBus]		excepttype_o,
	
	// bubble
	output wire					if_isbubble_o,
	
	output reg					stallreq
);

	wire adel;
	
	assign adel = ~(pc[1:0] == 2'b00);
	
	assign if_isbubble_o = 1'b0;
	
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			pc <= new_pc;
		end else 
		if (stall[0] == `NoStop)
		begin
			if (flush == 1'b1) 
			begin
				pc <= new_pc;
			end else
			if (branch_flag_i == `Branch)
			begin
				pc <= branch_target_address_i;
			end else
			begin
				pc <= pc + 4'h4;
			end
		end else
		begin
		end
	end
	
	assign excepttype_o = {{10{1'b0}}, {5{1'b0}}, adel, 1'b0, tlb_err_i, {15{1'b0}}};
	
	always @(*)
	begin
		stallreq <= ~pc_ready_i;
		pc_o <= pc;
		inst_o <= pc_data_i;
	end

endmodule
