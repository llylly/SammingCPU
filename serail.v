`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.30
// Module Name:    serail
// Project Name:   SammingCPU
//
// Serail controller module
// Used with MMU
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module serail(

	input wire					rst,
	input wire					clk,
	
	output reg					rxd,
	input wire					txd,
	
	output reg[`RAMBus]			data_o,
	output reg					ready_o,
	
	input wire[`SerailAddrBus]	addr_i,
	input wire[`RAMBus]			data_i,
	input wire					we_i,
	input wire					ce_i,
	input wire[3:0]				sel_i,
	
	output wire					readEnable,
	output reg					writeBusy,
	
	output wire[31:0]			debug
);

	reg[3:0] readCnt;
	reg[3:0] readSample;
	reg[15:0] currentRead;
	reg[3:0] current1Cnt, current0Cnt;
	
	reg[7:0] readBuf[0:127];
	reg[6:0] readL, readR;
	
	assign readEnable = !(readL == readR);
	
	wire seClk;
	reg[4:0] seCnt = 5'b00000;
	
	assign seClk = seCnt[4];
	
	assign debug = {{2{1'b0}}, readL, readR, data_o[15:0]};
	
	// get slower clk for read and write serail
	always @(posedge clk)
	begin
		if (seCnt == 5'b11110)
		begin
			seCnt <= 5'b00000;
		end else
		begin
			seCnt <= seCnt + 1;
		end
	end
	
	// receiving serail
	always @(posedge seClk)
	begin
		if (rst == `RstEnable)
		begin
			readCnt <= 4'b0000;
			readSample <= 4'b0000;
			readR <= 8'b00000000;
		end else
		begin
			if (readCnt == 4'b0000)
			begin
				if (txd == 1'b0)
				begin
					readCnt <= 4'b0001;
					readSample <= 4'b0001;
					current1Cnt <= 4'b0000;
					current0Cnt <= 4'b0001;
				end else
				begin
					readCnt <= 4'b0000;
					readSample <= 4'b0000;
					current1Cnt <= 4'b0000;
					current0Cnt <= 4'b0000;
				end
			end else
			begin
				if (txd == 1'b1) 
				begin
					current1Cnt <= current1Cnt + 1; 
				end else 
				begin
					current0Cnt <= current0Cnt + 1;
				end
				if (readSample == (`repCoef - 1))
				begin
					readCnt <= readCnt + 1;
					readSample <= 4'b0000;
				end else
				begin
					readSample <= readSample + 1;
					if (readSample == 4'b0000)
					begin
						if (current1Cnt >= current0Cnt)
						begin
							currentRead[readCnt - 1] <= 1'b1;
						end else
						begin
							currentRead[readCnt - 1] <= 1'b0;
						end
						if (readCnt == 4'd11)
						begin	
							readCnt <= 4'b0000;
							readBuf[readR] <= currentRead[9:2];
							readR <= readR + 1;
						end
						if (txd == 1'b1) current1Cnt <= 4'b0001; else current1Cnt <= 4'b0000;
						if (txd == 1'b0) current0Cnt <= 4'b0001; else current0Cnt <= 4'b0000;
					end
				end
			end
		end
	end
	
	reg[1:0] cnt2;
	reg[0:11] writeBuf;
	reg[4:0] cntWrite;
	reg[10:0] writeClk;
	
	// handle read and write
	always @(posedge clk)
	begin
		if ((rst == `RstEnable) || (ce_i == 1'b0))
		begin
			ready_o <= 1'b0;
			cnt2 <= 2'b00;
			writeClk <= 10'b0000000000;
		end else
		begin
			if (we_i == 1'b0)
			begin
				// read
				if (addr_i == 3'b000)
				begin
					if (cnt2 == 2'b00)
					begin
						if (!(readL == readR))
						begin
							data_o <= {{24{1'b0}}, readBuf[readL]};
							readL <= readL + 1;
						end else
						begin
							data_o <= `ZeroWord;
						end
						cnt2 <= 2'b01;
						ready_o <= 1'b1;
					end
				end
				if (addr_i == 3'b001)
				begin
					data_o <= {{30{1'b0}}, readEnable, ~writeBusy};
					ready_o <= 1'b1;
				end
			end else
			begin
				// write
				if (addr_i == 3'b000)
				begin
					writeBuf <= {1'b1, 1'b0, data_i[0], data_i[1], data_i[2], data_i[3],
						data_i[4], data_i[5], data_i[6], data_i[7], 1'b1, 1'b1};
					if (cnt2 == 2'b00)
					begin
						writeBusy <= 1'b1;
						cnt2 <= 2'b01;
					end else
					if (cnt2 == 2'b01)
					begin
						ready_o <= 1'b1;
					end
				end
			end
		end
		
		if (rst == `RstEnable)
		begin
			writeClk <= 10'b0000000000;
			cntWrite <= 4'b0000;
			writeBusy <= 1'b0;
			readL <= 8'b00000000;
		end else
		begin
			if (writeClk == (`totCoef - 1))
				writeClk <= 10'b0000000000;
			else
				writeClk <= writeClk + 1;
			
			if (writeClk == 10'b0000000000)
			begin
				if (writeBusy == 1'b0)
				begin
					cntWrite <= 4'b0000;
					rxd <= 1'b1;
				end else
				begin
					cntWrite <= cntWrite + 1;
					rxd <= writeBuf[cntWrite + 1];
					if (cntWrite == 4'd11)
					begin
						cntWrite <= 4'b0000;
						writeBusy <= 1'b0;
						rxd <= 1'b1;
					end
				end
			end
		end
	end

endmodule
