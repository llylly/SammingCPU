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
	output reg[`RegBus]			wdata_o,
		// operation result
		
	// HI/LO input wires
	input wire[`RegBus]			hi_i,
	input wire[`RegBus]			lo_i,
	
	input wire					mem_whilo_i,
		// bypass from MEM
	input wire[`RegBus]			mem_hi_i,
	input wire[`RegBus]			mem_lo_i,
	
	input wire					wb_whilo_i,
		// bypass from WB
	input wire[`RegBus]			wb_hi_i,
	input wire[`RegBus]			wb_lo_i,
	
	// HI/LO output wires
	output reg					whilo_o,
	output reg[`RegBus]			hi_o,
	output reg[`RegBus]			lo_o
	
);

	reg[`RegBus] logicOut;
		// save result of logic operations
	reg[`RegBus] shiftRes;
		// save result of shift operations
	reg[`RegBus] moveres;
		// save result of move operations
	reg[`RegBus] HI;
		// save latest HI value
	reg[`RegBus] LO;
		// save latest LO value
		
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
	
	/* determine latest HI/LO value */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			{HI, LO} <= {`ZeroWord, `ZeroWord};
		end else
		if (mem_whilo_i == `WriteEnable)
		begin
			{HI, LO} <= {mem_hi_i, mem_lo_i};
		end else
		if (wb_whilo_i == `WriteEnable)
		begin
			{HI, LO} <= {wb_hi_i, wb_lo_i};
		end else
		begin
			{HI, LO} <= {hi_i, lo_i};
		end
	end
	
	/* run certain calculation specified by aluop_i(subtype of ALU) of move operation */
	always @(*) 
	begin
		if (rst == `RstEnable)
		begin
			moveres <= `ZeroWord;
		end else
		begin
			moveres <= `ZeroWord;
			case (aluop_i)
				`EXE_MFHI_OP: begin
					moveres <= HI;
				end
				`EXE_MFLO_OP: begin
					moveres <= LO;
				end
				`EXE_MOVZ_OP: begin
					moveres <= reg1_i;
				end
				`EXE_MOVN_OP: begin
					moveres <= reg1_i;
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
			`EXE_RES_MOVE: begin
				wdata_o <= moveres;
			end
			default: begin
				wdata_o <= `ZeroWord;
			end
		endcase
	end
	
	/* handling MTHI and MTLO */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end else
		if (aluop_i == `EXE_MTHI_OP)
		begin
			whilo_o <= `WriteEnable;
			hi_o <= reg1_i;
			lo_o <= LO;
		end else
		if (aluop_i == `EXE_MTLO_OP)
		begin
			whilo_o <= `WriteEnable;
			hi_o <= HI;
			lo_o <= reg1_i;
		end else
		begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end
	end

endmodule
