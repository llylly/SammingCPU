`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.13
// Module Name:    ram
// Project Name:   SammingCPU
//
// RAM module
// RAM driver
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ram(
	
	input wire					rst,
	input wire					clk,
	
	// from upper module
	input wire					we_i,
		// whether write RAM (otherwise read)
	input wire					ce_i,
		// module enable flag
	input wire[`RegBus]			addr_i,
	input wire[`RAMBus]			data_i,
	input wire[3:0]				sel_i,
	
	// to upper module
	output reg					ready_o,
	output reg[`RAMBus]			data_o,
	
	// from SRAM
	inout wire[`RAMBus]			base_ram_data,
	inout wire[`RAMBus]			ext_ram_data,
	
	// to SRAM
	output reg[`RAMAddrBus]		base_ram_addr,
	output reg					base_ram_ce,
	output reg					base_ram_oe,
	output reg					base_ram_we,
	
	output reg[`RAMAddrBus]		ext_ram_addr,
	output reg					ext_ram_ce,
	output reg					ext_ram_oe,
	output reg					ext_ram_we
);

	reg[1:0] cnt;
	
	reg[`RAMBus] base_ram_data_buf;
	reg[`RAMBus] ext_ram_data_buf;
	
	assign base_ram_data = base_ram_data_buf;
	assign ext_ram_data = ext_ram_data_buf;
	
	reg data_ready;
	
	reg[`RAMBus] store_buf;
	
	always @(*)
	begin
		ready_o <= data_ready & (rst == `RstDisable) & (ce_i == `ChipEnable);
	end
	
	always @(posedge clk)
	begin
		if ((rst == `RstEnable) || (ce_i == `ChipDisable))
		begin
			cnt <= 2'b00;
			data_ready <= 1'b0;
			data_o <= `ZeroWord;
			base_ram_ce <= 1'b1;
			base_ram_we <= 1'b1;
			base_ram_oe <= 1'b0;
			base_ram_data_buf <= 32'hZZZZZZZZ;
			ext_ram_ce <= 1'b1;
			ext_ram_we <= 1'b1;
			ext_ram_oe <= 1'b0;
			ext_ram_data_buf <= 32'hZZZZZZZZ;
		end else
		begin
			base_ram_ce <= 1'b1;
			base_ram_we <= 1'b1;
			base_ram_oe <= 1'b0;
			base_ram_data_buf <= 32'hZZZZZZZZ;
			ext_ram_ce <= 1'b1;
			ext_ram_we <= 1'b1;
			ext_ram_oe <= 1'b0;
			ext_ram_data_buf <= 32'hZZZZZZZZ;
			if (we_i == `RAMWrite_OP)
			begin
				if (sel_i == 4'b1111)
				begin
					if (addr_i[22] == 1'b0)
					begin
						base_ram_addr <= addr_i[21:2];
						base_ram_ce <= 1'b0;
						base_ram_we <= 1'b0;
						base_ram_oe <= 1'b1;
						base_ram_data_buf <= data_i;
					end else
					if (addr_i[22] == 1'b1)
					begin
						ext_ram_addr <= addr_i[21:2];
						ext_ram_ce <= 1'b0;
						ext_ram_we <= 1'b0;
						ext_ram_oe <= 1'b1;
						ext_ram_data_buf <= data_i;
					end
					data_o <= `ZeroWord;
					data_ready <= 1'b1;
				end else
				if (sel_i == 4'b0000)
				begin
					data_o <= `ZeroWord;
					data_ready <= 1'b1;
				end else
				begin
					case (cnt)
						2'b00: begin
							// read
							if (addr_i[22] == 1'b0)
							begin
								base_ram_addr <= addr_i[21:2];
								base_ram_ce <= 1'b0;
								base_ram_we <= 1'b1;
								base_ram_oe <= 1'b0;
								base_ram_data_buf <= 32'hZZZZZZZZ;
							end else
							if (addr_i[22] == 1'b1)
							begin
								ext_ram_addr <= addr_i[21:2];
								ext_ram_ce <= 1'b0;
								ext_ram_we <= 1'b1;
								ext_ram_oe <= 1'b0;
								ext_ram_data_buf <= 32'hZZZZZZZZ;
							end
							cnt <= 2'b01;
						end
						2'b01: begin
							// cal
							if (sel_i[3] == 1'b1)
							begin
								store_buf[31:24] <= data_i[31:24];
							end else
							begin
								if (addr_i[22] == 1'b0)
									store_buf[31:24] <= base_ram_data[31:24];
								else
									store_buf[31:24] <= ext_ram_data[31:24];
							end
							if (sel_i[2] == 1'b1)
							begin
								store_buf[23:16] <= data_i[23:16];
							end else
							begin
								if (addr_i[22] == 1'b0)
									store_buf[23:16] <= base_ram_data[23:16];
								else
									store_buf[23:16] <= ext_ram_data[23:16];
							end
							if (sel_i[1] == 1'b1)
							begin
								store_buf[15:8] <= data_i[15:8];
							end else
							begin
								if (addr_i[22] == 1'b0)
									store_buf[15:8] <= base_ram_data[15:8];
								else
									store_buf[15:8] <= ext_ram_data[15:8];
							end
							if (sel_i[0] == 1'b1)
							begin
								store_buf[7:0] <= data_i[7:0];
							end else
							begin
								if (addr_i[22] == 1'b0)
									store_buf[7:0] <= base_ram_data[7:0];
								else
									store_buf[7:0] <= ext_ram_data[7:0];
							end
							cnt <= 2'b10;
						end
						2'b10: begin
							// write
							if (addr_i[22] == 1'b0)
							begin
								base_ram_addr <= addr_i[21:2];
								base_ram_ce <= 1'b0;
								base_ram_we <= 1'b0;
								base_ram_oe <= 1'b1;
								base_ram_data_buf <= store_buf;
							end else
							if (addr_i[22] == 1'b1)
							begin
								ext_ram_addr <= addr_i[21:2];
								ext_ram_ce <= 1'b0;
								ext_ram_we <= 1'b0;
								ext_ram_oe <= 1'b1;
								ext_ram_data_buf <= data_i;
							end
							data_o <= `ZeroWord;
							data_ready <= 1'b1;
						end
					endcase
				end
			end else
			if (we_i == `RAMRead_OP)
			begin
				if (cnt == 2'b00)
				begin
					if (addr_i[22] == 1'b0)
					begin
						base_ram_addr <= addr_i[21:2];
						base_ram_ce <= 1'b0;
						base_ram_we <= 1'b1;
						base_ram_oe <= 1'b0;
						base_ram_data_buf <= 32'hZZZZZZZZ;
					end else
					if (addr_i[22] == 1'b1)
					begin
						ext_ram_addr <= addr_i[21:2];
						ext_ram_ce <= 1'b0;
						ext_ram_we <= 1'b1;
						ext_ram_oe <= 1'b0;
						ext_ram_data_buf <= 32'hZZZZZZZZ;
					end
					data_ready <= 1'b0;
					cnt <= 2'b01;
				end else
				begin
					if (addr_i[22] == 1'b0)
					begin
						data_o <= base_ram_data;
					end else
					if (addr_i[22] == 1'b1)
					begin
						data_o <= ext_ram_data;
					end
					data_ready <= 1'b1;
				end
			end
		end
	end

endmodule
