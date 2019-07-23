module div(
	input         div_clk,
	input         reset,
	input         div,
	input         div_signed,
	input  [31:0] x,
	input  [31:0] y,
	output [31:0] s,
	output [31:0] r,
	output        complete
);

wire [31:0] x_abs;
wire [31:0] y_abs;

wire [63:0] A;
wire [32:0] B;
wire [31:0] S;
wire [31:0] R;
wire [32:0] minus_ans;
wire [ 5:0] count;

reg  [ 5:0] count_reg;
reg  [63:0] A_reg;
reg  [31:0] S_reg;

assign x_abs = div_signed && x[31]==1'b1 ? (~x)+1 :
										        x ;
assign y_abs = div_signed && y[31]==1'b1 ? (~y)+1 :
										        y ;
assign R = A[31:0];
assign B = {1'b0, y_abs};												
assign count = count_reg;												
assign minus_ans = (A_reg>>(6'd32-count)) - B;
												
assign A = minus_ans[32] == 0 ? ((A_reg & (96'hffffffff000000007fffffff>>(count-1))) | ({31'b0,minus_ans}<<(6'd32-count))) :
											                                                                         A_reg ;

assign S = minus_ans[32] == 0 ? (S_reg | (32'b1<<(6'd32-count))) :
					       		                           S_reg ;

always @(posedge div_clk) begin
	if(!reset) begin
		if(div) begin
			if(count == 0) begin
				A_reg <= {31'b0, x_abs};
				S_reg <= 0;
			end
			else begin
				A_reg <= A;
				S_reg <= S;
			end
			count_reg <= count_reg+1'b1;
		end
		else begin
			count_reg <= 0;
		end
	end
end

assign complete = count == 6'd33;

assign s = div_signed && x[31]+y[31] == 1'b1 ? ~S+1 :
												  S ;
												 
assign r = div_signed && x[31] == 1'b1       ? ~R+1 :
											      R ;
endmodule