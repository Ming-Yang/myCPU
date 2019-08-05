`include "defines.h"
`include "config.h"

module fetch_reg
(	
	input         clk,
	input         reset,
	
	input         cur_stall          ,//暂停当前流水�?
	input         goon_stall         ,
	output        cur_allowin        ,//当前级允许输�?
	output        reg_valid          ,
	input         pre_valid          ,//前一级有�?
	input         post_allowin       ,//后一级允许输�?
	output	      goon_valid         ,//后一级有�?
	
	input  [31:0] next_pc            ,
	output [31:0] pc
);
reg  [31:0] reg_pc;
reg         is_valid;
wire        cur_ready_go;

assign reg_valid       = is_valid;
assign cur_ready_go    = !cur_stall;
assign cur_allowin     = !(is_valid) || (cur_ready_go && post_allowin);
assign goon_valid      = (is_valid && cur_ready_go);

always @(posedge clk) begin
	if(reset) begin 
		is_valid <= 1'b0;
	end
	else if(cur_allowin) begin
		is_valid <= pre_valid;
	end
	
	if(reset) begin
		reg_pc <= `RESET_PC;
	end
	else if(pre_valid && cur_allowin) begin
		reg_pc <= next_pc;
	end
end

assign pc = reg_pc;

endmodule


module mux_branch(
	input  [ 1:0] sel,
	input         is_branch,
	input  [31:0] pc4,  
	input  [31:0] imm,  
	input  [31:0] breg, 
	input  [31:0] index,
	output [31:0] target
	);
assign target  =
                 sel==`BRANCH_INDEX             ? index:
				 sel==`BRANCH_REG               ? breg:
				 sel==`BRANCH_IMM && is_branch  ? imm:
					  	                          pc4;	
endmodule