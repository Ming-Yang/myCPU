`include "defines.h"

module mycpu_top(
    input         clk ,
    input         resetn ,
    // inst sram interface
    output        inst_sram_en ,
    output [ 3:0] inst_sram_wen ,//vacuum
    output [31:0] inst_sram_addr , 
    output [31:0] inst_sram_wdata ,//vacuum
    input  [31:0] inst_sram_rdata ,
    // data sram interface
    output        data_sram_en ,
    output [ 3:0] data_sram_wen ,
    output [31:0] data_sram_addr ,
    output [31:0] data_sram_wdata ,
    input  [31:0] data_sram_rdata ,
    // trace debug interface
    output [31:0] debug_wb_pc ,
    output [ 3:0] debug_wb_rf_wen ,
    output [ 4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);
//reset
reg         reset ;

//piplie ctl
wire         f_reg_valid;
wire        fd_reg_valid;
wire        de_reg_valid;
wire        em_reg_valid;
wire        mw_reg_valid;

wire         f_allowin;
wire        fd_allowin;
wire        de_allowin;
wire        em_allowin;
wire        mw_allowin;

wire         f_stall;
wire        fd_stall;
wire        de_stall;
wire        em_stall;
wire        mw_stall;

wire          to_f_valid;
wire        f_to_d_valid;
wire        d_to_e_valid;
wire        e_to_m_valid;
wire        m_to_w_valid;
//fetch
wire [31:0] f_pc             ;
wire [31:0] f_next_pc        ;
wire [31:0] f_inst           ;

wire [ 1:0] f_sig_branch     ;
wire        f_isbranch       ;

//decode
wire [31:0] d_inst           ;
wire [31:0] d_pc             ;
wire [31:0] d_pc4            ;
wire [31:0] d_pc8            ;
wire [ 4:0] d_rs             ;
wire [ 4:0] d_rt             ;
wire [ 4:0] d_rd             ;
wire [ 4:0] d_shamt          ;
wire [15:0] d_imm            ;
wire [25:0] d_index          ;
wire [31:0] d_extend         ;
wire [31:0] d_0extend        ;
wire [31:0] d_16_target	     ;
wire [31:0] d_26_target      ;
wire [31:0] d_rd1            ;
wire [31:0] d_rd2            ;
wire [31:0] d_forward1_reg   ;
wire [31:0] d_forward2_reg   ;
wire [31:0] d_branch_src1    ;
wire [31:0] d_branch_src2    ;
wire        d_isbranch       ;
wire [31:0] d_hi             ;
wire [31:0] d_lo             ;
wire        d_compare_0      ;

wire [ 1:0] d_sig_branch     ;
wire [ 1:0] d_sig_regdst     ;
wire [ 1:0] d_sig_alusrc     ;
wire [ 4:0] d_sig_aluop      ;
wire [ 3:0] d_sig_memen      ;
wire [ 2:0] d_sig_memtoreg   ;
wire        d_sig_regen      ;
wire [ 2:0] d_sig_brjudge    ;
wire        d_sig_shamt      ;
wire [ 3:0] d_sig_hilo_rwen  ;
wire        d_sig_mul_sign   ;
wire        d_sig_div        ;

wire [ 1:0] d_forwardAD      ;
wire [ 1:0] d_forwardBD      ;
wire [ 2:0] d_forwardAD_hilo ;
wire [ 2:0] e_forwardAE_hilo ;

//execute
wire [31:0] e_pc             ;
wire [ 4:0] e_rs             ;
wire [ 4:0] e_rt             ;
wire [ 4:0] e_rd             ;
wire [ 4:0] e_shamt          ;
wire [31:0] e_rd1            ;
wire [31:0] e_rd2            ;
wire [31:0] e_extend         ;
wire [31:0] e_0extend        ;
wire [ 4:0] e_regdstaddr     ;
wire [31:0] e_alu_src1       ;
wire [31:0] e_alu_src2       ;
wire [31:0] e_forward1_reg   ;
wire [31:0] e_alu_reg_src1   ;
wire [31:0] e_alu_reg_src2   ;
wire [31:0] e_alu_res        ;
wire [31:0] e_mem_data       ;
wire [31:0] e_mem_addr       ;
wire [31:0] e_hi             ;
wire [31:0] e_lo             ;
wire [63:0] e_div_res        ;

wire [ 1:0] e_sig_regdst     ;
wire [ 1:0] e_sig_alusrc     ;
wire [ 4:0] e_sig_aluop      ;
wire [ 3:0] e_sig_memen      ;
wire [ 2:0] e_sig_memtoreg   ;
wire        e_sig_regen      ;
wire [ 1:0] e_sig_branch     ;
wire        e_sig_shamt      ;
wire [ 3:0] e_wmem_en        ;
wire [ 3:0] e_sig_hilo_rwen  ;
wire        e_sig_mul_sign   ;
wire        e_sig_div        ;

wire [ 1:0] e_forwardAE      ;
wire [ 1:0] e_forwardBE      ;

wire [31:0] e_aluop_hotkey   ;
//memory
wire [31:0] m_pc             ;
wire [31:0] m_pc8            ;
wire [31:0] m_alu_res        ;
wire [31:0] m_alu_pc8        ;
wire [31:0] m_mem_data       ;
wire [ 4:0] m_reg_addr       ;
wire [31:0] m_mem_data_read  ;
wire [31:0] m_hi             ;
wire [31:0] m_lo             ;
wire [63:0] m_mul_res        ;
wire [63:0] m_div_res        ;
wire [63:0] m_muldiv_res     ;
wire        m_div_complete   ;

wire [ 1:0] m_sig_regdst     ;
wire [ 3:0] m_sig_memen      ;
wire [ 2:0] m_sig_memtoreg   ;
wire        m_sig_regen      ;
wire [ 1:0] m_sig_branch     ;
wire [ 3:0] m_sig_hilo_rwen  ;
wire        m_sig_div        ;

//writeback
wire [31:0] w_pc             ;
wire [31:0] w_mem_data_read  ;
wire [31:0] w_alu_res        ;
wire [ 4:0] w_reg_addr       ;
wire [31:0] w_reg_data       ;
wire [31:0] w_pc8            ;

wire [31:0] w_alu_mem_data   ;
wire        w_wreg_en        ;
wire [31:0] w_reg2_data      ;
wire [31:0] w_hi             ;
wire [31:0] w_lo             ;
wire [63:0] w_muldiv_res     ;

wire [ 2:0] w_sig_memtoreg   ;
wire        w_sig_regen      ;
wire [ 1:0] w_sig_branch     ;
wire [ 3:0] w_sig_hilo_rwen  ;


//hazard
wire        hazard_stall     ;
wire        hazard_div_stall ;
wire        hazard_div_relation_stall;

////////////////////////////////////////////////////////////////////////////////////////////////////////
//fetch
assign f_sig_branch = d_sig_branch & {2{fd_reg_valid}};
assign f_isbranch = d_isbranch;

mux_branch pc_mux(
	f_sig_branch,
	f_isbranch,
	f_pc+3'h4,
	d_16_target,
	d_branch_src1,
	d_26_target,
	f_next_pc
);

assign f_stall = reset;
assign to_f_valid = 1'b1;
fetch_reg fetch_reg(
	.clk                (clk             ),
	.reset              (reset           ),
	.cur_stall          (f_stall         ),
	.cur_allowin        (f_allowin       ),
	.reg_valid          (f_reg_valid     ),
	.pre_valid          (to_f_valid      ),
	.post_allowin       (fd_allowin      ),
	.goon_valid         (f_to_d_valid    ),
	
	.next_pc            (f_next_pc       ),
	.pc                 (f_pc            )	
);

assign inst_sram_addr = f_next_pc;
assign f_inst = inst_sram_rdata;
assign inst_sram_en = f_allowin;
assign inst_sram_wen = 4'h0;
//fetch2decode
reg_pipline_full_stage pipe_f_d(
	.clk                (clk             ),
	.reset              (reset           ),
	.cur_stall          (fd_stall        ),
	.cur_allowin        (fd_allowin      ),
	.reg_valid          (fd_reg_valid    ),
	.pre_valid          (f_to_d_valid    ),
	.post_allowin       (de_allowin      ),
	.goon_valid         (d_to_e_valid    ),
	
	.pre_instruction    (f_inst          ),
	.pre_pc             (f_pc            ),
	
	.instruction        (d_inst          ),
	.pc                 (d_pc            )
	);

//decode
ins_decoder decode_reg(
	.instruct      (d_inst          ), 
	.rs            (d_rs            ), 
	.rt            (d_rt            ), 
	.rd            (d_rd            ), 
	.immediate     (d_imm           ), 
	.instr_index   (d_index         ),
	.shamt         (d_shamt         )
	);

sig_generator generate_sig(
	.instruct      (d_inst          ), 
	.sig_branch    (d_sig_branch    ), 
	.sig_regdst    (d_sig_regdst    ), 
	.sig_alusrc    (d_sig_alusrc    ), 
	.sig_aluop     (d_sig_aluop     ), 
	.sig_memen     (d_sig_memen     ), 
	.sig_memtoreg  (d_sig_memtoreg  ), 
	.sig_regen     (d_sig_regen     ),
	.sig_brjudge   (d_sig_brjudge   ),
	.sig_shamt     (d_sig_shamt     ),
	.sig_hilo_rwen (d_sig_hilo_rwen ),
	.sig_mul_sign  (d_sig_mul_sign  ),
	.sig_div       (d_sig_div       )
	);

assign d_pc4 = d_pc+3'h4;
assign d_pc8 = d_pc+4'h8;

jump_16 jump16(
	d_imm                             ,
	d_pc4                             ,
	d_extend                          ,
	d_16_target	
	);
	
jump_26 jump26(	
	d_index                           ,
	d_pc8[31:28]                      ,
	d_26_target                       
	);

extend zero_extend(
	(d_sig_alusrc != `ALUSRC_0EXT)    ,
	d_imm                             ,
	d_0extend
);

regfile regfile(
	clk                               ,
	d_rs                              ,
	d_rd1                             ,
	d_rt                              ,
	d_rd2                             ,
	w_wreg_en                         ,
	w_reg_addr                        ,
	w_reg_data
	);
	
reg_hilo reg_hilo(
	clk,
	w_sig_hilo_rwen[1:0],
	w_muldiv_res[63:32],
	w_muldiv_res[31: 0],
	w_reg_data,
	d_hi,
	d_lo
);	

mux3_32 d_forward1_reg_mux(
	d_forwardAD,
	d_rd1,
	w_reg_data,
	m_alu_pc8,
	d_forward1_reg
);

mux6_32 d_forward1_hilo_mux(
	d_forwardAD_hilo,
	d_forward1_reg,
	d_lo,
	d_hi,
    w_muldiv_res[31: 0],
	w_muldiv_res[63:32],
	m_alu_pc8,
    d_branch_src1	
);
	
mux3_32 d_forward2_mux(
	d_forwardBD,
	d_rd2,
	w_reg_data,
	m_alu_pc8,
	d_forward2_reg
	);

assign d_compare_0 = d_sig_brjudge == `BRJUDGE_MORETHAN || d_sig_brjudge == `BRJUDGE_LESSTHAN ||
					 d_sig_brjudge == `BRJUDGE_N_MORE   || d_sig_brjudge == `BRJUDGE_N_LESS ;
mux2_32 d_forward2_0_mux(
	d_compare_0,
	d_forward2_reg,
	32'b0,
	d_branch_src2
);

branch_judge branch_judge(
	d_sig_brjudge,
	d_branch_src1,
	d_branch_src2,
	d_isbranch
	);

// decode2execute
reg_pipline_full_stage pipe_d_e(
	.clk                (clk             ),
	.reset              (reset           ),
	.cur_stall          (de_stall        ),
	.cur_allowin        (de_allowin      ),
	.reg_valid          (de_reg_valid    ),
	.pre_valid          (d_to_e_valid    ),
	.post_allowin       (em_allowin      ),
	.goon_valid         (e_to_m_valid    ),
	
	.pre_pc             (d_pc            ),
	.pre_rs             (d_rs            ),
	.pre_rt             (d_rt            ),
	.pre_rd             (d_rd            ),
	.pre_shamt          (d_shamt         ),
	.pre_reg_o1         (d_branch_src1   ),
	.pre_reg_o2         (d_branch_src2   ),
	.pre_extend         (d_extend        ),
	.pre_zextend        (d_0extend       ),
	.pre_hi             (d_hi            ),
	.pre_lo             (d_lo            ),
	
	.pc                 (e_pc            ),
	.rs                 (e_rs            ),
	.rt                 (e_rt            ),
	.rd                 (e_rd            ),
	.shamt              (e_shamt         ),
	.reg_o1             (e_rd1           ),
	.reg_o2             (e_rd2           ),
	.extend             (e_extend        ),
	.zextend            (e_0extend       ),
	.hi                 (e_hi            ),
	.lo                 (e_lo            ),
	
	.pre_sig_regdst     (d_sig_regdst    ),
	.pre_sig_alusrc     (d_sig_alusrc    ),
	.pre_sig_aluop      (d_sig_aluop     ),
	.pre_sig_memen      (d_sig_memen     ),
	.pre_sig_memtoreg   (d_sig_memtoreg  ),
	.pre_sig_regen      (d_sig_regen     ),
	.pre_sig_branch     (d_sig_branch    ),
	.pre_sig_shamt      (d_sig_shamt     ),
	.pre_sig_hilo_rwen  (d_sig_hilo_rwen ),
	.pre_sig_mul_sign   (d_sig_mul_sign  ),
	.pre_sig_div        (d_sig_div       ),

	.sig_regdst         (e_sig_regdst    ),
	.sig_alusrc         (e_sig_alusrc    ),
	.sig_aluop          (e_sig_aluop     ),
	.sig_memen          (e_sig_memen     ),
	.sig_memtoreg       (e_sig_memtoreg  ),
	.sig_regen          (e_sig_regen     ),
	.sig_branch         (e_sig_branch    ),
	.sig_shamt          (e_sig_shamt     ),
	.sig_hilo_rwen      (e_sig_hilo_rwen ),
	.sig_mul_sign       (e_sig_mul_sign  ),
	.sig_div            (e_sig_div       )
	);
//execute
mux3_5 regdst_mux(
	e_sig_regdst,
	e_rt,
	e_rd,
	`REG_RA,
	e_regdstaddr
	);

///////////////////////e_forward_mux////////////
`ifdef _USE_E_FORWARD
mux3_32 e_forward1_reg_mux(
	e_forwardAE,
	e_rd1,
	w_reg_data,
	m_alu_pc8,
	e_forward1_reg
);

mux6_32 e_forward1_hilo_mux(
	e_forwardAE_hilo,
	e_forward1_reg,
	e_forward1_reg,
	e_forward1_reg,
    w_muldiv_res[31: 0],
	w_muldiv_res[63:32],
	m_alu_pc8,
    e_alu_reg_src1	
);

mux3_32 e_foward2_mux(
	e_forwardBE,
	e_rd2,
	w_reg_data,
	m_alu_pc8,
	e_alu_reg_src2
	);	
`else
assign e_alu_reg_src1 = e_rd1;
assign e_alu_reg_src2 = e_rd2;
`endif

/////////////////////////////////////////////////	

mux2_32 alusrc1_mux(
	e_sig_shamt,
	e_alu_reg_src1,
	{27'b0,e_shamt},
	e_alu_src1
	);	

mux3_32 alusrc2_mux(
	e_sig_alusrc,
	e_alu_reg_src2,
	e_extend,
	e_0extend,
	e_alu_src2
	);
	
mul multiplier(
	clk,
	reset,
	e_sig_mul_sign,
	e_alu_src1,
	e_alu_src2,
	m_mul_res
	);
 
div divider(
	clk,
	reset,
	e_sig_div,
	e_sig_mul_sign,
	e_alu_src1,
	e_alu_src2,
	e_div_res[31: 0],
	e_div_res[63:32],
	m_div_complete
);
	
alu alu(
	e_sig_aluop,
	e_alu_src1,
	e_alu_src2,
	e_alu_res
	);

memory_in_mux memory_in_mux(
	e_sig_memen,
	de_reg_valid,
	e_alu_reg_src2,
	e_alu_res,
	e_wmem_en,
	e_mem_data,
	e_mem_addr
);

//execute2memory
assign em_stall = 1'b0;
reg_pipline_full_stage pipe_e_m(
	.clk                    (clk              ),
	.reset                  (reset            ),
	.cur_stall              (em_stall         ),
	.cur_allowin            (em_allowin       ),
	.reg_valid              (em_reg_valid     ),
	.pre_valid              (e_to_m_valid     ),
	.post_allowin           (mw_allowin       ),
	.goon_valid             (m_to_w_valid     ),
	
	.pre_pc                 (e_pc             ),
	.pre_wreg_addr          (e_regdstaddr     ),
	.pre_alu_res            (e_mem_addr       ),
	.pre_data_write_mem     (e_mem_data       ),
	.pre_hi                 (e_hi             ),
	.pre_lo                 (e_lo             ),
	.pre_div_res            (e_div_res        ),
					       
	.pc                     (m_pc             ),
	.wreg_addr              (m_reg_addr       ),
	.alu_res                (m_alu_res        ),
	.data_write_mem         (m_mem_data       ),
	.hi                     (m_hi             ),
	.lo                     (m_lo             ),
	.div_res                (m_div_res        ),
	
	.pre_sig_regdst         (e_sig_regdst     ),
	.pre_sig_memen          (e_sig_memen      ),
	.pre_sig_memtoreg       (e_sig_memtoreg   ),
	.pre_sig_regen          (e_sig_regen      ),
	.pre_sig_branch         (e_sig_branch     ),
	.pre_sig_hilo_rwen      (e_sig_hilo_rwen  ),
	.pre_sig_div            (e_sig_div        ),
						   
	.sig_regdst             (m_sig_regdst     ),
	.sig_memen              (m_sig_memen      ),
	.sig_memtoreg           (m_sig_memtoreg   ),
	.sig_regen              (m_sig_regen      ),
	.sig_branch             (m_sig_branch     ),
	.sig_hilo_rwen          (m_sig_hilo_rwen  ),
	.sig_div                (m_sig_div        )
	);


//memory

assign data_sram_en = 1'b1;
assign data_sram_wen = e_wmem_en;
assign data_sram_wdata = e_mem_data;
assign m_mem_data_read = data_sram_rdata;
assign data_sram_addr = e_mem_addr;

assign m_pc8 = m_pc+4'h8;
mux2_32 reg_m_pc8_mux(
	(m_sig_branch != `BRANCH_PC4),
	m_alu_res,
	m_pc8,
	m_alu_pc8
);

mux2_64 muldiv_res_mux(
	m_sig_div,
	m_mul_res,
	m_div_res,
	m_muldiv_res
	);

//memory2writeback
assign mw_stall = 1'b0;
reg_pipline_full_stage pipe_m_w(
	.clk                (clk             ),
	.reset              (reset           ),
	.cur_stall          (mw_stall        ),
	.cur_allowin        (mw_allowin      ),
	.reg_valid          (mw_reg_valid    ),
	.pre_valid          (m_to_w_valid    ),
	.post_allowin       (1'b1            ),
	
	.pre_pc             (m_pc            ),
	.pre_wreg_addr      (m_reg_addr      ),
	.pre_alu_res        (m_alu_res       ),
	.pre_data_read_mem  (m_mem_data_read ),
	.pre_data_write_mem (m_mem_data      ),
	.pre_hi             (m_hi            ),
	.pre_lo             (m_lo            ),
	.pre_muldiv_res     (m_muldiv_res    ),
	
	.pc                 (w_pc            ),
	.wreg_addr          (w_reg_addr      ),
	.alu_res            (w_alu_res       ),
	.data_read_mem      (w_mem_data_read ),
	.data_write_mem     (w_reg2_data     ),
	.hi                 (w_hi            ),
	.lo                 (w_lo            ),
	.muldiv_res         (w_muldiv_res    ),
	
	.pre_sig_memtoreg   (m_sig_memtoreg  ),
	.pre_sig_regen      (m_sig_regen     ),
	.pre_sig_branch     (m_sig_branch    ),
	.pre_sig_hilo_rwen  (m_sig_hilo_rwen ),

	.sig_memtoreg       (w_sig_memtoreg  ),
	.sig_regen          (w_sig_regen     ),
	.sig_branch         (w_sig_branch    ),
	.sig_hilo_rwen      (w_sig_hilo_rwen )
	);

//writeback
assign w_wreg_en = w_sig_regen && mw_reg_valid;
memory_out_mux memory_out_mux(
	w_sig_memtoreg,
	w_alu_res,
	w_mem_data_read,
	w_reg2_data,
	w_alu_mem_data
);

assign w_pc8 = w_pc+4'h8;
mux2_32 reg_w_pc8_mux(
	(w_sig_branch != `BRANCH_PC4),
	w_alu_mem_data,
	w_pc8,
	w_reg_data
);

//hazard
hazard hazard(
	d_rs              , 
	d_rt              ,
	e_rs              ,
	e_rt              ,
	e_regdstaddr      ,
	m_reg_addr        ,
	w_reg_addr        ,
	
	de_reg_valid      ,
	em_reg_valid      ,
	mw_reg_valid      ,
	                  
	d_sig_branch      ,
	d_sig_div         ,
	e_sig_memtoreg    ,
	e_sig_regdst      ,
	e_sig_regen       ,
	m_sig_memtoreg    ,
	m_sig_regdst      ,
	m_sig_regen       ,
	w_sig_regen       ,
	
	d_forwardAD       ,
	d_forwardBD       ,
	e_forwardAE       ,
	e_forwardBE       ,
	hazard_stall      
);

mul_div_hazard mul_div_hazard(
	clk               ,
	reset             ,
	
	d_sig_div         ,
	m_div_complete    ,
	
	de_reg_valid      ,
	em_reg_valid      ,
	
	d_sig_hilo_rwen[3:2] ,
	e_sig_hilo_rwen[3:2] ,
	e_sig_hilo_rwen[1:0] ,
	m_sig_hilo_rwen[1:0] ,
	w_sig_hilo_rwen[1:0] ,
	
	d_forwardAD_hilo  ,
	e_forwardAE_hilo  ,
	
	hazard_div_stall  ,
	hazard_div_relation_stall
);

assign fd_stall = hazard_stall || hazard_div_relation_stall;
assign de_stall = hazard_div_stall;

//reset
always @(posedge clk) reset <= ~resetn;
//debug signal
assign debug_wb_pc = w_pc;
assign debug_wb_rf_wen = w_wreg_en==1'b1 ? 4'b1111 : 4'b0000;
assign debug_wb_rf_wnum = w_reg_addr;
assign debug_wb_rf_wdata = w_reg_data;

endmodule