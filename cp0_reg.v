`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.24
// Module Name:    cp0_reg
// Project Name:   SammingCPU
//
// Implementation of CP0 registers
// v1.0
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module cp0_reg(
	
	input wire 					clk,
	input wire					rst,
	
	input wire					we_i,
		// whether to write cp0 registers
	input wire[`RegAddrBus]		waddr_i,
		// write address
	input wire[`RegBus]			data_i,
		// write data
	input wire[`RegAddrBus]		raddr_i,
		// read address
		
	input wire[5:0]				int_i,
		// hardware interrupt in
		
	output reg[`RegBus]			data_o,
		// read data of specified register
	
	output reg[`RegBus]			count_o,
	output reg[`RegBus]			compare_o,
	output reg[`RegBus]			status_o,
	output reg[`RegBus]			cause_o,
		// read-only
	output reg[`RegBus]			epc_o,
	output reg[`RegBus]			config_o,
	output reg[`RegBus]			prid_o,
		// read-only
	
	output reg					timer_int_o
		// whether timer interrupt happened
);

	/** write operations **/
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			count_o <= `ZeroWord;
			compare_o <= `ZeroWord;
			status_o <= 32'b00010000000000000000000000000000;
			cause_o <= `ZeroWord;
			epc_o <= `ZeroWord;
			config_o <= 32'b00000000000000001000000000000000;
			prid_o <= 32'b00000000010100110000000100000010;
				// name: S
			timer_int_o <= `InterruptNotAssert;
		end else
		begin
			count_o <= count_o + 1;
			cause_o[15:10] <= int_i;
				// hardware IP
			
			// timer interrupt
			if (compare_o != `ZeroWord && count_o == compare_o)
			begin
				timer_int_o <= `InterruptAssert;
			end
			
			if (we_i == `WriteEnable)
			begin
				case (waddr_i)
					`CP0_REG_COUNT: begin
						count_o <= data_i;
					end
					`CP0_REG_COMPARE: begin
						compare_o <= data_i;
						timer_int_o <= `InterruptNotAssert;
					end
					`CP0_REG_STATUS: begin
						//status_o <= data_i;
						status_o[22] <= data_i[22];
							// BEV
						status_o[21] <= data_i[21];
							// TS
						status_o[20] <= data_i[20];
							// SR
						status_o[19] <= data_i[19];
							// NMI
						status_o[15:8] <= data_i[15:8];
							// IM
						status_o[4] <= data_i[4];
							// UM: 1-kernel, 0-user
						status_o[1] <= data_i[1];
							// EXL
						status_o[0] <= data_i[0];
							// IE
					end
					`CP0_REG_EPC: begin
						epc_o <= data_i;
					end
					`CP0_REG_CAUSE: begin
						cause_o[9:8] <= data_i[9:8];
							// software IP
						cause_o[23] <= data_i[23];
							// IV
						cause_o[22] <= data_i[22];
							// WP
					end
				endcase
			end
		end
	end
	
	/** read operations **/
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			data_o <= `ZeroWord;
		end else
		begin
			case (raddr_i)
				`CP0_REG_COUNT: begin
					data_o <= count_o;
				end
				`CP0_REG_COMPARE: begin
					data_o <= compare_o;
				end
				`CP0_REG_STATUS: begin
					data_o <= status_o;
				end
				`CP0_REG_CAUSE: begin
					data_o <= cause_o;
				end
				`CP0_REG_EPC: begin
					data_o <= epc_o;
				end
				`CP0_REG_PRID: begin
					data_o <= prid_o;
				end
				`CP0_REG_CONFIG: begin
					data_o <= config_o;
				end
			endcase
		end
	end

endmodule
