`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.28
// Module Name:    mem
// Project Name:   SammingCPU
//
// MEM module
// Currently load/store operation is not supported, so this module only sends signals to next module now
// Or it will execute read and write from RAM operation
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module mem(
	input wire					rst,
	
	// from EX stage
	input wire[`RegAddrBus]		wd_i,
	input wire					wreg_i,
	input wire[`RegBus]			wdata_i,
	input wire					whilo_i,
	input wire[`RegBus]			hi_i,
	input wire[`RegBus]			lo_i,
	
	input wire[`ALUOpBus]		aluop_i,
	input wire[`RegBus]			mem_addr_i,
	input wire[`RegBus]			reg2_i,
		
	// from WB stage
	input wire[1:0] 			cnt_i,
		// EXTENSION for multiple clocks
	
	// to WB stage
	output reg[`RegAddrBus]		wd_o,
	output reg					wreg_o,
	output reg[`RegBus]			wdata_o,
	output reg					whilo_o,
	output reg[`RegBus]			hi_o,
	output reg[`RegBus]			lo_o,
	output reg[1:0]				cnt_o,
		// EXTENSION for multiple clocks
		
	// for LL/SC
	input wire					llbit_i,
		// llbit input
	input wire					wb_llbit_we_i,
		// wb whether to wire
	input wire					wb_llbit_value_i,
		// wb write value
	
	output reg					llbit_we_o,
		// whether to write
	output reg					llbit_value_o,
		// write value
	
	// from external RAM stage
	input wire[`RegBus]			mem_data_i,
	input wire					mem_ready_i,
		// EXTENSION for multiple clocks
	
	// to external RAM stage
	output reg[`RegBus]			mem_addr_o,
		// output of RAM IO address
	output wire					mem_we_o,
		// output of whether to write memory
	output reg[3:0]				mem_sel_o,
		// byte selection signal
	output reg[`RegBus]			mem_data_o,
		// data to write to memory
	output reg					mem_ce_o,
		// RAM enabling signal
	
	output reg					stallreq
		// EXTENSION request for stall
);

	wire[`RegBus] zero32;
	reg mem_we;
	
	assign mem_we_o = mem_we;
	assign zero32 = `ZeroWord;
	
	reg llbit;
	
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			llbit <= 1'b0;
		end else
		begin
			if (wb_llbit_we_i == 1'b1)
			begin
				llbit <= wb_llbit_value_i;
			end else
			begin
				llbit <= llbit_i;
			end
		end
	end
	
	always @(*)
	begin
		if (rst == `RstEnable)
		begin
			wd_o <= `NOPRegAddr;
			wreg_o <= `WriteDisable;
			wdata_o <= `ZeroWord;
			hi_o <= `ZeroWord;
			lo_o <= `ZeroWord;
			whilo_o <= `WriteDisable;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b0000;
			mem_data_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;
			cnt_o <= 2'b00;
			stallreq <= 1'b0;
			llbit_we_o <= 1'b0;
			llbit_value_o <= 1'b0;
		end else
		begin
			wd_o <= wd_i;
			wreg_o <= wreg_i;
			wdata_o <= wdata_i;
			hi_o <= hi_i;
			lo_o <= lo_i;
			whilo_o <= whilo_i;
			mem_addr_o <= `ZeroWord;
			mem_we <= `WriteDisable;
			mem_sel_o <= 4'b1111;
			mem_data_o <= `ZeroWord;
			mem_ce_o <= `ChipDisable;
			cnt_o <= 2'b00;
			stallreq <= 1'b0;
			llbit_we_o <=1'b0;
			llbit_value_o <= 1'b0;
			case (aluop_i)
				`EXE_LB_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{24{mem_data_i[7]}}, mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							wdata_o <= {{24{mem_data_i[15]}}, mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b10: begin
							wdata_o <= {{24{mem_data_i[23]}}, mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							wdata_o <= {{24{mem_data_i[31]}}, mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LBU_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[7:0]};
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[15:8]};
							mem_sel_o <= 4'b0010;
						end
						2'b10: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[23:16]};
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							wdata_o <= {{24{1'b0}}, mem_data_i[31:24]};
							mem_sel_o <= 4'b1000;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LH_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						2'b10: begin
							wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LHU_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
							mem_sel_o <= 4'b0011;
						end
						2'b10: begin
							wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
							mem_sel_o <= 4'b1100;
						end
						default: begin
							wdata_o <= `ZeroWord;
						end
					endcase
				end
				`EXE_LW_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
				end
				`EXE_LWL_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= {mem_data_i[7:0], reg2_i[23:0]};
						end
						2'b01: begin
							wdata_o <= {mem_data_i[15:0], reg2_i[15:0]};
						end
						2'b10: begin
							wdata_o <= {mem_data_i[23:0], reg2_i[7:0]};
						end
						2'b11: begin
							wdata_o <= mem_data_i;
						end
					endcase
				end
				`EXE_LWR_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteDisable;
					mem_sel_o <= 4'b1111;
					case (mem_addr_i[1:0])
						2'b00: begin
							wdata_o <= mem_data_i;
						end
						2'b01: begin
							wdata_o <= {reg2_i[31:24], mem_data_i[31:8]};
						end
						2'b10: begin
							wdata_o <= {reg2_i[31:16], mem_data_i[31:16]};
						end
						2'b11: begin
							wdata_o <= {reg2_i[31:8], mem_data_i[31:24]};
						end
					endcase
				end
				`EXE_SB_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[7:0], reg2_i[7:0], reg2_i[7:0], reg2_i[7:0]};
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b0001;
						end
						2'b01: begin
							mem_sel_o <= 4'b0010;
						end
						2'b10: begin
							mem_sel_o <= 4'b0100;
						end
						2'b11: begin
							mem_sel_o <= 4'b1000;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SH_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b0011;
						end
						2'b10: begin
							mem_sel_o <= 4'b1100;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SW_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteEnable;
					mem_data_o <= reg2_i;
					mem_sel_o <= 4'b1111;
				end
				`EXE_SWL_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b1111;
							mem_data_o <= reg2_i;
						end
						2'b01: begin
							mem_sel_o <= 4'b0111;
							mem_data_o <= {zero32[7:0], reg2_i[31:8]};
						end
						2'b10: begin
							mem_sel_o <= 4'b0011;
							mem_data_o <= {zero32[15:0], reg2_i[31:16]};
						end
						2'b11: begin
							mem_sel_o <= 4'b0001;
							mem_data_o <= {zero32[23:0], reg2_i[31:24]};
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_SWR_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= {mem_addr_i[31:2], 2'b00};
					mem_we <= `WriteEnable;
					case (mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o <= 4'b1000;
							mem_data_o <= {reg2_i[7:0], zero32[23:0]};
						end
						2'b01: begin
							mem_sel_o <= 4'b1100;
							mem_data_o <= {reg2_i[15:0], zero32[15:0]};
						end
						2'b10: begin
							mem_sel_o <= 4'b1110;
							mem_data_o <= {reg2_i[23:0], zero32[7:0]};
						end
						2'b11: begin
							mem_sel_o <= 4'b1111;
							mem_data_o <= reg2_i;
						end
						default: begin
							mem_sel_o <= 4'b0000;
						end
					endcase
				end
				`EXE_LL_OP: begin
					if (cnt_i == 2'b00) 
					begin
						if (mem_ready_i == 1'b1) 
						begin
							cnt_o <= 2'b01;
						end
						stallreq <= 1'b1;
						mem_ce_o <= `ChipEnable;
					end else
					begin
						if (cnt_i == 2'b01)
						begin
							cnt_o <= 2'b10;
						end
						stallreq <= 1'b0;
						mem_ce_o <= `ChipDisable;
					end
					mem_addr_o <= mem_addr_i;
					mem_we <= `WriteDisable;
					wdata_o <= mem_data_i;
					mem_sel_o <= 4'b1111;
					llbit_we_o <= 1'b1;
					llbit_value_o <= 1'b1;
				end
				`EXE_SC_OP: begin
					if (llbit == 1'b1)
					begin
						if (cnt_i == 2'b00) 
						begin
							if (mem_ready_i == 1'b1) 
							begin
								cnt_o <= 2'b01;
							end
							stallreq <= 1'b1;
							mem_ce_o <= `ChipEnable;
						end else
						begin
							if (cnt_i == 2'b01)
							begin
								cnt_o <= 2'b10;
							end
							stallreq <= 1'b0;
							mem_ce_o <= `ChipDisable;
						end
						mem_addr_o <= mem_addr_i;
						mem_we <= `WriteEnable;
						mem_data_o <= reg2_i;
						mem_sel_o <= 4'b1111;
						llbit_we_o <= 1'b1;
						llbit_value_o <= 1'b0;
						wdata_o <= 32'b1;
					end else 
					begin
						wdata_o <= 32'b0;
					end
				end
				default: begin
				end
			endcase
		end
	end

endmodule
