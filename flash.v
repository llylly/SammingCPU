`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.12.1
// Module Name:    serail
// Project Name:   SammingCPU
//
// Serail controller module
// Used with MMU
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module flash(

	input wire					rst,
	input wire					clk,
	
	// with MMU
	output reg[`FlashBus]		data_o,
	output reg					ready_o,
	
	input wire[`FlashAddrBus]	addr_i,
	input wire					ce_i,
	input wire					we_i,
	input wire[`FlashBus]		data_i,
	input wire[3:0]				sel_i,
	
	// with Outer
	output reg[`FlashAddrBus]	flash_addr_o,
	inout wire[`FlashRealBus]	flash_data,
	output reg					flash_byte_o,
	output reg					flash_ce_o,
	output reg					flash_ce1_o,
	output reg					flash_ce2_o,
	output reg					flash_oe_o,
	output reg					flash_rp_o,
	input wire					flash_sys_i,
	output reg					flash_vpen_o,
	output reg					flash_we_o

);

	reg[`FlashRealBus] flash_regData;
	
	assign flash_data = flash_regData;

	// const configuration
	always @(*)
	begin
		flash_byte_o <= 1'b1;
		flash_vpen_o <= 1'b1;
		flash_ce1_o <= 1'b0;
		flash_ce2_o <= 1'b0;
		flash_rp_o <= 1'b1;
	end
	
	
	// registers
	reg[2:0] cnt;
		// status
	reg[4:0] dcnt;
		// delayCnt
	reg status_set;
		// whether configured read mode
	
	// main part
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			flash_ce_o <= 1'b1;
			flash_oe_o <= 1'b1;
			flash_we_o <= 1'b0;
			cnt <= 3'b000;
			dcnt <= 4'b0000;
			status_set <= 1'b0;
			ready_o <= 1'b0;
		end else
		begin
			flash_ce_o <= 1'b0;
			if (ce_i == 1'b0)
			begin
				flash_oe_o <= 1'b1;
				flash_we_o <= 1'b1;
				flash_regData <= 16'hZZZZ;
				cnt <= 3'b000;
				dcnt <= 5'b00000;
				ready_o <= 1'b0;
			end else
			begin
				if (we_i == 1'b1)
				begin
					// currently no write operations
					ready_o <= 1'b1;
				end else
				begin
					// read
					case (cnt)
						3'b000: begin
							dcnt <= 5'b00000;
							/*if (status_set == 1'b1)
								cnt <= 3'b010;
							else
								cnt <= 3'b001;*/
							cnt <= 3'b001;
						end
						
						// flush write mode
						3'b001: begin
							if (dcnt != 5'b11111)
							begin
								flash_oe_o <= 1'b1;
								flash_we_o <= 1'b0;
								flash_regData <= 16'h00FF;
								dcnt <= dcnt + 1;
							end else
							begin
								status_set <= 1'b1;
								dcnt <= 5'b00000;
								cnt <= 3'b010;
							end
						end
						
						// read1
						3'b010: begin
							if (dcnt == 5'b00000)
							begin
								flash_regData <= 16'hZZZZ;
								flash_oe_o <= 1'b1;
								flash_we_o <= 1'b1;
								dcnt <= dcnt + 1;
							end else
							if (dcnt != 5'b11111)
							begin
								flash_oe_o <= 1'b0;
								flash_we_o <= 1'b1;
								flash_addr_o <= {addr_i[22:2], 2'b00};
								dcnt <= dcnt + 1;
							end else
							begin
								data_o[15:0] <= flash_data;
								cnt <= 3'b011;
								dcnt <= 5'b00000;
							end
						end
						
						3'b011: begin
							flash_oe_o <= 1'b1;
							flash_we_o <= 1'b1;
							if (dcnt == 5'b00111)
							begin
								dcnt <= 5'b00000;
								cnt <= 3'b100;
							end else
								dcnt <= dcnt + 1;
						end
						
						// read2
						3'b100: begin
							if (dcnt == 5'b00000)
							begin
								flash_regData <= 16'hZZZZ;
								flash_oe_o <= 1'b1;
								flash_we_o <= 1'b1;
								dcnt <= dcnt + 1;
							end else
							if (dcnt != 5'b11111)
							begin
								flash_oe_o <= 1'b0;
								flash_we_o <= 1'b1;
								flash_addr_o <= {addr_i[22:2], 2'b10};
								dcnt <= dcnt + 1;
							end else
							begin
								data_o[31:16] <= flash_data;
								cnt <= 3'b101;
								dcnt <= 5'b00000;
							end
						end
						
						3'b101: begin
							if (dcnt == 5'b00111)
							begin
								dcnt <= 5'b00000;
								ready_o <= 1'b1;
							end else
								dcnt <= dcnt + 1;
							flash_oe_o <= 1'b1;
							flash_we_o <= 1'b1;
						end
						
						// idle
						default: begin
						end
					
					endcase
				end
			end
		end
	end


endmodule
