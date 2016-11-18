`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    id-ex
// Project Name:   SammingCPU
//
// ID-EX module
// Save operands and op types sent from ID
// Send them to EX in next clock
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module id_ex(
	input wire					clk,
	input wire					rst,
	input wire[5:0]				stall,
	input wire					flush,
	
	// read signals from ID
	input wire[`ALUOpBus]		id_aluop,
	input wire[`ALUSelBus]		id_alusel,
	input wire[`RegBus]			id_reg1,
	input wire[`RegBus]			id_reg2,
	input wire[`RegAddrBus]		id_wd,
	input wire					id_wreg,
	input wire[`RegBus]			id_inst,
	
	// send signals to EX
	output reg[`ALUOpBus]		ex_aluop,
	output reg[`ALUSelBus]		ex_alusel,
	output reg[`RegBus]			ex_reg1,
	output reg[`RegBus]			ex_reg2,
	output reg[`RegAddrBus]		ex_wd,
	output reg					ex_wreg,
	output reg[`RegBus]			ex_inst,
	
	// signals related to branch
	input wire[`RegBus]			id_link_address,
	input wire					id_is_in_delayslot,
	input wire					next_inst_in_delayslot_i,
	
	output reg[`RegBus]			ex_link_address,
	output reg					ex_is_in_delayslot,
	output reg					is_in_delayslot_o,
	
	// related to interrupt
	input wire[`InstAddrBus]	id_current_inst_address,
	input wire[`ExceptBus]		id_excepttype,
	
	output reg[`InstAddrBus]	ex_current_inst_address,
	output reg[`ExceptBus]		ex_excepttype
);

	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			// when rst = 1, sent NOP operation
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			is_in_delayslot_o <= `NotInDelaySlot;
			
			ex_inst <= `ZeroWord;
			
			ex_excepttype <= `ZeroWord;
			ex_current_inst_address <= `ZeroWord;
		end else
		if (flush == 1'b1)
		begin
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			is_in_delayslot_o <= `NotInDelaySlot;
			
			ex_inst <= `ZeroWord;
			
			ex_excepttype <= `ZeroWord;
			ex_current_inst_address <= `ZeroWord;
		end else
		if (stall[2] == `Stop && stall[3] == `NoStop)
		begin
			// NOP added
			ex_aluop <= `EXE_NOP_OP;
			ex_alusel <= `EXE_RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			
			ex_link_address <= `ZeroWord;
			ex_is_in_delayslot <= `NotInDelaySlot;
			
			ex_inst <= `ZeroWord;
			
			ex_excepttype <= `ZeroWord;
			ex_current_inst_address <= `ZeroWord;
		end else
		if (stall[2] == `NoStop)
		begin
			// simply sent to EX at rising edge of clk
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;
			
			ex_link_address <= id_link_address;
			ex_is_in_delayslot <= id_is_in_delayslot;
			is_in_delayslot_o <= next_inst_in_delayslot_i;
			
			ex_inst <= id_inst;
			
			ex_excepttype <= id_excepttype;
			ex_current_inst_address <= id_current_inst_address;
		end
	end

endmodule
