`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.12.10
// Module Name:    VGA
// Project Name:   SammingCPU
//
// Handle vga output
// 800x600 @ 75Hz
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module vga(

	input wire					rst,
	input wire					clk,
	
	input wire[7:0]				current_i,
	input wire					writeBusy_i,
	
	output reg[8:0]				vga_color_o,
	output reg					vga_vhync_o,
	output reg					vga_hhync_o,
	
	output wire[7:0]			debug

);

	reg[11:0] hhync_cnt, x;
	reg[11:0] vhync_cnt, y;
	
	reg[8:0] backColor[0:3];
	reg[8:0] textColor[0:3];
	
	reg in_display;
	
	always @(posedge clk)
	begin
		textColor[0] <= 9'b010100010;
		backColor[0] <= 9'b110111110;
	end
	
	// calculate cnt and coordinate(x,y)
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			hhync_cnt <= 12'd0;
			vhync_cnt <= 12'd0;
			x <= 12'd0;
			y <= 12'd0;
		end else
		begin
			if (hhync_cnt == 12'd1343)
			begin
				if (vhync_cnt == 12'd805)
					vhync_cnt <= 12'd0;
				else
					vhync_cnt <= vhync_cnt + 1;
				hhync_cnt <= 12'd0;
				if ((vhync_cnt >= 12'd1) && (vhync_cnt <= 12'd766))
					y <= y + 1;
				else
					y <= 12'd0;
			end else
				hhync_cnt <= hhync_cnt + 1;
			if ((hhync_cnt >= 12'd1) && (hhync_cnt <= 12'd1022))
				x <= x + 1;
			else
				x <= 12'd0;
		end
	end
	
	// calculate whether in display area
	always @(*)
	begin
		if ((hhync_cnt >= 12'd0 && hhync_cnt <= 12'd1023) &&
			(vhync_cnt >= 12'd0 && vhync_cnt <= 12'd799))
		begin
			in_display <= 1'b1;
		end else
		begin
			in_display <= 1'b0;
		end
	end
	
	// give sync signal
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			vga_vhync_o <= 1'b1;
			vga_hhync_o <= 1'b1;
		end else
		begin
			if (hhync_cnt >= 12'd1048 && hhync_cnt <= 12'd1183)
				vga_hhync_o <= 1'b0;
			else
				vga_hhync_o <= 1'b1;
			if (vhync_cnt >= 12'd772 && vhync_cnt <= 12'd777)
				vga_vhync_o <= 1'b0;
			else
				vga_vhync_o <= 1'b1;
		end
	end
	
	// vga-ram instantiate
	reg we;
	reg[11:0] waddr;
	reg[7:0] wdata;
	wire[11:0] raddr;
	wire[7:0] current;
	
	vga_ram vga_ram0(
		.clka(clk), .wea(we), .addra(waddr), .dina(wdata),
		.clkb(clk), .addrb(raddr), .doutb(current)
	);
	
	// queue management
	reg[5:0] tail, headx, heady;
	reg slice;
	
	wire[11:0] precal1, precal2, precal3;
	assign precal1 = {{heady+1}, 6'b000000};
	assign precal2[11:6] = heady;
	assign precal2[5:0] = headx + 1;
	assign precal3[11:6] = heady;
	assign precal3[5:0] = headx;
	
	reg[11:0] rstCnt = 12'd0;
	reg[5:0] cleanCnt;
	reg toClean = 1'b0;
	
	reg old_writeBusy, writeBusy;
	always @(posedge clk)
	begin
		old_writeBusy <= writeBusy;
		writeBusy <= writeBusy_i;
	end
	
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			headx <= 6'b000000;
			heady <= 6'b000000;
			tail <= 6'b000000;
			slice <= 1'b0;
			we <= 1'b1;
			waddr <= rstCnt;
			wdata <= 8'h00000000;
			rstCnt <= rstCnt + 1;
			toClean <= 1'b0;
		end else
		begin
			if (writeBusy == 1'b0 && old_writeBusy == 1'b1)
			begin
				if (heady == 6'd28 && headx == 6'd58)
				begin
					slice <= 1'b1;
				end
				if (current_i == 8'h08)
				begin
					we <= 1'b1;
					waddr <= precal3;
					wdata <= 8'h00;
					if (headx > 6'b000000)
						headx <= headx - 1;
				end else
				begin
					if ((headx == 6'd58) || (current_i == 8'h0A))
					begin
						if (current_i != 8'h0A)
						begin
							we <= 1'b1;
							waddr <= precal1;
							wdata <= current_i;
						end
						heady <= heady + 1;
						headx <= 6'b000000;
						if (heady == 6'd28) 
							slice <= 1'b1;
						if (heady == 6'd28 || slice == 1'b1)
						begin
							tail <= tail + 1;
						end
						toClean <= 1'b1;
						cleanCnt <= 6'b000000;
					end else
					begin
						we <= 1'b1;
						waddr <= precal2;
						wdata <= current_i;
						headx <= headx + 1;
					end
				end
			end
			if (toClean == 1'b1)
			begin
				we <= 1'b1;
				waddr[11:6] <= tail - 1;
				waddr[5:0] <= cleanCnt;
				wdata <= 8'h00;
				if (cleanCnt == 6'b111111)
					toClean <= 1'b0;
				else
					cleanCnt <= cleanCnt + 1;
			end
		end
	end
	
	// getting color
	reg[5:0] y_no, x_no, y_offset, x_offset;
	assign raddr = {{tail + y_no}, x_no};
	wire data_o;
	
	vga_rom vga_rom0(
		.no_i(current), .x_i(x_offset), .y_i(y_offset),
		.data_o(data_o)
	);
	
	// give color signal
	always @(posedge clk)
	begin
		if (in_display == 1'b0)
		begin
			vga_color_o <= 9'b000000000;
		end else
		if (in_display == 1'b1)
		begin
			vga_color_o <= backColor[0];
			if (y >= 17 && y <= 21 && x >= 17 && x <= 1007)
				vga_color_o <= textColor[0];
			else if (y >= 746 && y <= 750 && x >= 17 && x <= 1007)
				vga_color_o <= textColor[0];
			else if (x >= 17 && x <= 21 && y >= 17 && y <= 750)
				vga_color_o <= textColor[0];
			else if (x >= 1003 && x <= 1007 && y >= 17 && y <= 750)
				vga_color_o <= textColor[0];
			else if (x >= 40 && x <= 984 && y >= 38 && y <= 734)
			begin
				vga_color_o <= (data_o == 1'b1) ? (textColor[0]) : (backColor[0]);
				if (x_offset == 6'd19)
				begin
					x_no <= x_no + 1;
					x_offset <= 6'd4;
				end else
				begin
					x_offset <= x_offset + 1;
					if (x_offset == 6'd4)
						vga_color_o <= backColor[0];
				end
			end
			if (y > 734)
			begin
				// start a new frame
				y_no <= 6'b000000;
				x_no <= 6'b000000;
				y_offset <= 6'b000000;
				x_offset <= 6'b000000;
			end else
			if (y >= 38 && y <= 734 && x == 1003)
			begin
				// to new line of current frame
				if (y_offset == 6'd23)
				begin
					y_offset <= 6'd0;
					x_offset <= 6'd0;
					y_no <= y_no + 1;
					x_no <= 6'd0;
				end else
				begin
					y_offset <= y_offset + 1;
					x_offset <= 6'd0;
					x_no <= 6'd0;
				end
			end else
			begin
			end
		end
	end

endmodule
