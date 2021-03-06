`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    SammingCPU
// Project Name:   SammingCPU
//
// Top module
// Working on connection of each module
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module samming_cpu(
	input wire					clk,
		// clock
	input wire					busclk,
		// busclock
	input wire					rst,
		// reset signal
	
	// from SRAM
	input wire					sram_ready_i,
	input wire[`RAMBus]			sram_data_i,
	
	// to SRAM
	output wire					sram_we_o,
		// whether write RAM (otherwise read)
	output wire					sram_ce_o,
		// module enable flag
	output wire[`RegBus]		sram_addr_o,
	output wire[`RAMBus]		sram_data_o,
	output wire[3:0]			sram_sel_o,
	
	// from ROM
	input wire[`ROMBus]			rom_data_i,
	input wire					rom_ready_i,
	
	// to ROM
	output wire[`ROMAddrBus]	rom_addr_o,
	output wire					rom_we_o,
	output wire					rom_ce_o,
	
	// from Flash
	input wire[`FlashBus]		flash_data_i,
	input wire					flash_ready_i,
	
	// to Flash
	output wire[`FlashAddrBus]	flash_addr_o,
	output wire					flash_ce_o,
	output wire					flash_we_o,
	output wire[`FlashBus]		flash_data_o,
	output wire[3:0]			flash_sel_o,
	
	// from/to serail
	input wire[`RAMBus]			serail_data_i,
	input wire					serail_ready_i,
	
	// to Serial
	output wire[`SerailAddrBus]	serail_addr_o,
	output wire[`RAMBus]		serail_data_o,
	output wire					serail_we_o,	
	output wire					serail_ce_o,
	output wire[3:0]			serail_sel_o,
	
	// port of cp0
	input wire[5:0]				int_i,
		// hardware interrupt input
	output wire					timer_int_o,
		// timer interrupt output
	
	output wire[`RegBus]		debug
		// used only for testing

);

	/* wire declaration */
	
	// IF(pc-reg) <=> RAM
	
	
	// IF(pc-reg) <=> IF-ID
	wire[`InstAddrBus] pc_o;
	wire[`InstBus] inst_o;
	wire[`ExceptBus] if_excepttype_o;
	wire if_isbubble_o;

	// IF-ID <=> ID
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	wire[`ExceptBus] id_excepttype_i;
	wire id_isbubble_i;
	
	// ID <=> ID-EX
	wire[`ALUOpBus] id_aluop_o;
	wire[`ALUSelBus] id_alusel_o;
	wire[`RegBus] id_reg1_o;
	wire[`RegBus] id_reg2_o;
	wire id_wreg_o;
	wire[`RegAddrBus] id_wd_o;
	wire id_is_in_delayslot_o;
	wire[`RegBus] id_link_address_o;
	wire is_in_delayslot_i;
	wire is_in_delayslot_o;
	wire next_ins_in_delayslot_o;
	wire[`RegBus] id_inst_o;
	wire[`ExceptBus] id_excepttype_o;
	wire[`RegBus] id_current_inst_address_o;
	wire[1:0] id_mtc0_cnt_o;
	wire[1:0] id_mtc0_cnt_i;
	wire id_isbubble_o;
	
	// ID => PC
	wire id_branch_flag_o;
	wire[`RegBus] branch_target_address;
	
	// ID <=> regfile
	wire reg1_read;
	wire[`RegBus] reg1_data;
	wire[`RegAddrBus] reg1_addr;
	wire reg2_read;
	wire[`RegBus] reg2_data;
	wire[`RegAddrBus] reg2_addr;
	
	// ID-EX <=> EX
	wire[`ALUOpBus] ex_aluop_i;
	wire[`ALUSelBus] ex_alusel_i;
	wire[`RegBus] ex_reg1_i;
	wire[`RegBus] ex_reg2_i;
	wire ex_wreg_i;
	wire[`RegAddrBus] ex_wd_i;
	wire ex_is_in_delayslot_i;
	wire[`RegBus] ex_link_address_i;
	wire[`RegBus] ex_inst_i;
	wire[`ExceptBus] ex_excepttype_i;
	wire[`RegBus] ex_current_inst_address_i;
	wire ex_isbubble_i;
	
	// EX <=> EX-MEM and EX => ID(bypass)
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire ex_whilo_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	wire[`ALUOpBus] ex_aluop_o;
	wire[`RegBus] ex_mem_addr_o;
	wire[`RegBus] ex_reg2_o;
	wire[`RegBus] ex_inst_o;
	wire[`RegBus] ex_cp0_reg_data_o;
	wire[`CP0RegAddrBus] ex_cp0_reg_write_addr_o;
	wire ex_cp0_reg_we_o;
	wire[`ExceptBus] ex_excepttype_o;
	wire[`RegBus] ex_current_inst_address_o;
	wire ex_is_in_delayslot_o;
	wire ex_rtlb_o;
	wire ex_wtlb_o;
	wire ex_wtlb_addr_o;
	wire ex_isbubble_o;
	
	// EX <=> CP0
	wire[`CP0RegAddrBus] ex_cp0_reg_read_addr_o;
	wire[`RegBus] cp_data_o;
	
	// EX-MEM <=> MEM
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire mem_whilo_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	wire[`ALUOpBus] mem_aluop_i;
	wire[`RegBus] mem_mem_addr_i;
	wire[`RegBus] mem_reg2_i;
	wire[`RegBus] mem_cp0_reg_data_i;
	wire[`CP0RegAddrBus] mem_cp0_reg_write_addr_i;
	wire mem_cp0_reg_we_i;
	wire[`RegBus] mem_inst_i;
	wire[`ExceptBus] mem_excepttype_i;
	wire mem_is_in_delayslot_i;
	wire[`RegBus] mem_current_inst_address_i;
	wire mem_rtlb_i;
	wire mem_wtlb_i;
	wire mem_wtlb_addr_i;
	wire mem_isbubble_i;
	
	// MEM <=> MEM-WB and MEM => ID(bypass)
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire mem_whilo_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	wire mem_llbit_value_o;
	wire mem_llbit_we_o;
	wire[`RegBus] mem_cp0_reg_data_o;
	wire[`CP0RegAddrBus] mem_cp0_reg_write_addr_o;
	wire mem_cp0_reg_we_o;
	wire mem_rtlb_o;
	wire mem_wtlb_o;
	wire mem_wtlb_addr_o;
	
	// MEM => CP0 and MEM => CTRL
	wire[`ExceptBus] mem_excepttype_o;
	wire mem_is_in_delayslot_o;
	wire[`RegBus] mem_badaddr_o;
	wire[`RegBus] mem_current_inst_address_o;
	wire[`RegBus] mem_cp0_epc_o;
	
	// MEM-WB <=> WB
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire wb_whilo_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	wire wb_llbit_value_i;
	wire wb_llbit_we_i;	
	wire[`RegBus] wb_cp0_reg_data_i;
	wire[`CP0RegAddrBus] wb_cp0_reg_write_addr_i;
	wire wb_cp0_reg_we_i;
	
	// WB(HI/LO) => EX
	wire[`RegBus] hi;
	wire[`RegBus] lo;
	
	// WB(LL/SC) => MEM
	wire llbit_o;
	
	// pipeline stall related
	wire[5:0] stall;
	wire stallreq_from_pc;
	wire stallreq_from_id;
	wire stallreq_from_ex;
	wire stallreq_from_mem;
	
	// buffer signals for MADD/MSUB
	wire[`DoubleRegBus] hilo_tmp_o;
	wire[1:0] cnt_o;
	wire[`DoubleRegBus] hilo_tmp_i;
	wire[1:0] cnt_i;
	
	// buffer signals for MEM
	wire[1:0] mem_cnt_o;
	wire[1:0] mem_cnt_i;
	
	// EX <=> DIV
	wire signed_div;
	wire[`RegBus] div_opdata1;
	wire[`RegBus] div_opdata2;
	wire div_start;
	wire[`DoubleRegBus] div_result;
	wire div_ready;
	
	// exception related
	wire flush;
	wire[`RegBus] new_pc;
	
	// cp0 output
	wire[`RegBus] cp0_index;
	wire[`RegBus] cp0_random;
	wire[`RegBus] cp0_entrylo0;
	wire[`RegBus] cp0_entrylo1;
	wire[`RegBus] cp0_wired;
	wire[`RegBus] cp0_badvaddr;
	wire[`RegBus] cp0_count;
	wire[`RegBus] cp0_entryhi;
	wire[`RegBus] cp0_compare;
	wire[`RegBus] cp0_status;
	wire[`RegBus] cp0_cause;
	wire[`RegBus] cp0_epc;
	wire[`RegBus] cp0_prid;
	wire[`RegBus] cp0_ebase;
	wire[`RegBus] cp0_config;
	wire[`RegBus] cp0_watchlo;
	wire[`RegBus] cp0_watchhi;
	wire[`RegBus] cp0_errorepc;
	
	// memory
	// from ram_adapter
	wire[`RegBus] ram_data_i;
	wire ram_ready_i;
	wire[`RegBus] pc_ram_data_i;
	wire pc_ram_ready_i;
	
	wire pc_tlb_err_i;
	
	wire ram_tlb_err_i;
	wire ram_tlb_mod_i;
	wire ram_tlb_mcheck_i;
	// to ram_adapter
	wire[`RegBus] ram_addr_o;
	wire ram_we_o;
	wire[3:0] ram_sel_o;
	wire[`RegBus] ram_data_o;
	wire ram_ce_o;
	wire[`InstAddrBus] pc_ram_o;
	
	// ram_adapter <=> MMU
	wire mmu_we_o;
	wire mmu_ce_o;
	wire[`RegBus] mmu_addr_o;
	wire[`RAMBus] mmu_data_o;
	wire[3:0] mmu_sel_o;
	
	wire mmu_ready_i;
	wire[`RAMBus] mmu_data_i;
	
	wire mmu_tlb_err_i;
	wire mmu_mod_i;
	
	// MMU => CP0 for write TLB entry
	wire tlb_we_o;
	wire[`RegBus] tlb_w_entryhi_o;
	wire[`RegBus] tlb_w_entrylo0_o;
	wire[`RegBus] tlb_w_entrylo1_o;
	
	wire[`ASIDWidth] mmu_latest_asid_o;
	
	/**** testing ****/
	/*
	always @(posedge clk)
	begin
		//debug <= {{2{1'b0}}, id_pc_i[31:2]};
		if (rst == `RstEnable)
		begin
			debug <= `ZeroWord;
		end else
		begin
			if (mem_excepttype_o != `ZeroWord)
				debug <= debug | mem_excepttype_o;
		end
	end
	*/
	
	/* pc_reg instantiate */
	pc_reg pc_reg0(
		.clk(clk), .rst(rst), 
		.flush(flush), .new_pc(new_pc),
		.stall(stall), 
		.branch_flag_i(id_branch_flag_o), 
		.branch_target_address_i(branch_target_address),
		.pc(pc_ram_o),
		.pc_data_i(pc_ram_data_i), .pc_ready_i(pc_ram_ready_i),
		.tlb_err_i(pc_tlb_err_i),
		.pc_o(pc_o), .inst_o(inst_o),
		.excepttype_o(if_excepttype_o),
		.if_isbubble_o(if_isbubble_o),
		.stallreq(stallreq_from_pc)
	);
	
	/* IF-ID instantiate */
	if_id if_id0(
		.clk(clk), .rst(rst), .stall(stall), .flush(flush),
		.if_pc(pc_o), .if_inst(inst_o), .if_excepttype(if_excepttype_o), 
		.if_isbubble(if_isbubble_o),
		.id_pc(id_pc_i), .id_inst(id_inst_i), .id_excepttype(id_excepttype_i),
		.id_isbubble(id_isbubble_i)
	);
	
	/* ID instantiate */
	id id0(
		.rst(rst), .pc_i(id_pc_i), .inst_i(id_inst_i),
		.reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
		
		// bypass
		.ex_wreg_i(ex_wreg_o), .ex_wdata_i(ex_wdata_o), .ex_wd_i(ex_wd_o),
		.mem_wreg_i(mem_wreg_o), .mem_wdata_i(mem_wdata_o), .mem_wd_i(mem_wd_o),
		
		.reg1_read_o(reg1_read), .reg2_read_o(reg2_read),
		.reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr),
		.aluop_o(id_aluop_o), .alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o), .reg2_o(id_reg2_o),
		.wd_o(id_wd_o), .wreg_o(id_wreg_o),
		
		// branch
		.is_in_delayslot_i(is_in_delayslot_i),
		.next_inst_in_delayslot_o(next_inst_in_delayslot),
		.branch_flag_o(id_branch_flag_o), .branch_target_address_o(branch_target_address),
		.link_addr_o(id_link_address_o),
		.is_in_delayslot_o(id_is_in_delayslot_o),
		
		// bypass from EX of next inst's aluop to handle load relate
		.ex_aluop_i(ex_aluop_o),
		
		// exception
		.excepttype_i(id_excepttype_i), .excepttype_o(id_excepttype_o), .current_inst_address_o(id_current_inst_address_o),
		
		// pass inst to EX
		.inst_o(id_inst_o),
		
		// mtc0 bubbles cnt
		.mtc0_cnt_i(id_mtc0_cnt_i), .mtc0_cnt_o(id_mtc0_cnt_o),
		
		// is bubble
		.id_isbubble_i(id_isbubble_i), .id_isbubble_o(id_isbubble_o),
		
		.stallreq(stallreq_from_id)
	);
	
	/* regfile instantiate */
	regfile regfile0(
		.clk(clk), .rst(rst),
		.we(wb_wreg_i), .waddr(wb_wd_i), .wdata(wb_wdata_i),
		.re1(reg1_read), .raddr1(reg1_addr), .rdata1(reg1_data),
		.re2(reg2_read), .raddr2(reg2_addr), .rdata2(reg2_data)
	);
	
	/* ID-EX instantiate */
	id_ex id_ex0(
		.clk(clk), .rst(rst), .stall(stall), .flush(flush),
		.id_aluop(id_aluop_o), .id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o), .id_reg2(id_reg2_o),
		.id_wd(id_wd_o), .id_wreg(id_wreg_o),
		.id_inst(id_inst_o),
		.ex_aluop(ex_aluop_i), .ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i),
		.ex_inst(ex_inst_i),
		// branch in
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot),
		// branch out
		.ex_link_address(ex_link_address_i),
		.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i),
		// mtc0 bubbles cnt
		.mtc0_cnt_i(id_mtc0_cnt_o), .mtc0_cnt_o(id_mtc0_cnt_i),
		// exception
		.id_current_inst_address(id_current_inst_address_o), .id_excepttype(id_excepttype_o),
		.ex_current_inst_address(ex_current_inst_address_i), .ex_excepttype(ex_excepttype_i),
		// bubble
		.id_isbubble(id_isbubble_o), .ex_isbubble(ex_isbubble_i)
	);
	
	/* EX instantiate */
	ex ex0(
		.rst(rst),
		.aluop_i(ex_aluop_i), .alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i), .reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i), .wreg_i(ex_wreg_i),
		.inst_i(ex_inst_i),
		.hi_i(hi), .lo_i(lo),
		.mem_whilo_i(mem_whilo_o), .mem_hi_i(mem_hi_o), .mem_lo_i(mem_lo_o),
		.wb_whilo_i(wb_whilo_i), .wb_hi_i(wb_hi_i), .wb_lo_i(wb_lo_i), 
		.wd_o(ex_wd_o), .wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),
		.aluop_o(ex_aluop_o), .mem_addr_o(ex_mem_addr_o), .reg2_o(ex_reg2_o), .inst_o(ex_inst_o),
		.whilo_o(ex_whilo_o), .hi_o(ex_hi_o), .lo_o(ex_lo_o),
		.cnt_i(cnt_i), .hilo_tmp_i(hilo_tmp_i),
		.cnt_o(cnt_o), .hilo_tmp_o(hilo_tmp_o),
		.div_result_i(div_result), .div_ready_i(div_ready), 
		.div_opdata1_o(div_opdata1), .div_opdata2_o(div_opdata2),
		.div_start_o(div_start), .signed_div_o(signed_div),	
		// branch
		.link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),
		// cp0
		.cp0_reg_data_i(cp_data_o),
		.cp0_reg_read_addr_o(ex_cp0_reg_read_addr_o),
		.cp0_reg_data_o(ex_cp0_reg_data_o),
		.cp0_reg_write_addr_o(ex_cp0_reg_write_addr_o),
		.cp0_reg_we_o(ex_cp0_reg_we_o),
		// exception
		.current_inst_address_i(ex_current_inst_address_i), .excepttype_i(ex_excepttype_i),
		.current_inst_address_o(ex_current_inst_address_o), .excepttype_o(ex_excepttype_o),
		.is_in_delayslot_o(ex_is_in_delayslot_o),
		// tlb
		.rtlb_o(ex_rtlb_o),
		.wtlb_o(ex_wtlb_o),
		.wtlb_addr_o(ex_wtlb_addr_o),
		// bubble
		.ex_isbubble_i(ex_isbubble_i), .ex_isbubble_o(ex_isbubble_o),
		.stallreq(stallreq_from_ex)
	);

	/* EX-MEM instantiate */
	ex_mem ex_mem0(
		.clk(clk), .rst(rst), .stall(stall), .flush(flush),
		.ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o), .ex_wdata(ex_wdata_o),
		.ex_aluop(ex_aluop_o), .ex_mem_addr(ex_mem_addr_o), .ex_reg2(ex_reg2_o),
		.ex_inst_i(ex_inst_o),
		.ex_whilo(ex_whilo_o), .ex_hi(ex_hi_o), .ex_lo(ex_lo_o),
		.mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i), .mem_wdata(mem_wdata_i),
		.mem_aluop(mem_aluop_i), .mem_mem_addr(mem_mem_addr_i), .mem_reg2(mem_reg2_i),
		.mem_inst_o(mem_inst_i),
		.mem_whilo(mem_whilo_i), .mem_hi(mem_hi_i), .mem_lo(mem_lo_i),
		.cnt_i(cnt_o), .hilo_tmp_i(hilo_tmp_o),
		.cnt_o(cnt_i), .hilo_tmp_o(hilo_tmp_i),
		.ex_cp0_reg_data(ex_cp0_reg_data_o),
		.ex_cp0_reg_write_addr(ex_cp0_reg_write_addr_o),
		.ex_cp0_reg_we(ex_cp0_reg_we_o),
		.mem_cp0_reg_data(mem_cp0_reg_data_i),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_i),
		.mem_cp0_reg_we(mem_cp0_reg_we_i),
		// exception
		.ex_excepttype(ex_excepttype_o),
		.ex_current_inst_address(ex_current_inst_address_o),
		.ex_is_in_delayslot(ex_is_in_delayslot_o),
		.mem_excepttype(mem_excepttype_i),
		.mem_current_inst_address(mem_current_inst_address_i),
		.mem_is_in_delayslot(mem_is_in_delayslot_i),
		// tlb
		.ex_rtlb(ex_rtlb_o),
		.ex_wtlb(ex_wtlb_o),
		.ex_wtlb_addr(ex_wtlb_addr_o),
		.mem_rtlb(mem_rtlb_i),
		.mem_wtlb(mem_wtlb_i),
		.mem_wtlb_addr(mem_wtlb_addr_i),
		// bubble
		.ex_isbubble(ex_isbubble_o), .mem_isbubble(mem_isbubble_i)
	);
	
	mem mem0(
		.rst(rst),
		.wd_i(mem_wd_i), .wreg_i(mem_wreg_i), .wdata_i(mem_wdata_i),
		.aluop_i(mem_aluop_i), .mem_addr_i(mem_mem_addr_i), .reg2_i(mem_reg2_i),
		.whilo_i(mem_whilo_i), .hi_i(mem_hi_i), .lo_i(mem_lo_i),
		.wd_o(mem_wd_o), .wreg_o(mem_wreg_o), .wdata_o(mem_wdata_o),
		.whilo_o(mem_whilo_o), .hi_o(mem_hi_o), .lo_o(mem_lo_o),
		.mem_data_i(ram_data_i), .mem_ready_i(ram_ready_i),
		.mem_addr_o(ram_addr_o), .mem_we_o(ram_we_o), .mem_sel_o(ram_sel_o),
		.mem_data_o(ram_data_o), .mem_ce_o(ram_ce_o),
		.cnt_i(mem_cnt_i), .cnt_o(mem_cnt_o),
		.llbit_i(llbit_o), .wb_llbit_we_i(wb_llbit_we_i), .wb_llbit_value_i(wb_llbit_value_i),
		.llbit_we_o(mem_llbit_we_o), .llbit_value_o(mem_llbit_value_o),
		.cp0_reg_data_i(mem_cp0_reg_data_i),
		.cp0_reg_write_addr_i(mem_cp0_reg_write_addr_i),
		.cp0_reg_we_i(mem_cp0_reg_we_i),
		.cp0_reg_data_o(mem_cp0_reg_data_o),
		.cp0_reg_write_addr_o(mem_cp0_reg_write_addr_o),
		.cp0_reg_we_o(mem_cp0_reg_we_o),
		// exception
		.excepttype_i(mem_excepttype_i),
		.is_in_delayslot_i(mem_is_in_delayslot_i),
		.current_inst_address_i(mem_current_inst_address_i),
		.inst_i(mem_inst_i),
		.cp0_status_i(cp0_status), .cp0_cause_i(cp0_cause), .cp0_epc_i(cp0_epc),
		.excepttype_o(mem_excepttype_o),
		.is_in_delayslot_o(mem_is_in_delayslot_o),
		.badaddr_o(mem_badaddr_o),
		.current_inst_address_o(mem_current_inst_address_o),
		.cp0_epc_o(mem_cp0_epc_o),
		// tlb
		.rtlb_i(mem_rtlb_i),
		.wtlb_i(mem_wtlb_i),
		.wtlb_addr_i(mem_wtlb_addr_i),
		.rtlb_o(mem_rtlb_o),
		.wtlb_o(mem_wtlb_o),
		.wtlb_addr_o(mem_wtlb_addr_o),
		.tlb_err_i(ram_tlb_err_i),
		.tlb_mod_i(ram_tlb_mod_i),
		.tlb_mcheck_i(ram_tlb_mcheck_i),
		// bubble
		.mem_isbubble_i(mem_isbubble_i),
		.stallreq(stallreq_from_mem),
		// debug
		.debug(debug)
	);
	
	/* MEM-WB instantiate */
	mem_wb mem_wb0(
		.clk(clk), .rst(rst), .stall(stall), .flush(flush),
		.mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o), .mem_wdata(mem_wdata_o),
		.mem_whilo(mem_whilo_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),
		.wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i), .wb_wdata(wb_wdata_i),
		.wb_whilo(wb_whilo_i), .wb_hi(wb_hi_i), .wb_lo(wb_lo_i),
		.mem_llbit_we(mem_llbit_we_o), .mem_llbit_value(mem_llbit_value_o),
		.wb_llbit_we(wb_llbit_we_i), .wb_llbit_value(wb_llbit_value_i),
		.mem_cp0_reg_data(mem_cp0_reg_data_o),
		.mem_cp0_reg_write_addr(mem_cp0_reg_write_addr_o),
		.mem_cp0_reg_we(mem_cp0_reg_we_o),
		.wb_cp0_reg_data(wb_cp0_reg_data_i),
		.wb_cp0_reg_write_addr(wb_cp0_reg_write_addr_i),
		.wb_cp0_reg_we(wb_cp0_reg_we_i),
		.cnt_i(mem_cnt_o), .cnt_o(mem_cnt_i)
	);
	
	/* cp0 registers instantiate */
	cp0_reg cp0_reg0(
		.clk(clk), .rst(rst),
		.data_i(wb_cp0_reg_data_i), .waddr_i(wb_cp0_reg_write_addr_i), .we_i(wb_cp0_reg_we_i),
		.raddr_i(ex_cp0_reg_read_addr_o), 
		.int_i(int_i),
		.data_o(cp_data_o),
		
		.index_o(cp0_index),
		.random_o(cp0_random),
		.entrylo0_o(cp0_entrylo0),
		.entrylo1_o(cp0_entrylo1),
		.wired_o(cp0_wired),
		.badvaddr_o(cp0_badvaddr),
		.count_o(cp0_count),
		.entryhi_o(cp0_entryhi),
		.compare_o(cp0_compare),
		.status_o(cp0_status),
		.cause_o(cp0_cause),
		.epc_o(cp0_epc),
		.prid_o(cp0_prid),
		.ebase_o(cp0_ebase),
		.config_o(cp0_config),
		.watchlo_o(cp0_watchlo),
		.watchhi_o(cp0_watchhi),
		.errorepc_o(cp0_errorepc),
		
		// exception
		.excepttype_i(mem_excepttype_o),
		.current_inst_addr_i(mem_current_inst_address_o),
		.is_in_delayslot_i(mem_is_in_delayslot_o),
		.badaddr_i(mem_badaddr_o),
		
		.mmu_latest_asid_i(mmu_latest_asid_o),
		
		// mmu tlbr
		.tlb_we_i(tlb_we_o),
		.tlb_w_entryhi_i(tlb_w_entryhi_o),
		.tlb_w_entrylo0_i(tlb_w_entrylo0_o),
		.tlb_w_entrylo1_i(tlb_w_entrylo1_o),
		
		.timer_int_o(timer_int_o)
	);
	
	/* HI/LO register instantiate */
	hilo_reg hilo_reg0(
		.clk(clk), .rst(rst),
		.we(wb_whilo_i), .hi_i(wb_hi_i), .lo_i(wb_lo_i),
		.hi_o(hi), .lo_o(lo)
	);
	
	/* LLbit register instantiate */
	llbit_reg llbit_reg0(
		.clk(clk), .rst(rst),
		.flush(flush),
		.we(wb_llbit_we_i), .llbit_i(wb_llbit_value_i), 
		.llbit_o(llbit_o)
	);
	
	/* DIV instantiate */
	div div0(
		.clk(clk), .rst(rst),
		.signed_div_i(signed_div), .opdata1_i(div_opdata1), .opdata2_i(div_opdata2),
		.start_i(div_start), .annul_i(1'b0),
		.result_o(div_result), .ready_o(div_ready)
	);
	
	/* pipeline stall controller */
	ctrl ctrl0(
		.rst(rst), 
		.stallreq_from_pc(stallreq_from_pc),
		.stallreq_from_id(stallreq_from_id), 
		.stallreq_from_ex(stallreq_from_ex),
		.stallreq_from_mem(stallreq_from_mem),
		//exception
		.cp0_epc_i(mem_cp0_epc_o),
		.excepttype_i(mem_excepttype_o),
		.ebase_i(cp0_ebase),
		.status_i(cp0_status),
		.cause_i(cp0_cause),
		.stall(stall),
		.new_pc(new_pc),
		.flush(flush)
	);
	
	/* RAM adapter instantiate */
	ram_adapter ram_adapter0(
		.rst(rst), .clk(busclk),
		.ram_addr_i(ram_addr_o), .ram_we_i(ram_we_o),
		.ram_sel_i(ram_sel_o), .ram_data_i(ram_data_o), .ram_ce_i(ram_ce_o),
		.ram_data_o(ram_data_i), .ram_ready_o(ram_ready_i),
		.ram_tlb_err_o(ram_tlb_err_i), .ram_tlb_mod_o(ram_tlb_mod_i),
		.pc_addr_i(pc_ram_o),
		.pc_data_o(pc_ram_data_i), .pc_ready_o(pc_ram_ready_i),
		.pc_tlb_err_o(pc_tlb_err_i),
		// MMU
		.we_o(mmu_we_o), .ce_o(mmu_ce_o), .addr_o(mmu_addr_o), .data_o(mmu_data_o), .sel_o(mmu_sel_o),
		.ready_i(mmu_ready_i), .data_i(mmu_data_i),
		.tlb_err_i(mmu_tlb_err_i), .mod_i(mmu_mod_i), .mcheck_i(mmu_mcheck_i)
	);
	
	/* MMU instantiate */
	mmu mmu0(
		.rst(rst), .clk(busclk),
		
		.we_i(mmu_we_o), .ce_i(mmu_ce_o), .addr_i(mmu_addr_o), .data_i(mmu_data_o), .sel_i(mmu_sel_o),
		
		.ready_o(mmu_ready_i), .data_o(mmu_data_i),
		
		.entryhi_i(cp0_entryhi), .entrylo0_i(cp0_entrylo0), .entrylo1_i(cp0_entrylo1),
		.index_i(cp0_index), .random_i(cp0_random),
		
		.tlb_err_o(mmu_tlb_err_i), .mod_o(mmu_mod_i), .mcheck_o(ram_tlb_mcheck_i),
		
		.wtlb_i(mem_wtlb_o), .wtlb_addr_i(mem_wtlb_addr_o),
		
		.rtlb_i(mem_rtlb_o), .tlb_we_o(tlb_we_o), 
		.tlb_w_entryhi_o(tlb_w_entryhi_o), .tlb_w_entrylo0_o(tlb_w_entrylo0_o), .tlb_w_entrylo1_o(tlb_w_entrylo1_o),
		
		.mmu_latest_asid_o(mmu_latest_asid_o),
		
		// SRAM
		.ram_data_i(sram_data_i), .ram_ready_i(sram_ready_i),
		.ram_we_o(sram_we_o), .ram_ce_o(sram_ce_o),
		.ram_addr_o(sram_addr_o), .ram_data_o(sram_data_o), .ram_sel_o(sram_sel_o),
		
		// ROM ports
		.rom_data_i(rom_data_i), .rom_ready_i(rom_ready_i),
		.rom_addr_o(rom_addr_o), .rom_we_o(rom_we_o), .rom_ce_o(rom_ce_o),
		
		// Flash ports
		.flash_data_i(flash_data_i), .flash_ready_i(flash_ready_i),
		.flash_addr_o(flash_addr_o), .flash_ce_o(flash_ce_o), .flash_we_o(flash_we_o), .flash_data_o(flash_data_o),
		.flash_sel_o(flash_sel_o),
		
		// Serail ports
		.serail_data_i(serail_data_i), .serail_ready_i(serail_ready_i),
		.serail_addr_o(serail_addr_o), .serail_data_o(serail_data_o),
		.serail_we_o(serail_we_o), .serail_ce_o(serail_ce_o), .serail_sel_o(serail_sel_o)
	);
	
endmodule
