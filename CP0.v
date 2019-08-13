`include "cp0defines.h"
`include "config.h"

module CP0(
	input         clk           ,
	input         reset         ,
	input         reg_valid     ,
	
	input  [31:0] cur_pc        ,
	input         cur_is_in_ds  ,
	
	input  [31:0] pre_pc        ,
	input  [31:0] pre_badvaddr  ,
	input  [ 4:0] pre_excCode   ,
	input         pre_is_exc    ,
	input         pre_is_in_ds  ,
	input         pre_is_eret   ,
								
	output [31:0] pc            ,
	output        exc_occur     ,
	output        inter_occur   ,
								
	input         wen           ,
	input  [ 4:0] waddr         ,
	input  [31:0] wdata         ,
	input  [ 4:0] raddr         ,
	output [31:0] rdata         
);

wire       is_higher_priority;
wire       pre_exc_occur;
wire       in_exc;

reg        counter;
reg [31:0] rf[31:0]; 

assign in_exc = rf[`Register_Status][`Register_Status_EXL];

CP0_priority_checker CP0_priority_checker(
	pre_excCode,
	rf[`Register_Cause][`Register_Cause_ExcCode],
	is_higher_priority
	);

always @(posedge clk) begin
	if(reset) begin
		rf[`Register_Status] <= `REGISTER_STATUS_INIT;
		rf[`Register_Cause] <= `REGISTER_CAUSE_INIT;
	end
	else begin
		counter <= ~counter;
		if(counter == 1'b1 && !(wen && waddr == `Register_Count))
			rf[`Register_Count] <= rf[`Register_Count] + 1'b1;	
		if(rf[`Register_Compare] == rf[`Register_Count]) begin
			rf[`Register_Cause][`Register_Cause_IP0+3'd7] <= 1'b1;
			rf[`Register_Cause][`Register_Cause_TI] <= 1'b1;
		end
		else
			rf[`Register_Cause][`Register_Cause_IP0+3'd7] <= 1'b0;
		
		if (wen) begin
			rf[waddr] <= wdata;
			if(waddr == `Register_Count)
				counter <= 0;
			if(waddr == `Register_Compare)
				rf[`Register_Cause][`Register_Cause_TI] <= 1'b0;
		end
		
		if(inter_occur) begin
			rf[`Register_Status][`Register_Status_EXL] <= 1'b1;
			rf[`Register_EPC] <= cur_is_in_ds ? cur_pc-3'd4 : cur_pc;
			rf[`Register_Cause][`Register_Cause_ExcCode] <= `ExcCode_Int;
		end
		else if(pre_exc_occur) begin
			if(~pre_is_eret) begin
				rf[`Register_EPC] <= pre_pc;
				rf[`Register_BadVAddr] <= pre_badvaddr;
				rf[`Register_Cause][`Register_Cause_ExcCode] <= pre_excCode;
			end
			rf[`Register_Cause][`Register_Cause_BD] <= pre_is_in_ds;
			rf[`Register_Status][`Register_Status_EXL] <= ~pre_is_eret;
		end
	end
end

assign inter_occur = ~in_exc && 
				     rf[`Register_Status][`Register_Status_IE] == 1'b1 &&
				     (rf[`Register_Cause][`Register_Cause_IP] & rf[`Register_Status][`Register_Status_IM]);
assign pre_exc_occur = reg_valid && pre_is_exc &&
				       (~in_exc || 
                       ( in_exc && (is_higher_priority || pre_is_eret)));
assign exc_occur = pre_exc_occur | inter_occur;

assign rdata = rf[raddr];
assign pc = pre_is_eret ? rf[`Register_EPC] :
				                    `EXC_PC ;
endmodule


module CP0_priority_checker
(
	input  [ 4:0] new_excCode,
	input  [ 4:0] old_excCode,
	
	output higher_priority
);

assign higher_priority = (old_excCode == `ExcCode_RESERVE || old_excCode == `ExcCode_Ov || old_excCode == `ExcCode_Bp || old_excCode == `ExcCode_Sys) && (new_excCode == `ExcCode_AdES) ||
						 (old_excCode == `ExcCode_RESERVE || old_excCode == `ExcCode_RI)                                                              && (new_excCode == `ExcCode_AdES || new_excCode == `ExcCode_Ov || new_excCode == `ExcCode_Bp || new_excCode == `ExcCode_Sys) ||
						 (old_excCode == `ExcCode_RESERVE || old_excCode == `ExcCode_AdEL)                                                            && (new_excCode == `ExcCode_AdES || new_excCode == `ExcCode_Ov || new_excCode == `ExcCode_Bp || new_excCode == `ExcCode_Sys || new_excCode == `ExcCode_RI) ||
						 (old_excCode == `ExcCode_RESERVE || old_excCode == `ExcCode_Int)                                                             && (new_excCode == `ExcCode_AdES || new_excCode == `ExcCode_Ov || new_excCode == `ExcCode_Bp || new_excCode == `ExcCode_Sys || new_excCode == `ExcCode_RI || new_excCode == `ExcCode_AdEL);
						 
endmodule