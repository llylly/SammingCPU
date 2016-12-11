`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.12.10
// Module Name:    VGA
// Project Name:   SammingCPU
//
// Handle vga output
// 800x600 @ 75Hz
//////////////////////////////////////////////////////////////////////////////////

module vga_rom(

	input wire[7:0]				no_i,
	input wire[4:0]				x_i,
	input wire[4:0]				y_i,
	
	output wire					data_o

);

	wire[11:0] bigNo, index;
	reg[0:23] romSet[0:4095];
	
	initial $readmemb("graph.mem", romSet);
	
	assign bigNo = {{5{1'b0}}, no_i[6:0]};
	assign index = (bigNo << 4) + (bigNo << 3) + y_i;
	
	assign data_o = romSet[index][x_i];

endmodule
