//appendix
`define EXTEND_SIGNED      1'b1

//cputop
`define REG_RA             5'd31

// signal defines
// sig_branch
`define BRANCH_PC4         2'b00
`define BRANCH_IMM         2'b01
`define BRANCH_REG         2'b10
`define BRANCH_INDEX       2'b11
// sig_regdst
`define REGDST_RT          2'b00
`define REGDST_RD          2'b01
`define REGDST_RA          2'b10
// sig_alusrc
`define ALUSRC_REG         2'b00
`define ALUSRC_EXT         2'b01
`define ALUSRC_0EXT        2'b10
// sig_memtoreg
`define REG_FROM_ALU       3'b000
`define REG_FROM_MEM       3'b001
`define REG_FROM_JOIN_L    3'b010
`define REG_FROM_JOIN_R    3'b011
`define REG_FROM_BYTE_S    3'b100
`define REG_FROM_BYTE_U    3'b101 
`define REG_FROM_HALF_S    3'b110
`define REG_FROM_HALF_U    3'b111

// sig_memen
`define MEMEN_EN           4'b1111
`define MEMEN_BYTE         4'b0001
`define MEMEN_HALF		   4'b0011
`define MEMEN_JOIN_L       4'b1000
`define MEMEN_JOIN_R       4'b1100

// sig_regen
`define REGEN_EN           1'b1
// sig_shamt
`define USE_SHAMT          1'b1
// sig_aluop                      
`define ALUOP_ADD          5'b00000	
`define ALUOP_SUB          5'b00001	
`define ALUOP_SLT          5'b00010	
`define ALUOP_SLTU         5'b00011	
`define ALUOP_AND          5'b00100	
`define ALUOP_NOR          5'b00101	 
`define ALUOP_OR           5'b00110	 
`define ALUOP_XOR          5'b00111	
`define ALUOP_SLL          5'b01000	
`define ALUOP_SRL          5'b01001	
`define ALUOP_SRA          5'b01010	
`define ALUOP_LUI          5'b01011
`define ALUOP_NULL         5'b11111	
// sig_brjudge
`define BRJUDGE_EQUAL      3'b000
`define BRJUDGE_NEQUAL     3'b100
`define BRJUDGE_MORETHAN   3'b001
`define BRJUDGE_LESSTHAN   3'b010
`define BRJUDGE_N_MORE     3'b101
`define BRJUDGE_N_LESS     3'b110

// hazard mux
`define MUX_FORWARD_NO     2'b00
`define MUX_FORWARD_W2D    2'b01
`define MUX_FORWARD_M2D    2'b10
`define MUX_FORWARD_W2E    2'b01
`define MUX_FORWARD_M2E    2'b10
// hilo forward
`define FORWARD_ALU        3'd5
`define FORWARD_W_HI       3'd4
`define FORWARD_W_LO       3'd3
`define FORWARD_D_HI       3'd2
`define FORWARD_D_LO       3'd1
`define FORWARD_HILO_NO    3'd0

// signed compare
`define SIGNED_LESS 2'b00
`define SIGNED_MORE 2'b01
`define SIGNED_EQL  2'b11

// exceptions
`define EXC_NONE  3'b000
`define EXC_ERET  3'b001
`define EXC_MFC0  3'b010
`define EXC_MTC0  3'b011
`define EXC_SYS   3'b100
`define EXC_BRK   3'b101
