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

`define InUcore
//`define NotInUcore

module ctrl(
	input wire 					rst,
	input wire					stallreq_from_pc,
		// pause request from pc_reg
	input wire					stallreq_from_id,
		// pause request from ID
	input wire					stallreq_from_ex,
		// pause request from EX
	input wire					stallreq_from_mem,
		// pause request from MEM
	input wire[`RegBus]			cp0_epc_i,
		// latest value of epc
	input wire[`ExceptBus]		excepttype_i,
		// final exception type
	input wire[`RegBus]			ebase_i,
		// ebase used for exception entrance
	input wire[`RegBus]			status_i,
		// cp0 status
	input wire[`RegBus]			cause_i,
		// cp0 cause
	output reg[5:0]				stall,
		// output stall array
	output reg[`RegBus]			new_pc,
		// pc-to-go for exception
	output reg					flush
		// flush signal
);

	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			stall <= 6'b000000;
			flush <= 1'b0;
			// RESET exception
			`ifdef InUcore
				new_pc <= 32'hBFC00000;
				//new_pc <= 32'h80000000;
			`endif
			`ifdef NotInUcore
				new_pc <= `ZeroWord;
			`endif
		end else
		if (excepttype_i != `ZeroWord)
		begin
			flush <= 1'b1;
			stall <= 6'b000000;
			
			`ifdef InUcore
			case (excepttype_i)
			
				`ERET_EXP: begin
					new_pc <= cp0_epc_i;
				end
				
				default: begin
					new_pc <= ebase_i;
				end
			
			endcase
			`endif
			
			`ifdef NotInUcore
			case (excepttype_i)
			
				// TLB refill
				`TLBL_EXP, `TLBS_EXP: begin
					// BEV=0
					if (status_i[22] == 1'b0)
					begin
						// EXL=0
						if (status_i[1] == 1'b0)
						begin
							new_pc <= 32'h80000000;
						end else
						// EXL=1
						if (status_i[1] == 1'b1)
						begin
							new_pc <= 32'h80000180;
						end
					end else
					// BEV=1
					if (status_i[22] == 1'b1)
					begin
						// EXL=0
						if (status_i[1] == 1'b0)
						begin
							new_pc <= 32'hBFC00200;
						end else
						// EXL1
						if (status_i[1] == 1'b1)
						begin
							new_pc <= 32'hBFC00380;
						end
					end
				end
				
				`INTERRUPT_EXP: begin
					// BEV=0
					if (status_i[22] == 1'b0)
					begin
						// IV=0
						if (cause_i[23] == 1'b0)
						begin
							new_pc <= 32'h80000180;
						end else
						// IV=1
						if (cause_i[23] == 1'b1)
						begin
							new_pc <= 32'h80000200;
						end
					end else
					// BEV=1
					if (status_i[22] == 1'b1)
					begin
						// IV=0
						if (cause_i[23] == 1'b0)
						begin
							new_pc <= 32'hBFC00380;
						end else
						// IV=1
						if (cause_i[23] == 1'b1)
						begin
							new_pc <= 32'hBFC00400;
						end
					end
				end
				
				`ERET_EXP: begin
					new_pc <= cp0_epc_i;
				end
				
				default: begin
					// BEV=0
					if (status_i[22] == 1'b0)
					begin
						new_pc <= 32'h80000180;
					end else
					// BEV=1
					if (status_i[22] == 1'b1)
					begin
						new_pc <= 32'hBFC00380;
					end
				end
			endcase
			`endif
		end else
		if (stallreq_from_mem == `Stop)
		begin
			stall <= 6'b011111;
			flush <= 1'b0;
		end else
		if (stallreq_from_ex == `Stop)
		begin
			stall <= 6'b001111;
			flush <= 1'b0;
		end else
		if (stallreq_from_id == `Stop)
		begin
			stall <= 6'b000111;
			flush <= 1'b0;
		end else
		if (stallreq_from_pc == `Stop)
		begin
			stall <= 6'b111111;
			flush <= 1'b0;
		end else
		begin
			stall <= 6'b000000;
			flush <= 1'b0;
		end
	end

endmodule
