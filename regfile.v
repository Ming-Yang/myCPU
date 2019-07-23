module regfile(
	input         clk,
    // READ PORT 1
	input  [ 4:0] raddr1,
	output [31:0] rdata1,
    // READ PORT 2
	input  [ 4:0] raddr2,
	output [31:0] rdata2,
    // WRITE PORT
	input         we,       //write enable, HIGH valid
	input  [ 4:0] waddr,
	input  [31:0] wdata
	);
	reg [31:0] rf[31:0]; //32个32位的寄存器， 读的潜伏期是0。
//WRITE
always @(posedge clk) 
	begin
		if (we) rf[waddr]<= wdata;
end

//READ OUT 1
assign rdata1 = (raddr1==5'b0) ? 32'b0 : rf[raddr1];
//READ OUT 2
assign rdata2 = (raddr2==5'b0) ? 32'b0 : rf[raddr2];

endmodule

module reg_hilo(
	input         clk,
	input  [ 1:0] wen,
	input  [31:0] hi_in,
	input  [31:0] lo_in,
	input  [31:0] alu_in,
	
	output [31:0] hi_out,
	output [31:0] lo_out
	);
reg [31:0] reg_hi;
reg [31:0] reg_lo;
	
assign hi_out = reg_hi;
assign lo_out = reg_lo;
always @(posedge clk) begin
	if(wen == 2'b11) begin
		reg_hi <= hi_in;
		reg_lo <= lo_in;
	end
	else begin
		if(wen[1])
			reg_hi <= alu_in;
		else if(wen[0])
			reg_lo <= alu_in;
	end
	
end


endmodule