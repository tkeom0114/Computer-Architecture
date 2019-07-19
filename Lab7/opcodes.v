		  
// Opcode
`define	ALU_OP	4'd15
`define	ADI_OP	4'd4
`define	ORI_OP	4'd5
`define	LHI_OP	4'd6
`define	LWD_OP	4'd7   		  
`define	SWD_OP	4'd8  
`define	BNE_OP	4'd0
`define	BEQ_OP	4'd1
`define BGZ_OP	4'd2
`define BLZ_OP	4'd3
`define	JMP_OP	4'd9
`define JAL_OP	4'd10
`define	JPR_OP	4'd15
`define	JRL_OP	4'd15

// ALU Function Codes
`define	FUNC_ADD	3'b000
`define	FUNC_SUB	3'b001				 
`define	FUNC_AND	3'b010
`define	FUNC_ORR	3'b011								    
`define	FUNC_NOT	3'b100
`define	FUNC_TCP	3'b101
`define	FUNC_SHL	3'b110
`define	FUNC_SHR	3'b111	

// ALU instruction function codes
`define INST_FUNC_ADD 6'd0
`define INST_FUNC_SUB 6'd1
`define INST_FUNC_AND 6'd2
`define INST_FUNC_ORR 6'd3
`define INST_FUNC_NOT 6'd4
`define INST_FUNC_TCP 6'd5
`define INST_FUNC_SHL 6'd6
`define INST_FUNC_SHR 6'd7
`define INST_FUNC_JPR 6'd25
`define INST_FUNC_JRL 6'd26
`define INST_FUNC_WWD 6'd28
`define INST_FUNC_HALT 6'd29

`define	WORD_SIZE	16			
`define	NUM_REGS	4

`define Jump 0
`define JALorJALR 1
`define Branch 2
`define MemRead 3
`define MemWrite 4
`define RegWrite 5
`define MemtoReg 6
`define PCtoReg 7
`define OpenPort 8
`define Halt 9
`define ALUOp 10
`define rs1 14
`define rs2 16
`define rd 18
`define ALUSrc 20
`define rs1Data 20
`define rs2Data 36
`define expPC 52
`define isInst 68
`define instruction 69
`define ALUResult 69

`define LINE_SIZE 77
`define BLOCK_NUM 8
`define BLOCK_SIZE 4
`define DIRTY 64
`define VALID 65

`define DEVICE_ADDRESS 16'h10
`define DEVICE_LENGTH 16'd12