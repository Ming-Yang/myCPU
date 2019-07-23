//解码器，将二进制数转换成独热码的形式

//输入         输出 
//6'b00_0000   64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0001
//6'b00_0001   64'b0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0000_0010

module decoder_5_32(
    input  [ 4:0] in,
    output [31:0] out
);

genvar i;
generate for (i=0; i<32; i=i+1) begin : gen_for_dec_5_32
    assign out[i] = (in == i);
end endgenerate

endmodule


module decoder_6_64(
    input  [ 5:0] in,
    output [63:0] out
);

genvar i;
generate for (i=0; i<63; i=i+1) begin : gen_for_dec_6_64
    assign out[i] = (in == i);
end endgenerate

endmodule

