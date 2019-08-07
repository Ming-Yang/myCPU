`include "defines.h"

module hazard(
	input [ 4:0] d_rs            , 
	input [ 4:0] d_rt            ,
	input [ 4:0] e_rs            ,
	input [ 4:0] e_rt            ,
	input [ 4:0] e_reg_addr      ,
	input [ 4:0] m_reg_addr      ,
	input [ 4:0] w_reg_addr      ,
	
	input        fd_valid        ,
	input        de_valid        ,
	input        em_valid        ,
	input        mw_valid        ,
	
	input [ 1:0] d_sig_branch    ,
	input        d_sig_div       ,
	input [ 2:0] e_sig_memtoreg  ,
	input [ 1:0] e_sig_regdst    ,
	input        e_sig_regen     ,
	input [ 2:0] m_sig_memtoreg  ,
	input [ 1:0] m_sig_regdst    ,
	input        m_sig_regen     ,
	input        w_sig_regen     ,
	
	output [1:0] forwardAD       ,
	output [1:0] forwardBD       ,
	output [1:0] forwardAE       ,
	output [1:0] forwardBE       ,
	output       stall                     
	);

wire        lw_reg_stall         ;
wire        lw_brach_stall       ;
wire        reg_branch_stall     ;
wire        reg_reg_stall        ;
wire        div_reg_reg_stall    ;

// d-brach e/m-lw
assign lw_brach_stall     = (e_reg_addr != 5'b0 && (e_reg_addr == d_rs || e_reg_addr == d_rt ) && e_sig_memtoreg != `REG_FROM_ALU && d_sig_branch != `BRANCH_PC4 && fd_valid && de_valid) ||
						    (m_reg_addr != 5'b0 && (m_reg_addr == d_rs || m_reg_addr == d_rt ) && m_sig_memtoreg != `REG_FROM_ALU && d_sig_branch != `BRANCH_PC4 && fd_valid && em_valid);

// d-brach e-reg
assign reg_branch_stall   = (e_reg_addr != 5'b0 && (e_reg_addr == d_rs || e_reg_addr == d_rt ) && e_sig_regen    == 1'b1          && d_sig_branch != `BRANCH_PC4 && fd_valid && de_valid);

// div res forward from M stage
assign div_reg_reg_stall  = (e_reg_addr != 5'b0 && (e_reg_addr == d_rs || e_reg_addr == d_rt ) && e_sig_regen    == 1'b1          && d_sig_div    == 1'b1        && fd_valid && de_valid);


/////////////e_forward_mux/////////////////////////
`ifdef _USE_E_FORWARD
assign reg_reg_stall      = 1'b0;
// d-reg e-lw
assign lw_reg_stall       = (e_reg_addr != 5'b0 && (e_reg_addr == d_rs || e_reg_addr == d_rt ) && e_sig_memtoreg != `REG_FROM_ALU && de_valid);
`else
assign reg_reg_stall      = (e_reg_addr != 5'b0 && (e_reg_addr == d_rs || e_reg_addr == d_rt ) && e_sig_regen    == 1'b1          && de_valid);
// d-reg e/m-lw
assign lw_reg_stall       = (e_reg_addr != 5'b0 && (e_reg_addr == d_rs || e_reg_addr == d_rt ) && e_sig_memtoreg != `REG_FROM_ALU && de_valid) ||
                            (m_reg_addr != 5'b0 && (m_reg_addr == d_rs || m_reg_addr == d_rt ) && m_sig_memtoreg != `REG_FROM_ALU && em_valid);
`endif
///////////////////////////////////////////////////

assign stall      = lw_brach_stall || lw_reg_stall || reg_branch_stall || reg_reg_stall || div_reg_reg_stall;

	
assign forwardAD  = (d_rs!= 5'b0 && d_rs == m_reg_addr && m_sig_regen && em_valid) ? `MUX_FORWARD_M2D :
					(d_rs!= 5'b0 && d_rs == w_reg_addr && w_sig_regen && mw_valid) ? `MUX_FORWARD_W2D :
				    `MUX_FORWARD_NO;                                     
	                                                                    
assign forwardBD  = (d_rt!= 5'b0 && d_rt == m_reg_addr && m_sig_regen && em_valid) ? `MUX_FORWARD_M2D :
					(d_rt!= 5'b0 && d_rt == w_reg_addr && w_sig_regen && mw_valid) ? `MUX_FORWARD_W2D :
				    `MUX_FORWARD_NO;	                                   
	                                                                    
assign forwardAE  = (e_rs!= 5'b0 && e_rs == m_reg_addr && m_sig_regen && em_valid) ? `MUX_FORWARD_M2E :
				    (e_rs!= 5'b0 && e_rs == w_reg_addr && w_sig_regen && mw_valid) ? `MUX_FORWARD_W2E :
				    `MUX_FORWARD_NO;	                                   
	                                                                    
assign forwardBE  = (e_rt!= 5'b0 && e_rt == m_reg_addr && m_sig_regen && em_valid) ? `MUX_FORWARD_M2E :
				    (e_rt!= 5'b0 && e_rt == w_reg_addr && w_sig_regen && mw_valid) ? `MUX_FORWARD_W2E :
				    `MUX_FORWARD_NO;
				   
endmodule


module mul_div_hazard(
	input        clk             ,
	input        reset           ,
	
	input        div             ,
	input        div_complete    ,
	
	input        fd_valid        ,
	input        de_valid        ,
	input        em_valid        ,
	
	input  [1:0] d_hilo_r        ,
	input  [1:0] e_hilo_r        ,
	input  [1:0] e_hilo_w        ,
	input  [1:0] m_hilo_w        ,
	input  [1:0] w_hilo_w        ,
	
	output [2:0] hilo_forwardAD  ,
	output [2:0] hilo_forwardAE  ,
	
	output       div_stall       ,
	output       relation_stall
);
//ready to stall, one clk before
wire        div_ready_stall      ;
reg         reg_div_stall        ;

//forward from W stage or get from normal register of get from hilo register
assign hilo_forwardAD = d_hilo_r[0] == 1'b1 && w_hilo_w == 2'b11 ? `FORWARD_W_LO :
					    d_hilo_r[0] == 1'b1 && w_hilo_w == 2'b00 ? `FORWARD_D_LO :
					    d_hilo_r[1] == 1'b1 && w_hilo_w == 2'b11 ? `FORWARD_W_HI :
                        d_hilo_r[1] == 1'b1 && w_hilo_w == 2'b00 ? `FORWARD_D_HI :
					    (d_hilo_r[0] == 1'b1 && w_hilo_w == 2'b01 || d_hilo_r[1] == 1'b1 && w_hilo_w == 2'b10) ? `FORWARD_ALU  :
					    d_hilo_r == 2'b00                        ?`FORWARD_HILO_NO :
					 										      `FORWARD_HILO_NO ;
																			   
assign hilo_forwardAE = e_hilo_r[0] == 1'b1 && w_hilo_w == 2'b11 ? `FORWARD_W_LO :
					    e_hilo_r[0] == 1'b1 && w_hilo_w == 2'b00 ? `FORWARD_D_LO :
					    e_hilo_r[1] == 1'b1 && w_hilo_w == 2'b11 ? `FORWARD_W_HI :
                        e_hilo_r[1] == 1'b1 && w_hilo_w == 2'b00 ? `FORWARD_D_HI :
					    (e_hilo_r[0] == 1'b1 && w_hilo_w == 2'b01 || e_hilo_r[1] == 1'b1 && w_hilo_w == 2'b10) ? `FORWARD_ALU  :
					    e_hilo_r == 2'b00                        ?`FORWARD_HILO_NO :
					 											  `FORWARD_HILO_NO ;																			   
																			   
			 
always @(posedge clk) begin
	if(!reset) begin
		if(div_ready_stall)
			reg_div_stall <= 1;
		if(div_complete)
			reg_div_stall <= 0;
	end
	else
		reg_div_stall <= 0;
end

assign div_ready_stall    = div == 1'b1 && div_complete == 1'b0 && fd_valid && de_valid && ~reset;
//stall for div 33 clk
assign div_stall          = (div_ready_stall || reg_div_stall) && div_complete == 1'b0;  

assign relation_stall     = d_hilo_r && (e_hilo_w && de_valid || m_hilo_w && em_valid);

endmodule