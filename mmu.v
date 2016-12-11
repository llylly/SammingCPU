`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.20
// Module Name:    mmu
// Project Name:   SammingCPU
//
// Memory Management Unit
// Maintain a TLB table inside
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module mmu(
	
	input wire					rst,
	input wire					clk,
	
	// in
	input wire					we_i,
		// whether write RAM (otherwise read)
	input wire					ce_i,
		// module enable flag
	input wire[`RegBus]			addr_i,
	input wire[`RAMBus]			data_i,
	input wire[3:0]				sel_i,
	
	// out
	output reg					ready_o,
	output reg[`RAMBus]			data_o,
	
	// cp0 need
	input wire[`RAMBus]			entryhi_i,
	input wire[`RAMBus]			entrylo0_i,
	input wire[`RAMBus]			entrylo1_i,
	input wire[`RAMBus]			index_i,
	input wire[`RAMBus]			random_i,
	
	// exception
	output reg					tlb_err_o,
	output reg					mod_o,
	output reg					mcheck_o,
	
	// write TLB port
	input wire					wtlb_i,
	input wire					wtlb_addr_i,
	
	// read TLB port
	input wire					rtlb_i,
	output reg					tlb_we_o,
	output reg[`RegBus]			tlb_w_entryhi_o,
	output reg[`RegBus]			tlb_w_entrylo0_o,
	output reg[`RegBus]			tlb_w_entrylo1_o,
	
	// latest ASID to CP0 for saving
	output reg[`ASIDWidth]		mmu_latest_asid_o,
	
	// from SRAM
	input wire					ram_ready_i,
	input wire[`RAMBus]			ram_data_i,
	
	// to SRAM
	output reg					ram_we_o,
		// whether write RAM (otherwise read)
	output reg					ram_ce_o,
		// module enable flag
	output reg[`RegBus]			ram_addr_o,
	output reg[`RAMBus]			ram_data_o,
	output reg[3:0]				ram_sel_o,
	
	// from ROM
	input wire[`ROMBus]			rom_data_i,
	input wire					rom_ready_i,
	
	// to ROM
	output reg[`ROMAddrBus]		rom_addr_o,
	output reg					rom_we_o,
	output reg					rom_ce_o,
	
	// from Flash
	input wire[`FlashBus]		flash_data_i,
	input wire					flash_ready_i,
	
	// to Flash
	output reg[`FlashAddrBus]	flash_addr_o,
	output reg					flash_ce_o,
	output reg					flash_we_o,
	output reg[`FlashBus]		flash_data_o,
	output reg[3:0]				flash_sel_o,
	
	// from/to serail
	input wire[`RAMBus]			serail_data_i,
	input wire					serail_ready_i,
	
	// to Serial
	output reg[`SerailAddrBus]	serail_addr_o,
	output reg[`RAMBus]			serail_data_o,
	output reg					serail_we_o,	
	output reg					serail_ce_o,
	output reg[3:0]				serail_sel_o
);

	reg[`ItemWidth] itemSet[0:`TLBNum - 1];
		// define of item set
		
	wire[`TLBWidth] writeIndex;

	/* handle read */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			tlb_we_o <= 1'b0;
			tlb_w_entryhi_o <= `ZeroWord;
			tlb_w_entrylo0_o <= `ZeroWord;
			tlb_w_entrylo1_o <= `ZeroWord;
		end else
		begin
			if (rtlb_i == 1'b1)
			begin
				tlb_we_o <= 1'b1;
				tlb_w_entryhi_o <= {itemSet[index_i[`TLBWidth]][`ItemVPN2], {5{1'b0}}, 
					itemSet[index_i[`TLBWidth]][`ItemASID]};
				tlb_w_entrylo0_o <= {{6{1'b0}}, itemSet[index_i[`TLBWidth]][`ItemPFN0],
					itemSet[index_i[`TLBWidth]][`ItemC0], itemSet[index_i[`TLBWidth]][`ItemD0],
					itemSet[index_i[`TLBWidth]][`ItemV0], itemSet[index_i[`TLBWidth]][`ItemG]};
				tlb_w_entrylo1_o <= {{6{1'b0}}, itemSet[index_i[`TLBWidth]][`ItemPFN1],
					itemSet[index_i[`TLBWidth]][`ItemC1], itemSet[index_i[`TLBWidth]][`ItemD1],
					itemSet[index_i[`TLBWidth]][`ItemV1], itemSet[index_i[`TLBWidth]][`ItemG]};
			end else
			begin
				tlb_we_o <= 1'b0;
				tlb_w_entryhi_o <= `ZeroWord;
				tlb_w_entrylo0_o <= `ZeroWord;
				tlb_w_entrylo1_o <= `ZeroWord;
			end
		end
	end

	reg[1:0] writeCnt;
	reg repeatted;

	/* handle write */
	assign writeIndex = ((wtlb_addr_i == `FromIndex) ? (index_i[`TLBWidth]) : (random_i[`TLBWidth]));
	always @(posedge clk)
	begin
		mcheck_o <= 1'b0;
		if (rst == `RstDisable)
		begin
			if (wtlb_i == 1'b1)
			begin
				if (writeCnt == 2'b00) 
				begin
					repeatted <= |{(itemSet[ 0][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b0000 != writeIndex) &&
								   ((itemSet[ 0][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 0][`ItemASID])) &&
								   (itemSet[ 0][`ItemTop] == 1'b1),
								   (itemSet[ 1][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b0001 != writeIndex) &&
								   ((itemSet[ 1][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 1][`ItemASID])) &&
								   (itemSet[ 1][`ItemTop] == 1'b1),
								   (itemSet[ 2][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b0010 != writeIndex) &&
								   ((itemSet[ 2][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 2][`ItemASID])) &&
								   (itemSet[ 2][`ItemTop] == 1'b1),
								   (itemSet[ 3][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b0011 != writeIndex) &&
								   ((itemSet[ 3][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 3][`ItemASID])) &&
								   (itemSet[ 3][`ItemTop] == 1'b1),
								   (itemSet[ 4][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b0100 != writeIndex) &&
								   ((itemSet[ 4][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 4][`ItemASID])) &&
								   (itemSet[ 4][`ItemTop] == 1'b1),
								   (itemSet[ 5][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b0101 != writeIndex) &&
								   ((itemSet[ 5][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 5][`ItemASID])) &&
								   (itemSet[ 5][`ItemTop] == 1'b1),
								   (itemSet[ 6][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b0110 != writeIndex) &&
								   ((itemSet[ 6][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 6][`ItemASID])) &&
								   (itemSet[ 6][`ItemTop] == 1'b1),
								   (itemSet[ 7][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b0111 != writeIndex) &&
								   ((itemSet[ 7][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 7][`ItemASID])) &&
								   (itemSet[ 7][`ItemTop] == 1'b1),
								   (itemSet[ 8][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b1000 != writeIndex) &&
								   ((itemSet[ 8][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 8][`ItemASID])) &&
								   (itemSet[ 8][`ItemTop] == 1'b1),
								   (itemSet[ 9][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b1001 != writeIndex) &&
								   ((itemSet[ 9][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[ 9][`ItemASID])) &&
								   (itemSet[ 9][`ItemTop] == 1'b1),
								   (itemSet[10][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b1010 != writeIndex) &&
								   ((itemSet[10][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[10][`ItemASID])) &&
								   (itemSet[10][`ItemTop] == 1'b1),
								   (itemSet[11][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b1011 != writeIndex) &&
								   ((itemSet[11][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[11][`ItemASID])) &&
								   (itemSet[11][`ItemTop] == 1'b1),
								   (itemSet[12][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b1100 != writeIndex) &&
								   ((itemSet[12][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[12][`ItemASID])) &&
								   (itemSet[12][`ItemTop] == 1'b1),
								   (itemSet[13][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b1101 != writeIndex) &&
								   ((itemSet[13][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[13][`ItemASID])) &&
								   (itemSet[13][`ItemTop] == 1'b1),
								   (itemSet[14][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b1110 != writeIndex) &&
								   ((itemSet[14][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[14][`ItemASID])) &&
								   (itemSet[14][`ItemTop] == 1'b1),
								   (itemSet[15][`ItemVPN2] == entryhi_i[31:13]) && 
								   (4'b1111 != writeIndex) &&
								   ((itemSet[15][`ItemG] == 1'b1) || (entryhi_i[7:0] == itemSet[15][`ItemASID])) &&
								   (itemSet[15][`ItemTop] == 1'b1)
								  };
					writeCnt <= 2'b01;
				end else
				begin
					if (repeatted == 2'b01) begin
						mcheck_o <= 1'b1;
					end else
					begin
						itemSet[writeIndex][`ItemTop] <= 1'b1;
						itemSet[writeIndex][`ItemVPN2] <= entryhi_i[31:13];
						itemSet[writeIndex][`ItemG] <= entrylo0_i[0] & entrylo1_i[0];
						itemSet[writeIndex][`ItemASID] <= entryhi_i[7:0];
						itemSet[writeIndex][`ItemPFN0] <= entrylo0_i[25:6];
						itemSet[writeIndex][`ItemC0] <= entrylo0_i[5:3];
						itemSet[writeIndex][`ItemD0] <= entrylo0_i[2];
						itemSet[writeIndex][`ItemV0] <= entrylo0_i[1];
						itemSet[writeIndex][`ItemPFN1] <= entrylo1_i[25:6];
						itemSet[writeIndex][`ItemC1] <= entrylo1_i[5:3];
						itemSet[writeIndex][`ItemD1] <= entrylo1_i[2];
						itemSet[writeIndex][`ItemV1] <= entrylo1_i[1];
						mcheck_o <= 1'b0;
					end
				end
			end else
			begin
				writeCnt <= 2'b00;
			end
		end else 
		begin
			itemSet[ 0] <= 79'h0;
			itemSet[ 1] <= 79'h0;
			itemSet[ 2] <= 79'h0;
			itemSet[ 3] <= 79'h0;
			itemSet[ 4] <= 79'h0;
			itemSet[ 5] <= 79'h0;
			itemSet[ 6] <= 79'h0;
			itemSet[ 7] <= 79'h0;
			itemSet[ 8] <= 79'h0;
			itemSet[ 9] <= 79'h0;
			itemSet[10] <= 79'h0;
			itemSet[11] <= 79'h0;
			itemSet[12] <= 79'h0;
			itemSet[13] <= 79'h0;
			itemSet[14] <= 79'h0;
			itemSet[15] <= 79'h0;
			
			writeCnt <= 2'b00;
		end
	end
	
	// ------- memory load/write ------------
	
	reg[2:0] cnt;
	
	reg[4:0] match;
	reg[`RegBus] res_addr_i;
	
	always @(posedge clk)
	begin
		if ((rst == `RstEnable) || (ce_i == `ChipDisable))
		begin
			cnt <= 3'b000;
			
			ram_we_o <= 1'b0;
			ram_ce_o <= 1'b0;
			ram_addr_o <= `ZeroWord;
			ram_data_o <= `ZeroWord;
			ram_sel_o <= 4'b0000;
			
			rom_addr_o <= `ZeroWord;
			rom_we_o <= 1'b0;
			rom_ce_o <= 1'b0;
			
			flash_addr_o <= `ZeroWord;
			flash_ce_o <= 1'b0;
			flash_we_o <= 1'b0;
			
			serail_addr_o <= 3'b000;
			serail_data_o <= `ZeroWord;
			serail_we_o <= 1'b0;
			serail_ce_o <= 1'b0;
			
			ready_o <= 1'b0;
			
			tlb_err_o <= 1'b0;
			mod_o <= 1'b0;
			
			res_addr_i <= `ZeroWord;
		end else
		begin
			case (cnt)
			
				// find entrance
				3'b000: begin
					if (addr_i[31:30] == 2'b10)
					begin
						res_addr_i <= {{3{1'b0}}, addr_i[28:0]};
						cnt <= 3'b110;
						tlb_err_o <= 1'b0;
						mod_o <= 1'b0;
					end else
					begin
						if ((addr_i[31:13] == itemSet[0][`ItemVPN2]) && 
							((itemSet[0][`ItemG] == 1'b1) || (itemSet[0][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[0][`ItemTop] == 1'b1)) begin
							match = 5'b10000;
						end else
						if ((addr_i[31:13] == itemSet[1][`ItemVPN2]) && 
							((itemSet[1][`ItemG] == 1'b1) || (itemSet[1][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[1][`ItemTop] == 1'b1)) begin
							match = 5'b10001;
						end else
						if ((addr_i[31:13] == itemSet[2][`ItemVPN2]) && 
							((itemSet[2][`ItemG] == 1'b1) || (itemSet[2][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[2][`ItemTop] == 1'b1)) begin
							match = 5'b10010;
						end else
						if ((addr_i[31:13] == itemSet[3][`ItemVPN2]) && 
							((itemSet[3][`ItemG] == 1'b1) || (itemSet[3][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[3][`ItemTop] == 1'b1)) begin
							match = 5'b10011;
						end else
						if ((addr_i[31:13] == itemSet[4][`ItemVPN2]) && 
							((itemSet[4][`ItemG] == 1'b1) || (itemSet[4][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[4][`ItemTop] == 1'b1)) begin
							match = 5'b10100;
						end else
						if ((addr_i[31:13] == itemSet[5][`ItemVPN2]) && 
							((itemSet[5][`ItemG] == 1'b1) || (itemSet[5][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[5][`ItemTop] == 1'b1)) begin
							match = 5'b10101;
						end else
						if ((addr_i[31:13] == itemSet[6][`ItemVPN2]) && 
							((itemSet[6][`ItemG] == 1'b1) || (itemSet[6][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[6][`ItemTop] == 1'b1)) begin
							match = 5'b10110;
						end else
						if ((addr_i[31:13] == itemSet[7][`ItemVPN2]) && 
							((itemSet[7][`ItemG] == 1'b1) || (itemSet[7][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[7][`ItemTop] == 1'b1)) begin
							match = 5'b10111;
						end else
						if ((addr_i[31:13] == itemSet[8][`ItemVPN2]) && 
							((itemSet[8][`ItemG] == 1'b1) || (itemSet[8][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[8][`ItemTop] == 1'b1)) begin
							match = 5'b11000;
						end else
						if ((addr_i[31:13] == itemSet[9][`ItemVPN2]) && 
							((itemSet[9][`ItemG] == 1'b1) || (itemSet[9][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[9][`ItemTop] == 1'b1)) begin
							match = 5'b11001;
						end else
						if ((addr_i[31:13] == itemSet[10][`ItemVPN2]) && 
							((itemSet[10][`ItemG] == 1'b1) || (itemSet[10][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[10][`ItemTop] == 1'b1)) begin
							match = 5'b11010;
						end else
						if ((addr_i[31:13] == itemSet[11][`ItemVPN2]) && 
							((itemSet[11][`ItemG] == 1'b1) || (itemSet[11][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[11][`ItemTop] == 1'b1)) begin
							match = 5'b11011;
						end else
						if ((addr_i[31:13] == itemSet[12][`ItemVPN2]) && 
							((itemSet[12][`ItemG] == 1'b1) || (itemSet[12][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[12][`ItemTop] == 1'b1)) begin
							match = 5'b11100;
						end else
						if ((addr_i[31:13] == itemSet[13][`ItemVPN2]) && 
							((itemSet[13][`ItemG] == 1'b1) || (itemSet[13][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[13][`ItemTop] == 1'b1)) begin
							match = 5'b11101;
						end else
						if ((addr_i[31:13] == itemSet[14][`ItemVPN2]) && 
							((itemSet[14][`ItemG] == 1'b1) || (itemSet[14][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[14][`ItemTop] == 1'b1)) begin
							match = 5'b11110;
						end else
						if ((addr_i[31:13] == itemSet[15][`ItemVPN2]) && 
							((itemSet[15][`ItemG] == 1'b1) || (itemSet[15][`ItemASID] == entryhi_i[7:0])) &&
							(itemSet[15][`ItemTop] == 1'b1)) begin
							match = 5'b11111;
						end else
							match = 5'b00000;
						cnt <= 3'b001;
						
					end
				end
				
				3'b001: begin
					cnt <= 3'b010;
				end
				
				3'b010: begin
					cnt <= 3'b011;
				end
				
				3'b011: begin
					if (match[4] == 1'b0)
						begin
							tlb_err_o <= 1'b1;
							ready_o <= 1'b1;
							cnt <= 3'b111;
						end else
						begin
							tlb_err_o <= 1'b0;
							cnt <= 3'b100;
							if (((addr_i[12] == 1'b0) && (itemSet[match[3:0]][`ItemV0] == 1'b0)) ||
								((addr_i[12] == 1'b1) && (itemSet[match[3:0]][`ItemV1] == 1'b0)))
							begin
								tlb_err_o <= 1'b1;
								ready_o <= 1'b1;
								cnt <= 3'b111;
							end
							if (we_i == `RAMWrite_OP)
							begin
								if (((addr_i[12] == 1'b0) && (itemSet[match[3:0]][`ItemD0] == 1'b0)) ||
									((addr_i[12] == 1'b1) && (itemSet[match[3:0]][`ItemD1] == 1'b0)))
								begin
									mod_o <= 1'b1;
									ready_o <= 1'b1;
									cnt <= 3'b111;
								end
							end
							mmu_latest_asid_o <= itemSet[match[3:0]][`ItemASID];
							if (addr_i[12] == 1'b0)
							begin
								res_addr_i <= {itemSet[match[3:0]][`ItemPFN0], addr_i[11:0]};
							end
							if (addr_i[12] == 1'b1)
							begin
								res_addr_i <= {itemSet[match[3:0]][`ItemPFN1], addr_i[11:0]};
							end
						end
				end
				
				3'b100: begin
					cnt <= 3'b101;
				end
				
				3'b101: begin
					cnt <= 3'b110;
				end
				
				// read/write and wait
				3'b110: begin
					/* debug */
					//tlb_err_o <= 1'b0;
					//mod_o <= 1'b0;
					
					if (we_i == `RAMWrite_OP)
					begin
						if (res_addr_i[31:28] == 16'h0)
						begin
							// SRAM
							ram_we_o <= `RAMWrite_OP;
							ram_ce_o <= 1'b1;
							ram_addr_o <= res_addr_i;
							ram_data_o <= data_i;
							ram_sel_o <= sel_i;
							if (ram_ready_i == 1'b1)
							begin
								ready_o <= 1'b1;
								cnt <= 3'b111;
							end
						end else
						if (res_addr_i[31:12] == 20'h1FC00)
						begin
							// ROM
							rom_we_o <= 1'b1;
							rom_ce_o <= 1'b1;
							rom_addr_o <= res_addr_i[11:0];
							if (rom_ready_i == 1'b1)
							begin
								ready_o <= 1'b1;
								cnt <= 3'b111;
							end
						end else
						if ((res_addr_i == 32'h1FD003F8) || (res_addr_i == 32'h1FD003FC))
						begin
							// serail
							serail_we_o <= 1'b1;
							serail_ce_o <= 1'b1;
							serail_addr_o <= {{2{1'b0}}, res_addr_i[2]};
							serail_data_o <= data_i;
							serail_sel_o <= sel_i;
							if (serail_ready_i == 1'b1)
							begin
								ready_o <= 1'b1;
								cnt <= 3'b111;
							end
						end else
						if (res_addr_i[31:24] == 8'h1E)
						begin
							// flash
							flash_we_o <= 1'b1;
							flash_ce_o <= 1'b1;
							flash_addr_o <= res_addr_i[`FlashAddrBus];
							flash_data_o <= data_i[`FlashBus];
							flash_sel_o <= sel_i;
							if (flash_ready_i == 1'b1)
							begin
								ready_o <= 1'b1;
								cnt <= 3'b111;
							end
						end else
						begin
							ready_o <= 1'b1;
							cnt <= 3'b111;
						end
					end
					if (we_i == `RAMRead_OP)
					begin
						if (res_addr_i[28] == 1'b0)
						begin
							// SRAM
							ram_we_o <= `RAMRead_OP;
							ram_ce_o <= 1'b1;
							ram_addr_o <= res_addr_i;
							ram_sel_o <= sel_i;
							if (ram_ready_i == 1'b1)
							begin
								ready_o <= 1'b1;
								cnt <= 3'b111;
								data_o <= ram_data_i;
							end
						end else
						if (res_addr_i[31:12] == 20'h1FC00)
						begin
							// ROM
							rom_we_o <= 1'b0;
							rom_ce_o <= 1'b1;
							rom_addr_o <= res_addr_i[11:0];
							if (rom_ready_i == 1'b1)
							begin
								ready_o <= 1'b1;
								cnt <= 3'b111;
								data_o <= rom_data_i;
							end
						end else
						if ((res_addr_i == 32'h1FD003F8) || (res_addr_i == 32'h1FD003FC))
						begin
							// serail
							serail_we_o <= 1'b0;
							serail_ce_o <= 1'b1;
							serail_addr_o <= {{2{1'b0}}, res_addr_i[2]};
							serail_sel_o <= sel_i;
							if (serail_ready_i == 1'b1)
							begin
								ready_o <= 1'b1;
								cnt <= 3'b111;
								data_o <= serail_data_i;
							end
						end else
						if (res_addr_i[31:24] == 8'h1E)
						begin
							// flash
							flash_we_o <= 1'b0;
							flash_ce_o <= 1'b1;
							flash_addr_o <= res_addr_i[`FlashAddrBus];
							flash_sel_o <= sel_i;
							if (flash_ready_i == 1'b1)
							begin
								ready_o <= 1'b1;
								cnt <= 3'b111;
								data_o <= {{16{1'b0}}, flash_data_i};
							end
						end else
						begin
							ready_o <= 1'b1;
							cnt <= 3'b111;
							data_o <= `ZeroWord;
						end
					end
				end
				
				// restore and finish
				3'b111: begin
					ram_we_o <= `RAMRead_OP;
					ram_ce_o <= 1'b0;

					rom_we_o <= 1'b0;
					rom_ce_o <= 1'b0;

					flash_ce_o <= 1'b0;
					flash_we_o <= 1'b0;

					serail_we_o <= 1'b0;
					serail_ce_o <= 1'b0;
				end
				
			endcase
		end
	end

endmodule
