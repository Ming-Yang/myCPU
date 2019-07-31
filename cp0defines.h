




`define ExcCode_Int   5'h00
`define ExcCode_AdEL  5'h04
`define ExcCode_AdES  5'h05
`define ExcCode_Sys   5'h08
`define ExcCode_Bp    5'h09
`define ExcCode_RI    5'h0a
`define ExcCode_Ov    5'h0c
`define ExcCode_RESERVE 5'h1f

`define Register_BadVAddr 5'd8
`define Register_Count    5'd9
`define Register_Compare  5'd11
`define Register_Status   5'd12
`define Register_Cause    5'd13
`define Register_EPC      5'd14

`define Register_Status_IM0  5'd8
`define Register_Status_IM  5'd15:5'd8
`define Register_Status_EXL 5'd1
`define Register_Status_IE  5'd0

`define Register_Cause_BD 5'd31
`define Register_Cause_TI 5'd30
`define Register_Cause_IP0 5'd8
`define Register_Cause_IP 5'd15:5'd8
`define Register_Cause_ExcCode 5'd6:5'd2

`define REGISTER_STATUS_INIT 32'h40FF01
`define REGISTER_CAUSE_INIT 32'h00007c