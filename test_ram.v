`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.12
// Module Name:    test_ram
// Project Name:   SammingCPU
//
// Test-RAM module
// Used for simulating real RAM
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module test_ram(
	
	input wire					clk,
	
	input wire[`RAMAddrBus]		base_ram_addr,
	input wire					base_ram_ce,
	input wire					base_ram_oe,
	input wire					base_ram_we,
	
	input wire[`RAMAddrBus]		ext_ram_addr,
	input wire					ext_ram_ce,
	input wire					ext_ram_oe,
	input wire					ext_ram_we,

	inout wire[`RAMBus]			base_ram_data,
	inout wire[`RAMBus]			ext_ram_data
);

	reg[`RAMBus] base_data_mem[0 : `DataMemNum - 1];
	reg[`RAMBus] ext_data_mem[0 : `DataMemNum - 1];
	
	reg[`RAMBus] base_ram_data_buf;
	reg[`RAMBus] ext_ram_data_buf;
	
	assign base_ram_data = base_ram_data_buf;
	assign ext_ram_data = ext_ram_data_buf;

	always @ (posedge clk)
	begin
		if (base_ram_ce == 1'b1)
		begin
			base_ram_data_buf <= 32'hZZZZZZZZ;
		end else
		begin
			if (base_ram_we == 1'b0)
				base_data_mem[base_ram_addr[`DataWidth]] <= base_ram_data;
		end
	end
	
	always @ (posedge clk)
	begin
		if (ext_ram_ce == 1'b1)
		begin
			ext_ram_data_buf <= 32'hZZZZZZZZ;
		end else
		begin
			if (ext_ram_we == 1'b0)
				ext_data_mem[ext_ram_addr[`DataWidth]] <= ext_ram_data;
		end
	end
	
	always @(*)
	begin
		if (base_ram_ce == 1'b1)
		begin
			base_ram_data_buf <= 32'hZZZZZZZZ;
		end else
		begin
			if (base_ram_we == 1'b0) 
				base_ram_data_buf <= 32'hZZZZZZZZ;
			if ((base_ram_we == 1'b1) && (base_ram_ce == 1'b0))
				base_ram_data_buf <= base_data_mem[base_ram_addr[`DataWidth]];
		end
	end
	
	always @(*)
	begin
		if (ext_ram_ce == 1'b1)
		begin
			ext_ram_data_buf <= 32'hZZZZZZZZ;
		end else
		begin
			if (ext_ram_we == 1'b0)
				ext_ram_data_buf <= 32'hZZZZZZZZ;
			if ((ext_ram_we == 1'b1) && (ext_ram_ce == 1'b0))
				ext_ram_data_buf <= ext_data_mem[ext_ram_addr[`DataWidth]];
		end
	end

endmodule
