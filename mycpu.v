`include "defines.h"
`include "cp0defines.h"
`include "config.h"

module mycpu(
    input         clk ,
    input         resetn ,
	
	//------inst sram-like-------
    output        inst_req    ,
    output        inst_wr     ,
    output [1 :0] inst_size   ,
    output [31:0] inst_addr   ,
    output [31:0] inst_wdata  ,
    input  [31:0] inst_rdata  ,
    input         inst_addr_ok,
    input         inst_data_ok,
    
    //------data sram-like-------
    output        data_req    ,
    output        data_wr     ,
    output [1 :0] data_size   ,
    output [31:0] data_addr   ,
    output [31:0] data_wdata  ,
    input  [31:0] data_rdata  ,
    input         data_addr_ok,
    input         data_data_ok,
    // trace debug interface
    output [31:0] debug_wb_pc ,
    output [ 3:0] debug_wb_rf_wen ,
    output [ 4:0] debug_wb_rf_wnum ,
    output [31:0] debug_wb_rf_wdata
);
// reset
reg         reset ;

// piplie ctl
wire        pre_f_reg_valid;
wire        fd_reg_valid;
wire        de_reg_valid;
wire        em_reg_valid;
wire        mw_reg_valid;

wire        pre_f_allowin;
wire        fd_allowin;
wire        de_allowin;
wire        em_allowin;
wire        mw_allowin;

wire        pre_f_stall;
wire        fd_stall;
wire        de_stall;
wire        em_stall;
wire        mw_stall;

wire        pre_to_f_valid;
wire        f_to_d_valid;
wire        d_to_e_valid;
wire        e_to_m_valid;
wire        m_to_w_valid;

wire        to_f_reset;
wire        fd_reset;
wire        de_reset;
wire        em_reset;
wire        mw_reset;
// pre fetch
wire [31:0] pre_f_pc         ;
wire [31:0] pre_f_branch_pc  ;
// fetch
wire [31:0] f_pc             ;
							  
							  
wire [31:0] f_inst           ;

wire [ 1:0] f_sig_branch     ;
wire        f_isbranch       ;

wire [ 2:0] f_sig_exc        ;
wire        f_adel_exc       ;

// decode
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
wire [31:0] d_forward1_hilo  ;
wire [31:0] d_forward2_0     ;
wire [31:0] d_branch_src1    ;
wire [31:0] d_branch_src2    ;
wire        d_isbranch       ;
wire [31:0] d_hi             ;
wire [31:0] d_lo             ;
wire        d_reg_hilo_0     ;
wire        d_compare_0      ;
wire        d_reg_cp0        ;
wire [31:0] d_cp0_data       ;

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
wire [ 2:0] d_sig_exc        ;
wire [ 7:0] d_sig_exc_cmd    ;
wire        d_ri_exc         ;
wire        d_sys_exc        ;
wire        d_brk_exc        ;
wire        d_eret_exc       ;

wire [ 1:0] d_forwardAD      ;
wire [ 1:0] d_forwardBD      ;
wire [ 2:0] d_forwardAD_hilo ;

// execute
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
wire [31:0] e_aluop_hotkey   ;
wire        e_div_complete   ;

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
wire [ 2:0] e_sig_exc        ;
wire [ 7:0] e_sig_exc_cmd    ;
wire        e_ov_exc         ;
wire        e_ades_exc       ;
wire        e_adel_exc       ;

// memory
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

wire [ 1:0] m_sig_regdst     ;
wire [ 3:0] m_sig_memen      ;
wire [ 2:0] m_sig_memtoreg   ;
wire        m_sig_regen      ;
wire [ 1:0] m_sig_branch     ;
wire [ 3:0] m_sig_hilo_rwen  ;
wire        m_sig_div        ;
wire [ 2:0] m_sig_exc        ;
wire [ 7:0] m_sig_exc_cmd    ;
wire        m_ades_exc       ;
wire        m_adel_exc       ;

//writeback
wire [31:0] w_pc             ;
wire [31:0] w_mem_data_read  ;
wire [31:0] w_alu_res        ;
wire [ 4:0] w_wreg_addr      ;
wire [31:0] w_wreg_data      ;
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
wire [ 2:0] w_sig_exc        ;

// hazard
wire        hazard_stall     ;
wire        hazard_div_stall ;
wire        hazard_div_relation_stall;

///////////////////////////////////cp0//////////////////////////////////////////////
wire [ 4:0] f_excCode        ;
wire        f_is_exc         ;
wire        f_is_in_ds       ;
wire        f_is_eret        ;

wire [31:0] fd_pc             ;
wire [31:0] fd_badvaddr       ;
wire [ 4:0] fd_excCode        ;
wire        fd_is_exc         ;
wire        fd_is_in_ds       ;
wire        fd_is_eret        ;
wire        fd_en_disable     ;

wire [ 4:0] d_excCode        ;
wire        d_is_exc         ;
wire        d_is_in_ds       ;
reg         d_is_in_ds_reg   ;
wire        d_is_eret        ;

wire [31:0] de_pc             ;
wire [31:0] de_badvaddr       ;
wire [ 4:0] de_excCode        ;
wire        de_is_exc         ;
wire        de_is_in_ds       ;
wire        de_is_eret        ;
wire        de_en_disable     ;

wire [ 4:0] e_excCode        ;
wire        e_is_exc         ;
wire        e_is_in_ds       ;
reg         e_is_in_ds_reg   ;
wire        e_is_eret        ;

wire [31:0] em_pc             ;
wire [31:0] em_badvaddr       ;
wire [ 4:0] em_excCode        ;
wire        em_is_exc         ;
wire        em_is_in_ds       ;
wire        em_is_eret        ;
wire        em_en_disable     ; 

wire [ 4:0] m_excCode        ;
wire        m_is_exc         ;
wire        m_is_in_ds       ;
reg         m_is_in_ds_reg   ;
wire        m_is_eret        ;

wire [31:0] mw_pc             ;
wire [31:0] mw_badvaddr       ;
wire [ 4:0] mw_excCode        ;
wire        mw_is_exc         ;
wire        mw_is_in_ds       ;
wire        mw_is_eret        ;
wire        mw_en_disable     ;

wire [ 4:0] w_excCode        ;
wire        w_is_exc         ;
wire        w_is_in_ds       ;
wire        w_is_eret        ;


wire [31:0] exc_pc           ;
wire        sig_exc_occur    ;
wire        sig_inter_occur  ;
wire        cp0_wen          ;


////////////////////////////////////ram///////////////////////////////////////////////////////////////
reg         iram_wait          ;
reg         iram_exc_wait      ;
wire        iram_stall         ;
wire        iram_data_ok       ;
wire        iram_addr_ok       ;

reg         dram_wait          ;
wire        dram_stall         ;
wire        dram_data_ok       ;
wire        dram_addr_ok       ;

/////////////////////////////////pipeline module/////////////////////////////////////////////////////////
// fetch
assign f_sig_branch = d_sig_branch ;
assign f_isbranch = d_isbranch;
always @(posedge clk) begin
	if(de_reg_valid)
		d_is_in_ds_reg <= e_sig_branch != `BRANCH_PC4;
	if(em_reg_valid)
		e_is_in_ds_reg <= m_sig_branch != `BRANCH_PC4;
	if(mw_reg_valid)
		m_is_in_ds_reg <= w_sig_branch != `BRANCH_PC4;

end
// reg        f_isbranch_reg;
// reg  [1:0] f_sig_branch_reg;
// assign f_sig_branch = ~fd_reg_valid ? f_sig_branch_reg :
									// d_sig_branch;
// assign f_isbranch = ~fd_reg_valid ? f_isbranch_reg :
								  // d_isbranch;

// always @(posedge clk) begin
	// if(fd_reg_valid) begin
		// f_sig_branch_reg <= d_sig_branch;
		// f_isbranch_reg <= d_isbranch;
	// end
// end

mux_branch pc_mux(
	f_sig_branch,
	f_isbranch,
	f_pc+3'h4,
	d_16_target,
	d_branch_src1,
	d_26_target,
	pre_f_branch_pc
);

assign pre_f_stall = iram_stall & ~sig_inter_occur;
assign pre_to_f_valid = 1'b1;
reg_pre_f pipe_pre_f(
	.clk                (clk                 ),
	.reset              (to_f_reset          ),
	.cur_stall          (pre_f_stall         ),
	.cur_allowin        (pre_f_allowin       ),
	.reg_valid          (pre_f_reg_valid     ),
	.pre_valid          (pre_to_f_valid      ),
	.post_allowin       (fd_allowin          ),
	.goon_valid         (f_to_d_valid        ),
	
	.pre_pc             (pre_f_pc            ),
	
	.pc                 (f_pc                )	
);

always @(posedge clk) begin
	if(reset) begin
		iram_wait <= 1'b0;
		iram_exc_wait <= 1'b0;
	end
	else begin
		if(iram_addr_ok)
			iram_wait <= 1'b1;
		if(inst_data_ok) begin
			iram_wait <= 1'b0;
			iram_exc_wait <= 1'b0;
		end
		
		if(iram_stall & sig_exc_occur)
			iram_exc_wait <= 1'b1;
	end
end

assign inst_req = ~iram_wait & pre_f_reg_valid & ~f_is_exc;

assign iram_addr_ok = inst_req & inst_addr_ok;
assign iram_data_ok = inst_data_ok & (~iram_exc_wait);
assign iram_stall = (inst_req | iram_wait) & ~iram_data_ok;

assign inst_wr = 1'b0;
assign inst_size = 2'b10;
assign inst_addr = f_pc;
assign inst_wdata = 32'b0;
assign f_inst = inst_rdata;
// fetch2decode
reg_pipeline_full_stage pipe_f_d(
	.clk                (clk             ),
	.reset              (fd_reset        ),
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

// decode
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
	.is_valid          (fd_reg_valid    ),
	.instruct          (d_inst          ), 
	.out_sig_branch    (d_sig_branch    ), 
	.out_sig_regdst    (d_sig_regdst    ), 
	.out_sig_alusrc    (d_sig_alusrc    ), 
	.out_sig_aluop     (d_sig_aluop     ), 
	.out_sig_memen     (d_sig_memen     ), 
	.out_sig_memtoreg  (d_sig_memtoreg  ), 
	.out_sig_regen     (d_sig_regen     ),
	.out_sig_brjudge   (d_sig_brjudge   ),
	.out_sig_shamt     (d_sig_shamt     ),
	.out_sig_hilo_rwen (d_sig_hilo_rwen ),
	.out_sig_mul_sign  (d_sig_mul_sign  ),
	.out_sig_div       (d_sig_div       ),
	.out_sig_exc       (d_sig_exc       ),
	.out_sig_exc_cmd   (d_sig_exc_cmd   ),
	.out_sig_ri_exc    (d_ri_exc        )
	);

assign d_pc4 = d_pc+3'h4;
assign d_pc8 = d_pc+4'h8;

jump_16 jump16(
	d_imm                             ,
	d_pc4                             ,
	d_extend                          ,
	d_0extend                         ,
	d_16_target	
	);
	
jump_26 jump26(	
	d_index                           ,
	d_pc8[31:28]                      ,
	d_26_target                       
	);

regfile regfile(
	clk                               ,
	d_rs                              ,
	d_rd1                             ,
	d_rt                              ,
	d_rd2                             ,
	w_wreg_en                         ,
	w_wreg_addr                       ,
	w_wreg_data
	);
	
reg_hilo reg_hilo(
	clk,
	w_sig_hilo_rwen[1:0],
	w_muldiv_res[63:32],
	w_muldiv_res[31: 0],
	w_wreg_data,
	d_hi,
	d_lo
);

// forward1__hilo__0 mux
mux3_32 d_forward1_reg_mux(
	d_forwardAD,
	d_rd1,
	w_wreg_data,
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
    d_forward1_hilo	
);

assign d_reg_hilo_0 = d_sig_exc == `EXC_MTC0;
mux2_32 d_forward1_hilo_0_mux(
	d_reg_hilo_0,
	d_forward1_hilo,
	32'b0,
	d_branch_src1
);

// forward2__0__cp0 mux
mux3_32 d_forward2_mux(
	d_forwardBD,
	d_rd2,
	w_wreg_data,
	m_alu_pc8,
	d_forward2_reg
	);

assign d_compare_0 = d_sig_brjudge == `BRJUDGE_MORETHAN || d_sig_brjudge == `BRJUDGE_LESSTHAN ||
					 d_sig_brjudge == `BRJUDGE_N_MORE   || d_sig_brjudge == `BRJUDGE_N_LESS ;
mux2_32 d_forward2_0_mux(
	d_compare_0,
	d_forward2_reg,
	32'b0,
	d_forward2_0
);

assign d_reg_cp0 = d_sig_exc == `EXC_MFC0;
mux2_32 d_forward2_0_cp0_mux(
	d_reg_cp0,
	d_forward2_0,
	d_cp0_data,
	d_branch_src2
);

// judge branch or not
branch_judge branch_judge(
	d_sig_brjudge,
	d_branch_src1,
	d_branch_src2,
	d_isbranch
	);

// decode2execute
reg_pipeline_full_stage pipe_d_e(
	.clk                (clk             ),
	.reset              (de_reset        ),
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
	.pre_sig_exc        (d_sig_exc       ),
	.pre_sig_exc_cmd    (d_sig_exc_cmd   ),

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
	.sig_div            (e_sig_div       ),
	.sig_exc            (e_sig_exc       ),
	.sig_exc_cmd        (e_sig_exc_cmd   )
	);
// execute
assign e_alu_reg_src1 = e_rd1;
assign e_alu_reg_src2 = e_rd2;

mux3_5 regdst_mux(
	e_sig_regdst,
	e_rt,
	e_rd,
	`REG_RA,
	e_regdstaddr
	);
	
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
	e_div_complete
);
	
alu alu(
	e_sig_aluop,
	e_alu_src1,
	e_alu_src2,
	e_alu_res
	);
	
// execute2memory
assign em_stall = dram_stall;

reg_pipeline_full_stage pipe_e_m(
	.clk                    (clk              ),
	.reset                  (em_reset         ),
	.cur_stall              (em_stall         ),
	.cur_allowin            (em_allowin       ),
	.reg_valid              (em_reg_valid     ),
	.pre_valid              (e_to_m_valid     ),
	.post_allowin           (mw_allowin       ),
	.goon_valid             (m_to_w_valid     ),
	
	.pre_pc                 (e_pc             ),
	.pre_wreg_addr          (e_regdstaddr     ),
	.pre_alu_res            (e_alu_res        ),
	.pre_data_write_mem     (e_alu_reg_src2   ),
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
	.pre_sig_exc            (e_sig_exc        ),
	.pre_sig_exc_cmd        (e_sig_exc_cmd    ),
						   
	.sig_regdst             (m_sig_regdst     ),
	.sig_memen              (m_sig_memen      ),
	.sig_memtoreg           (m_sig_memtoreg   ),
	.sig_regen              (m_sig_regen      ),
	.sig_branch             (m_sig_branch     ),
	.sig_hilo_rwen          (m_sig_hilo_rwen  ),
	.sig_div                (m_sig_div        ),
	.sig_exc                (m_sig_exc        ),
	.sig_exc_cmd            (m_sig_exc_cmd    )
	);


//memory
wire        m_wmem_en;
wire        mem_wen;
wire [31:0] m_addr1;
wire [31:0] m_addr2;
wire [31:0] m_data1;
wire [31:0] m_data2;
wire [ 1:0] m_size1;
wire [ 1:0] m_size2;
reg  [ 1:0] joint_cmd_reg;
wire        joint_stall;


memory_in_mux_axi m_memin_mux(
	.sig_memen            (m_sig_memen),
	.data_in              (m_mem_data),
	.addr_in              (m_alu_res),
	
	.out_data1            (m_data1),	
	.out_addr1            (m_addr1),
	.out_size1            (m_size1),
	 
	.out_data2            (m_data2),
	.out_addr2            (m_addr2),
	.out_size2            (m_size2),
	
	.en                   (m_wmem_en)
);

always @(posedge clk) begin
	if(reset) begin
		dram_wait <= 1'b0;
		joint_cmd_reg <= 2'd0;
	end
	else begin
		if((m_sig_memen == `MEMEN_JOIN_L || m_sig_memen == `MEMEN_JOIN_R) && m_size2 != 2'b10 && joint_cmd_reg == 2'd0)
			joint_cmd_reg = 2'd2;
			
		if(dram_addr_ok)
			dram_wait <= 1'b1;
		if(dram_data_ok) begin
			dram_wait <= 1'b0;
			if(joint_cmd_reg == 2'd2)
				joint_cmd_reg <= 2'd1;
			else if(joint_cmd_reg == 2'd1)
				joint_cmd_reg <= 2'd0;
		end
	end
end

assign mem_wen = m_wmem_en & ~em_en_disable;

assign data_req = ~dram_wait & (m_sig_memtoreg != `REG_FROM_ALU | mem_wen) & em_reg_valid & ~m_is_exc;
assign dram_addr_ok = data_req & data_addr_ok;
assign dram_data_ok = data_data_ok;

assign data_wr = mem_wen;
assign data_size = m_sig_memtoreg == `REG_FROM_BYTE_S || m_sig_memtoreg == `REG_FROM_BYTE_U ? 2'b00 :
				   m_sig_memtoreg == `REG_FROM_HALF_S || m_sig_memtoreg == `REG_FROM_HALF_U ? 2'b01 :
				   (m_sig_memen == `MEMEN_JOIN_L || m_sig_memen == `MEMEN_JOIN_R) && joint_cmd_reg == 2'd1 ? m_size2 :
																									         m_size1 ;
assign data_addr = (m_sig_memen == `MEMEN_JOIN_L || m_sig_memen == `MEMEN_JOIN_R) && joint_cmd_reg == 2'd1 ? m_addr2 :
																								             m_addr1 ;
assign data_wdata = (m_sig_memen == `MEMEN_JOIN_L || m_sig_memen == `MEMEN_JOIN_R) && joint_cmd_reg == 2'd1 ? m_data2 :
																									          m_data1 ;
assign m_mem_data_read = data_rdata;
assign joint_stall = joint_cmd_reg == 2'd1 && dram_data_ok ? 1'b0 :
									 joint_cmd_reg != 2'd0 ? 1'b1 :
															 1'b0 ;
assign dram_stall = (data_req | dram_wait) & ~dram_data_ok | joint_stall;

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

// memory2writeback
assign mw_stall = 1'b0;
reg_pipeline_full_stage pipe_m_w(
	.clk                (clk             ),
	.reset              (mw_reset        ),
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
	.wreg_addr          (w_wreg_addr     ),
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
	.pre_sig_exc        (m_sig_exc       ),

	.sig_memtoreg       (w_sig_memtoreg  ),
	.sig_regen          (w_sig_regen     ),
	.sig_branch         (w_sig_branch    ),
	.sig_hilo_rwen      (w_sig_hilo_rwen ),
	.sig_exc            (w_sig_exc       )
	);

// writeback
assign w_wreg_en = w_sig_regen & (~sig_exc_occur);
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
	w_wreg_data
);

// hazard
hazard hazard(
	d_rs              , 
	d_rt              ,
	e_rs              ,
	e_rt              ,
	e_regdstaddr      ,
	m_reg_addr        ,
	w_wreg_addr       ,
	
	fd_reg_valid      ,
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
	hazard_stall      
);

mul_div_hazard mul_div_hazard(
	clk               ,
	de_reset          ,
	
	e_sig_div         ,
	e_div_complete    ,
	
	fd_reg_valid      ,
	de_reg_valid      ,
	em_reg_valid      ,
	
	d_sig_hilo_rwen[3:2] ,
	e_sig_hilo_rwen[3:2] ,
	e_sig_hilo_rwen[1:0] ,
	m_sig_hilo_rwen[1:0] ,
	w_sig_hilo_rwen[1:0] ,
	
	d_forwardAD_hilo  ,
	
	hazard_div_stall  ,
	hazard_div_relation_stall
);

assign fd_stall = hazard_stall | hazard_div_relation_stall | (iram_stall & ~sig_inter_occur);
assign de_stall = hazard_div_stall;

//////////////////////////////// exception and interrupt module ///////////////////////////////////
// f stage
assign f_adel_exc = f_pc[1:0] != 2'b00;
assign f_is_exc = f_adel_exc;
assign f_excCode = f_adel_exc ? `ExcCode_AdEL :
								`ExcCode_RESERVE ;
assign f_is_in_ds = d_sig_branch != `BRANCH_PC4;
assign f_is_eret = 1'b0;
// fd stage
CP0_reg_pipeline fd_cp0(
	.clk                (clk             ),
	.reset              (fd_reset        ),
	.cur_stall          (fd_stall        ),
	.pre_valid          (f_to_d_valid    ),
	.post_allowin       (de_allowin      ),
	.reg_valid          (fd_reg_valid    ),
	
	.cur_pc             (f_pc            ),
	.cur_badvaddr       (f_pc            ),
	.cur_excCode        (f_excCode       ),
	.cur_is_exc         (f_is_exc        ),
	.cur_is_in_ds       (f_is_in_ds      ),
	.cur_is_eret        (f_is_eret       ),
	
	.pre_pc             (                    ),
	.pre_badvaddr       (                    ),
	.pre_excCode        (`ExcCode_RESERVE    ),
	.pre_is_exc         (1'b0                ),
	.pre_is_in_ds       (1'b0                ),
	.pre_is_eret        (1'b0                ),
	
	.pc                 (fd_pc           ),
	.badvaddr           (fd_badvaddr     ),
	.excCode            (fd_excCode      ),
	.is_exc             (fd_is_exc       ),
	.is_in_ds           (fd_is_in_ds     ),
	.is_eret            (fd_is_eret      ),
	
	.en_disable         (fd_en_disable   )
);
// d stage
assign d_sys_exc = d_sig_exc == `EXC_SYS;
assign d_brk_exc = d_sig_exc == `EXC_BRK;
assign d_eret_exc = d_sig_exc == `EXC_ERET;

assign d_is_exc = d_sys_exc || d_brk_exc || d_eret_exc || d_ri_exc;
assign d_excCode = d_sys_exc ? `ExcCode_Sys :
				   d_brk_exc ? `ExcCode_Bp  :
				   d_ri_exc  ? `ExcCode_RI  :
						   `ExcCode_RESERVE ;

assign d_is_in_ds = e_sig_branch != `BRANCH_PC4 | d_is_in_ds_reg;
assign d_is_eret = d_eret_exc;
// de stage
CP0_reg_pipeline de_cp0(
	.clk                (clk             ),
	.reset              (de_reset        ),
	.cur_stall          (de_stall        ),
	.pre_valid          (d_to_e_valid    ),
	.post_allowin       (em_allowin      ),
	.reg_valid          (de_reg_valid    ),
	
	.cur_pc             (d_pc            ),
	.cur_badvaddr       (                ),
	.cur_excCode        (d_excCode       ),
	.cur_is_exc         (d_is_exc        ),
	.cur_is_in_ds       (d_is_in_ds      ),
	.cur_is_eret        (d_is_eret       ),
	
	.pre_pc             (fd_pc           ),
	.pre_badvaddr       (fd_badvaddr     ),
	.pre_excCode        (fd_excCode      ),
	.pre_is_exc         (fd_is_exc       ),
	.pre_is_in_ds       (fd_is_in_ds     ),
	.pre_is_eret        (fd_is_eret      ),
	
	.pc                 (de_pc           ),
	.badvaddr           (de_badvaddr     ),
	.excCode            (de_excCode      ),
	.is_exc             (de_is_exc       ),
	.is_in_ds           (de_is_in_ds     ),
	.is_eret            (de_is_eret      ),
	
	.en_disable         (de_en_disable   )
);
// e stage
assign e_ov_exc = (e_sig_exc_cmd[0] || e_sig_exc_cmd[1] ) && e_alu_src1[31] == e_alu_src2[31] && e_alu_res[31] != e_alu_src1[31] ||
				  e_sig_exc_cmd[2] && e_alu_src1[31] != e_alu_src2[31] && e_alu_res[31] == e_alu_src2[31];
assign e_excCode = e_ov_exc ? `ExcCode_Ov :
						 `ExcCode_RESERVE ;
assign e_is_exc = e_ov_exc;
assign e_is_in_ds = m_sig_branch != `BRANCH_PC4 | e_is_in_ds_reg;
assign e_is_eret = 1'b0;
// em stage
CP0_reg_pipeline em_cp0(
	.clk                (clk             ),
	.reset              (em_reset        ),
	.cur_stall          (em_stall        ),
	.pre_valid          (e_to_m_valid    ),
	.post_allowin       (mw_allowin      ),
	.reg_valid          (em_reg_valid    ),
	
	.cur_pc             (e_pc            ),
	.cur_badvaddr       (e_alu_res       ),
	.cur_excCode        (e_excCode       ),
	.cur_is_exc         (e_is_exc        ),
	.cur_is_in_ds       (e_is_in_ds      ),
	.cur_is_eret        (e_is_eret       ),
	
	.pre_pc             (de_pc           ),
	.pre_badvaddr       (de_badvaddr     ),
	.pre_excCode        (de_excCode      ),
	.pre_is_exc         (de_is_exc       ),
	.pre_is_in_ds       (de_is_in_ds     ),
	.pre_is_eret        (de_is_eret      ),
	
	.pc                 (em_pc           ),
	.badvaddr           (em_badvaddr     ),
	.excCode            (em_excCode      ),
	.is_exc             (em_is_exc       ),
	.is_in_ds           (em_is_in_ds     ),
	.is_eret            (em_is_eret      ),
	
	.en_disable         (em_en_disable   )
);
// m stage
assign m_adel_exc = ((m_sig_exc_cmd[3] && m_alu_res[1:0] != 2'b00) || 
					((m_sig_exc_cmd[4] || m_sig_exc_cmd[5]) && m_alu_res[0] != 1'b0)) &&
					em_reg_valid; 
assign m_ades_exc = ((m_sig_exc_cmd[6] && m_alu_res[1:0] != 2'b00) ||
					(m_sig_exc_cmd[7] && m_alu_res[0] != 1'b0)) &&
					em_reg_valid;
assign m_excCode = m_adel_exc ? `ExcCode_AdEL :
				   m_ades_exc ? `ExcCode_AdES :
				             `ExcCode_RESERVE ;
assign m_is_exc = m_adel_exc | m_ades_exc;
assign m_is_in_ds = w_sig_branch != `BRANCH_PC4 | m_is_in_ds_reg;
assign m_is_eret = 1'b0;
// mw stage
CP0_reg_pipeline mw_cp0(
	.clk                (clk             ),
	.reset              (mw_reset        ),
	.cur_stall       	(mw_stall        ),
	.pre_valid          (m_to_w_valid    ),
	.post_allowin       (1'b1            ),
	.reg_valid          (mw_reg_valid    ),
	
	.cur_pc             (m_pc            ),
	.cur_badvaddr       (m_alu_res       ),
	.cur_excCode        (m_excCode       ),
	.cur_is_exc         (m_is_exc        ),
	.cur_is_in_ds       (m_is_in_ds      ),
	.cur_is_eret        (m_is_eret       ),
	
	.pre_pc             (em_pc           ),
	.pre_badvaddr       (em_badvaddr     ),
	.pre_excCode        (em_excCode      ),
	.pre_is_exc         (em_is_exc       ),
	.pre_is_in_ds       (em_is_in_ds     ),
	.pre_is_eret        (em_is_eret      ),
	
	.pc                 (mw_pc           ),
	.badvaddr           (mw_badvaddr     ),
	.excCode            (mw_excCode      ),
	.is_exc             (mw_is_exc       ),
	.is_in_ds           (mw_is_in_ds     ),
	.is_eret            (mw_is_eret      ),
	
	.en_disable         (mw_en_disable   )
);
// w stage
assign cp0_wen = w_sig_exc == `EXC_MTC0;
CP0 CP0(
	.clk                (clk                        ),
	.reset              (mw_reset                   ),
	.reg_valid          (mw_reg_valid               ),
	
	.cur_pc             (f_pc                       ),
	.cur_is_in_ds       (f_is_in_ds                 ),
	
	.pre_pc             (mw_pc                      ),
	.pre_badvaddr       (mw_badvaddr                ),
	.pre_excCode        (mw_excCode                 ),
	.pre_is_exc         (mw_is_exc                  ),
	.pre_is_in_ds       (mw_is_in_ds                ),
	.pre_is_eret        (mw_is_eret                 ),
	
	.pc                 (exc_pc                     ),
	.exc_occur          (sig_exc_occur              ),
	.inter_occur        (sig_inter_occur            ),
	
	.wen                (cp0_wen                    ),
	.waddr              (w_wreg_addr                ),
	.wdata              (w_wreg_data                ),
	.raddr              (d_rd                       ),
	.rdata              (d_cp0_data                 )
);

mux2_32 branch_exc_pc_mux(
	sig_exc_occur,
	pre_f_branch_pc,
	exc_pc,
	pre_f_pc
);

assign to_f_reset = reset | de_en_disable | em_en_disable | mw_en_disable ;
assign fd_reset   = reset | de_en_disable | em_en_disable | mw_en_disable | sig_inter_occur ;
assign de_reset   = reset | em_en_disable | mw_en_disable;
assign em_reset   = reset | mw_en_disable ;
assign mw_reset   = reset ;

//reset
always @(posedge clk) reset <= ~resetn;
//debug signal
assign debug_wb_pc = w_pc;
assign debug_wb_rf_wen = w_wreg_en==1'b1 ? 4'b1111 : 4'b0000;
assign debug_wb_rf_wnum = w_wreg_addr;
assign debug_wb_rf_wdata = w_wreg_data;

endmodule