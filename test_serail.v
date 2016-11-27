`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.23
// Module Name:    test_serail
// Project Name:   SammingCPU
//
// A simulate serail used for testing
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module test_serail(

	input wire					clk,
	input wire					rst,
	
	// output
	output reg[`RAMBus]			serail_data_o,
	output reg					serail_ready_o,
	
	// input
	input wire[`SerailAddrBus]	serail_addr_i,
	input wire[`RAMBus]			serail_data_i,
	input wire[`RAMBus]			serail_we_i,
	input wire[`RAMBus]			serail_ce_i
);

	reg[1:0] cnt;

	always @(posedge clk)
	begin
		if ((rst == `RstEnable) || (serail_ce_i == 1'b0))
		begin
			serail_ready_o <= 1'b0;
			cnt <= 2'b00;
		end else
		begin
			if (serail_we_i == 1'b1)
			begin
				if (cnt == 2'b00)
				begin
					$write("%c", serail_data_i[7:0]);
					serail_ready_o <= 1'b1;
					cnt <= 2'b01;
				end
			end else
			begin
				cnt <= 2'b00;
			end
		end
	end

endmodule
