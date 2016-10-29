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
	
	// receive from EX
	input wire[`RegAddrBus]		ex_wd,
	input wire					ex_wreg,
	input wire[`RegBus]			ex_wdata,
	
	// send to MEM
	output reg[`RegAddrBus]		mem_wd,
	output reg					mem_wreg,
	output reg[`RegBus]			mem_wdata
);

	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			// When rst == 1, treat as NOP instruction
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
			mem_wdata <= `ZeroWord;
		end else
		begin
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;
		end
	end

endmodule
