`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.24
// Module Name:    regfile
// Project Name:   SammingCPU
//
// Register set
// Support two read op and one write op at one time
// Read op executed whenever signals transmitted
// Write op only executed at rising edge of clk
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module regfile(
	input wire					clk,
	input wire					rst,
	
	// write port
	input wire					we,
		// write enable
	input wire[`RegAddrBus]		waddr,
		// write reg no
	input wire[`RegBus]			wdata,
		// write reg data
	
	// read port 1
	input wire					re1,
		// read enable
	input wire[`RegAddrBus]		raddr1,
		// read reg no
	output reg[`RegBus]		rdata1,
		// read reg data
	
	// read port 2
	input wire					re2,
		// read enable
	input wire[`RegAddrBus]		raddr2,
		// read reg no
	output reg[`RegBus]		rdata2
		// read reg data

);

	reg[`RegBus] regSet[0:`RegNum-1];
		// define of reg set
		
	/* write operation */
	always @(posedge clk)
	begin
		if (rst == `RstDisable)
		begin
			if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0))
			begin
				regSet[waddr] <= wdata;
			end
		end
	end
	
	/* read operation 1 */
	always @(*) 
	begin
		if (rst == `RstEnable)
		begin
			// async reset
			rdata1 <= `ZeroWord;
		end else
		if (raddr1 == `RegNumLog2'h0)
		begin
			// read reg 0
			rdata1 <= `ZeroWord;
		end else
		if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable))
		begin
			// read unwritten immediate reg data
			rdata1 <= wdata;
		end else
		if (re1 == `ReadEnable)
		begin
			// normal read
			rdata1 <= regSet[raddr1];
		end else
		begin
			// read unabled
			rdata1 <= `ZeroWord;
		end
	end
	
	/* read operation 2 */
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			// async reset
			rdata2 <= `ZeroWord;
		end else
		if (raddr2 == `RegNumLog2'h0)
		begin
			// read reg 0
			rdata2 <= `ZeroWord;
		end else
		if ((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable))
		begin
			// read unwritten immediate reg data
			rdata2 <= wdata;
		end else
		if (re2 == `ReadEnable)
		begin
			// normal read
			rdata2 <= regSet[raddr2];
		end else
		begin
			// read unabled
			rdata2 <= `ZeroWord;
		end
	end

endmodule
