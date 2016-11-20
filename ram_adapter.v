`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.13
// Module Name:    ram_adapter
// Project Name:   SammingCPU
//
// RAM adapter module
// Transform CPU ram operation to ram module accepted form
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module ram_adapter(

	input wire					rst,
	input wire					clk,

	// from cpu
	input wire[`RegBus]			ram_addr_i,
		// output of RAM IO address
	input wire					ram_we_i,
		// output of whether to write memory
	input wire[3:0]				ram_sel_i,
		// byte selection signal
	input wire[`RegBus]			ram_data_i,
		// data to write to memory
	input wire					ram_ce_i,
	
	// to cpu
	output reg[`RegBus]			ram_data_o,
	output reg					ram_ready_o,
	
	// from pc
	input wire[`RegBus]			pc_addr_i,
	
	// to pc
	output reg[`RegBus]			pc_data_o,
	output wire					pc_ready_o,
	
	// base seg SRAM
	inout wire[`RAMBus]			base_ram_data,
	inout wire[`RAMBus]			ext_ram_data,
	
	// base seg SRAM
	output wire[`RAMAddrBus]	base_ram_addr,
	output wire					base_ram_ce,
	output wire					base_ram_oe,
	output wire					base_ram_we,
	
	output wire[`RAMAddrBus]	ext_ram_addr,
	output wire					ext_ram_ce,
	output wire					ext_ram_oe,
	output wire					ext_ram_we
);

	/* DFA state record */
	reg[1:0] cnt;
	
	/* ram_adapter <=> ram */
	reg we_o;
		// whether write RAM (otherwise read)
	reg ce_o;
	reg[`RegBus] addr_o;
	reg[`RAMBus] data_o;
	wire ready_i;
	wire[`RAMBus] data_i;
	
	/* PC old */
	reg[`RegBus] oldpc;
	
	/* PC DFA state record */
	reg[1:0] pc_cnt;
	
	/* PC ready_o */
	reg pc_ready;
	assign pc_ready_o = pc_ready && (oldpc == pc_addr_i);
	
	/* ram instantiate */
	ram ram0(
		.rst(rst), .clk(clk),
		.we_i(we_o), .ce_i(ce_o), .addr_i(addr_o), .data_i(data_o),
		.ready_o(ready_i), .data_o(data_i),
		.base_ram_data(base_ram_data), .ext_ram_data(ext_ram_data),
		.base_ram_addr(base_ram_addr), .base_ram_ce(base_ram_ce),
		.base_ram_oe(base_ram_oe), .base_ram_we(base_ram_we),
		.ext_ram_addr(ext_ram_addr), .ext_ram_ce(ext_ram_ce),
		.ext_ram_oe(ext_ram_oe), .ext_ram_we(ext_ram_we)
	);
	
	/* data_o buffer */
	reg[`RAMBus] data_o_tmp;
	
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			pc_ready <= 1'b0;
			pc_cnt <= 2'b00;
			oldpc <= `ZeroWord;
			cnt <= 2'b00;
			ce_o <= `ChipDisable;
			ram_ready_o <= 1'b0;
		end else
		begin
			ce_o <= `ChipDisable;
		
			if (pc_cnt == 2'b00)
			begin
				oldpc <= pc_addr_i;
				we_o <= `RAMRead_OP;
				ce_o <= `ChipEnable;
				addr_o <= pc_addr_i;
				pc_ready <= 1'b0;
				if (ready_i == 1'b1)
				begin
					pc_cnt <= 2'b01;
				end
			end else
			if (pc_cnt == 2'b01)
			begin
				ce_o <= `ChipDisable;
				pc_data_o <= data_i;
				pc_cnt <= 2'b10;
			end else
			if (pc_cnt == 2'b10)
			begin
				pc_ready <= 1'b1;
				// when pc issued new, then read a new data
				if ((pc_addr_i != oldpc))
				begin
					pc_cnt <= 2'b00;
				end
			end
		
			if ((ram_ce_i == `ChipDisable) || (pc_addr_i != oldpc) || (pc_ready == 1'b0))
			begin
				cnt <= 2'b00;
				ram_ready_o <= 1'b0;
			end else
			begin
				// when pc is not ready, load/store DFA will stuck in 00 state to wait
				if (ram_we_i == 1'b1)
				begin
					// write operation:
					// read - combile - write - wait or
					// wait - write - wait
					if (cnt == 2'b00)
					begin
						ram_ready_o <= 1'b0;
						if (ram_sel_i == 4'b0000)
						begin
							cnt <= 2'b11;
						end else
						if (ram_sel_i == 4'b1111)
						begin
							data_o_tmp <= ram_data_i;
							cnt <= 2'b10;
						end else
						begin
							we_o <= `RAMRead_OP;
							ce_o <= `ChipEnable;
							addr_o <= ram_addr_i;
							if (ready_i == 1'b1)
							begin
								data_o_tmp <= data_i;
								cnt <= 2'b01;
							end else
							begin
								cnt <= 2'b00;
							end
						end
					end
					if (cnt == 2'b01)
					begin
						ce_o <= `ChipDisable;
						data_o_tmp <= data_i;
						if (ram_sel_i[3] == 1'b1)
						begin
							data_o_tmp[31:24] <= ram_data_i[31:24];
						end
						if (ram_sel_i[2] == 1'b1)
						begin
							data_o_tmp[23:16] <= ram_data_i[23:16];
						end
						if (ram_sel_i[1] == 1'b1)
						begin
							data_o_tmp[15:8] <= ram_data_i[15:8];
						end
						if (ram_sel_i[0] == 1'b1)
						begin
							data_o_tmp[7:0] <= ram_data_i[7:0];
						end
						cnt <= 2'b10;
					end
					if (cnt == 2'b10)
					begin
						we_o <= `RAMWrite_OP;
						ce_o <= `ChipEnable;
						addr_o <= ram_addr_i;
						data_o <= data_o_tmp;
						if (ready_i == 1'b1)
						begin
							cnt <= 2'b11;
						end else
						begin
							cnt <= 2'b10;
						end
					end
					if (cnt == 2'b11)
					begin
						ce_o <= `ChipDisable;
						ram_data_o <= `ZeroWord;
						ram_ready_o <= 1'b1;
					end
				end else
				if (ram_we_i == 1'b0)
				begin
					// read operation
					if (cnt == 2'b00)
					begin
						we_o <= `RAMRead_OP;
						ce_o <= `ChipEnable;
						addr_o <= ram_addr_i;
						if (ready_i == 1'b1)
						begin
							cnt <= 2'b01;
						end else
						begin
							cnt <= 2'b00;
						end
						ram_ready_o <= 1'b0;
					end
					if (cnt == 2'b01)
					begin
						cnt <= 2'b10;
						ram_data_o <= data_i;
						ram_ready_o <= 1'b1;
					end
					if (cnt == 2'b10)
					begin
						ce_o <= `ChipDisable;
					end
				end	
			end
		end
	end

endmodule
