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
	input wire[`RegBus]			inst_i,
	
	// output to EX-MEM
	output reg[`RegAddrBus]		wd_o,
		// specify which register to write, just transmit from input
	output reg					wreg_o,
		// specify whether to write register, just transmit from input
	output reg[`RegBus]			wdata_o,
		// operation result
		
	// output for MEM
	output wire[`ALUOpBus]		aluop_o,
	output wire[`RegBus]		mem_addr_o,
	output wire[`RegBus]		reg2_o,
		
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
	output reg[`RegBus]			lo_o,
	
	// port for multi and add/sub operations signal buffer
	input wire[`DoubleRegBus]	hilo_tmp_i,
	input wire[1:0]				cnt_i,
	
	output reg[`DoubleRegBus]	hilo_tmp_o,
	output reg[1:0]				cnt_o,
	
	// input of DIV module
	input wire[`DoubleRegBus]	div_result_i,
	input wire					div_ready_i,
	
	// output of DIV module
	output reg[`RegBus]			div_opdata1_o,
	output reg[`RegBus]			div_opdata2_o,
	output reg					div_start_o,
	output reg					signed_div_o,
	
	// signals related to branch
	input wire[`RegBus]			link_address_i,
	input wire					is_in_delayslot_i,
	
	// input related to CP0
	input wire[`RegBus]			cp0_reg_data_i,
	input wire[`RegBus]			wb_cp0_reg_data,
	input wire[`RegAddrBus]		wb_cp0_reg_write_addr,
	input wire					wb_cp0_reg_we,
	input wire[`RegBus]			mem_cp0_reg_data,
	input wire[`RegAddrBus]		mem_cp0_reg_write_addr,
	input wire					mem_cp0_reg_we,
	
	//output to cp0
	output reg[`RegAddrBus]		cp0_reg_read_addr_o,
	output reg[`RegBus]			cp0_reg_data_o,
	output reg[`RegAddrBus]		cp0_reg_write_addr_o,
	output reg					cp0_reg_we_o,
	
	// control signal for pipeline stall
	output reg					stallreq
	
);

	reg[`RegBus] logicOut;
		// save result of logic operations
	reg[`RegBus] shiftRes;
		// save result of shift operations
	reg[`RegBus] moveRes;
		// save result of move operations
	reg[`RegBus] arithmeticRes;
		// save result of arithmetic operations
	reg[`DoubleRegBus] mulRes;
		// save result of multiplication operations
	reg[`RegBus] HI;
		// save latest HI value
	reg[`RegBus] LO;
		// save latest LO value
		
	wire ov_sum;
		// save signed overflow
	wire reg1_lt_reg2;
		// save whether operand1 < operand2
	wire[`RegBus] reg2_i_mux;
		// 1's complement of ope2
	wire[`RegBus] reg1_i_not;
		// inverse of ope1
	wire[`RegBus] result_sum;
		// result of add
	wire[`RegBus] opdata1_mult;
		// ope1 of multi
	wire[`RegBus] opdata2_mult;
		// ope2 of multi
	wire[`DoubleRegBus] hilo_tmp;
		// tmp storage of multi result
	reg[`DoubleRegBus] hilo_tmp1;
		// tmp storage of multi-add/sub result
	reg stallreq_for_madd_msub;
		// pipeline stall signal for madd and msub inst
	reg stallreq_for_div;
		// pipeline stall signal for div inst
		
	/* calculate results of some variables */
	assign reg2_i_mux = ((aluop_i == `EXE_SUB_OP) || 
						(aluop_i == `EXE_SUBU_OP) || 
						(aluop_i == `EXE_SLT_OP)) 
						? 
							(~reg2_i) + 1 
						:
							reg2_i;
	assign result_sum = reg1_i + reg2_i_mux;
	assign ov_sum =    ((!reg1_i[31] && !reg2_i_mux[31]) && (result_sum[31]))
					|| ((reg1_i[31] && reg2_i_mux[31]) && (!result_sum[31])); // overflow check for signed
	assign reg1_lt_reg2 = (aluop_i == `EXE_SLT_OP) 
						  ? // signed compare
							((reg1_i[31] && !reg2_i[31]) ||
							 (!reg1_i[31] && !reg2_i[31] && result_sum[31]) ||
							 (reg1_i[31] && reg2_i[31] && result_sum[31]))
						  : // unsigned compare
							(reg1_i < reg2_i);
	assign reg1_i_not = ~reg1_i;
	
	// send aluop_o to MEM stage, to determine its load, store type
	assign aluop_o = aluop_i;
	assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};
		// determine memory address from 32-bit inst: reg1 + signedExt(15:0)
	assign reg2_o = reg2_i;
		// it saves to store value or to partly-fill value
		
	/* logic operation */
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
	
	/* shift operation */
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
	
	/* move operation */
	always @(*) 
	begin
		if (rst == `RstEnable)
		begin
			moveRes <= `ZeroWord;
		end else
		begin
			moveRes <= `ZeroWord;
			case (aluop_i)
				`EXE_MFHI_OP: begin
					moveRes <= HI;
				end
				`EXE_MFLO_OP: begin
					moveRes <= LO;
				end
				`EXE_MOVZ_OP: begin
					moveRes <= reg1_i;
				end
				`EXE_MOVN_OP: begin
					moveRes <= reg1_i;
				end
				`EXE_MFC0_OP: begin
					cp0_reg_read_addr_o <= inst_i[15:11];
					moveRes <= cp0_reg_data_i;
					
					if (mem_cp0_reg_we == `WriteEnable && 
						mem_cp0_reg_write_addr == inst_i[15:11])
					begin
						moveRes <= mem_cp0_reg_data;
					end else
					if (wb_cp0_reg_we == `WriteEnable &&
						wb_cp0_reg_write_addr == inst_i[15:11])
					begin
						moveRes <= wb_cp0_reg_data;
					end
				end
				default: begin
				end
			endcase
		end
	end
	
	/* arithmetic operation */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			arithmeticRes <= `ZeroWord;
		end else
		begin
			case (aluop_i)
				`EXE_SLT_OP, `EXE_SLTU_OP: begin
					arithmeticRes <= reg1_lt_reg2;
				end
				`EXE_ADD_OP, `EXE_ADDU_OP, `EXE_ADDI_OP, `EXE_ADDIU_OP: begin
					arithmeticRes <= result_sum;
				end
				`EXE_SUB_OP, `EXE_SUBU_OP: begin
					arithmeticRes <= result_sum;
				end
				`EXE_CLZ_OP: begin
					arithmeticRes <= 	reg1_i[31] ? 0  : reg1_i[30] ? 1  : reg1_i[29] ? 2  :
										reg1_i[28] ? 3  : reg1_i[27] ? 4  : reg1_i[26] ? 5  :
										reg1_i[25] ? 6  : reg1_i[24] ? 7  : reg1_i[23] ? 8  :
										reg1_i[22] ? 9  : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
										reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 :
										reg1_i[16] ? 15 : reg1_i[15] ? 16 : reg1_i[14] ? 17 :
										reg1_i[13] ? 18 : reg1_i[12] ? 19 : reg1_i[11] ? 20 :
										reg1_i[10] ? 21 : reg1_i[9]  ? 22 : reg1_i[8]  ? 23 :
										reg1_i[7]  ? 24 : reg1_i[6]  ? 25 : reg1_i[5] ? 26 :
										reg1_i[4]  ? 27 : reg1_i[3]  ? 28 : reg1_i[2] ? 29 :
										reg1_i[1]  ? 30 : reg1_i[0]  ? 31 : 32;
				end
				`EXE_CLO_OP: begin
					arithmeticRes <= 	reg1_i_not[31] ? 0  : reg1_i_not[30] ? 1  : reg1_i_not[29] ? 2  :
										reg1_i_not[28] ? 3  : reg1_i_not[27] ? 4  : reg1_i_not[26] ? 5  :
										reg1_i_not[25] ? 6  : reg1_i_not[24] ? 7  : reg1_i_not[23] ? 8  :
										reg1_i_not[22] ? 9  : reg1_i_not[21] ? 10 : reg1_i_not[20] ? 11 :
										reg1_i_not[19] ? 12 : reg1_i_not[18] ? 13 : reg1_i_not[17] ? 14 :
										reg1_i_not[16] ? 15 : reg1_i_not[15] ? 16 : reg1_i_not[14] ? 17 :
										reg1_i_not[13] ? 18 : reg1_i_not[12] ? 19 : reg1_i_not[11] ? 20 :
										reg1_i_not[10] ? 21 : reg1_i_not[9]  ? 22 : reg1_i_not[8]  ? 23 :
										reg1_i_not[7]  ? 24 : reg1_i_not[6]  ? 25 : reg1_i_not[5] ? 26 :
										reg1_i_not[4]  ? 27 : reg1_i_not[3]  ? 28 : reg1_i_not[2] ? 29 :
										reg1_i_not[1]  ? 30 : reg1_i_not[0]  ? 31 : 32;
				end
				default: begin
					arithmeticRes <= `ZeroWord;
				end
			endcase
		end
	end
	
	/* multiplicaiton operation */
	assign opdata1_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
							(aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) && 
							(reg1_i[31] == 1'b1)) ?
							(~reg1_i + 1) : reg1_i; // signed : unsigned
	assign opdata2_mult = (((aluop_i == `EXE_MUL_OP) || (aluop_i == `EXE_MULT_OP) ||
							(aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP)) &&
							(reg2_i[31] == 1'b1)) ?
							(~reg2_i + 1) : reg2_i; // signed : unsigned
	assign hilo_tmp = opdata1_mult * opdata2_mult;
	
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			mulRes <= {`ZeroWord, `ZeroWord};
		end else
		if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MUL_OP) ||
			(aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MSUB_OP))
		begin
			// signed multiplication
			if (reg1_i[31] ^ reg2_i[31] == 1'b1) 
			begin
				mulRes <= ~hilo_tmp + 1;
			end else
			begin
				mulRes <= hilo_tmp;
			end
		end else
		begin
			// unsigned multiplicaton
			mulRes <= hilo_tmp;
		end
	end
	
	/* choose one as final result according to alusel_i(type of ALU) */
	always @(*)
	begin
		wd_o <= wd_i;
		
		if (((aluop_i == `EXE_ADD_OP) || (aluop_i == `EXE_ADDI_OP) ||
			(aluop_i == `EXE_SUB_OP)) && (ov_sum == 1'b1))
		begin
			// overflow handling
			wreg_o <= `WriteDisable;
		end else
		begin
			wreg_o <= wreg_i;
		end
		
		case (alusel_i)
			`EXE_RES_LOGIC: begin
				wdata_o <= logicOut;
			end
			`EXE_RES_SHIFT: begin
				wdata_o <= shiftRes;
			end
			`EXE_RES_MOVE: begin
				wdata_o <= moveRes;
			end
			`EXE_RES_ARITHMETIC: begin
				wdata_o <= arithmeticRes;
			end
			`EXE_RES_MUL: begin
				wdata_o <= mulRes[31:0];
			end
			`EXE_RES_JUMP_BRANCH: begin
				wdata_o <= link_address_i;
			end
			default: begin
				wdata_o <= `ZeroWord;
			end
		endcase
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
	
	/* MADD and MSUB operation */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			hilo_tmp_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;
			stallreq_for_madd_msub <= `NoStop;
		end else
		begin
			case (aluop_i)
				`EXE_MADD_OP, `EXE_MADDU_OP: begin
					if (cnt_i == 2'b00) 
					begin
						// state 0
						hilo_tmp_o <= mulRes; // add
						cnt_o <= 2'b01;
						hilo_tmp1 <= {`ZeroWord, `ZeroWord};
						stallreq_for_madd_msub <= `Stop;
					end else
					if (cnt_i == 2'b01)
					begin
						// state 1
						hilo_tmp_o <= {`ZeroWord, `ZeroWord};
						cnt_o <= 2'b10;
						hilo_tmp1 <= hilo_tmp_i + {HI, LO};
						stallreq_for_madd_msub <= `NoStop;
					end
				end
				`EXE_MSUB_OP, `EXE_MSUBU_OP: begin
					if (cnt_i == 2'b00)
					begin
						// state 0
						hilo_tmp_o <= ~mulRes + 1; // minus
						cnt_o <= 2'b01;
						hilo_tmp1 <= {`ZeroWord, `ZeroWord};
						stallreq_for_madd_msub <= `Stop;
					end else
					if (cnt_i == 2'b01)
					begin
						// state 1
						hilo_tmp_o <= {`ZeroWord, `ZeroWord};
						cnt_o <= 2'b10;
						hilo_tmp1 <= hilo_tmp_i + {HI, LO};
						stallreq_for_madd_msub <= `NoStop;
					end
				end
				default: begin
					hilo_tmp_o <= {`ZeroWord, `ZeroWord};
					cnt_o <= 2'b00;
					stallreq_for_madd_msub <= `NoStop;
				end
			endcase
		end
	end
	
	/* DIV and DIVU operation */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			stallreq_for_div <= `NoStop;
			div_opdata1_o <= `ZeroWord;
			div_opdata2_o <= `ZeroWord;
			div_start_o <= `DivStop;
			signed_div_o <= 1'b0;
		end else
		begin
			stallreq_for_div <= `NoStop;
			div_opdata1_o <= `ZeroWord;
			div_opdata2_o <= `ZeroWord;
			div_start_o <= `DivStop;
			signed_div_o <= 1'b0;
			case (aluop_i)
				`EXE_DIV_OP: begin
					if (div_ready_i == `DivResultNotReady)
					begin
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStart;
						signed_div_o <= 1'b1;
						stallreq_for_div <= `Stop;
					end else
					if (div_ready_i == `DivResultReady)
					begin
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b1;
						stallreq_for_div <= `NoStop;
					end else
					begin
						div_opdata1_o <= `ZeroWord;
						div_opdata2_o <= `ZeroWord;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end
				end
				`EXE_DIVU_OP: begin
					if (div_ready_i == `DivResultNotReady)
					begin
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStart;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `Stop;
					end else
					if (div_ready_i == `DivResultReady)
					begin
						div_opdata1_o <= reg1_i;
						div_opdata2_o <= reg2_i;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end else
					begin
						div_opdata1_o <= `ZeroWord;
						div_opdata2_o <= `ZeroWord;
						div_start_o <= `DivStop;
						signed_div_o <= 1'b0;
						stallreq_for_div <= `NoStop;
					end
				end
			endcase
		end
	end
	
	/* handling HI and LO result */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			whilo_o <= `WriteDisable;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end else
		if ((aluop_i == `EXE_DIV_OP) || (aluop_i == `EXE_DIVU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= div_result_i[63:32];
			lo_o <= div_result_i[31:0];
		end else
		if ((aluop_i == `EXE_MADD_OP) || (aluop_i == `EXE_MADDU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= hilo_tmp1[63:32];
			lo_o <= hilo_tmp1[31:0];
		end else
		if ((aluop_i == `EXE_MSUB_OP) || (aluop_i == `EXE_MSUBU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= hilo_tmp1[63:32];
			lo_o <= hilo_tmp1[31:0];
		end else
		if ((aluop_i == `EXE_MULT_OP) || (aluop_i == `EXE_MULTU_OP)) begin
			whilo_o <= `WriteEnable;
			hi_o <= mulRes[63:32];
			lo_o <= mulRes[31:0];
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
	
	/* determine signals given to cp0 */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_data_o <= `ZeroWord;
		end else
		if (aluop_i == `EXE_MTC0_OP)
		begin
			cp0_reg_write_addr_o <= inst_i[15:11];
			cp0_reg_we_o <= `WriteEnable;
			cp0_reg_data_o <= reg1_i;
		end else
		begin
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_data_o <= `ZeroWord;
		end
	end
	
	/* pipeline stall signal */
	always @(*)
	begin
		stallreq <= stallreq_for_madd_msub || stallreq_for_div;
	end

endmodule
