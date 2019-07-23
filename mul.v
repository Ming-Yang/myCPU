module one_bit_add
(
	input         A,
	input         B,
	input         Cin,
	output        Cout,
	output        S
);
assign {Cout, S} = A+B+Cin;
endmodule

module one_bit_wallace
	(
		input  [16:0] bit_in,
		input  [13:0] Cin,
		output [13:0] Cout,
		output        C,
		output        S
	);

wire [13:0] wallace_s;

one_bit_add one_bit_add_0  (   bit_in[16],    bit_in[15],   bit_in[14],  Cout[0],  wallace_s[0]);
one_bit_add one_bit_add_1  (   bit_in[13],    bit_in[12],   bit_in[11],  Cout[1],  wallace_s[1]);
one_bit_add one_bit_add_2  (   bit_in[10],     bit_in[9],    bit_in[8],  Cout[2],  wallace_s[2]);
one_bit_add one_bit_add_3  (    bit_in[7],     bit_in[6],    bit_in[5],  Cout[3],  wallace_s[3]);
one_bit_add one_bit_add_4  (    bit_in[4],     bit_in[3],    bit_in[2],  Cout[4],  wallace_s[4]);
one_bit_add one_bit_add_5  ( wallace_s[0],  wallace_s[1], wallace_s[2],  Cout[5],  wallace_s[5]);
one_bit_add one_bit_add_6  ( wallace_s[3],  wallace_s[4],    bit_in[1],  Cout[6],  wallace_s[6]);
one_bit_add one_bit_add_7  (    bit_in[0],        Cin[0],       Cin[1],  Cout[7],  wallace_s[7]);
one_bit_add one_bit_add_8  (       Cin[2],        Cin[3],       Cin[4],  Cout[8],  wallace_s[8]);
one_bit_add one_bit_add_9  ( wallace_s[5],  wallace_s[6], wallace_s[7],  Cout[9],  wallace_s[9]);
one_bit_add one_bit_add_10 ( wallace_s[8],        Cin[5],       Cin[6], Cout[10], wallace_s[10]);
one_bit_add one_bit_add_11 ( wallace_s[9], wallace_s[10],       Cin[7], Cout[11], wallace_s[11]);
one_bit_add one_bit_add_12 (       Cin[8],        Cin[9],      Cin[10], Cout[12], wallace_s[12]);
one_bit_add one_bit_add_13 (wallace_s[11], wallace_s[12],      Cin[11], Cout[13], wallace_s[13]);
one_bit_add one_bit_add_14 (wallace_s[13],       Cin[12],      Cin[13],        C,             S);

endmodule

module booth_encoder(
	input  [63:0] X,
	input  [ 2:0] Y,
	output [63:0] P,
	output        c
	);

`define ZERO  4'd0
`define POS   4'd1
`define NEG   4'd2
`define POS_2 4'd3
`define NEG_2 4'd4
wire [ 2:0] operate;
wire [63:0] data_op;

assign operate = Y==3'd0 ? `ZERO  :
				 Y==3'd1 ? `POS   :
				 Y==3'd2 ? `POS   :
				 Y==3'd3 ? `POS_2 :
				 Y==3'd4 ? `NEG_2 :
				 Y==3'd5 ? `NEG   :
				 Y==3'd6 ? `NEG   :
				 Y==3'd7 ? `ZERO  :
				 `ZERO;
assign data_op = operate == `ZERO   ?  32'b0         :
				 operate == `POS    ?  X             :
				 operate == `NEG    ?  ~X            :
				 operate == `POS_2  ?  (X<<1)        :
				 operate == `NEG_2  ?  ~(X<<1)       :
				                       32'b0         ;
									   
assign c       = operate == `NEG || operate == `NEG_2   ?  1'b1 :
														   1'b0 ;

assign P       = data_op;
endmodule

module adder_64(
	input  [63:0] A,
	input  [63:0] B, 
	input         Cin,
	output [63:0] ans,
	output        Cout
	);
assign {Cout,ans} = A+B+Cin;
endmodule

module mul(
	input         mul_clk,
	input         reset,
	input         mul_signed,
	input  [31:0] x,
	input  [31:0] y,
	output [63:0] result
	);

wire [32:0] x_sign_ext;
wire [32:0] y_sign_ext;
wire [63:0] x_64_ext;

wire [63:0] stage_1_2[16:0];
wire [16:0] stage_1_2_c;

wire [16:0] stage_2_3_pre[63:0];
wire [16:0] stage_2_3_post[63:0];
wire [16:0] stage_2_3_c_pre;
wire [16:0] stage_2_3_c_post;

wire [13:0] wallace_cin[63:0];
wire [13:0] wallace_cout[63:0];

wire [63:0] adder_src_s;
wire [63:0] adder_src_c;

wire [63:0] adder_ans;

reg	 [16:0] stage_reg_data[63:0];
reg  [16:0] stage_reg_c;

reg         valid;

parameter size_booth=17;
parameter size_wallace=64;


//1
assign x_sign_ext = mul_signed ? {x[31], x} :
								 {1'b0,  x} ;
assign y_sign_ext = mul_signed ? {y[31], y} :
								 {1'b0,  y} ;								 
								 
assign x_64_ext = {{31{x_sign_ext[32]}}, x_sign_ext};

generate 
	genvar i;
	
	for(i=0;i<size_booth;i=i+1) begin:booth
		if(i==0)begin
			booth_encoder booth_encoder(
			.X(x_64_ext<<i*2), 
			.Y({y_sign_ext[2*i+1:2*i],1'b0}), 
			.P(stage_1_2[i]),
			.c(stage_1_2_c[i])
			);
		end
		else if(i==size_booth-1)begin
			booth_encoder booth_encoder(
			.X(x_64_ext<<i*2), 
			.Y({y_sign_ext[32],y_sign_ext[2*i:2*i-1]}), 
			.P(stage_1_2[i]),
			.c(stage_1_2_c[i])
			);
		end
		else begin
			booth_encoder booth_encoder(
			.X(x_64_ext<<i*2), 
			.Y(y_sign_ext[2*i+1:2*i-1]), 
			.P(stage_1_2[i]),
			.c(stage_1_2_c[i])
			);
		end
	end
endgenerate
//2
assign stage_2_3_c_pre = stage_1_2_c;
generate
	genvar j;
	
	for(j=0;j<size_wallace;j=j+1) begin:switch
		assign stage_2_3_pre[j] = {stage_1_2[16][j],
								   stage_1_2[15][j],
								   stage_1_2[14][j],
								   stage_1_2[13][j],
								   stage_1_2[12][j],
								   stage_1_2[11][j],
								   stage_1_2[10][j],
								   stage_1_2[ 9][j],
								   stage_1_2[ 8][j],
								   stage_1_2[ 7][j],
								   stage_1_2[ 6][j],
								   stage_1_2[ 5][j],
								   stage_1_2[ 4][j],
								   stage_1_2[ 3][j],
								   stage_1_2[ 2][j],
								   stage_1_2[ 1][j],
								   stage_1_2[ 0][j]};
	end
endgenerate
//2-3
always @(posedge mul_clk) begin
	if(reset)
		valid <= 1'b0;
	else begin
		valid <= 1'b1;
		stage_reg_c <= stage_2_3_c_pre;
		begin:to_reg
			integer m;
			for(m=0;m<size_wallace;m=m+1)
				stage_reg_data[m] <= stage_2_3_pre[m];
		end
	end
end

assign stage_2_3_c_post = stage_reg_c;

generate
	genvar n;
	for(n=0;n<size_wallace;n=n+1) begin:to_next_stage
		assign stage_2_3_post[n] = stage_reg_data[n];
	end
endgenerate
//3	
generate
	genvar k;
	
	for(k=0;k<size_wallace;k=k+1) begin:wallace
		if(k==0) begin
			assign wallace_cin[k]=stage_2_3_c_post[13:0];
		end
		else begin
			assign wallace_cin[k]=wallace_cout[k-1];
		end
		
		if(k==size_wallace-1) begin
			one_bit_wallace wallace(
			.bit_in(stage_2_3_post[k]),
			.Cin(wallace_cin[k]),
			.Cout(wallace_cout[k]),
			.S(adder_src_s[k])
			);
		end
		else begin
			one_bit_wallace wallace(
			.bit_in(stage_2_3_post[k]),
			.Cin(wallace_cin[k]),
			.Cout(wallace_cout[k]),
			.C(adder_src_c[k+1]),
			.S(adder_src_s[k])
			);
		end
	end
endgenerate
//4
adder_64 c_s_adder(
	.A(adder_src_s),
	.B({adder_src_c[63:1],stage_2_3_c_post[14]}),
	.Cin(stage_2_3_c_post[15]),
	.ans(adder_ans)
	);
assign result = adder_ans+stage_2_3_c_post[16];

endmodule