`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    mem
// Project Name:   SammingCPU
//
// MEM module
// Currently load/store operation is not supported, so this module only sends signals to next module now
// Or it will execute read and write from RAM operation
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

//`define NO_RESET_EXCEPTION
`define RESET_EXCEPTION

module mem(
	input wire					rst,
	
	// from EX stage
	input wire[`RegAddrBus]		wd_i,
	input wire					wreg_i,
	input wire[`RegBus]			wdata_i,
	input wire					whilo_i,
	input wire[`RegBus]			hi_i,
	input wire[`RegBus]			lo_i,
	
	input wire[`ALUOpBus]		aluop_i,
	input wire[`RegBus]			mem_addr_i,
	input wire[`RegBus]			reg2_i,
		
	// from WB stage
	input wire[1:0] 			cnt_i,
		// EXTENSION for multiple clocks
	
	// to WB stage
	output reg[`RegAddrBus]		wd_o,
	output reg					wreg_o,
	output reg[`RegBus]			wdata_o,
	output reg					whilo_o,
	output reg[`RegBus]			hi_o,
	output reg[`RegBus]			lo_o,
	output reg[1:0]				cnt_o,
		// EXTENSION for multiple clocks
		
	// for LL/SC
	input wire					llbit_i,
		// llbit input
	input wire					wb_llbit_we_i,
		// wb whether to wire
	input wire					wb_llbit_value_i,
		// wb write value
	
	output reg					llbit_we_o,
		// whether to write
	output reg					llbit_value_o,
		// write value
	
	// from external RAM stage
	input wire[`RegBus]			mem_data_i,
	input wire					mem_ready_i,
		// EXTENSION for multiple clocks
	input wire					mem_tlbl_i,
	input wire					mem_tlbs_i,
	input wire					mem_mod_i,
	
	// to external RAM stage
	output reg[`RegBus]			mem_addr_o,
		// output of RAM IO address
	output wire					mem_we_o,
		// output of whether to write memory
	output reg[3:0]				mem_sel_o,
		// byte selection signal
	output reg[`RegBus]			mem_data_o,
		// data to write to memory
	output wire					mem_ce_o,
		// RAM enabling signal
		
	// port for cp0
	input wire[`RegBus]			cp0_reg_data_i,
	input wire[`CP0RegAddrBus]	cp0_reg_write_addr_i,
	input wire					cp0_reg_we_i,
	
	output reg[`RegBus]			cp0_reg_data_o,
	output reg[`CP0RegAddrBus]	cp0_reg_write_addr_o,
	output reg					cp0_reg_we_o,
	
	// for interrupt handle
	// port from EX
	input wire[`ExceptBus]		excepttype_i,
	input wire					is_in_delayslot_i,
	input wire[`InstAddrBus]	current_inst_address_i,
	input wire[`RegBus]			inst_i,
	
	// port from CP0
	input wire[`RegBus]			cp0_status_i,
	input wire[`RegBus]			cp0_cause_i,
	input wire[`RegBus]			cp0_epc_i,
	
	// port to cp0 (some also to ctrl)
	output reg[`ExceptBus]		excepttype_o,
		// final except type
	output wire[`RegBus]		cp0_epc_o,
		// epc for CP0
	output wire					is_in_delayslot_o,
		// whether instruction in this stage is in delay slot
	output reg[`RegBus]			badaddr_o,
		// badaddr output
	output wire[`RegBus]		current_inst_address_o,
		// address of instruciton in this stage
	
	// port for tlb w/r
	input wire					rtlb_i,
	input wire					wtlb_i,
	input wire					wtlb_addr_i,
	
	output reg					rtlb_o,
	output reg					wtlb_o,
	output reg					wtlb_addr_o,
	
	output reg					stallreq
		// EXTENSION request for stall
);

	wire[`RegBus] zero32;
	reg mem_we;
	assign mem_we_o = mem_we;
	reg mem_ce;
	
	assign zero32 = `ZeroWord;
	
	reg llbit;
	
	// used to save latest value from CP0
	reg[`RegBus]				cp0_status;
	reg[`RegBus]				cp0_cause;
	reg[`RegBus]				cp0_epc;
	
	// these to be sent to CP0
	assign is_in_delayslot_o = is_in_delayslot_i;
	assign current_inst_address_o = current_inst_address_i;
	
	// exception
	wire excepttype;
	reg adel, ades;
	reg tlbl, tlbs;
	reg mod, mcheck;
	
	/* handling LLbit, which is used in LL/SC operations */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			llbit <= 1'b0;
		end else
		begin
			if (wb_llbit_we_i == 1'b1)
			begin
				llbit <= wb_llbit_value_i;
			end else
			begin
				llbit <= llbit_i;
			end
		end
	end
	
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			wdata_o <= `ZeroWord;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
			whilo_o <= `WriteDisable;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_data_o <= `ZeroWord;
			mem_ce <= `ChipDisable;
			cnt_o <= 2'b00;
			stallreq <= 1'b0;
			llbit_we_o <= 1'b0;
			llbit_value_o <= 1'b0;
			
			cp0_reg_we_o <= `WriteDisable;
			cp0_reg_write_addr_o <= 5'b00000;
			cp0_reg_data_o <= `ZeroWord;
			
			rtlb_o <= `WriteDisable;
			wtlb_o <= `WriteDisable;
			wtlb_addr_o <= `FromIndex;
			
			adel <= 1'b0;
			ades <= 1'b0;
			tlbl <= 1'b0;
			tlbs <= 1'b0;
			mod <= 1'b0;
			mcheck <= 1'b0;
		end else
		begin
			wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			hi_o <= hi_i;
			lo_o <= lo_i;
			whilo_o <= whilo_i;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b1111;
			mem_data_o <= `ZeroWord;
			mem_ce <= `ChipDisable;
			cnt_o <= 2'b00;
			stallreq <= 1'b0;
			llbit_we_o <=1'b0;
			llbit_value_o <= 1'b0;
			
			cp0_reg_we_o <= cp0_reg_we_i;
			cp0_reg_write_addr_o <= cp0_reg_write_addr_i;
			cp0_reg_data_o <= cp0_reg_data_i;
			
			rtlb_o <= rtlb_i;
			wtlb_o <= wtlb_i;
			wtlb_addr_o <= wtlb_addr_i;
			
			case (aluop_i)
				`EXE_LB_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b10: begin
							wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b10: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LH_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						2'b10: begin
							wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LHU_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						2'b10: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LW_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
				end
				`EXE_LWL_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {mem_data_i[7:0], reg2_i[23:0]};
						end
						2'b01: begin
							wdata_o <= {mem_data_i[15:0], reg2_i[15:0]};
						end
						2'b10: begin
							wdata_o <= {mem_data_i[23:0], reg2_i[7:0]};
						end
						2'b11: begin
							wdata_o <= mem_data_i;
						end
					endcase
				end
				`EXE_LWR_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= mem_data_i;
						end
						2'b01: begin
							wdata_o <= {reg2_i[31:24], mem_data_i[31:8]};
						end
						2'b10: begin
							wdata_o <= {reg2_i[31:16], mem_data_i[31:16]};
						end
						2'b11: begin
							wdata_o <= {reg2_i[31:8], mem_data_i[31:24]};
						end
					endcase
				end
				`EXE_SB_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							mem_sel_o <= 4'b0010;
						end
						2'b10: begin
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							mem_sel_o <= 4'b1000;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SH_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b0011;
						end
						2'b10: begin
							mem_sel_o <= 4'b1100;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SW_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= reg2_i;
					mem_sel_o <= 4'b1111;
				end
				`EXE_SWL_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b1111;
							mem_data_o <= reg2_i;
						end
						2'b01: begin
							mem_sel_o <= 4'b0111;
							mem_data_o <= {zero32[7:0], reg2_i[31:8]};
						end
						2'b10: begin
							mem_sel_o <= 4'b0011;
							mem_data_o <= {zero32[15:0], reg2_i[31:16]};
						end
						2'b11: begin
							mem_sel_o <= 4'b0001;
							mem_data_o <= {zero32[23:0], reg2_i[31:24]};
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SWR_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b1000;
							mem_data_o <= {reg2_i[7:0], zero32[23:0]};
						end
						2'b01: begin
							mem_sel_o <= 4'b1100;
							mem_data_o <= {reg2_i[15:0], zero32[15:0]};
						end
						2'b10: begin
							mem_sel_o <= 4'b1110;
							mem_data_o <= {reg2_i[23:0], zero32[7:0]};
						end
						2'b11: begin
							mem_sel_o <= 4'b1111;
							mem_data_o <= reg2_i;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_LL_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
					llbit_we_o <= 1'b1;
					llbit_value_o <= 1'b1;
				end
				`EXE_SC_OP: begin
					if (llbit == 1'b1)
					begin
						if (cnt_i == 2'b00) 
						begin
							if (mem_ready_i == 1'b1) 
							begin
								cnt_o <= 2'b01;
							end
							stallreq <= 1'b1;
							mem_ce <= `ChipEnable;
						end else
						begin
							if (cnt_i == 2'b01)
							begin
								cnt_o <= 2'b10;
							end
							stallreq <= 1'b0;
							mem_ce <= `ChipDisable;
						end
						mem_addr_o <= mem_addr_i;
						mem_we <= `WriteEnable;
						mem_data_o <= reg2_i;
						mem_sel_o <= 4'b1111;
						llbit_we_o <= 1'b1;
						llbit_value_o <= 1'b0;
						wdata_o <= 32'b1;
					end else 
					begin
						wdata_o <= 32'b0;
					end
				end
				default: begin
				end
			endcase
		end
	end
	
	/* read latest value of CP0 registers */
	// status reg
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			cp0_status <= `ZeroWord;
		end else
		begin
			cp0_status <= cp0_status_i;
		end
	end
	
	// epc
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			cp0_epc <= `ZeroWord;
		end else
		begin
			cp0_epc <= cp0_epc_i;
		end
	end
	assign cp0_epc_o = cp0_epc;
	
	// cause
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			cp0_cause <= `ZeroWord;
		end else
		begin
			cp0_cause <= cp0_cause_i;
		end
	end
	
	/*
		excepttype_o:
		[0-7] : for external interrupt
		[8] : syscall
		[9] : invalid instruction
		[10]: trap
		[11]: overflow
		[12]: eret (which viewed as a special exception)
		[13]: reset
		[14]: tlbmodify
		[15]: inst-tlbl
		[16]: inst-tlbs
		[17]: inst-adel
		[18]: 0
		[19]: lw-tlbl
		[20]: lw-tlbs
		[21]: lw-adel
		[22]: lw-ades
		[23]: mcheck
		// interrupt exception is given directly, besides from these codes
		// watch is also
	*/
	
	assign excepttype = {excepttype_i[31:24], mcheck || excepttype_i[23], ades, adel, tlbs, tlbl, excepttype_i[18:15], mod, excepttype_i[13:0]}; 
	
	/* give final exception type */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			`ifdef NO_RESET_EXCEPTION
				excepttype_o <= `ZeroWord;
			`endif
			`ifdef RESET_EXCEPTION
				excepttype_o <= {{18{1'b0}}, 1'b1, {13{1'b0}}};
			`endif
			badaddr_o <= `ZeroWord;
		end else
		begin
			excepttype_o <= `ZeroWord;
			// not a null inst
			if (inst_i != `ZeroWord)
			begin
				// reset
				if (excepttype_i[13] == 1'b1)
				begin
					excepttype_o <= `RESET_EXP;
				end else
				// mcheck
				if (excepttype_i[23] == 1'b1)
				begin
					excepttype_o <= `MCHECK_EXP;
				end else
				// interrupt
				if (((cp0_cause[15:8] & (cp0_status[15:8])) != 8'h00) &&
					(cp0_status[2] == 1'b0) &&
					(cp0_status[1] == 1'b0) &&
					(cp0_status[0] == 1'b1))
				begin
					excepttype_o <= `INTERRUPT_EXP;
				end else
				// inst-adel
				if (excepttype_i[17] == 1'b1)
				begin
					excepttype_o <= `ADEL_EXP;
				end else
				// inst-tlbl
				if (excepttype_i[15] == 1'b1)
				begin
					excepttype_o <= `TLBL_EXP;
					badaddr_o <= current_inst_address_i;
				end
				// inst-tlbs
				if (excepttype_i[16] == 1'b1)
				begin
					excepttype_o <= `TLBS_EXP;
					badaddr_o <= current_inst_address_i;
				end
				// syscall
				if (excepttype_i[8] == 1'b1)
				begin
					excepttype_o <= `SYSCALL_EXP;
				end else
				// inst invalid
				if (excepttype_i[9] == 1'b1)
				begin
					excepttype_o <= `RI_EXP;
				end else
				// overflow
				if (excepttype_i[11] == 1'b1)
				begin
					excepttype_o <= `OVERFLOW_EXP;
				end else
				// trap
				if (excepttype_i[10] == 1'b1)
				begin
					excepttype_o <= `TRAP_EXP;
				end else
				// lw-adel
				if (excepttype_i[21] == 1'b1)
				begin
					excepttype_o <= `ADEL_EXP;
					badaddr_o <= mem_data_o;
				end else
				// lw-ades
				if (excepttype_i[22] == 1'b1)
				begin
					excepttype_o <= `ADES_EXP;
					badaddr_o <= mem_data_o;
				end else
				// lw-tlbl
				if (excepttype_i[19] == 1'b1)
				begin
					excepttype_o <= `TLBL_EXP;
					badaddr_o <= mem_data_o;
				end else
				// lw-tlbs
				if (excepttype_i[20] == 1'b1)
				begin
					excepttype_o <= `TLBS_EXP;
					badaddr_o <= mem_data_o;
				end else
				// tlb-modify
				if (excepttype_i[14] == 1'b1)
				begin
					excepttype_o <= `MOD_EXP;
					badaddr_o <= mem_data_o;
				end else
				// eret
				if (excepttype_i[12] == 1'b1)
				begin
					excepttype_o <= `ERET_EXP;
				end
			end
		end
	end
	
	/* forbid mem_ce signal once exception occurred to prevent data writing to RAM */
	assign mem_ce_o = mem_ce & (~(|excepttype_o));

endmodule
