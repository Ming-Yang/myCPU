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
	input         is_valid,
	input  [31:0] instruct,
	output [ 1:0] out_sig_branch,
	output [ 1:0] out_sig_regdst,
	output [ 1:0] out_sig_alusrc,
	output [ 4:0] out_sig_aluop,
	output [ 3:0] out_sig_memen,
	output [ 2:0] out_sig_memtoreg,
	output        out_sig_regen,
	output [ 2:0] out_sig_brjudge,
	output        out_sig_shamt,
	output [ 3:0] out_sig_hilo_rwen,
	output        out_sig_mul_sign,
	output        out_sig_div,
	output [ 2:0] out_sig_exc,
	output [ 7:0] out_sig_exc_cmd,

	output        out_sig_ri_exc
);

wire [5:0] op;
wire [4:0] rs;
wire [4:0] rt;
wire [5:0] func;

ins_decoder decode_sig(
	.instruct(instruct),
	.opcode(op),
	.rs(rs),
	.rt(rt),
	.func(func)
);

//decode
wire    inst_lui	= op == 6'b001111	                                                                 ;
wire    inst_addu	= op == 6'b000000	                                         && func == 6'b100001    ;
wire    inst_addiu	= op == 6'b001001	                                                                 ;
wire    inst_subu	= op == 6'b000000	                                         && func == 6'b100011    ;
wire    inst_slt	= op == 6'b000000	                                         && func == 6'b101010    ;
wire    inst_sltu	= op == 6'b000000	                                         && func == 6'b101011    ;
wire    inst_and	= op == 6'b000000	                                         && func == 6'b100100    ;
wire    inst_or	    = op == 6'b000000	                                         && func == 6'b100101    ;
wire    inst_xor	= op == 6'b000000	                                         && func == 6'b100110    ;
wire    inst_nor	= op == 6'b000000	                                         && func == 6'b100111    ;
wire    inst_sll	= op == 6'b000000	                                         && func == 6'b000000    ;
wire    inst_srl	= op == 6'b000000	                                         && func == 6'b000010    ;
wire    inst_sra	= op == 6'b000000	                                         && func == 6'b000011    ;
wire    inst_lw	    = op == 6'b100011	                                                                 ;
wire    inst_sw	    = op == 6'b101011	                                                                 ;
wire    inst_beq	= op == 6'b000100	                                                                 ;
wire    inst_bne	= op == 6'b000101	                                                                 ;
wire    inst_jal	= op == 6'b000011	                                                                 ;
wire    inst_jr	    = op == 6'b000000	                                         && func == 6'b001000    ;
										                                         	                          
wire    inst_add	= op == 6'b000000	                                         && func == 6'b100000    ;
wire    inst_addi	= op == 6'b001000	                                                                 ;
wire    inst_sub	= op == 6'b000000	                                         && func == 6'b100010    ;
wire    inst_slti	= op == 6'b001010	                                                                 ;
wire    inst_sltiu	= op == 6'b001011	                                                                 ;
wire    inst_andi	= op == 6'b001100	                                                                 ;
wire    inst_ori	= op == 6'b001101	                                                                 ;
wire    inst_xori	= op == 6'b001110	                                                                 ;
wire    inst_sllv	= op == 6'b000000	                                         && func == 6'b000100    ;
wire    inst_srav	= op == 6'b000000	                                         && func == 6'b000111    ;
wire    inst_srlv	= op == 6'b000000	                                         && func == 6'b000110    ;
										                                         	                      
wire    inst_div	= op == 6'b000000 	                                         && func == 6'b011010    ;
wire    inst_divu	= op == 6'b000000 	                                         && func == 6'b011011    ;
wire    inst_mult	= op == 6'b000000 	                                         && func == 6'b011000    ;
wire    inst_multu	= op == 6'b000000 	                                         && func == 6'b011001    ;
wire    inst_mfhi	= op == 6'b000000	                                         && func == 6'b010000    ;
wire    inst_mflo	= op == 6'b000000	                                         && func == 6'b010010    ;
wire    inst_mthi	= op == 6'b000000	                                         && func == 6'b010001    ;
wire    inst_mtlo	= op == 6'b000000	                                         && func == 6'b010011    ;

wire    inst_j	    = op == 6'b000010	                                                                 ;
wire    inst_bgez	= op == 6'b000001 	                     && rt == 5'b00001                           ;
wire    inst_bgtz	= op == 6'b000111                                                                    ;
wire    inst_blez	= op == 6'b000110                                                                    ;
wire    inst_bltz	= op == 6'b000001 	                     && rt == 5'b00000                           ; 
wire    inst_bltzal	= op == 6'b000001 	                     && rt == 5'b10000                           ;
wire    inst_bgezal	= op == 6'b000001 	                     && rt == 5'b10001                           ;
wire    inst_jalr	= op == 6'b000000	                                         && func == 6'b001001    ;
wire    inst_lb	    = op == 6'b100000                                                                    ;
wire    inst_lbu    = op == 6'b100100                                                                    ;
wire    inst_lh	    = op == 6'b100001                                                                    ;
wire    inst_lhu    = op == 6'b100101                                                                    ;
wire    inst_lwl    = op == 6'b100010                                                                    ;
wire    inst_lwr    = op == 6'b100110                                                                    ;
wire    inst_sb	    = op == 6'b101000                                                                    ;
wire    inst_sh	    = op == 6'b101001                                                                    ;
wire    inst_swl    = op == 6'b101010                                                                    ;
wire    inst_swr    = op == 6'b101110                                                                    ;

wire   inst_eret	= op ==6'b010000			                                  && func == 6'b011000   ;
wire   inst_mfc0	= op ==6'b010000	&&rs == 5'b00000                                                 ;
wire   inst_mtc0	= op ==6'b010000	&&rs == 5'b00100                                                 ;
wire   inst_syscall	= op ==6'b000000			                                  && func == 6'b001100   ;
wire   inst_break	= op ==6'b000000			                                  && func == 6'b001101   ;
																							    

wire [ 1:0] sig_branch       ;
wire [ 1:0] sig_regdst       ;
wire [ 1:0] sig_alusrc       ;
wire [ 4:0] sig_aluop        ;
wire [ 3:0] sig_memen        ;
wire [ 2:0] sig_memtoreg     ;
wire        sig_regen        ;
wire [ 2:0] sig_brjudge      ;
wire        sig_shamt        ;
wire [ 3:0] sig_hilo_rwen    ;
wire        sig_mul_sign     ;
wire        sig_div          ;
wire [ 2:0] sig_exc          ;
wire [ 7:0] sig_exc_cmd      ;
							 
wire        sig_ri_exc       ;


assign sig_branch    = (inst_jal || inst_j) ? `BRANCH_INDEX :
					   (inst_jr || inst_jalr) ? `BRANCH_REG :
					   (inst_beq || inst_bne || inst_bgez || inst_bgtz || inst_blez || inst_bltz || inst_bltzal || inst_bgezal) ? `BRANCH_IMM :
					   `BRANCH_PC4;


assign sig_aluop     =      (inst_sub || inst_subu) ? `ALUOP_SUB   :
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
						inst_lb || inst_lbu || inst_lh || inst_lhu || inst_lwl || inst_lwr || inst_mfc0) ? `REGDST_RT :
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
						inst_sb || inst_sh || inst_swl || inst_swr || 
						inst_eret || inst_mtc0 || inst_syscall || inst_break) ? !`REGEN_EN :
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
												 
assign sig_exc       = inst_eret ? `EXC_ERET :
					   inst_mfc0 ? `EXC_MFC0 :
					   inst_mtc0 ? `EXC_MTC0 :
					   inst_syscall ? `EXC_SYS :
					   inst_break ? `EXC_BRK :
									`EXC_NONE ;
												  

assign sig_exc_cmd[0] = inst_add;
assign sig_exc_cmd[1] = inst_addi;
assign sig_exc_cmd[2] = inst_sub;

assign sig_exc_cmd[3] = inst_lw;
assign sig_exc_cmd[4] = inst_lh;
assign sig_exc_cmd[5] = inst_lhu;

assign sig_exc_cmd[6] = inst_sw;
assign sig_exc_cmd[7] = inst_sh;

assign sig_ri_exc = ~ ( inst_lui || inst_addu || inst_addiu || inst_subu || inst_slt || inst_sltu || inst_and || inst_or || inst_xor || inst_nor || inst_sll || inst_srl || inst_sra || inst_lw || inst_sw || inst_beq || inst_bne || inst_jal || inst_jr || inst_add || inst_addi || inst_sub || inst_slti || inst_sltiu || inst_andi || inst_ori || inst_xori || inst_sllv || inst_srav || inst_srlv || inst_div || inst_divu || inst_mult || inst_multu || inst_mfhi || inst_mflo || inst_mthi || inst_mtlo || inst_j || inst_bgez || inst_bgtz || inst_blez || inst_bltz || inst_bltzal || inst_bgezal || inst_jalr || inst_lb || inst_lbu || inst_lh || inst_lhu || inst_lwl || inst_lwr || inst_sb || inst_sh || inst_swl || inst_swr || inst_eret || inst_mfc0 || inst_mtc0 || inst_syscall || inst_break );


assign out_sig_branch    = {2{is_valid}} & sig_branch      ;
assign out_sig_regdst    = {2{is_valid}} & sig_regdst      ;
assign out_sig_alusrc    = {2{is_valid}} & sig_alusrc      ;
assign out_sig_aluop     = {5{is_valid}} & sig_aluop       ;
assign out_sig_memen     = {4{is_valid}} & sig_memen       ;
assign out_sig_memtoreg  = {3{is_valid}} & sig_memtoreg    ;
assign out_sig_regen     = {1{is_valid}} & sig_regen       ;
assign out_sig_brjudge   = {3{is_valid}} & sig_brjudge     ;
assign out_sig_shamt     = {1{is_valid}} & sig_shamt       ;
assign out_sig_hilo_rwen = {4{is_valid}} & sig_hilo_rwen   ;
assign out_sig_mul_sign  = {1{is_valid}} & sig_mul_sign    ;
assign out_sig_div       = {1{is_valid}} & sig_div         ;
assign out_sig_exc       = {3{is_valid}} & sig_exc         ;
assign out_sig_exc_cmd   = {8{is_valid}} & sig_exc_cmd     ;
assign out_sig_ri_exc    = {1{is_valid}} & sig_ri_exc      ;

endmodule