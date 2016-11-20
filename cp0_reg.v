`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.24
// Module Name:    cp0_reg
// Project Name:   SammingCPU
//
// Implementation of CP0 registers
// v1.0
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module cp0_reg(
	
	input wire 					clk,
	input wire					rst,
	
	input wire					we_i,
		// whether to write cp0 registers
	input wire[`CP0RegAddrBus]	waddr_i,
		// write address
	input wire[`RegBus]			data_i,
		// write data
	input wire[`CP0RegAddrBus]	raddr_i,
		// read address
		
	input wire[5:0]				int_i,
		// hardware interrupt in
		
	output reg[`RegBus]			data_o,
		// read data of specified register
	
	output reg[`RegBus]			index_o,
		// no:0 Index
	output reg[`RegBus]			random_o,
		// no:1 Random
	output reg[`RegBus]			entrylo0_o,
		// no:2 entryLo0
	output reg[`RegBus]			entrylo1_o,
		// no:3 entryLo1
	output reg[`RegBus]			wired_o,
		// no:6 wired
	output reg[`RegBus]			badvaddr_o,
		// no:8 badvaddr
	output reg[`RegBus]			count_o,
		// no:9 count
	output reg[`RegBus]			entryhi_o,
		// no:10 entryhi
	output reg[`RegBus]			compare_o,
		// no:11 compare
	output reg[`RegBus]			status_o,
		// no:12 status
	output reg[`RegBus]			cause_o,
		// no:13 case
	output reg[`RegBus]			epc_o,
		// no:14 epc
	output reg[`RegBus]			prid_o,
		// no:15:0/16:1 prid
	output reg[`RegBus]			ebase_o,
		// no:15:1 ebase
	output reg[`RegBus]			config_o,
		// no:16:0 config
	output reg[`RegBus]			watchlo_o,
		// no:18 watchlo
	output reg[`RegBus]			watchhi_o,
		// no:19 watchhi
	output reg[`RegBus]			errorepc_o,
		// no:30 errorEPC
	
	// exception input
	input wire[`ExceptBus]		excepttype_i,
	input wire[`RegBus]			current_inst_addr_i,
	input wire					is_in_delayslot_i,
	input wire[`RegBus]			badaddr_i,
	
	// mmu input
	input wire[`ASIDWidth]		mmu_latest_asid_i,
	
	output reg					timer_int_o
		// whether timer interrupt happened
);

	/** write operations **/
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			index_o <= `ZeroWord;
			
			random_o <= {{28{1'b0}}, `TLBIndexMax};
			
			entrylo0_o <= `ZeroWord;
			
			entrylo1_o <= `ZeroWord;
			
			wired_o <= `ZeroWord;
			
			count_o <= `ZeroWord;
			
			entryhi_o <= `ZeroWord;
			
			compare_o <= `ZeroWord;
			
			status_o <= 32'b00010000010000000000000000000000;
			
			cause_o <= `ZeroWord;
			
			epc_o <= `ZeroWord;
			
			prid_o <= 32'b00000000001010011011101100000000;
				// CompanyID: 00101001
				// ProcessorID: 10111011
				// revision: 0x0
			
			ebase_o <= `ZeroWord;
			
			config_o <= 32'b00000000000000000000000010000100;
			
			watchlo_o <= `ZeroWord;
			
			watchhi_o <= `ZeroWord;
			
			timer_int_o <= `InterruptNotAssert;
		end else
		begin
			count_o <= count_o + 1;
			
			cause_o[15:10] <= int_i;
				// hardware IP
			
			// random countdown
			if (random_o[`TLBWidth] == wired_o[`TLBWidth])
			begin
				random_o[`TLBWidth] <= `TLBIndexMax;
			end else
			begin
				random_o[`TLBWidth] <= random_o[`TLBWidth] - 1;
			end
			
			// timer interrupt
			if (compare_o != `ZeroWord && count_o == compare_o)
			begin
				timer_int_o <= `InterruptAssert;
			end
			
			if (we_i == `WriteEnable)
			begin
				case (waddr_i)
					`CP0_REG_INDEX: begin
						index_o[`TLBWidth] <= data_i[`TLBWidth];
					end
					`CP0_REG_ENTRYLO0: begin
						entrylo0_o[29:0] <= data_i[29:0];
					end
					`CP0_REG_ENTRYLO1: begin
						entrylo1_o[29:0] <= data_i[29:0];
					end
					`CP0_REG_WIRED: begin
						wired_o[`TLBWidth] <= data_i[`TLBWidth];
						random_o[`TLBWidth] <= `TLBIndexMax;
					end
					`CP0_REG_COUNT: begin
						count_o <= data_i;
					end
					`CP0_REG_ENTRYHI: begin
						entryhi_o[31:13] <= data_i[31:13];
						entryhi_o[7:0] <= data_i[7:0];
					end
					`CP0_REG_COMPARE: begin
						compare_o <= data_i;
						timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS: begin
						status_o[31:28] <= data_i[31:28];
							// CU3-CU0
						status_o[27] <= data_i[27];
							// RP
						status_o[25] <= data_i[25];
							// RE
						status_o[22] <= data_i[22];
							// BEV
						status_o[21] <= data_i[21];
							// TS
						status_o[20] <= data_i[20];
							// SR
						status_o[19] <= data_i[19];
							// NMI
						status_o[15:8] <= data_i[15:8];
							// IM
						status_o[4] <= data_i[4];
							// UM: 1-kernel, 0-user
						status_o[2] <= data_i[2];
							// ERL
						status_o[1] <= data_i[1];
							// EXL
						status_o[0] <= data_i[0];
							// IE
					end
					`CP0_REG_CAUSE: begin
						cause_o[23] <= data_i[23];
							// IV
						cause_o[22] <= data_i[22];
							// WP
						cause_o[9:8] <= data_i[9:8];
							// software IP
					end
					`CP0_REG_EPC: begin
						epc_o <= data_i;
					end
					`CP0_REG_EBASE: begin
						ebase_o <= data_i;
					end
					`CP0_REG_WATCHLO: begin
						watchlo_o <= data_i;
					end
					`CP0_REG_WATCHHI: begin
						watchhi_o[30] <= data_i[30];
						watchhi_o[23:16] <= data_i[23:16];
						watchhi_o[11:3] <= data_i[11:3];
					end
					`CP0_REG_ERROREPC: begin
						errorepc_o <= data_i;
					end
				endcase
			end
			
			// exception handle
			case (excepttype_i)
				
				`RESET_EXP: begin
					if (is_in_delayslot_i == `InDelaySlot)
					begin
						errorepc_o <= current_inst_addr_i - 4;
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else
					begin
						errorepc_o <= current_inst_addr_i;
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b1;
					end
					/* no cause no */
					status_o[1] <= 1'b1;
				end
				
				`MCHECK_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					/* no cause no */
					status_o[1] <= 1'b1;
					status_o[21] <= 1'b1;
				end
				
				`INTERRUPT_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `INTERRUPT_CODE;
					status_o[1] <= 1'b1;
				end
				
				`ADEL_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `ADEL_CODE;
					status_o[1] <= 1'b1;
					badvaddr_o <= badaddr_i;
				end
				
				`ADES_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `ADES_CODE;
					status_o[1] <= 1'b1;
					badvaddr_o <= badaddr_i;
				end
				
				`TLBL_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `TLBL_CODE;
					status_o[1] <= 1'b1;
					badvaddr_o <= badaddr_i;
					entryhi_o[7:0] <= mmu_latest_asid_i;
					entryhi_o[31:13] <= badaddr_i[31:13];
				end
				
				`TLBS_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `TLBS_CODE;
					status_o[1] <= 1'b1;
					badvaddr_o <= badaddr_i;
					entryhi_o[7:0] <= mmu_latest_asid_i;
					entryhi_o[31:13] <= badaddr_i[31:13];
				end
				
				`SYSCALL_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `SYSCALL_CODE;
					status_o[1] <= 1'b1;
				end
				
				`RI_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `RI_CODE;
					status_o[1] <= 1'b1;
				end
				
				`OVERFLOW_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `OVERFLOW_CODE;
					status_o[1] <= 1'b1;
				end
				
				`TRAP_EXP: begin
					if (status_o[1] == 1'b0)
					begin
						if (is_in_delayslot_i == `InDelaySlot)
						begin
							epc_o <= current_inst_addr_i - 4;
							cause_o[31] <= 1'b1;
						end else
						begin
							epc_o <= current_inst_addr_i;
							cause_o[31] <= 1'b1;
						end
					end
					cause_o[6:2] <= `TRAP_CODE;
					status_o[1] <= 1'b1;
				end
				
				`MOD_EXP: begin
					if (is_in_delayslot_i == `InDelaySlot)
					begin
						epc_o <= current_inst_addr_i - 4;
						cause_o[31] <= 1'b1;
					end else
					begin
						epc_o <= current_inst_addr_i;
						cause_o[31] <= 1'b1;
					end
					cause_o[6:2] <= `MOD_CODE;
					status_o[1] <= 1'b1;
					badvaddr_o <= badaddr_i;
					entryhi_o[7:0] <= mmu_latest_asid_i;
					entryhi_o[31:13] <= badaddr_i[31:13];
				end
				
				`ERET_EXP: begin
					// Status : EXL
					status_o[1] <= 1'b0;
				end

				default: begin
				end
			endcase
		end
	end
	
	/** read operations **/
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			data_o <= `ZeroWord;
		end else
		begin
			case (raddr_i)
				`CP0_REG_INDEX: begin
					data_o <= index_o;
				end
				`CP0_REG_RANDOM: begin
					data_o <= random_o;
				end
				`CP0_REG_ENTRYLO0: begin
					data_o <= entrylo0_o;
				end
				`CP0_REG_ENTRYLO1: begin
					data_o <= entrylo1_o;
				end
				`CP0_REG_WIRED: begin
					data_o <= wired_o;
				end
				`CP0_REG_BADVADDR: begin
					data_o <= badvaddr_o;
				end
				`CP0_REG_COUNT: begin
					data_o <= count_o;
				end
				`CP0_REG_ENTRYHI: begin
					data_o <= count_o;
				end
				`CP0_REG_COMPARE: begin
					data_o <= compare_o;
				end
				`CP0_REG_STATUS: begin
					data_o <= status_o;
				end
				`CP0_REG_CAUSE: begin
					data_o <= cause_o;
				end
				`CP0_REG_EPC: begin
					data_o <= epc_o;
				end
				`CP0_REG_PRID, `CP0_REG_PRID2: begin
					data_o <= prid_o;
				end
				`CP0_REG_EBASE: begin
					data_o <= ebase_o;
				end
				`CP0_REG_CONFIG: begin
					data_o <= config_o;
				end
				`CP0_REG_WATCHLO: begin
					data_o <= watchlo_o;
				end
				`CP0_REG_WATCHHI: begin
					data_o <= watchhi_o;
				end
				`CP0_REG_ERROREPC: begin
					data_o <= errorepc_o;
				end
			endcase
		end
	end

endmodule
