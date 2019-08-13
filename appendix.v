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

module mux6_32(
	input  [ 2:0] sel,
	input  [31:0] data0,
	input  [31:0] data1,
	input  [31:0] data2,
	input  [31:0] data3,
	input  [31:0] data4,
	input  [31:0] data5,
	output [31:0] outdata
);
assign outdata = sel==3'd0 ? data0:
				 sel==3'd1 ? data1:
				 sel==3'd2 ? data2:
				 sel==3'd3 ? data3:
				 sel==3'd4 ? data4:
				             data5;

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
	output [31:0] zextend_res,
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
	
extend z_sign_extend(
	~`EXTEND_SIGNED,
	imm,
	zextend_res
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
	output [31:0] to_reg_data
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

module memory_in_mux_axi(
	input  [ 3:0] sig_memen,
	input  [31:0] data_in,
	input  [31:0] addr_in,
	
	output [31:0] out_addr1,
	output [31:0] out_data1,
	output [ 1:0] out_size1,
						   
	output [31:0] out_data2,
	output [31:0] out_addr2,
	output [ 1:0] out_size2,

	output        en
);
wire [ 1:0] low_addr; 
assign low_addr = addr_in[1:0];

assign out_addr1 = 
					 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b00 ? addr_in :
					 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b01 ? addr_in-2'd1 :
					 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b10 ? addr_in-2'd2 :
                     sig_memen == `MEMEN_JOIN_L && low_addr == 2'b11 ? addr_in-2'd3 :
                                                                            addr_in ;
												 
assign out_data1 = 
                     sig_memen == `MEMEN_JOIN_L && low_addr == 2'b00 ? {24'b0, data_in[31:24]} :
					 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b01 ? {16'b0, data_in[31:16]} :
					 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b10 ? { 8'b0, data_in[31: 8]} :
					 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b11 ?                 data_in :
					 
					 sig_memen == `MEMEN_BYTE || sig_memen == `MEMEN_HALF || sig_memen == `MEMEN_JOIN_R ? data_in << {low_addr, 3'b0} :
					                                                                                                          data_in ;
					 
					 
assign out_size1 = 
					 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b00 ? 2'b00 :
					 sig_memen == `MEMEN_JOIN_L && low_addr == 2'b01 ? 2'b01 :
                     sig_memen == `MEMEN_JOIN_L && low_addr == 2'b10 ? 2'b01 :
                     sig_memen == `MEMEN_JOIN_L && low_addr == 2'b11 ? 2'b10 :
                     
                     sig_memen == `MEMEN_JOIN_R && low_addr == 2'b00 ? 2'b10 :
                     sig_memen == `MEMEN_JOIN_R && low_addr == 2'b01 ? 2'b00 :
                     sig_memen == `MEMEN_JOIN_R && low_addr == 2'b10 ? 2'b01 :
                     sig_memen == `MEMEN_JOIN_R && low_addr == 2'b11 ? 2'b00 :
                     
                     sig_memen == `MEMEN_BYTE                        ? 2'b00 :
					 sig_memen == `MEMEN_HALF                        ? 2'b01 :
																	   2'b10 ;
					 
assign out_addr2 = 	sig_memen == `MEMEN_JOIN_L && low_addr == 2'b10 ? addr_in : 
					sig_memen == `MEMEN_JOIN_R && low_addr == 2'b01 ? addr_in+32'd1 :
																	  addr_in ;
																	  
assign out_data2 =  out_data1 ;
					// sig_memen == `MEMEN_JOIN_L && low_addr == 2'b10 ? {24'b0,data_in[31:24]} : 				 
					// sig_memen == `MEMEN_JOIN_R && low_addr == 2'b01 ? {16'b0,data_in[23:8 ]} : 
																	                 // data_in ; 
																	  
assign out_size2 =  sig_memen == `MEMEN_JOIN_L && low_addr == 2'b10 ? 2'b00 :
					sig_memen == `MEMEN_JOIN_R && low_addr == 2'b01 ? 2'b01 :
																	  2'b10 ;

assign en = sig_memen != 4'b0 ;

endmodule