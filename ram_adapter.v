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
	
	// to cpu of TLB exception
	output reg					ram_tlb_err_o,
	output reg					ram_tlb_mod_o,
	
	// from pc
	input wire[`RegBus]			pc_addr_i,
	
	// to pc
	output reg[`RegBus]			pc_data_o,
	output wire					pc_ready_o,
	
	// to pc of TLB exception
	output reg					pc_tlb_err_o,
	
	// interact with MMU
	output reg					we_o,
	output reg					ce_o,
	output reg[`RegBus]			addr_o,
	output reg[`RAMBus]			data_o,
	output reg[3:0]				sel_o,
	
	input wire					ready_i,
	input wire[`RAMBus]			data_i,
	
	input wire					tlb_err_i,
	input wire					mod_i,
	input wire					mcheck_i
);

	/* DFA state record */
	reg[1:0] cnt;
	
	/* PC old */
	reg[`RegBus] oldpc;
	
	/* PC DFA state record */
	reg[1:0] pc_cnt;
	
	/* PC ready_o */
	reg pc_ready;
	assign pc_ready_o = pc_ready && (oldpc == pc_addr_i);
	
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
				sel_o <= 4'b1111;
				pc_ready <= 1'b0;
				pc_tlb_err_o <= 1'b0;
				if (ready_i == 1'b1)
				begin
					ce_o <= `ChipDisable;
					pc_data_o <= data_i;
					pc_cnt <= 2'b10;
					pc_tlb_err_o <= tlb_err_i;
				end
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
				ram_tlb_err_o <= 1'b0;
				ram_tlb_mod_o <= 1'b0;
			end else
			begin
				// when pc is not ready, load/store DFA will stuck in 00 state to wait
				if (ram_we_i == 1'b1)
				begin
					// write operation
					if (cnt == 2'b00)
					begin
						we_o <= `RAMWrite_OP;
						ce_o <= `ChipEnable;
						addr_o <= ram_addr_i;
						data_o <= ram_data_i;
						sel_o <= ram_sel_i;
						ram_ready_o <= 1'b0;
						if (ready_i == 1'b1)
						begin
							cnt <= 2'b01;
							ce_o <= `ChipEnable;
							ram_data_o <= `ZeroWord;
							ram_ready_o <= 1'b1;
							ram_tlb_err_o <= tlb_err_i;
							ram_tlb_mod_o <= mod_i;
						end
					end
					if (cnt == 2'b01)
					begin
						
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
						ram_ready_o <= 1'b0;
						if (ready_i == 1'b1)
						begin
							cnt <= 2'b01;
							ce_o <= `ChipEnable;
							cnt <= 2'b10;
							ram_data_o <= data_i;
							ram_ready_o <= 1'b1;
							ram_tlb_err_o <= tlb_err_i;
						end
					end
					if (cnt == 2'b01)
					begin
						
					end
				end	
			end
		end
	end

endmodule
