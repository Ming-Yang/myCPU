`include "defines.h"

module mux2_5(
	input         sel,
	input  [ 4:0] data0,
	input  [ 4:0] data1,
	output [ 4:0] outdata
);
assign outdata = sel==1'b0 ? data0:data1;
endmodule

module mux3_5(
	input  [ 1:0] sel,
	input  [ 4:0] data0,
	input  [ 4:0] data1,
	input  [ 4:0] data2,
	output [ 4:0] outdata
);
assign outdata = sel==2'b00 ? data0:
				 sel==2'b01 ? data1:
							  data2;
endmodule

module mux2_32(
	input         sel,
	input  [31:0] data0,
	input  [31:0] data1,
	output [31:0] outdata
);
assign outdata = sel==1'b0 ? data0:data1;
endmodule

module mux2_64(
	input         sel,
	input  [63:0] data0,
	input  [63:0] data1,
	output [63:0] outdata
);
assign outdata = sel==1'b0 ? data0:data1;
endmodule

module mux3_32(
	input  [ 1:0] sel,
	input  [31:0] data0,
	input  [31:0] data1,
	input  [31:0] data2,
	output [31:0] outdata
);
assign outdata = sel==2'b00 ? data0:
				 sel==2'b01 ? data1:
							  data2;
endmodule

module mux4_32(
	input  [ 1:0] sel,
	input  [31:0] data0,
	input  [31:0] data1,
	input  [31:0] data2,
	input  [31:0] data3,
	output [31:0] outdata
);
assign outdata = sel==2'b00 ? data0:
				 sel==2'b01 ? data1:
				 sel==2'b10 ? data2:
							  data3;

endmodule

module mux_RD(
	input  [ 1:0] forwardAD,
	input  [ 2:0] forward_hilo,
	input  [31:0] d_rd1,
	input  [31:0] w_reg_data,
	input  [31:0] m_alu_pc8,
	input  [31:0] d_hi,
	input  [31:0] d_lo,
	input  [31:0] w_hi,
	input  [31:0] w_lo,
	output [31:0] res
);
assign res = forward_hilo == `FORWARD_W_HI ? w_hi :
             forward_hilo == `FORWARD_W_LO ? w_lo :
             forward_hilo == `FORWARD_D_HI ? d_hi :
             forward_hilo == `FORWARD_D_LO ? d_lo :
			 forward_hilo == `FORWARD_ALU  ? w_reg_data :
			 forward_hilo == 3'b0 && forwardAD == `MUX_FORWARD_M2D ? m_alu_pc8 :
			 forward_hilo == 3'b0 && forwardAD == `MUX_FORWARD_W2D ? w_reg_data :
			 forward_hilo == 3'b0 && forwardAD == `MUX_FORWARD_NO  ? d_rd1 :
			 d_rd1 ;
endmodule

module mux_branch(
    input         valid,
	input  [ 1:0] sel,
	input         branch,
	input  [31:0] pc4,  
	input  [31:0] imm,  
	input  [31:0] breg, 
	input  [31:0] index,
	output [31:0] target
	);
assign target  = valid==1'b0                 ? pc4:
                 sel==`BRANCH_INDEX          ? index:
				 sel==`BRANCH_REG            ? breg:
				 sel==`BRANCH_IMM && branch  ? imm:
					  	                       pc4;	
endmodule
	

module extend(
	input         is_signed,
	input  [15:0] data_in,
	output [31:0] data_out
);
wire [15:0] extend_sign;
assign extend_sign = data_in[15] == 1'b0 ? 16'h0000 :
										   16'hffff ;
assign data_out = is_signed == !`EXTEND_SIGNED ? {16'b0,data_in}:
												 {extend_sign,data_in};
									  
endmodule
									
module left_shifter2(
	input  [31:0] in,
	output [31:0] out
);
assign out = in << 2;
endmodule

module jump_16(
	input  [15:0] imm,
	input  [31:0] pc4,
	output [31:0] extend_res,
	output [31:0] target
	);
wire [31:0] extended;
wire [31:0] branch;
assign extend_res = extended;
extend sign_extend(
	`EXTEND_SIGNED,
	imm,
	extended
	);	
left_shifter2 shifter(
	extended,
	branch
	);
assign target = branch+pc4;
endmodule

module jump_26(
	input  [25:0] imm,
	input  [ 3:0] pc_high,
	output [31:0] target
	);
wire [31:0] shift_res;

left_shifter2 shifter(
	{6'b0,imm},
	shift_res
	);
assign target = {pc_high,shift_res[27:0]};
endmodule

module signed_compare(
	input  [31:0] src1,
	input  [31:0] src2,
	output [ 1:0] res
);

assign res = src1[31] == 1'b0 && src2[31] == 1'b0 && src1 < src2 ? `SIGNED_LESS :
             src1[31] == 1'b1 && src2[31] == 1'b1 && src1 > src2 ? `SIGNED_LESS :
			 src1[31] == 1'b1 && src2[31] == 1'b0                ? `SIGNED_LESS :
			 src1 == src2                                    	 ? `SIGNED_EQL  :
																   `SIGNED_MORE ;
endmodule

module branch_judge(
	input  [ 2:0] sig_judge,
	input  [31:0] src1,
	input  [31:0] src2,
	output        res
	);
wire [ 1:0]cmp;
signed_compare compare(
	src1,
	src2,
	cmp
);
assign res = sig_judge ==`BRJUDGE_EQUAL    ?  cmp == `SIGNED_EQL  :
			 sig_judge ==`BRJUDGE_NEQUAL   ?  cmp != `SIGNED_EQL  :
             sig_judge ==`BRJUDGE_MORETHAN ?  cmp == `SIGNED_MORE :
             sig_judge ==`BRJUDGE_LESSTHAN ?  cmp == `SIGNED_LESS :
             sig_judge ==`BRJUDGE_N_MORE   ? (cmp == `SIGNED_LESS || cmp == `SIGNED_EQL) :
             sig_judge ==`BRJUDGE_N_LESS   ? (cmp == `SIGNED_MORE || cmp == `SIGNED_EQL) :
						                                                            1'b0 ;
endmodule

module splice(
	input         lr,
	input  [ 1:0] addr,
	input  [31:0] mem_data,
	input  [31:0] reg_data,
	output [31:0] out_data
);

assign out_data = lr == 1'b0 && addr == 2'd0 ? {mem_data[ 7: 0], reg_data[23: 0]} :
				  lr == 1'b0 && addr == 2'd1 ? {mem_data[15: 0], reg_data[15: 0]} :
				  lr == 1'b0 && addr == 2'd2 ? {mem_data[23: 0], reg_data[ 7: 0]} :
				  lr == 1'b0 && addr == 2'd3 ? {mem_data[31: 0]                 } :
				  lr == 1'b1 && addr == 2'd0 ? {                 mem_data[31: 0]} :
                  lr == 1'b1 && addr == 2'd1 ? {reg_data[31:24], mem_data[31: 8]} :
                  lr == 1'b1 && addr == 2'd2 ? {reg_data[31:16], mem_data[31:16]} :
                  lr == 1'b1 && addr == 2'd3 ? {reg_data[31: 8], mem_data[31:24]} :
																         mem_data ;
endmodule

module memory_out_mux(
	input  [ 2:0] sig_memtoreg,
	input  [31:0] alu_res,
	input  [31:0] mem_data,
	input  [31:0] reg_data,
	input  [31:0] to_reg_data
);

wire [ 1:0] mem_addr;
wire        lr      ;
wire [31:0] splice_data;
wire [ 7:0] byte_data;
wire [15:0] half_data;

assign mem_addr = alu_res[1:0];
assign lr = sig_memtoreg[0];
assign byte_data = (mem_data >> {mem_addr, 3'b0}) & 8'hff;
assign half_data = (mem_data >> {mem_addr, 3'b0}) & 16'hffff;

splice splice(
	lr,
	mem_addr,
	mem_data,
	reg_data,
	splice_data
); 

assign to_reg_data = sig_memtoreg == `REG_FROM_ALU                     ? alu_res                          :
                     sig_memtoreg == `REG_FROM_MEM                     ? mem_data                         :
					 sig_memtoreg == `REG_FROM_BYTE_S                  ? {{24{byte_data[ 7]}}, byte_data} :
                     sig_memtoreg == `REG_FROM_BYTE_U                  ? {24'b0, byte_data}               :
                     sig_memtoreg == `REG_FROM_HALF_S                  ? {{16{half_data[15]}}, half_data} :
					 sig_memtoreg == `REG_FROM_HALF_U                  ? {16'b0, half_data}               :
                     sig_memtoreg == `REG_FROM_JOIN_L                  ? splice_data                      :
                     sig_memtoreg == `REG_FROM_JOIN_R                  ? splice_data                      :
									                                         alu_res                      ;

endmodule

module memory_in_mux(
	input  [ 3:0] sig_memen,
	input         reg_valid,
	input  [31:0] data_in,
	input  [31:0] alu_res,
	output [ 3:0] en,
	output [31:0] data_out,
	output [31:0] addr
);
wire [ 3:0] mem_wen;
wire [31:0] l_data;
wire [31:0] r_data;
wire [31:0] move_data;
wire [ 1:0] low_addr;

assign low_addr = alu_res[1:0];
assign mem_wen = sig_memen == `MEMEN_EN                        ? sig_memen : 
				 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b00 ? 4'b0001 :
                 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b01 ? 4'b0011 :
                 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b10 ? 4'b0111 :
                 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b11 ? 4'b1111 :
				 
				 sig_memen == `MEMEN_JOIN_R && low_addr == 2'b00 ? 4'b1111 :
                 sig_memen == `MEMEN_JOIN_R && low_addr == 2'b01 ? 4'b1110 :
                 sig_memen == `MEMEN_JOIN_R && low_addr == 2'b10 ? 4'b1100 :
                 sig_memen == `MEMEN_JOIN_R && low_addr == 2'b11 ? 4'b1000 :

				 sig_memen == `MEMEN_BYTE && low_addr == 2'b00 ? 4'b0001 :
				 sig_memen == `MEMEN_BYTE && low_addr == 2'b01 ? 4'b0010 :
				 sig_memen == `MEMEN_BYTE && low_addr == 2'b10 ? 4'b0100 :
				 sig_memen == `MEMEN_BYTE && low_addr == 2'b11 ? 4'b1000 :
				 
				 sig_memen == `MEMEN_HALF && low_addr == 2'b00 ? 4'b0011 :
				 sig_memen == `MEMEN_HALF && low_addr == 2'b10 ? 4'b1100 :
				                                                 4'b0000 ;

assign l_data = data_in >> {3'd3-low_addr, 3'b0};
assign r_data = data_in << {low_addr, 3'b0};
assign move_data = data_in << {low_addr, 3'b0};

assign data_out = sig_memen == `MEMEN_JOIN_L ? l_data :
                  sig_memen == `MEMEN_JOIN_R ? r_data :
			      (sig_memen == `MEMEN_BYTE || sig_memen == `MEMEN_HALF) ? move_data :
			                                                                 data_in ;

assign addr = alu_res ;
assign en = mem_wen & {4{reg_valid}};

endmodule