/**
 * Samming CPU
 * defines.v
 * 
 * Written by llylly
*/

//////////////////////////////////////////////////////////////////////////////////
// Writer: llylly 
// 
// Create Date:    2016.10.24
// Module Name:    \ 
// Project Name:   SammingCPU
//
// Definition of all macros
//////////////////////////////////////////////////////////////////////////////////

/*** global macro definition ***/
`define RstEnable		1'b0
	// reset enabled value
`define RstDisable		1'b1
	// reset disabled value
`define ZeroWord		32'h00000000
	// 32-bit zero
`define WriteEnable		1'b1
	// write enabled value
`define WriteDisable	1'b0
	// write disabled value
`define ReadEnable		1'b1
	// read enabled value
`define ReadDisable		1'b0
	// read disabled value
`define ALUOpBus 		7:0
	// width of ALU_op wire
`define ALUSelBus 		2:0
	// width of ALU_sel wire
`define InstValid 		1'b0
	// instruction valid value
`define InstInvalid 	1'b1
	// instruction invalid value
`define TrueValue 		1'b1
	// logic true value
`define FalseValue 		1'b0
	// logic false value
`define ChipEnable 		1'b1
	// all chip enabled value
`define ChipDisable 	1'b0
	// all chip disabled value
	
/*** macro define related to certain instruction ***/
// inst code
`define EXE_ANDI		6'b001100
`define EXE_ORI 		6'b001101
`define EXE_XORI		6'b001110
`define EXE_LUI			6'b001111
`define EXE_PREF		6'b110011
`define EXE_SPECIAL		6'b000000
`define EXE_SPECIAL2	6'b011100
`define EXE_SLTI		6'b001010
`define EXE_SLTIU		6'b001011
`define EXE_ADDI		6'b001000
`define EXE_ADDIU		6'b001001
`define EXE_SLTI		6'b001010
`define EXE_SLTIU		6'b001011

`define EXE_J			6'b000010
`define EXE_JAL			6'b000011
`define EXE_BEQ			6'b000100
`define EXE_BGTZ		6'b000111
`define EXE_BLEZ		6'b000110
`define EXE_BNE			6'b000101
`define EXE_REGIMM		6'b000001

`define EXE_LB			6'b100000
`define EXE_LBU			6'b100100
`define EXE_LH			6'b100001
`define EXE_LHU			6'b100101
`define EXE_LW			6'b100011
`define EXE_LWL			6'b100010
`define EXE_LWR			6'b100110
`define EXE_SB			6'b101000
`define EXE_SH			6'b101001
`define EXE_SW			6'b101011
`define EXE_SWL			6'b101010
`define EXE_SWR			6'b101110

`define EXE_LL			6'b110000
`define EXE_SC			6'b111000

// function code
`define EXE_AND			6'b100100
`define EXE_OR			6'b100101
`define EXE_XOR			6'b100110
`define EXE_NOR			6'b100111
`define EXE_SLL			6'b000000
`define EXE_SLLV		6'b000100
`define EXE_SRL			6'b000010
`define EXE_SRLV		6'b000110
`define EXE_SRA			6'b000011
`define EXE_SRAV		6'b000111
`define EXE_SYNC		6'b001111
`define EXE_MOVZ		6'b001010
`define EXE_MOVN		6'b001011
`define EXE_MFHI		6'b010000
`define EXE_MTHI		6'b010001
`define EXE_MFLO		6'b010010
`define EXE_MTLO		6'b010011
`define EXE_SLT			6'b101010
`define EXE_SLTU		6'b101011
`define EXE_ADD			6'b100000
`define EXE_ADDU		6'b100001
`define EXE_SUB			6'b100010
`define EXE_SUBU		6'b100011
`define EXE_CLZ			6'b100000
`define EXE_CLO			6'b100001
`define EXE_MULT		6'b011000
`define EXE_MULTU		6'b011001
`define EXE_MUL			6'b000010
`define EXE_MADD		6'b000000
`define EXE_MADDU		6'b000001
`define EXE_MSUB		6'b000100
`define EXE_MSUBU		6'b000101
`define EXE_DIV			6'b011010
`define EXE_DIVU		6'b011011

`define EXE_JALR		6'b001001
`define EXE_JR			6'b001000
`define EXE_BLTZ		5'b00000
`define EXE_BLTZAL		5'b10000
`define EXE_BGEZ		5'b00001
`define EXE_BGEZAL		5'b10001

`define EXE_SYSCALL		6'b001100

`define EXE_TEQ			6'b110100
`define EXE_TGE			6'b110000
`define EXE_TGEU		6'b110001
`define EXE_TLT			6'b110010
`define EXE_TLTU		6'b110011
`define EXE_TNE			6'b110110

`define EXE_TEQI		5'b01100
`define EXE_TGEI		5'b01000
`define EXE_TGEIU		5'b01001
`define EXE_TLTI		5'b01010
`define EXE_TLTIU		5'b01011
`define EXE_TNEI		5'b01110

`define EXE_ERET		32'b01000010000000000000000000011000

`define EXE_TLBR		32'b01000000000000000000000000000001
`define EXE_TLBWI		32'b01000010000000000000000000000010
`define EXE_TLBWR		32'b01000010000000000000000000000110
	
// ALU inner op
`define EXE_AND_OP		8'b00100100
`define EXE_OR_OP		8'b00100101
`define EXE_XOR_OP		8'b00100110
`define EXE_NOR_OP		8'b00100111
`define EXE_LUI_OP		8'b01011100   
`define EXE_SLL_OP		8'b01111100
`define EXE_SLLV_OP		8'b00000100
`define EXE_SRL_OP		8'b00000010
`define EXE_SRLV_OP		8'b00000110
`define EXE_SRA_OP		8'b00000011
`define EXE_SRAV_OP		8'b00000111
`define EXE_MOVZ_OP		8'b00001010
`define EXE_MOVN_OP		8'b00001011
`define EXE_MFHI_OP		8'b00010000
`define EXE_MTHI_OP		8'b00010001
`define EXE_MFLO_OP		8'b00010010
`define EXE_MTLO_OP		8'b00010011
`define EXE_SLT_OP		8'b00101010
`define EXE_SLTU_OP		8'b00101011
`define EXE_ADD_OP		8'b00100000
`define EXE_ADDU_OP		8'b00100001
`define EXE_ADDI_OP		8'b01010101
`define EXE_ADDIU_OP	8'b01010110
`define EXE_SUB_OP		8'b00100010
`define EXE_SUBU_OP		8'b00100011
`define EXE_CLZ_OP		8'b10110000
`define EXE_CLO_OP		8'b10110001
`define EXE_MUL_OP		8'b10101001
`define EXE_MULT_OP		8'b00011000
`define EXE_MULTU_OP	8'b00011001
`define EXE_NOP_OP		8'b00000000
`define EXE_MADD_OP		8'b10100110
`define EXE_MADDU_OP	8'b10101000
`define EXE_MSUB_OP		8'b10101010
`define EXE_MSUBU_OP	8'b10101011
`define EXE_DIV_OP		8'b00011010
`define EXE_DIVU_OP		8'b00011011
`define EXE_J_OP		8'b01001111
`define EXE_JAL_OP		8'b01010000
`define EXE_JALR_OP		8'b00001001
`define EXE_JR_OP		8'b00001000
`define EXE_BEQ_OP		8'b01010001
`define EXE_BGEZ_OP		8'b01000001
`define EXE_BGEZAL_OP	8'b01001011
`define EXE_BGTZ_OP		8'b01010100
`define EXE_BLEZ_OP		8'b01010011
`define EXE_BLTZ_OP		8'b01000000
`define EXE_BLTZAL_OP	8'b01001010
`define EXE_BNE_OP		8'b01010010
`define EXE_LB_OP		8'b11100000
`define EXE_LBU_OP		8'b11100100
`define EXE_LH_OP		8'b11100001
`define EXE_LHU_OP		8'b11100101
`define EXE_LL_OP		8'b11110000
`define EXE_LW_OP		8'b11100011
`define EXE_LWL_OP		8'b11100010
`define EXE_LWR_OP		8'b11100110
`define EXE_SB_OP		8'b11101000
`define EXE_SC_OP		8'b11111000
`define EXE_SH_OP		8'b11101001
`define EXE_SW_OP		8'b11101011
`define EXE_SWL_OP		8'b11101010
`define EXE_SWR_OP		8'b11101110
`define EXE_MFC0_OP		8'b01011101
`define EXE_MTC0_OP		8'b01100000
`define EXE_SYSCALL_OP	8'b00001100
`define EXE_TEQ_OP		8'b00110100
`define EXE_TEQI_OP		8'b01001000
`define EXE_TGE_OP		8'b00110000
`define EXE_TGEI_OP		8'b01000100
`define EXE_TGEIU_OP	8'b01000101
`define EXE_TGEU_OP		8'b00110001
`define EXE_TLT_OP		8'b00110010
`define EXE_TLTI_OP		8'b01000110
`define EXE_TLTIU_OP	8'b01000111
`define EXE_TLTU_OP		8'b00110011
`define EXE_TNE_OP		8'b00110110
`define EXE_TNEI_OP		8'b01001001
   
`define EXE_ERET_OP		8'b01101011

`define EXE_TLBR_OP		8'b11111110
`define EXE_TLBWI_OP	8'b11111100
`define EXE_TLBWR_OP	8'b11111101

// ALU Sel
`define EXE_RES_NOP 		3'b000
`define EXE_RES_LOGIC		3'b001
`define EXE_RES_SHIFT		3'b010
`define EXE_RES_MOVE		3'b011
`define EXE_RES_ARITHMETIC 	3'b100
`define EXE_RES_MUL			3'b101
`define EXE_RES_JUMP_BRANCH 3'b110
`define EXE_RES_LOAD_STORE 	3'b111

/*** macro define related to instruction storage ROM ***/
`define InstAddrBus 	31:0
	// address wire width of ROM
`define InstBus			31:0
	// data wire width of ROM
`define InstMemNum		1024
	// real size of instruction ROM (in temp testing version)
`define InstMemNumLog2	10
	// real in use width of address bus (in temp testing version)
	
/*** macro define related to SRAM ***/
`define RAMAddrBus		19:0
	// address width of SRAM
`define RAMBus			31:0
	// data width of SRAM
`define RAMWrite_OP		1'b1
`define RAMRead_OP		1'b0
`define ROMBus			31:0
`define ROMAddrBus		11:0
`define FlashBus		31:0
`define FlashRealBus	15:0
`define FlashAddrBus	22:0
`define SerailAddrBus	2:0
`define DataMemNum		524288
`define DataWidth		18:0
`define ROMNum			1024
`define FlashNum		131072
`define FlashSimuBus	18:2

/*** macro define related to uniform registers (Regfile) ***/
`define RegAddrBus		4:0
	// address wire width of module Regfile
`define RegBus			31:0
	// data wire width of module Regfile
`define RegWidth		32
	// data bits of uniform registers
`define DoubleRegWidth	64
	// double of data width
`define DoubleRegBus	63:0
	// double width of data wire
`define RegNum			32
	// quantity of uniform registers
`define RegNumLog2		5
	// width of address

`define NOPRegAddr		5'b00000
	// address of register for operation NOP

/*** macro define of ctrl module which controls pipeline stall ***/
`define Stop			1'b1
`define NoStop			1'b0

/*** DIV module macro ***/
`define DivFree			2'b00
`define DivByZero		2'b01
`define DivOn			2'b10
`define DivEnd			2'b11
`define DivResultReady	1'b1
`define DivResultNotReady 1'b0
`define DivStart		1'b1
`define DivStop			1'b0

/*** Branch macro ***/
`define Branch 			1'b1
`define NotBranch		1'b0
`define InDelaySlot		1'b1
`define NotInDelaySlot	1'b0

/*** CP0 macro ***/
`define CP0_REG_INDEX	8'b00000000
`define CP0_REG_RANDOM	8'b00001000
`define CP0_REG_ENTRYLO0 8'b00010000
`define CP0_REG_ENTRYLO1 8'b00011000
`define CP0_REG_WIRED	8'b00110000
`define CP0_REG_BADVADDR 8'b01000000
`define CP0_REG_COUNT	8'b01001000
`define CP0_REG_ENTRYHI	8'b01010000
`define CP0_REG_COMPARE	8'b01011000
`define CP0_REG_STATUS	8'b01100000
`define CP0_REG_CAUSE	8'b01101000
`define CP0_REG_EPC		8'b01110000
`define CP0_REG_PRID	8'b01111000
`define CP0_REG_PRID2	8'b10000001
`define CP0_REG_EBASE	8'b01111001
`define CP0_REG_CONFIG	8'b10000000
`define CP0_REG_WATCHLO	8'b10010000
`define CP0_REG_WATCHHI	8'b10011000
`define CP0_REG_ERROREPC 8'b11110000

`define InterruptAssert	1'b1
`define InterruptNotAssert 1'b0

/*** interrupt macro ***/
`define ExceptBus		31:0
`define CP0RegAddrBus	7:0
`define TrapAssert		1'b1
`define TrapNotAssert	1'b0

`define INTERRUPT_CODE	5'b00000
`define MOD_CODE		5'b00001
`define TLBL_CODE		5'b00010
`define TLBS_CODE		5'b00011
`define ADEL_CODE		5'b00100
`define ADES_CODE		5'b00101
`define SYSCALL_CODE	5'b01000
`define RI_CODE			5'b01010
`define OVERFLOW_CODE	5'b01100
`define TRAP_CODE		5'b01101
`define WATCH_CODE		5'b10111
`define MCHECK_CODE		5'b11000

`define INTERRUPT_EXP	32'h00000001
`define MOD_EXP			32'h00000002
`define TLBL_EXP		32'h00000003
`define TLBS_EXP		32'h00000004
`define ADEL_EXP		32'h00000005
`define ADES_EXP		32'h00000006
`define SYSCALL_EXP		32'h00000009
`define RI_EXP			32'h0000000b
`define OVERFLOW_EXP	32'h0000000d
`define TRAP_EXP		32'h0000000e
`define WATCH_EXP		32'h00000018
`define MCHECK_EXP		32'h00000019
`define RESET_EXP		32'h0000001f
`define ERET_EXP		32'h00000020

/** TLB macro **/
`define TLBNum			16
`define TLBTotal		5'b10000
`define TLBIndexMax		4'b1111
`define TLBWidth		3:0

/** MMU macro **/
`define ASIDWidth		7:0
`define FromIndex		1'b0
`define FromRandom		1'b1

`define ItemWidth		78:0
`define ItemTop			78
`define ItemVPN2		77:59
`define ItemG			58
`define ItemASID		57:50
`define ItemPFN0		49:30
`define ItemC0			29:27
`define ItemD0			26
`define ItemV0			25
`define ItemPFN1		24:5
`define ItemC1			4:2
`define ItemD1			1
`define ItemV1			0

/** serail macro **/
`define clkCoef			6'd31
`define repCoef			5'd14
`define totCoef			10'd434


