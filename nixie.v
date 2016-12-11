`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    nixie
// Project Name:   SammingCPU
//
// Nixie module
// transform byte data to nixie tube 2 numbers
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module nixie(
	input wire					rst,

	input wire[7:0]				data_i,
	
	output reg[0:6]				show1_o,
	output reg[0:6]				show0_o

);

	reg[0:6] corres[0:15];

	always @(*)
	begin
		corres[0] <= 7'b1111110;
		corres[1] <= 7'b0110000;
		corres[2] <= 7'b1101101;
		corres[3] <= 7'b1111001;
		corres[4] <= 7'b0110011;
		corres[5] <= 7'b1011011;
		corres[6] <= 7'b1011111;
		corres[7] <= 7'b1110000;
		corres[8] <= 7'b1111111;
		corres[9] <= 7'b1111011;
		corres[10] <= 7'b1110111;
		corres[11] <= 7'b0011111;
		corres[12] <= 7'b1001110;
		corres[13] <= 7'b0111101;
		corres[14] <= 7'b1001111;
		corres[15] <= 7'b1000111;
	end

	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			show1_o <= corres[0];
			show0_o <= corres[0];
		end else
		begin
			show1_o <= corres[data_i[7:4]];
			show0_o <= corres[data_i[3:0]];
		end
	end

endmodule
