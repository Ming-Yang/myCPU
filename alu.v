module alu(
  input  [ 4:0] sig_aluop,
  input  [31:0] alu_src1,
  input  [31:0] alu_src2,
  output [31:0] alu_result
);

wire [31:0] alu_hotkey;
wire [11:0] alu_op;

decoder_5_32 decoder_5_32(
	sig_aluop,
	alu_hotkey
	);
assign alu_op = alu_hotkey[11:0];

wire op_add;   //加法操作
wire op_sub;   //减法操作
wire op_slt;   //有符号比较，小于置位   
wire op_sltu;  //无符号比较，小于置位
wire op_and;   //按位与
wire op_nor;   //按位或非
wire op_or;    //按位或
wire op_xor;   //按位异或
wire op_sll;   //逻辑左移
wire op_srl;   //逻辑右移
wire op_sra;   //算术右移
wire op_lui;   //立即数置于高半部分

//以上定义的是12种运算，定义了位宽是12的控制位，采用的是独热码的形式
// control code decomposition
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6];
assign op_xor  = alu_op[ 7];
assign op_sll  = alu_op[ 8];
assign op_srl  = alu_op[ 9];
assign op_sra  = alu_op[10];
assign op_lui  = alu_op[11];

wire [31:0] add_sub_result; 
wire [31:0] slt_result; 
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result; 
wire [63:0] sr64_result; 
wire [31:0] sr_result; 

// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

//第一个操作数不动
assign adder_a   = alu_src1;
//如果是减法、有符号比较（减法）无符号比较（减法），第二个操作数按位取反 和adder_cin一起，
//将减法编程加法。
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;

//下面三行执行加法运算

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
//如果RS<RT，则将Rd置1   ???????对应的置位不对，等待仿真  。
assign slt_result[31:1] = 31'b0;
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result       等待仿真  。
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = {alu_src2[15:0], 16'b0};

// SLL result 逻辑左移，
assign sll_result = alu_src2 << alu_src1[4:0];

// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src2[31]}}, alu_src2[31:0]} >> alu_src1[4:0];

assign sr_result   = sr64_result[31:0];

// final result mux
assign alu_result = ({32{op_add|op_sub}} & add_sub_result)
                  | ({32{op_slt       }} & slt_result)
                  | ({32{op_sltu      }} & sltu_result)
                  | ({32{op_and       }} & and_result)
                  | ({32{op_nor       }} & nor_result)
                  | ({32{op_or        }} & or_result)
                  | ({32{op_xor       }} & xor_result)
                  | ({32{op_lui       }} & lui_result)
                  | ({32{op_sll       }} & sll_result)
                  | ({32{op_srl|op_sra}} & sr_result);

endmodule