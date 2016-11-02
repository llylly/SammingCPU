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
	
	// read signals from ID
	input wire[`ALUOpBus]		id_aluop,
	input wire[`ALUSelBus]		id_alusel,
	input wire[`RegBus]			id_reg1,
	input wire[`RegBus]			id_reg2,
	input wire[`RegAddrBus]		id_wd,
	input wire					id_wreg,
	
	// send signals to EX
	output reg[`ALUOpBus]		ex_aluop,
	output reg[`ALUSelBus]		ex_alusel,
	output reg[`RegBus]			ex_reg1,
	output reg[`RegBus]			ex_reg2,
	output reg[`RegAddrBus]		ex_wd,
	output reg					ex_wreg
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
		end else
		begin
			// simply sent to EX at rising edge of clk
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;
		end
	end

endmodule