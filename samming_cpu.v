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
	input wire					rst,
		// reset signal
	
	input wire[`InstBus]		rom_data_i,
		// instruction get from RAM
	output wire[`InstAddrBus]	rom_addr_o,
		// address of instruction required
	output wire					rom_ce_o,
		// RAM enable signal
		
	output wire[`RegBus]		test_signal
		// used only for testing

);

	/* wire declaration */

	// IF(pc_reg) <=> IF-ID
	// 		another signal to send is inst, which is from rom_data_i
	wire[`InstAddrBus] pc;

	// IF-ID <=> ID
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus] id_inst_i;
	
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
	
	// EX <=> EX-MEM and EX => ID(bypass)
	wire ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus] ex_wdata_o;
	wire ex_whilo_o;
	wire[`RegBus] ex_hi_o;
	wire[`RegBus] ex_lo_o;
	
	// EX-MEM <=> MEM
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus] mem_wdata_i;
	wire mem_whilo_i;
	wire[`RegBus] mem_hi_i;
	wire[`RegBus] mem_lo_i;
	
	// MEM <=> MEM-WB and MEM => ID(bypass)
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	wire mem_whilo_o;
	wire[`RegBus] mem_hi_o;
	wire[`RegBus] mem_lo_o;
	
	// MEM-WB <=> WB
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	wire wb_whilo_i;
	wire[`RegBus] wb_hi_i;
	wire[`RegBus] wb_lo_i;
	
	// WB(HI/LO) => EX
	wire[`RegBus] hi;
	wire[`RegBus] lo;
	
	// pipeline stall related
	wire[5:0] stall;
	wire stallreq_from_id;
	wire stallreq_from_ex;
	
	// buffer signals for MADD/MSUB
	wire[`DoubleRegBus] hilo_tmp_o;
	wire[1:0] cnt_o;
	wire[`DoubleRegBus] hilo_tmp_i;
	wire[1:0] cnt_i;
	
	// EX <=> DIV
	wire signed_div;
	wire[`RegBus] div_opdata1;
	wire[`RegBus] div_opdata2;
	wire div_start;
	wire[`DoubleRegBus] div_result;
	wire div_ready;
	
	/**** testing ****/
	assign test_signal = wb_wdata_i;
	
	/* Link with instruction RAM */
	assign rom_addr_o = pc;
	
	/* pc_reg instantiate */
	pc_reg pc_reg0(
		.clk(clk), .rst(rst), .stall(stall), .pc(pc), .ce(rom_ce_o),
		.branch_flag_i(id_branch_flag_o), 
		.branch_target_address_i(branch_target_address)
	);
	
	/* IF-ID instantiate */
	if_id if_id0(
		.clk(clk), .rst(rst), .stall(stall),
		.if_pc(pc), .if_inst(rom_data_i),
		.id_pc(id_pc_i), .id_inst(id_inst_i)
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
		.clk(clk), .rst(rst), .stall(stall),
		.id_aluop(id_aluop_o), .id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o), .id_reg2(id_reg2_o),
		.id_wd(id_wd_o), .id_wreg(id_wreg_o),
		.ex_aluop(ex_aluop_i), .ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i),
		// branch in
		.id_link_address(id_link_address_o),
		.id_is_in_delayslot(id_is_in_delayslot_o),
		.next_inst_in_delayslot_i(next_inst_in_delayslot),
		// branch out
		.ex_link_address(ex_link_address_i),
		.ex_is_in_delayslot(ex_is_in_delayslot_i),
		.is_in_delayslot_o(is_in_delayslot_i)
	);
	
	/* EX instantiate */
	ex ex0(
		.rst(rst),
		.aluop_i(ex_aluop_i), .alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i), .reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i), .wreg_i(ex_wreg_i),
		.hi_i(hi), .lo_i(lo),
		.mem_whilo_i(mem_whilo_o), .mem_hi_i(mem_hi_o), .mem_lo_i(mem_lo_o),
		.wb_whilo_i(wb_whilo_i), .wb_hi_i(wb_hi_i), .wb_lo_i(wb_lo_i), 
		.wd_o(ex_wd_o), .wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),
		.whilo_o(ex_whilo_o), .hi_o(ex_hi_o), .lo_o(ex_lo_o),
		.cnt_i(cnt_i), .hilo_tmp_i(hilo_tmp_i),
		.cnt_o(cnt_o), .hilo_tmp_o(hilo_tmp_o),
		.div_result_i(div_result), .div_ready_i(div_ready), 
		.div_opdata1_o(div_opdata1), .div_opdata2_o(div_opdata2),
		.div_start_o(div_start), .signed_div_o(signed_div),	
		// branch
		.link_address_i(ex_link_address_i),
		.is_in_delayslot_i(ex_is_in_delayslot_i),
		.stallreq(stallreq_from_ex)
	);
	
	/* EX-MEM instantiate */
	ex_mem ex_mem0(
		.clk(clk), .rst(rst), .stall(stall),
		.ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o), .ex_wdata(ex_wdata_o),
		.ex_whilo(ex_whilo_o), .ex_hi(ex_hi_o), .ex_lo(ex_lo_o),
		.mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i), .mem_wdata(mem_wdata_i),
		.mem_whilo(mem_whilo_i), .mem_hi(mem_hi_i), .mem_lo(mem_lo_i),
		.cnt_i(cnt_o), .hilo_tmp_i(hilo_tmp_o),
		.cnt_o(cnt_i), .hilo_tmp_o(hilo_tmp_i)
	);
	
	/* MEM instantiate */
	mem mem0(
		.rst(rst),
		.wd_i(mem_wd_i), .wreg_i(mem_wreg_i), .wdata_i(mem_wdata_i),
		.whilo_i(mem_whilo_i), .hi_i(mem_hi_i), .lo_i(mem_lo_i),
		.wd_o(mem_wd_o), .wreg_o(mem_wreg_o), .wdata_o(mem_wdata_o),
		.whilo_o(mem_whilo_o), .hi_o(mem_hi_o), .lo_o(mem_lo_o)
	);
	
	/* MEM-WB instantiate */
	mem_wb mem_wb0(
		.clk(clk), .rst(rst), .stall(stall),
		.mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o), .mem_wdata(mem_wdata_o),
		.mem_whilo(mem_whilo_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),
		.wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i), .wb_wdata(wb_wdata_i),
		.wb_whilo(wb_whilo_i), .wb_hi(wb_hi_i), .wb_lo(wb_lo_i)
	);
	
	/* HI/LO register instantiate */
	hilo_reg hilo_reg0(
		.clk(clk), .rst(rst),
		.we(wb_whilo_i), .hi_i(wb_hi_i), .lo_i(wb_lo_i),
		.hi_o(hi), .lo_o(lo)
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
		.stallreq_from_id(stallreq_from_id), .stallreq_from_ex(stallreq_from_ex),
		.stall(stall)
	);

endmodule
