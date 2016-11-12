`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    ex-mem
// Project Name:   SammingCPU
//
// EX-MEM module
// Receive signals from EX and send them to MEM at rising edge of clock
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ex_mem(
	input wire					clk,
	input wire					rst,
	input wire[5:0]				stall,
	
	// receive from EX
	input wire[`RegAddrBus]		ex_wd,
	input wire					ex_wreg,
	input wire[`RegBus]			ex_wdata,
	input wire					ex_whilo,
	input wire[`RegBus]			ex_hi,
	input wire[`RegBus]			ex_lo,
	input wire[`ALUOpBus]		ex_aluop,
	input wire[`RegBus]			ex_mem_addr,
	input wire[`RegBus]			ex_reg2,
	
	// send to MEM
	output reg[`RegAddrBus]		mem_wd,
	output reg					mem_wreg,
	output reg[`RegBus]			mem_wdata,
	output reg					mem_whilo,
	output reg[`RegBus]			mem_hi,
	output reg[`RegBus]			mem_lo,
	output wire[`ALUOpBus]		mem_aluop,
	output wire[`RegBus]		mem_mem_addr,
	output wire[`RegBus]		mem_reg2,
	
	// port for multi and add/sub operations signal buffer
	input wire[`DoubleRegBus]	hilo_tmp_i,
	input wire[1:0]				cnt_i,
	
	output reg[`DoubleRegBus]	hilo_tmp_o,
	output reg[1:0]				cnt_o
);

	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			// When rst == 1, treat as NOP instruction
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_whilo <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
			
			hilo_tmp_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;
			
			mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
		end else
		if (stall[3] == `Stop && stall[4] == `NoStop)
		begin
			// NOP added
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
			mem_wdata <= `ZeroWord;
			mem_whilo <= `WriteDisable;
			mem_hi <= `ZeroWord;
			mem_lo <= `ZeroWord;
			
			hilo_tmp_o <= hilo_tmp_i;
			cnt_o <= cnt_i;
			
			mem_aluop <= `EXE_NOP_OP;
			mem_mem_addr <= `ZeroWord;
			mem_reg2 <= `ZeroWord;
		end else
		if (stall[3] == `NoStop)
		begin
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;
			mem_whilo <= ex_whilo;
			mem_hi <= ex_hi;
			mem_lo <= ex_lo;
			
			hilo_tmp_o <= {`ZeroWord, `ZeroWord};
			cnt_o <= 2'b00;
			
			mem_aluop <= ex_aluop;
			mem_mem_addr <= exe_mem_addr;
			mem_reg2 <= ex_reg2;
		end else
		begin
			hilo_tmp_o <= hilo_tmp_i;
			cnt_o <= cnt_i;
		end
	end

endmodule
