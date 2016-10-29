`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    ex
// Project Name:   SammingCPU
//
// EX module
// Core executiong module
// Receive signals from ID-EX module and execute certain operation specified by aluop and alusel
// Send result, write register NO and whether to write signals to next module
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ex(
	input wire					rst,
	
	// receive from ID-EX
	input wire[`ALUOpBus]		aluop_i,
	input wire[`ALUSelBus]		alusel_i,
	input wire[`RegBus]			reg1_i,
	input wire[`RegBus]			reg2_i,
	input wire[`RegAddrBus]		wd_i,
	input wire					wreg_i,
	
	// output to EX-MEM
	output reg[`RegAddrBus]		wd_o,
		// specify which register to write, just transmit from input
	output reg					wreg_o,
		// specify whether to write register, just transmit from input
	output reg[`RegBus]			wdata_o
		// operation result
	
);

	reg[`RegBus] logicOut;
		// save result of logic operations
	reg[`RegBus] shiftRes;
		// save result of shift operations
		
	/* run certain calculation specified by aluop_i(subtype of ALU) of logic operation */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			logicOut <= `ZeroWord;
		end else
		begin
			case (aluop_i)
				`EXE_OR_OP: begin
					logicOut <= reg1_i | reg2_i;
				end
				`EXE_AND_OP: begin
					logicOut <= reg1_i & reg2_i;
				end
				`EXE_NOR_OP: begin
					logicOut <= ~(reg1_i | reg2_i);
				end
				`EXE_XOR_OP: begin
					logicOut <= reg1_i ^ reg2_i;
				end
				default: begin
					logicOut <= `ZeroWord;
				end
			endcase
		end
	end
	
	/* run certain calculation specified by aluop_i(subtype of ALU) of shift operation */
	always @(*) 
	begin
		if (rst == `RstEnable) 
		begin
			shiftRes <= `ZeroWord;
		end else
		begin
			case (aluop_i)
				`EXE_SLL_OP: begin
					shiftRes <= reg2_i << reg1_i[4:0];
				end
				`EXE_SRL_OP: begin
					shiftRes <= reg2_i >> reg1_i[4:0];
				end
				`EXE_SRA_OP: begin
					shiftRes <= ({32{reg2_i[31]}} << (6'd32 - {1'b0, reg1_i[4:0]})) |
						(reg2_i >> reg1_i[4:0]);
				end
				default: begin
					shiftRes <= `ZeroWord;
				end
			endcase
		end
	end
	
	/* choose one as final result according to alusel_i(type of ALU) */
	always @(*)
	begin
		wd_o <= wd_i;
		wreg_o <= wreg_i;
		case (alusel_i)
			`EXE_RES_LOGIC: begin
				wdata_o <= logicOut;
			end
			`EXE_RES_SHIFT: begin
				wdata_o <= shiftRes;
			end
			default: begin
				wdata_o <= `ZeroWord;
			end
		endcase
	end

endmodule
