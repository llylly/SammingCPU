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
	
	// branch related signals
	input wire					is_in_delayslot_i,
		// if current inst is in delay slot
	output reg					next_inst_in_delayslot_o,
		// if next inst is in delay slot
	output reg					branch_flag_o,
		// if branch occurred
	output reg[`RegBus]			branch_target_address_o,
		// destination address
	output reg[`RegBus]			link_addr_o,
		// saved return address for branch inst
	output reg					is_in_delayslot_o,
		// if current inst is in delay slot
		
	// inst out
	output wire[`RegBus]		inst_o,
	
	// bypass from EX
	input wire[`ALUOpBus]		ex_aluop_i,
	
	// interrupt port
	input wire[`ExceptBus]		excepttype_i,
	output wire[`ExceptBus]		excepttype_o,
	output wire[`InstAddrBus]	current_inst_address_o,
	
	// mtc0 bubbles cnt
	input wire[1:0]				mtc0_cnt_i,
	output reg[1:0]				mtc0_cnt_o,
	
	// bubble
	input wire					id_isbubble_i,
	output wire					id_isbubble_o,
	
	// control signal for pipeline stall
	output wire					stallreq

);

	assign inst_o = inst_i;

	// get inst code and func code
	wire[5:0] op = inst_i[31:26];
	wire[4:0] op2 = inst_i[10:6];
	wire[5:0] op3 = inst_i[5:0];
	wire[4:0] op4 = inst_i[20:16];
	
	// save immediate num of instruction
	reg[`RegBus] imm;
	
	// whether instruction is valid
	reg instValid;
	
	wire[`RegBus] pc_plus_8;
	wire[`RegBus] pc_plus_4;
	wire[`RegBus] imm_sll2_signedext;
		// signed extended for Imm << 2
	
	assign pc_plus_8 = pc_i + 8;
		// save next second inst address
	assign pc_plus_4 = pc_i + 4;
		// save next inst address
	assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};
		// used in branch inst as offset
		
	reg stallreq_for_reg1_load_relate;
	reg stallreq_for_reg2_load_relate;
	reg stallreq_for_mtc0;
	wire pre_inst_is_load;
	wire pre_inst_is_mtc0;
	
	assign pre_inst_is_load =(	(ex_aluop_i == `EXE_LB_OP) ||
								(ex_aluop_i == `EXE_LBU_OP) ||
								(ex_aluop_i == `EXE_LH_OP) ||
								(ex_aluop_i == `EXE_LHU_OP) ||
								(ex_aluop_i == `EXE_LW_OP) ||
								(ex_aluop_i == `EXE_LWR_OP) ||
								(ex_aluop_i == `EXE_LWL_OP) ||
								(ex_aluop_i == `EXE_LL_OP) ||
								(ex_aluop_i == `EXE_SC_OP)) ? 1'b1 : 1'b0;
	
	assign pre_inst_is_mtc0 = (ex_aluop_i == `EXE_MTC0_OP) || (ex_aluop_i == `EXE_TLBR_OP);
	
	// interrupt handle 
	reg excepttype_is_syscall;
		// whether it is syscall
	reg excepttype_is_eret;
		// whether it is eret
		
		// excepttype records type of interrupt
		// [0-7] : for external interrupt
		// [8] : syscall
		// [9] : invalid instruction
		// [12]: eret ( which viewed as a special exception)
	assign excepttype_o = {excepttype_i[31:13], excepttype_is_eret, excepttype_i[11:10], instValid, excepttype_is_syscall, 8'b0};
	
	assign current_inst_address_o = pc_i;
	
	assign id_isbubble_o = id_isbubble_i;

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
			instValid <= `InstValid;
			excepttype_is_syscall <= `FalseValue;
			excepttype_is_eret <= `FalseValue;
			
			reg1_read_o <= 1'b0;
			reg1_addr_o <= `NOPRegAddr;
			reg2_read_o <= 2'b0;
			reg2_addr_o <= `NOPRegAddr;
			
			imm <= 32'h0;
			
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
		end else
		begin
			aluop_o <= `EXE_NOP_OP;
			alusel_o <= `EXE_RES_NOP;
			wd_o <= inst_i[15:11];
				// [15:11] is rd position => if write needed, write to this register
			wreg_o <= `WriteDisable;
			excepttype_is_syscall <= `FalseValue;
			excepttype_is_eret <= `FalseValue;
			instValid <= `InstInvalid;
			
			reg1_read_o <= 1'b0;
			reg1_addr_o <= inst_i[25:21];
				// discard regfile port 1
			reg2_read_o <= 1'b0;
			reg2_addr_o <= inst_i[20:16];
				// discard regfile port 2
			
			imm <= `ZeroWord;
			
			link_addr_o <= `ZeroWord;
			branch_target_address_o <= `ZeroWord;
			branch_flag_o <= `NotBranch;
			next_inst_in_delayslot_o <= `NotInDelaySlot;
			
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
								`EXE_JR: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_JR_OP;
									alusel_o <= `EXE_RES_JUMP_BRANCH;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									link_addr_o <= `ZeroWord;
									branch_target_address_o <= reg1_o;
									branch_flag_o <= `Branch;
									next_inst_in_delayslot_o <= `InDelaySlot;
									instValid <= `InstValid;
								end
								`EXE_JALR: begin
									wreg_o <= `WriteEnable;
									aluop_o <= `EXE_JALR_OP;
									alusel_o <= `EXE_RES_JUMP_BRANCH;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b0;
									wd_o <= inst_i[15:11];
									link_addr_o <= pc_plus_8;
									branch_target_address_o <= reg1_o;
									branch_flag_o <= `Branch;
									next_inst_in_delayslot_o <= `InDelaySlot;
									instValid <= `InstValid;
								end
								`EXE_TEQ: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_TEQ_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_TGE: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_TGE_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_TGEU: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_TGEU_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_TLT: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_TLT_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_TLTU: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_TLTU_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_TNE: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_TNE_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b1;
									reg2_read_o <= 1'b1;
									instValid <= `InstValid;
								end
								`EXE_SYSCALL: begin
									wreg_o <= `WriteDisable;
									aluop_o <= `EXE_SYSCALL_OP;
									alusel_o <= `EXE_RES_NOP;
									reg1_read_o <= 1'b0;
									reg2_read_o <= 1'b0;
									instValid <= `InstValid;
									excepttype_is_syscall <= `TrueValue;
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
				`EXE_REGIMM: begin
				// handle instuction code == 000001 operations
					case (op4)
					// [20:16]
						`EXE_BGEZ: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BGEZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							link_addr_o <= `ZeroWord;
							if (reg1_o[31] == 1'b0)
							begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
							instValid <= `InstValid;
						end
						`EXE_BGEZAL: begin
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_BGEZAL_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							link_addr_o <= pc_plus_8;
							wd_o <= 5'b11111;
							if (reg1_o[31] == 1'b0)
							begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
							instValid <= `InstValid;
						end
						`EXE_BLTZ: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_BLTZ_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							link_addr_o <= `ZeroWord;
							if (reg1_o[31] == 1'b1)
							begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
							instValid <= `InstValid;
						end
						`EXE_BLTZAL: begin
							wreg_o <= `WriteEnable;
							aluop_o <= `EXE_BLTZAL_OP;
							alusel_o <= `EXE_RES_JUMP_BRANCH;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							link_addr_o <= pc_plus_8;
							wd_o <= 5'b11111;
							if (reg1_o[31] == 1'b1)
							begin
								branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
								branch_flag_o <= `Branch;
								next_inst_in_delayslot_o <= `InDelaySlot;
							end
							instValid <= `InstValid;
						end
						`EXE_TEQI: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TEQI_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
							instValid <= `InstValid;
						end
						`EXE_TGEI: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TGEI_OP;
							alusel_o <=`EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
							instValid <= `InstValid;
						end
						`EXE_TGEIU: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TGEIU_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
							instValid <= `InstValid;
						end
						`EXE_TLTI: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TLTI_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
							instValid <= `InstValid;
						end
						`EXE_TLTIU: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TLTIU_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
							instValid <= `InstValid;
						end
						`EXE_TNEI: begin
							wreg_o <= `WriteDisable;
							aluop_o <= `EXE_TNEI_OP;
							alusel_o <= `EXE_RES_NOP;
							reg1_read_o <= 1'b1;
							reg2_read_o <= 1'b0;
							imm <= {{16{inst_i[15]}}, inst_i[15:0]};
							instValid <= `InstValid;
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
				`EXE_J: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_J_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					link_addr_o <= `ZeroWord;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
					instValid <= `InstValid;
				end
				`EXE_JAL: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_JAL_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b0;
					reg2_read_o <= 1'b0;
					wd_o <= 5'b11111;
					link_addr_o <= pc_plus_8;
					branch_target_address_o <= {pc_plus_4[31:28], inst_i[25:0], 2'b00};
					branch_flag_o <= `Branch;
					next_inst_in_delayslot_o <= `InDelaySlot;
					instValid <= `InstValid;
				end
				`EXE_BEQ: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BEQ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					link_addr_o <= `ZeroWord;
					if (reg1_o == reg2_o)
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
					instValid <= `InstValid;
				end
				`EXE_BGTZ: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BGTZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					link_addr_o <= `ZeroWord;
					if ((reg1_o[31] == 1'b0) && (reg1_o != `ZeroWord))
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
					instValid <= `InstValid;
				end
				`EXE_BLEZ: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BLEZ_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					link_addr_o <= `ZeroWord;
					if ((reg1_o[31] == 1'b1) || (reg1_o == `ZeroWord))
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
					instValid <= `InstValid;
				end
				`EXE_BNE: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_BNE_OP;
					alusel_o <= `EXE_RES_JUMP_BRANCH;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					link_addr_o <= `ZeroWord;
					if (reg1_o != reg2_o)
					begin
						branch_target_address_o <= pc_plus_4 + imm_sll2_signedext;
						branch_flag_o <= `Branch;
						next_inst_in_delayslot_o <= `InDelaySlot;
					end
					instValid <= `InstValid;
				end
				`EXE_LB: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_LBU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LBU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_LH: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LH_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_LHU: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LHU_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_LW: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_LWL: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LWL_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_LWR: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LWR_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_SB: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SB_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_SH: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SH_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_SW: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SW_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_SWL: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SWL_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_SWR: begin
					wreg_o <= `WriteDisable;
					aluop_o <= `EXE_SWR_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_LL: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_LL_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b0;
					wd_o <= inst_i[20:16];
					instValid <= `InstValid;
				end
				`EXE_SC: begin
					wreg_o <= `WriteEnable;
					aluop_o <= `EXE_SC_OP;
					alusel_o <= `EXE_RES_LOAD_STORE;
					reg1_read_o <= 1'b1;
					reg2_read_o <= 1'b1;
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
			
			// handle mfc0/mtc0 instructions
			if (inst_i[31:21] == 11'b01000000000 && inst_i[10:3] == 8'b00000000)
			begin
				// mfc0
				aluop_o <= `EXE_MFC0_OP;
				alusel_o <= `EXE_RES_MOVE;
				wd_o <= inst_i[20:16];
				wreg_o <= `WriteEnable;
				instValid <= `InstValid;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
			end else
			if (inst_i[31:21] == 11'b01000000100 && inst_i[10:3] == 8'b00000000)
			begin
				// mtc0
				aluop_o <= `EXE_MTC0_OP;
				alusel_o <= `EXE_RES_NOP;
				wreg_o <= `WriteDisable;
				instValid <= `InstValid;
				reg1_read_o <= 1'b1;
				reg1_addr_o <= inst_i[20:16];
				reg2_addr_o <= 1'b0;
			end
			
			if (inst_i == `EXE_ERET)
			begin
				// eret
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_ERET_OP;
				alusel_o <= `EXE_RES_NOP;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				instValid <= `InstValid;
				excepttype_is_eret <= `TrueValue;
			end
			
			if (inst_i == `EXE_TLBR)
			begin
				// tlbr
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_TLBR_OP;
				alusel_o <= `EXE_RES_NOP;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				instValid <= `InstValid;
			end
			if (inst_i == `EXE_TLBWI)
			begin
				// tlbwi
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_TLBWI_OP;
				alusel_o <= `EXE_RES_NOP;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				instValid <= `InstValid;
			end
			if (inst_i == `EXE_TLBWR)
			begin
				// tlbwr
				wreg_o <= `WriteDisable;
				aluop_o <= `EXE_TLBWR_OP;
				alusel_o <= `EXE_RES_NOP;
				reg1_read_o <= 1'b0;
				reg2_read_o <= 1'b0;
				instValid <= `InstValid;
			end
			
			if (inst_i == `ZeroWord)
			begin
				// nop is a valid inst
				instValid <= `InstValid;
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
		/* bypass handling */
		if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o))
		begin
			reg1_o <= ex_wdata_i;
		end else
		if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o))
		begin
			reg1_o <= mem_wdata_i;
		end else
		/* end bypass handling */
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
		/* bypass handling */
		if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o))
		begin
			reg2_o <= ex_wdata_i;
		end else
		if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o))
		begin
			reg2_o <= mem_wdata_i;
		end else
		/* end bypass handling */
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
	
	/* handle is_in_delayslot_o, which represents whether current inst is in delay slot */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			is_in_delayslot_o <= `NotInDelaySlot;
		end else
		begin
			is_in_delayslot_o <= is_in_delayslot_i;
		end
	end
	
	/* handle load relate: stall when necessary */
	always @(*)
	begin
		stallreq_for_reg1_load_relate <= `NoStop;
		if (rst == `RstEnable)
		begin
		end else
		if (pre_inst_is_load == 1'b1 && ex_wd_i == reg1_addr_o && reg1_read_o == 1'b1)
		begin
			stallreq_for_reg1_load_relate <= `Stop;
		end
	end
	
	always @(*)
	begin
		stallreq_for_reg2_load_relate <= `NoStop;
		if (rst == `RstEnable)
		begin
		end else
		if (pre_inst_is_load == 1'b1 && ex_wd_i == reg2_addr_o && reg2_read_o == 1'b1)
		begin
			stallreq_for_reg2_load_relate <= `Stop;
		end
	end
	
	/* handle stall of mtc0 */
	always @(*)
	begin
		if (pre_inst_is_mtc0)
		begin
			mtc0_cnt_o <= 2'b10;
			stallreq_for_mtc0 <= 1'b1;
		end else
		if (mtc0_cnt_i != 2'b00)
		begin
			mtc0_cnt_o <= mtc0_cnt_i - 1;
			stallreq_for_mtc0 <= 1'b1;
		end else
		begin
			stallreq_for_mtc0 <= 1'b0;
		end
	end
	
	/* pipeline stall signal */
	assign stallreq = stallreq_for_reg1_load_relate || stallreq_for_reg2_load_relate ||
						stallreq_for_mtc0;

endmodule
