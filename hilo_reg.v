`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.2
// Module Name:    hilo_reg 
// Project Name:   SammingCPU
//
// Implementation of HI/LO register
// HI/LO set to input when write enabled and at rising edge of clock
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module hilo_reg(
	input wire 					clk,
	input wire					rst,
	
	// write port
	input wire					we,
	input wire[`RegBus]			hi_i,
	input wire[`RegBus]			lo_i,
	
	// read port and themselves as registers
	output reg[`RegBus]			hi_o,
	output reg[`RegBus]			lo_o
 );

	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
		end else
		if (we == `WriteEnable)
		begin
			hi_o <= hi_i;
			lo_o <= lo_i;
		end
	end

endmodule
