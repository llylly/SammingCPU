`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.11.30
// Module Name:    serail
// Project Name:   SammingCPU
//
// Serail and keyboard controller module
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
	output reg[7:0]				current_o,
	
	input wire					ps2_clk_i,
	input wire					ps2_data_i,
	
	output reg[7:0]				nixie_o,
	
	output wire[31:0]			debug
);

	reg[3:0] readCnt;
	reg[3:0] readSample;
	reg[15:0] currentRead;
	reg[3:0] current1Cnt, current0Cnt;
	
	reg[3:0] keyCnt;
	reg[3:0] keyStat;
	reg[7:0] keyBuf0;
	reg[3:0] keyPressCnt;
	
	reg[7:0] readBuf[0:127];
	reg[6:0] readL, readR;
	
	assign readEnable = !(readL == readR);
	
	wire seClk;
	reg[4:0] seCnt = 5'b00000;
	
	assign seClk = seCnt[4];
	
	assign debug = {{2{1'b0}}, readL, readR, data_o[15:0]};
	
	// PS2
	reg ps2_pre_clk = 1'b0, ps2_pre_data = 1'b0, ps2_clk = 1'b0, ps2_data = 1'b0;
	
	// get slower clk for read and write serail and keyboard
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
	
	always @(posedge seClk)
	begin
		ps2_pre_clk <= ps2_clk;
		ps2_pre_data <= ps2_data;
		ps2_clk <= ps2_clk_i;
		ps2_data <= ps2_data_i;
	end
	
	// receiving serail and keyboard
	always @(posedge seClk)
	begin
		if (rst == `RstEnable)
		begin
			readCnt <= 4'b0000;
			readSample <= 4'b0000;
			readR <= 8'b00000000;
			keyCnt <= 4'b0000;
			keyStat <= 4'b0000;
			keyPressCnt <= 4'b0000;
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
		
		if (ps2_pre_clk == 1'b0 && ps2_clk == 1'b1)
		begin
			if (keyCnt >= 4'b0001 && keyCnt <= 4'b1000)
			begin
				keyBuf0[keyCnt - 1] <= ps2_data;
			end
			if (keyCnt == 4'b1010) 
			begin
				keyCnt <= 4'b0000;
				
				case (keyBuf0)
					8'h1C: if (keyPressCnt == 4'b0000) begin
						//'A'
						readBuf[readR] <= 8'h61;
						readR <= readR + 1;
						nixie_o <= 8'h61;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h32: if (keyPressCnt == 4'b0000) begin
						//'B'
						readBuf[readR] <= 8'h62;
						readR <= readR + 1;
						nixie_o <= 8'h62;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h21: if (keyPressCnt == 4'b0000) begin
						//'C'
						readBuf[readR] <= 8'h63;
						readR <= readR + 1;
						nixie_o <= 8'h63;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h23: if (keyPressCnt == 4'b0000) begin
						//'D'
						readBuf[readR] <= 8'h64;
						readR <= readR + 1;
						nixie_o <= 8'h64;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h24: if (keyPressCnt == 4'b0000) begin
						//'E'
						readBuf[readR] <= 8'h65;
						readR <= readR + 1;
						nixie_o <= 8'h65;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h2B: if (keyPressCnt == 4'b0000) begin
						//'F'
						readBuf[readR] <= 8'h66;
						readR <= readR + 1;
						nixie_o <= 8'h66;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h34: if (keyPressCnt == 4'b0000) begin
						//'G'
						readBuf[readR] <= 8'h67;
						readR <= readR + 1;
						nixie_o <= 8'h67;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h33: if (keyPressCnt == 4'b0000) begin
						//'H'
						readBuf[readR] <= 8'h68;
						readR <= readR + 1;
						nixie_o <= 8'h68;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h43: if (keyPressCnt == 4'b0000) begin
						//'I'
						readBuf[readR] <= 8'h69;
						readR <= readR + 1;
						nixie_o <= 8'h69;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h3B: if (keyPressCnt == 4'b0000) begin
						//'J'
						readBuf[readR] <= 8'h6A;
						readR <= readR + 1;
						nixie_o <= 8'h6A;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h42: if (keyPressCnt == 4'b0000) begin
						//'K'
						readBuf[readR] <= 8'h6B;
						readR <= readR + 1;
						nixie_o <= 8'h6B;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h4B: if (keyPressCnt == 4'b0000) begin
						//'L'
						readBuf[readR] <= 8'h6C;
						readR <= readR + 1;
						nixie_o <= 8'h6C;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h3A: if (keyPressCnt == 4'b0000) begin
						//'M'
						readBuf[readR] <= 8'h6D;
						readR <= readR + 1;
						nixie_o <= 8'h6D;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h31: if (keyPressCnt == 4'b0000) begin
						//'N'
						readBuf[readR] <= 8'h6E;
						readR <= readR + 1;
						nixie_o <= 8'h6E;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h44: if (keyPressCnt == 4'b0000) begin
						//'O'
						readBuf[readR] <= 8'h6F;
						readR <= readR + 1;
						nixie_o <= 8'h6F;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h4D: if (keyPressCnt == 4'b0000) begin
						//'P'
						readBuf[readR] <= 8'h70;
						readR <= readR + 1;
						nixie_o <= 8'h70;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h15: if (keyPressCnt == 4'b0000) begin
						//'Q'
						readBuf[readR] <= 8'h71;
						readR <= readR + 1;
						nixie_o <= 8'h71;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h2D: if (keyPressCnt == 4'b0000) begin
						//'R'
						readBuf[readR] <= 8'h72;
						readR <= readR + 1;
						nixie_o <= 8'h72;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h1B: if (keyPressCnt == 4'b0000) begin
						//'S'
						readBuf[readR] <= 8'h73;
						readR <= readR + 1;
						nixie_o <= 8'h73;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h2C: if (keyPressCnt == 4'b0000) begin
						//'T'
						readBuf[readR] <= 8'h74;
						readR <= readR + 1;
						nixie_o <= 8'h74;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h3C: if (keyPressCnt == 4'b0000) begin
						//'U'
						readBuf[readR] <= 8'h75;
						readR <= readR + 1;
						nixie_o <= 8'h75;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h2A: if (keyPressCnt == 4'b0000) begin
						//'V'
						readBuf[readR] <= 8'h76;
						readR <= readR + 1;
						nixie_o <= 8'h76;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h1D: if (keyPressCnt == 4'b0000) begin
						//'W'
						readBuf[readR] <= 8'h77;
						readR <= readR + 1;
						nixie_o <= 8'h77;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h22: if (keyPressCnt == 4'b0000) begin
						//'X'
						readBuf[readR] <= 8'h78;
						readR <= readR + 1;
						nixie_o <= 8'h78;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h35: if (keyPressCnt == 4'b0000) begin
						//'Y'
						readBuf[readR] <= 8'h79;
						readR <= readR + 1;
						nixie_o <= 8'h79;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h1A: if (keyPressCnt == 4'b0000) begin
						//'Z'
						readBuf[readR] <= 8'h7A;
						readR <= readR + 1;
						nixie_o <= 8'h7A;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h45: if (keyPressCnt == 4'b0000) begin
						//'0'
						readBuf[readR] <= 8'h30;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h16: if (keyPressCnt == 4'b0000) begin
						//'1'
						readBuf[readR] <= 8'h31;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h1E: if (keyPressCnt == 4'b0000) begin
						//'2'
						readBuf[readR] <= 8'h32;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h26: if (keyPressCnt == 4'b0000) begin
						//'3'
						readBuf[readR] <= 8'h33;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h25: if (keyPressCnt == 4'b0000) begin
						//'4'
						readBuf[readR] <= 8'h34;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h2E: if (keyPressCnt == 4'b0000) begin
						//'5'
						readBuf[readR] <= 8'h35;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h36: if (keyPressCnt == 4'b0000) begin
						//'6'
						readBuf[readR] <= 8'h36;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h3D: if (keyPressCnt == 4'b0000) begin
						//'7'
						readBuf[readR] <= 8'h37;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h3E: if (keyPressCnt == 4'b0000) begin
						//'8'
						readBuf[readR] <= 8'h38;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h46: if (keyPressCnt == 4'b0000) begin
						//'9'
						readBuf[readR] <= 8'h39;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h70: if (keyPressCnt == 4'b0000) begin
						//'0'
						readBuf[readR] <= 8'h30;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h69: if (keyPressCnt == 4'b0000) begin
						//'1'
						readBuf[readR] <= 8'h31;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h72: if (keyPressCnt == 4'b0000) begin
						//'2'
						readBuf[readR] <= 8'h32;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h7A: if (keyPressCnt == 4'b0000) begin
						//'3'
						readBuf[readR] <= 8'h33;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h6B: if (keyPressCnt == 4'b0000) begin
						//'4'
						readBuf[readR] <= 8'h34;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h73: if (keyPressCnt == 4'b0000) begin
						//'5'
						readBuf[readR] <= 8'h35;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h74: if (keyPressCnt == 4'b0000) begin
						//'6'
						readBuf[readR] <= 8'h36;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h6C: if (keyPressCnt == 4'b0000) begin
						//'7'
						readBuf[readR] <= 8'h37;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h75: if (keyPressCnt == 4'b0000) begin
						//'8'
						readBuf[readR] <= 8'h38;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h7D: if (keyPressCnt == 4'b0000) begin
						//'9'
						readBuf[readR] <= 8'h39;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h54: if (keyPressCnt == 4'b0000) begin
						//'['
						readBuf[readR] <= 8'h5B;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h5B: if (keyPressCnt == 4'b0000) begin
						//']'
						readBuf[readR] <= 8'h5D;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h4C: if (keyPressCnt == 4'b0000) begin
						//';'
						readBuf[readR] <= 8'h3B;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h52: if (keyPressCnt == 4'b0000) begin
						//'''
						readBuf[readR] <= 8'h27;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h41: if (keyPressCnt == 4'b0000) begin
						//','
						readBuf[readR] <= 8'h2C;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h49: if (keyPressCnt == 4'b0000) begin
						//'.'
						readBuf[readR] <= 8'h2E;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h4A: if (keyPressCnt == 4'b0000) begin
						//'/'
						readBuf[readR] <= 8'h2F;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h0E: if (keyPressCnt == 4'b0000) begin
						//'`'
						readBuf[readR] <= 8'h60;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h4E: if (keyPressCnt == 4'b0000) begin
						//'-'
						readBuf[readR] <= 8'h2D;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h55: if (keyPressCnt == 4'b0000) begin
						//'='
						readBuf[readR] <= 8'h3D;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h5D: if (keyPressCnt == 4'b0000) begin
						//'\'
						readBuf[readR] <= 8'h5C;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h66: if (keyPressCnt == 4'b0000) begin
						//BKSP
						readBuf[readR] <= 8'h08;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h29: if (keyPressCnt == 4'b0000) begin
						//SPACE
						readBuf[readR] <= 8'h20;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h5A: if (keyPressCnt == 4'b0000) begin
						//ENTER
						readBuf[readR] <= 8'h0D;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					8'h0D: if (keyPressCnt == 4'b0000) begin
						//TAB
						readBuf[readR] <= 8'h09;
						readR <= readR + 1;
						keyPressCnt <= keyPressCnt + 1;
					end else
						keyPressCnt <= keyPressCnt - 1;
					default: begin
					end
				endcase
			end else
				keyCnt <= keyCnt + 1;
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
						current_o <= data_i[7:0];
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
