`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    id
// Project Name:   SammingCPU
//
// ID module
// Translate instruction
// Give value of operands from reading registers
// Data bypath added
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module id(
	input wire					rst,
	input wire[`InstAddrBus]	pc_i,
		// PC
	input wire[`InstBus]		inst_i,
		// instruction
	
	// regs data from regfile
	input wire[`RegBus]			reg1_data_i,
	input wire[`RegBus]			reg2_data_i,
	
	// data bypath
	input wire					ex_wreg_i,
	input wire[`RegBus]			ex_wdata_i,
	input wire[`RegAddrBus]		ex_wd_i,
	
	input wire					mem_wreg_i,
	input wire[`RegBus]			mem_wdata_i,
	input wire[`RegAddrBus]		mem_wd_i,
	
	// control signals output to regfile
	output reg					reg1_read_o,
		// read enable for reg port 1
	output reg					reg2_read_o,
		// read enable for reg port 2
	output reg[`RegAddrBus]		reg1_addr_o,
		// read addr for reg port 1
	output reg[`RegAddrBus]		reg2_addr_o,
		// read addr for reg port 2
		
	// control signals for EXE
	output reg[`ALUOpBus]		aluop_o,
		// detail op type of ALU
	output reg[`ALUSelBus]		alusel_o,
		// macro op type of ALU
	output reg[`RegBus]			reg1_o,
		// operand 1
	output reg[`RegBus]			reg2_o,
		// operand 2
	output reg[`RegAddrBus]		wd_o,
		// to write register no
	output reg					wreg_o,
		// whether write op is required for current instruction
		
	// control signal for pipeline stall
	output wire					stallreq

);

	// get inst code and func code
	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];
	
	// save immediate num of instruction
	reg[`RegBus] imm;
	
	// whether instruction is valid
	reg instValid;

	/* transcode instruction */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			// when reset, treat as NOP instruction
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			instValid = `InstValid;
			
			reg1_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_read_o <= 2'b0;
			reg2_addr_o <= `NOPRegAddr;
			
			imm <= 32'h0;
		end else
		begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
				// [15:11] is rd position => if write needed, write to this register
			wreg_o <= `WriteDisable;
			instValid <= `InstInvalid;
			
			reg1_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
				// discard regfile port 1
			reg2_read_o <= 1'b0;
			reg2_addr_o <= inst_i[20:16];
				// discard regfile port 2
			
			imm <= `ZeroWord;
			
			case (op) 
			// [31:26]
				`EXE_SPECIAL: begin
					// handle instuction code == 0 operations
					case (op2)
					// [10:6]
						5'b00000: begin
							case (op3)
							//[5:0]
								`EXE_OR: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_OR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_AND: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_AND_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_XOR: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_XOR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_NOR: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_NOR_OP;
									alusel_o <= `EXE_RES_LOGIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_SLLV: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLL_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_SRLV: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SRL_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_SRAV: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SRA_OP;
									alusel_o <= `EXE_RES_SHIFT;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_SYNC: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_NOP_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instValid <= `InstValid;
								end
								`EXE_MFHI: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MFHI_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instValid <= `InstValid;
								end
								`EXE_MFLO: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MFLO_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instValid <= `InstValid;
								end
								`EXE_MTHI: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MTHI_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instValid <= `InstValid;
								end
								`EXE_MTLO: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MTLO_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instValid <= `InstValid;
								end
								`EXE_MOVN: begin
									aluop_o <= `EXE_MOVN_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
									if (reg2_o != `ZeroWord) 
									begin
										wreg_o <= `WriteEnable;
									end else
									begin
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_MOVZ: begin
									aluop_o <= `EXE_MOVZ_OP;
									alusel_o <= `EXE_RES_MOVE;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
									if (reg2_o == `ZeroWord)
									begin
										wreg_o <= `WriteEnable;
									end else
									begin
										wreg_o <= `WriteDisable;
									end
								end
								`EXE_SLT: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLT_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_SLTU: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SLTU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_ADD: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_ADD_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_ADDU: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_ADDU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_SUB: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SUB_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_SUBU: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_SUBU_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_MULT: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MULT_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_MULTU: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MULTU_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_DIV: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_DIV_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_DIVU: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_DIVU_OP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								default: begin
								end
							endcase
						end
						default: begin
						end
					endcase
				end
				`EXE_SPECIAL2: begin
				// handle instuction code == 011100 operations
					case (op2)
					// [10:6]
						5'b00000: begin
							case (op3)
							//[5:0]
								`EXE_CLZ: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_CLZ_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instValid <= `InstValid;
								end
								`EXE_CLO: begin
									wreg_o <= `WriteEnable;
									aluop_o <= 	`EXE_CLO_OP;
									alusel_o <= `EXE_RES_ARITHMETIC;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									instValid <= `InstValid;
								end
								`EXE_MUL: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_MUL_OP;
									alusel_o <= `EXE_RES_MUL;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_MADD: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MADD_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_MADDU: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MADDU_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_MSUB: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MSUB_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_MSUBU: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_MSUBU_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								default: begin
								end
							endcase
						end
						default: begin
						end
					endcase
				end
				`EXE_ORI: begin
					wreg_o <= `WriteEnable;
						// need to write to register
					aluop_o <= `EXE_OR_OP;
						// ALU need execute OR operation
					alusel_o <= `EXE_RES_LOGIC;
						// ALU need execute logic operation
					reg1_read_o <= 1'b1;
						// need read port 1
					reg2_read_o <= 1'b0;
						// discard read port 2
					imm <= {16'h0, inst_i[15:0]};
						// unsigned extension
					wd_o <= inst_i[20:16];
						// aim register to write
					instValid <= `InstValid;
						// a valid instruction
				end
				`EXE_ANDI: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_AND_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_XORI: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_XOR_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {16'h0, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_LUI: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_OR_OP;
					alusel_o <= `EXE_RES_LOGIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {inst_i[15:0], 16'h0};
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_PREF: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_NOP_OP;
					alusel_o <= `EXE_RES_NOP;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					instValid <= `InstValid;
				end
				`EXE_SLTI: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLT_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]}; // signed
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_SLTIU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLTU_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_ADDI: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_ADDI_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_ADDIU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_ADDIU_OP;
					alusel_o <= `EXE_RES_ARITHMETIC;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					imm <= {{16{inst_i[15]}}, inst_i[15:0]};
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				default: begin
				
				end
			endcase
			
			// handle immediate shift operation which has special form
			if (inst_i[31:21] == 11'b00000000000)
			begin
				if (op3 == `EXE_SLL)
				begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SLL_OP;
					alusel_o <= `EXE_RES_SHIFT;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;
					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];
					instValid <= `InstValid;
				end else
				if (op3 == `EXE_SRL)
				begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SRL_OP;
					alusel_o <= `EXE_RES_SHIFT;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;
					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];
					instValid <= `InstValid;
				end else
				if (op3 == `EXE_SRA)
				begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SRA_OP;
					alusel_o <= `EXE_RES_SHIFT;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b1;
					imm[4:0] <= inst_i[10:6];
					wd_o <= inst_i[15:11];
					instValid <= `InstValid;
				end
			end
		end
	end
	
	/* determine source operand 1 */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			reg1_o <= `ZeroWord;
		end else
		/* bypath handling */
		if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o))
		begin
			reg1_o <= ex_wdata_i;
		end else
		if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o))
		begin
			reg1_o <= mem_wdata_i;
		end else
		/* end bypath handling */
		if (reg1_read_o == 1'b1)
		begin
			reg1_o <= reg1_data_i;
		end else
		if (reg1_read_o == 1'b0)
		begin
			// unused output operands always filled by Imm
			reg1_o <= imm;
		end else
		begin
			reg1_o <= `ZeroWord;
		end
	end
	
	/* determine source operand 2 */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			reg2_o <= `ZeroWord;
		end else
		/* bypath handling */
		if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o))
		begin
			reg2_o <= ex_wdata_i;
		end else
		if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o))
		begin
			reg2_o <= mem_wdata_i;
		end else
		/* end bypath handling */
		if (reg2_read_o == 1'b1)
		begin
			reg2_o <= reg2_data_i;
		end else
		if (reg2_read_o == 1'b0)
		begin
			// unused output operands always filled by Imm
			reg2_o <= imm;
		end else
		begin
			reg2_o <= `ZeroWord;
		end
	end
	
	/* pipeline stall signal */
	assign stallreq = `NoStop;

endmodule
