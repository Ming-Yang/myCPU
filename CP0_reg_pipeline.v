`include "cp0defines.h"
`include "config.h"

module CP0_reg_pipeline(
	input         clk                ,                    
	input         reset              ,
	input         cur_stall          ,//暂停当前流水线
	input         pre_valid          ,//前一级有敿
	input         post_allowin       ,//后一级允许输兿
	
	input  [31:0] cur_pc             ,
	input  [31:0] cur_badvaddr       ,
	input  [ 4:0] cur_excCode        ,
	input         cur_is_exc         ,
	input         cur_is_in_ds       ,
	input         cur_is_eret        ,
	
	input  [31:0] pre_pc             ,
	input  [31:0] pre_badvaddr       ,
	input  [ 4:0] pre_excCode        ,
	input         pre_is_exc         ,
	input         pre_is_in_ds       ,
	input         pre_is_eret        ,
	
	output [31:0] pc                 ,
	output [31:0] badvaddr           ,
	output [ 4:0] excCode            ,
	output        is_exc             ,
	output        is_in_ds           ,
	output        is_eret            ,
	
	input         exc_occur          ,
	input  [31:0] cp0_Status         ,
	input  [31:0] cp0_EPC            ,
	output        en_disable         
);
reg  [31:0] reg_pc                   ;
reg  [31:0] reg_badvaddr             ;
reg  [ 4:0] reg_excCode              ;
reg         reg_is_exc               ;
reg         reg_is_in_ds             ;
reg         reg_is_eret              ;
reg  [31:0] reg_cp0_pc               ;

reg        is_valid           ;//当前级有敿
wire       cur_ready_go       ;//当前级准备好发射
wire       cur_allowin        ;

assign pc           =  reg_pc           ;
assign badvaddr     =  reg_badvaddr     ;
assign excCode      =  reg_excCode      ;
assign is_exc       =  reg_is_exc       ;
assign is_in_ds     =  reg_is_in_ds     ;
assign is_eret      =  reg_is_eret      ;

assign cur_ready_go    = !cur_stall;
assign cur_allowin     = !is_valid || (cur_ready_go && post_allowin);

wire       is_higher_priority;
CP0_priority_checker CP0_priority_checker(
	cur_excCode,
	pre_excCode,
	is_higher_priority
	);

always @(posedge clk) begin
	if(reset) begin
		is_valid <= 1'b0;    
	end
	else if(cur_allowin) begin
		is_valid <= pre_valid;                            
	end

	if(pre_valid && cur_allowin) begin
		if(cur_is_exc) begin
			if(cur_is_in_ds)
				reg_pc <= cur_pc - 3'h4;
			else
				reg_pc <= cur_pc;
				
			if(cur_excCode == `ExcCode_AdEL || cur_excCode == `ExcCode_AdES)
				reg_badvaddr <= cur_badvaddr;
			else
				reg_badvaddr <= pre_badvaddr;
			
			if(is_higher_priority)
				reg_excCode <= cur_excCode;
			else
				reg_excCode <= pre_excCode;
			
			reg_is_exc   <= cur_is_exc;
			reg_is_in_ds <= cur_is_in_ds;
			reg_is_eret  <= cur_is_eret;
		end
		else begin
			reg_pc          <=      pre_pc        ;
			reg_badvaddr    <=      pre_badvaddr  ;
			reg_excCode     <=      pre_excCode   ;
			reg_is_exc      <=      pre_is_exc    ;
			reg_is_in_ds    <=      pre_is_in_ds  ;
			reg_is_eret     <=      pre_is_eret   ;
		end	
	end
end

assign en_disable   =  cur_allowin && pre_valid && (cur_is_exc || pre_is_exc);

endmodule
