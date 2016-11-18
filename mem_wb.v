`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    mem-wb
// Project Name:   SammingCPU
//
// MEM-WB module
// Receive write register signals and execute them at rising edge of clock
// Execution implemented simply by connecting output signals to regfile
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem_wb(
	input wire					clk,
	input wire					rst,
	input wire[5:0]				stall,
	input wire					flush,
	
	// from MEM
	input wire[`RegAddrBus]		mem_wd,
	input wire					mem_wreg,
	input wire[`RegBus]			mem_wdata,
	input wire					mem_whilo,
	input wire[`RegBus]			mem_hi,
	input wire[`RegBus]			mem_lo,
	
	// send to write
	output reg[`RegAddrBus]		wb_wd,
	output reg					wb_wreg,
	output reg[`RegBus]			wb_wdata,
	output reg					wb_whilo,
	output reg[`RegBus]			wb_hi,
	output reg[`RegBus]			wb_lo,
	
	// port for LL/SC
	input wire					mem_llbit_we,
	input wire					mem_llbit_value,
	output reg					wb_llbit_we,
	output reg					wb_llbit_value,
	
	// port for cp0
	input wire[`RegBus]			mem_cp0_reg_data,
	input wire[`CP0RegAddrBus]	mem_cp0_reg_write_addr,
	input wire					mem_cp0_reg_we,
	
	output reg[`RegBus]			wb_cp0_reg_data,
	output reg[`CP0RegAddrBus]	wb_cp0_reg_write_addr,
	output reg					wb_cp0_reg_we,
	
	// port for MEM DFA
	input wire[1:0]				cnt_i,
		// EXTENSION for multiple MEM clocks
	output reg[1:0]				cnt_o
		// EXTENSION for multiple MEM clocks
);

	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			// treat as NOP operation when rst == 1
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			cnt_o <= 2'b00;
			wb_llbit_we <= 1'b0;
			wb_llbit_value <= 1'b0;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else
		if (flush == 1'b1)
		begin
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			cnt_o <= 2'b00;
			wb_llbit_we <= 1'b0;
			wb_llbit_value<= 1'b0;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else
		if (stall[4] == `Stop && stall[5] == `NoStop)
		begin
			// NOP added
			wb_wd <= `NOPRegAddr;
			wb_wreg <= `WriteDisable;
			wb_wdata <= `ZeroWord;
			wb_whilo <= `WriteDisable;
			wb_hi <= `ZeroWord;
			wb_lo <= `ZeroWord;
			cnt_o <= cnt_i;
			wb_llbit_we <= 1'b0;
			wb_llbit_value <= 1'b0;
			wb_cp0_reg_we <= `WriteDisable;
			wb_cp0_reg_write_addr <= 5'b00000;
			wb_cp0_reg_data <= `ZeroWord;
		end else
		if (stall[4] == `NoStop)
		begin
			wb_wd <= mem_wd;
			wb_wreg <= mem_wreg;
			wb_wdata <= mem_wdata;
			wb_whilo <= mem_whilo;
			wb_hi <= mem_hi;
			wb_lo <= mem_lo;
			cnt_o <= 2'b00;
			wb_llbit_we <= mem_llbit_we;
			wb_llbit_value <= mem_llbit_value;
			wb_cp0_reg_we <= mem_cp0_reg_we;
			wb_cp0_reg_write_addr <= mem_cp0_reg_write_addr;
			wb_cp0_reg_data <= mem_cp0_reg_data;
		end else
		begin
			cnt_o <= cnt_i;
		end
	end

endmodule
