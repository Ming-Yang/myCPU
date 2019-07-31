`include "cp0defines.h"
`include "config.h"

module CP0(
	input         clk           ,
	input         reset         ,
	input         reg_valid     ,							
	
	input  [31:0] cur_pc        ,
	
	input  [31:0] pre_pc        ,
	input  [31:0] pre_badvaddr  ,
	input  [ 4:0] pre_excCode   ,
	input         pre_is_exc    ,
	input         pre_is_in_ds  ,
	input         pre_is_eret   ,
								
	output [31:0] pc            ,
	output        exc_occur     ,
	output        inter_occur   ,
	output        inter___      ,
	
	output [31:0] Status        ,
	output [31:0] Cause         ,
	output [31:0] EPC           ,
								
	input         wen           ,
	input  [ 4:0] waddr         ,
	input  [31:0] wdata         ,
	input  [ 4:0] raddr         ,
	output [31:0] rdata         
);

wire       is_higher_priority;
wire       pre_exc_occur;

reg        counter;
reg        counter_stop;
reg [31:0] rf[31:0]; 
reg        reg_inter;
reg        reg_inter___;

assign inter___    = reg_inter___;
assign inter_occur = in_inter == 1'b1 && reg_inter == 1'b0;
assign in_inter    = rf[`Register_Status][`Register_Status_EXL] == 1'b0 &&
				     rf[`Register_Status][`Register_Status_IE] == 1'b1 &&
				     (rf[`Register_Cause][`Register_Cause_IP] & rf[`Register_Status][`Register_Status_IM]);

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
	else if(reg_valid)begin
		if (wen) begin
			rf[waddr]<= wdata;
			if(waddr == `Register_Count)
				counter_stop <= 1'b1;
		end
		
		if(pre_exc_occur) begin
			if(rf[`Register_Status][`Register_Status_EXL] == 1'b0)
				rf[`Register_EPC] <= pre_pc;
			rf[`Register_Cause][`Register_Cause_ExcCode] <= pre_excCode;
			rf[`Register_Cause][`Register_Cause_BD] <= pre_is_in_ds;
			rf[`Register_Status][`Register_Status_EXL] <= ~pre_is_eret;
			if(pre_excCode == `ExcCode_AdEL || pre_excCode == `ExcCode_AdES)
				rf[`Register_BadVAddr] <= pre_badvaddr;
		end
		else if(inter_occur) begin
			rf[`Register_Status][`Register_Status_EXL] = 1'b1;
			rf[`Register_EPC] <= cur_pc;
			rf[`Register_Cause][`Register_Cause_ExcCode] <= `ExcCode_Int;
		end
		reg_inter <= in_inter;
		reg_inter___ <= inter_occur;
	end
end


always @(posedge clk) begin
	if(~reset) begin
		if(counter_stop) begin
			counter = 1'b0;
			counter_stop <= 1'b0;
		end
		else begin
			counter <= ~counter;
			if(counter)
				rf[`Register_Count] <= rf[`Register_Count] + 32'b1;
			if(rf[`Register_Compare] == rf[`Register_Count]) begin
				rf[`Register_Cause][`Register_Cause_IP0+3'd7] = 1'b1;
				rf[`Register_Cause][`Register_Cause_TI] = 1'b1;
			end
		end
	end
end

assign rdata = rf[raddr];
assign pc = pre_is_eret ? rf[`Register_EPC] :
				                    `EXC_PC ;



assign pre_exc_occur = reg_valid && pre_is_exc &&
				       ((rf[`Register_Status][`Register_Status_EXL] == 1'b0) || 
                       (rf[`Register_Status][`Register_Status_EXL] == 1'b1 && (is_higher_priority || pre_is_eret)));
assign exc_occur = pre_exc_occur || (reg_valid && inter_occur);


assign Status = rf[`Register_Status] ;
assign Cause = rf[`Register_Cause] ;
assign EPC = rf[`Register_EPC] ;

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