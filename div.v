`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.24
// Module Name:    div 
// Project Name:   SammingCPU
//
// Implementation of DIV module, it uses 32 clocks to implement 32-bit division
//    DIVFREE        --> DIVON     -->DIVEND --(start_i = divstop)--> DIVFREE
//  (clear ans)       \> DIVBYZERO  / 
//////////////////////////////////////////////////////////////////////////////////

`include "defines.v"

module div(
	
	input wire					clk,
	input wire					rst,
	
	input wire					signed_div_i,
		// signed division or unsigned
	input wire[`RegBus]			opdata1_i,
	input wire[`RegBus]			opdata2_i,
	input wire					start_i,
		// notify start or stop
	input wire					annul_i,
		// cancel signal
	
	output reg[`DoubleRegBus]	result_o,
	output reg					ready_o
);

	wire[32:0] div_temp;
		// advance minus answer
	reg[5:0] cnt;
		// finished count
	reg[64:0] dividend;
		// main arr
	reg[1:0] state;
		// record state
	reg[31:0] divisor;
		// absolute divisor
	reg[31:0] temp_op1;
		// absolute dividend
	reg[31:0] temp_op2;
		// absolute divisor

	assign div_temp = {1'b0, dividend[63:32]} - {1'b0, divisor};
	
	always @(posedge clk)
	begin
		if (rst == `RstEnable)
		begin
			// default in divfree state
			state <= `DivFree;
			ready_o <= `DivResultNotReady;
			result_o <= {`ZeroWord, `ZeroWord};
		end else
		begin
			case (state)
				`DivFree: begin
					if (start_i == `DivStart && annul_i == 1'b0) begin
						if (opdata2_i == `ZeroWord)
						begin
							state <= `DivByZero;
						end else
						begin
							state <= `DivOn;
							cnt <= 6'b000000;
							if (signed_div_i == 1'b1 && opdata1_i[31] == 1'b1)
							begin
								temp_op1 = ~opdata1_i + 1;
							end else
							begin
								temp_op1 = opdata1_i;
							end
							if (signed_div_i == 1'b1 && opdata2_i[31] == 1'b1)
							begin
								temp_op2 = ~opdata2_i + 1;
							end else
							begin
								temp_op2 = opdata2_i;
							end
							dividend <= {`ZeroWord, `ZeroWord};
							dividend[32:1] <= temp_op1;
							divisor <= temp_op2;
						end
					end else
					begin
						ready_o <= `DivResultNotReady;
						result_o <= {`ZeroWord, `ZeroWord};
					end
				end
				
				`DivByZero: begin
					dividend <= {`ZeroWord, `ZeroWord};
					state <= `DivEnd;
				end
				
				`DivOn: begin
					if (annul_i == 1'b0)
					begin
						if (cnt != 6'b100000)
						begin
							if (div_temp[32] == 1'b1)
							begin
								dividend <= {dividend[63:0], 1'b0};
							end else
							begin
								dividend <= {div_temp[31:0], dividend[31:0], 1'b1};
							end
							cnt <= cnt + 1;
						end else
						begin
							if ((signed_div_i == 1'b1) &&
								((opdata1_i[31] ^ opdata2_i[31]) == 1'b1))
							begin
								dividend[31:0] <= (~dividend[31:0] + 1);
							end 
							if ((signed_div_i == 1'b1) && 
								((opdata1_i[31] ^ dividend[64]) == 1'b1))
							begin
								dividend[64:33] <= (~dividend[64:33] + 1);
							end
							state <= `DivEnd;
							cnt <= 6'b000000;
						end
					end else
					begin
						state <= `DivFree;
							// ready_o has been not ready, not need to restore
					end
				end
				
				`DivEnd: begin
					result_o <= {dividend[64:33], dividend[31:0]};
					ready_o <= `DivResultReady;
					if (start_i == `DivStop)
					begin
						state <= `DivFree;
						ready_o <= `DivResultNotReady;
						// DIFFERENT FROM GUIDE
						//result_o <= {`ZeroWord, `ZeroWord};
					end
				end
			endcase
		end
	end

endmodule
