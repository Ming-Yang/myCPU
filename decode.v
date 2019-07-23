`include "defines.h"

module ins_decoder(
	input  [31:0] instruct,
	output [ 5:0] opcode,
	output [ 4:0] rs,
	output [ 4:0] rt,
	output [ 4:0] rd,
	output [ 4:0] shamt,
	output [ 5:0] func,
	output [15:0] immediate,
	output [25:0] instr_index
	);

assign {opcode,rs,rt,rd,shamt,func} = instruct;
assign immediate = {rd,shamt,func};
assign instr_index = {rs,rt,immediate};

endmodule

module sig_generator(
	input  [31:0] instruct,
	output [ 1:0] sig_branch,
	output [ 1:0] sig_regdst,
	output [ 1:0] sig_alusrc,
	output [ 4:0] sig_aluop,
	output [ 3:0] sig_memen,
	output [ 2:0] sig_memtoreg,
	output        sig_regen,
	output [ 2:0] sig_brjudge,
	output        sig_shamt,
	output [ 3:0] sig_hilo_rwen,
	output        sig_mul_sign,
	output        sig_div
);

wire [5:0] op;
wire [5:0] func;
wire [4:0] rt;

ins_decoder decode_sig(
	.instruct(instruct),
	.opcode(op),
	.func(func),
	.rt(rt)
);

//19
wire       inst_addu;
wire       inst_subu;
wire       inst_slt;
wire       inst_sltu;
wire       inst_and;
wire       inst_or;
wire       inst_xor;
wire       inst_nor;
wire       inst_sll;
wire       inst_srl;
wire       inst_sra;
wire       inst_addiu;
wire       inst_lui;
wire       inst_lw;
wire       inst_sw;
wire       inst_beq;
wire       inst_bne;
wire       inst_jal;
wire       inst_jr;


//11
wire       inst_add    ;
wire       inst_addi   ;
wire       inst_sub    ;
wire       inst_slti   ;
wire       inst_sltiu  ;
wire       inst_andi   ;
wire       inst_ori    ;
wire       inst_xori   ;
wire       inst_sllv   ;
wire       inst_srav   ;
wire       inst_srlv   ;


//muldiv
wire       inst_div    ;
wire       inst_divu   ;
wire       inst_mult   ;
wire       inst_multu  ;
wire       inst_mfhi   ;
wire       inst_mflo   ;
wire       inst_mthi   ;
wire       inst_mtlo   ;


//
wire       inst_j      ;
wire       inst_bgez   ;
wire       inst_bgtz   ;
wire       inst_blez   ;
wire       inst_bltz   ;
wire       inst_bltzal ;
wire       inst_bgezal ;
wire       inst_jalr   ;

wire       inst_lb	   ;
wire       inst_lbu    ;
wire       inst_lh	   ;
wire       inst_lhu    ;
wire       inst_lwl    ;
wire       inst_lwr    ;
wire       inst_sb	   ;
wire       inst_sh	   ;
wire       inst_swl    ;
wire       inst_swr    ;

//decode
assign  inst_lui	= op == 6'b001111	                                           ;
assign  inst_addu	= op == 6'b000000	&& func == 6'b100001                       ;
assign  inst_addiu	= op == 6'b001001	                                           ;
assign  inst_subu	= op == 6'b000000	&& func == 6'b100011                       ;
assign  inst_slt	= op == 6'b000000	&& func == 6'b101010                       ;
assign  inst_sltu	= op == 6'b000000	&& func == 6'b101011                       ;
assign  inst_and	= op == 6'b000000	&& func == 6'b100100                       ;
assign  inst_or	    = op == 6'b000000	&& func == 6'b100101                       ;
assign  inst_xor	= op == 6'b000000	&& func == 6'b100110                       ;
assign  inst_nor	= op == 6'b000000	&& func == 6'b100111                       ;
assign  inst_sll	= op == 6'b000000	&& func == 6'b000000                       ;
assign  inst_srl	= op == 6'b000000	&& func == 6'b000010                       ;
assign  inst_sra	= op == 6'b000000	&& func == 6'b000011                       ;
assign  inst_lw	    = op == 6'b100011	                                           ;
assign  inst_sw	    = op == 6'b101011	                                           ;
assign  inst_beq	= op == 6'b000100	                                           ;
assign  inst_bne	= op == 6'b000101	                                           ;
assign  inst_jal	= op == 6'b000011	                                           ;
assign  inst_jr	    = op == 6'b000000	&& func == 6'b001000                       ;
															                       
															                       
assign  inst_add	= op == 6'b000000	&& func == 6'b100000                       ;
assign  inst_addi	= op == 6'b001000	                                           ;
assign  inst_sub	= op == 6'b000000	&& func == 6'b100010                       ;
assign  inst_slti	= op == 6'b001010	                                           ;
assign  inst_sltiu	= op == 6'b001011	                                           ;
assign  inst_andi	= op == 6'b001100	                                           ;
assign  inst_ori	= op == 6'b001101	                                           ;
assign  inst_xori	= op == 6'b001110	                                           ;
assign  inst_sllv	= op == 6'b000000	&& func == 6'b000100                       ;
assign  inst_srav	= op == 6'b000000	&& func == 6'b000111                       ;
assign  inst_srlv	= op == 6'b000000	&& func == 6'b000110                       ;
															                       
assign  inst_div	= op == 6'b000000 	&& func == 6'b011010                       ;
assign  inst_divu	= op == 6'b000000 	&& func == 6'b011011                       ;
assign  inst_mult	= op == 6'b000000 	&& func == 6'b011000                       ;
assign  inst_multu	= op == 6'b000000 	&& func == 6'b011001                       ;
assign  inst_mfhi	= op == 6'b000000	&& func == 6'b010000                       ;
assign  inst_mflo	= op == 6'b000000	&& func == 6'b010010                       ;
assign  inst_mthi	= op == 6'b000000	&& func == 6'b010001                       ;
assign  inst_mtlo	= op == 6'b000000	&& func == 6'b010011                       ;

assign  inst_j	    = op == 6'b000010	                                           ;
assign  inst_bgez	= op == 6'b000001 	                         && rt == 5'b00001 ;
assign  inst_bgtz	= op == 6'b000111                                              ;
assign  inst_blez	= op == 6'b000110                                              ;
assign  inst_bltz	= op == 6'b000001 	                         && rt == 5'b00000 ; 
assign  inst_bltzal	= op == 6'b000001 	                         && rt == 5'b10000 ;
assign  inst_bgezal	= op == 6'b000001 	                         && rt == 5'b10001 ;
assign  inst_jalr	= op == 6'b000000	&& func == 6'b001001                       ;
assign  inst_lb	    = op == 6'b100000                                              ;
assign  inst_lbu    = op == 6'b100100                                              ;
assign  inst_lh	    = op == 6'b100001                                              ;
assign  inst_lhu    = op == 6'b100101                                              ;
assign  inst_lwl    = op == 6'b100010                                              ;
assign  inst_lwr    = op == 6'b100110                                              ;
assign  inst_sb	    = op == 6'b101000                                              ;
assign  inst_sh	    = op == 6'b101001                                              ;
assign  inst_swl    = op == 6'b101010                                              ;
assign  inst_swr    = op == 6'b101110                                              ;
																				   
	


assign sig_branch    = (inst_jal || inst_j) ? `BRANCH_INDEX :
					   (inst_jr || inst_jalr) ? `BRANCH_REG :
					   (inst_beq || inst_bne || inst_bgez || inst_bgtz || inst_blez || inst_bltz || inst_bltzal || inst_bgezal) ? `BRANCH_IMM :
					   `BRANCH_PC4;


assign sig_aluop     = 
					        (inst_sub || inst_subu) ? `ALUOP_SUB   :
					        (inst_slti || inst_slt) ? `ALUOP_SLT   :
					      (inst_sltu || inst_sltiu) ? `ALUOP_SLTU  :
					        (inst_and || inst_andi) ? `ALUOP_AND   :
					                     (inst_nor) ? `ALUOP_NOR   :
					          (inst_or || inst_ori) ? `ALUOP_OR    :
					        (inst_xor || inst_xori) ? `ALUOP_XOR   :
					        (inst_sll || inst_sllv) ? `ALUOP_SLL   :
					        (inst_srl || inst_srlv) ? `ALUOP_SRL   :
					        (inst_sra || inst_srav) ? `ALUOP_SRA   :
					                     (inst_lui) ? `ALUOP_LUI   :
					                                  `ALUOP_ADD   ;
					   
					   
assign sig_regdst    = (inst_lui || inst_addiu || inst_lw ||
						inst_addi || inst_slti || inst_sltiu || inst_andi || inst_addi || inst_ori || inst_xori ||
						inst_lb || inst_lbu || inst_lh || inst_lhu || inst_lwl || inst_lwr) ? `REGDST_RT :
					   (inst_jal || inst_bltzal || inst_bgezal)                             ? `REGDST_RA :
					                                                                          `REGDST_RD ;
					   
					   
assign sig_alusrc    = (inst_lui || inst_addiu || inst_lw || inst_sw || inst_jr ||
						inst_addi || inst_slti || inst_sltiu || inst_lb || inst_lbu || inst_lh || inst_lhu || inst_lwl || inst_lwr ||
						inst_sb || inst_sh || inst_swl || inst_swr) ? `ALUSRC_EXT :
					    (inst_ori || inst_xori || inst_andi)        ? `ALUSRC_0EXT :
					                                                   `ALUSRC_REG ;
					   
					   
assign sig_memen     = (inst_sw) ? `MEMEN_EN :
					   (inst_sb) ? `MEMEN_BYTE :
					   (inst_sh) ? `MEMEN_HALF :
					   (inst_swl) ? `MEMEN_JOIN_L :
					   (inst_swr) ? `MEMEN_JOIN_R :
					              ~`MEMEN_EN ;
					   
assign sig_memtoreg  = (inst_lw)             ? `REG_FROM_MEM    :
					   (inst_lb)             ? `REG_FROM_BYTE_S :
					   (inst_lbu)            ? `REG_FROM_BYTE_U :
					   (inst_lh)             ? `REG_FROM_HALF_S :
					   (inst_lhu)            ? `REG_FROM_HALF_U :
					   (inst_lwl)            ? `REG_FROM_JOIN_L :
					   (inst_lwr)            ? `REG_FROM_JOIN_R :
					                              `REG_FROM_ALU ;
					   
assign sig_regen     = (inst_sw || inst_beq || inst_bne || inst_jr || 
						inst_div || inst_divu || inst_mult || inst_multu || inst_mthi || inst_mtlo ||
						inst_j || inst_bgez || inst_bgtz || inst_blez || inst_bltz ||
						inst_sb || inst_sh || inst_swl || inst_swr) ? !`REGEN_EN :
					                                                   `REGEN_EN ;

assign sig_brjudge   = (inst_bne) ? `BRJUDGE_NEQUAL :
					   (inst_bgez || inst_bgezal) ? `BRJUDGE_N_LESS :
					   (inst_bgtz) ? `BRJUDGE_MORETHAN :
					   (inst_blez) ? `BRJUDGE_N_MORE :
					   (inst_bltz || inst_bltzal) ? `BRJUDGE_LESSTHAN :
					                                   `BRJUDGE_EQUAL ;
		
assign sig_shamt     = (inst_sll || inst_sra || inst_srl) ? | `USE_SHAMT :
						!`USE_SHAMT;
						
assign sig_hilo_rwen  = (inst_div || inst_divu || inst_mult || inst_multu) ? 4'b0011 :
					                                          (inst_mthi) ? 4'b0010 :
					                                          (inst_mtlo) ? 4'b0001 :
											                  (inst_mfhi) ? 4'b1000 :
															  (inst_mflo) ? 4'b0100 :
					                                                        4'b0000 ;

assign sig_mul_sign  = (inst_divu || inst_multu) ? 1'b0 :
												   1'b1 ;
												   
assign sig_div       = (inst_div || inst_divu) ? 1'b1 :
												 1'b0 ;
												  
endmodule