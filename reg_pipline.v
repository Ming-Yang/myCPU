//f-d-e-m-w
//pre_x x reg_x 两次赋忿
module reg_pipline_full_stage(
	input         clk                ,                    
	input         reset              ,
	
	input         cur_stall          ,//暂停当前流水线
	input         goon_stall         ,
	output        cur_allowin        ,//当前级允许输入
	output        reg_valid          ,
	input         pre_valid          ,//前一级有效
	input         post_allowin       ,//后一级允许输入
	output	      goon_valid         ,//后一级有效
              
	//input                          
	input  [31:0] pre_instruction    ,                         
	input  [31:0] pre_pc             ,
                                     
	input  [ 4:0] pre_rs             ,                
	input  [ 4:0] pre_rt             ,                
	input  [ 4:0] pre_rd             ,
	input  [ 4:0] pre_shamt          ,
	input  [ 4:0] pre_wreg_addr      ,
	input  [31:0] pre_extend         ,
	input  [31:0] pre_zextend        ,
                                     
	input  [31:0] pre_reg_o1         ,                    
	input  [31:0] pre_reg_o2         ,                    
                                     
	input  [31:0] pre_alu_res        ,                     
	input  [31:0] pre_data_write_mem ,                            
	input  [31:0] pre_data_read_mem  ,

	input  [31:0] pre_hi             ,
	input  [31:0] pre_lo             ,
	input  [63:0] pre_muldiv_res     ,
	input  [63:0] pre_div_res        ,
                                     
	input  [ 1:0] pre_sig_regdst     ,                        
	input  [ 1:0] pre_sig_alusrc     ,                        
	input  [ 4:0] pre_sig_aluop      ,                       
	input  [ 3:0] pre_sig_memen      ,                       
	input  [ 2:0] pre_sig_memtoreg   ,                          
	input         pre_sig_regen      ,
	input  [ 1:0] pre_sig_branch     ,
	input         pre_sig_shamt      ,
	input  [ 3:0] pre_sig_hilo_rwen  ,
	input         pre_sig_mul_sign   ,
	input         pre_sig_div        ,
	input  [ 2:0] pre_sig_exc        ,
	input  [ 7:0] pre_sig_exc_cmd    ,
	                                 
	//output                         
	output [31:0] instruction        ,                         
	output [31:0] pc                 ,
                                     
	output [ 4:0] rs                 ,                
	output [ 4:0] rt                 ,                
	output [ 4:0] rd                 ,
	output [ 4:0] shamt              ,
	output [ 4:0] wreg_addr          ,
	output [31:0] extend             ,
	output [31:0] zextend            ,
                                     
	output [31:0] reg_o1             ,                    
	output [31:0] reg_o2             ,                    
                                     
	output [31:0] alu_res            ,                     
	output [31:0] data_write_mem     ,                            
	output [31:0] data_read_mem      ,
	
	output [31:0] hi                 ,
	output [31:0] lo                 ,
	output [63:0] muldiv_res         ,
	output [63:0] div_res            ,
	         
	output [ 1:0] sig_regdst         ,                        
	output [ 1:0] sig_alusrc         ,                        
	output [ 4:0] sig_aluop          ,                       
	output [ 3:0] sig_memen          ,                       
	output [ 2:0] sig_memtoreg       ,                          
	output        sig_regen          ,
	output [ 1:0] sig_branch         ,
	output        sig_shamt          ,
	output [ 3:0] sig_hilo_rwen      ,
	output        sig_mul_sign       ,
	output        sig_div            ,
	output [ 2:0] sig_exc            ,
	output [ 7:0] sig_exc_cmd    
);                                                  

reg [31:0] reg_instruction    ;                         
reg [31:0] reg_pc             ;      
                              
reg [ 4:0] reg_rs             ;                
reg [ 4:0] reg_rt             ;                
reg [ 4:0] reg_rd             ;
reg [ 4:0] reg_shamt          ;
reg [ 4:0] reg_wreg_addr      ;
reg [31:0] reg_extend         ;  
reg [31:0] reg_zextend        ;              
                              
reg [31:0] reg_reg_o1         ;                    
reg [31:0] reg_reg_o2         ;                    
                      
reg [31:0] reg_alu_res        ;                     
reg [31:0] reg_data_write_mem ;                            
reg [31:0] reg_data_read_mem  ;   

reg [31:0] reg_hi             ;
reg [31:0] reg_lo             ;
reg [63:0] reg_muldiv_res     ;  
reg [63:0] reg_div_res        ;                   
                              
reg [ 1:0] reg_sig_regdst     ;                        
reg [ 1:0] reg_sig_alusrc     ;                        
reg [ 4:0] reg_sig_aluop      ;                       
reg [ 3:0] reg_sig_memen      ;                       
reg [ 2:0] reg_sig_memtoreg   ;                          
reg        reg_sig_regen      ;
reg [ 1:0] reg_sig_branch     ;    
reg        reg_sig_shamt      ;
reg [ 3:0] reg_sig_hilo_rwen  ;
reg        reg_sig_mul_sign   ;
reg        reg_sig_div        ;
reg [ 2:0] reg_sig_exc        ;
reg [ 7:0] reg_sig_exc_cmd    ;
                   
assign instruction     = reg_instruction    ;
assign pc              = reg_pc             ;
                                            
assign rs              = reg_rs             ;
assign rt              = reg_rt             ;
assign rd              = reg_rd             ;
assign shamt           = reg_shamt          ;
assign wreg_addr       = reg_wreg_addr      ;
assign extend          = reg_extend         ;
assign zextend         = reg_zextend        ;
                                            
assign reg_o1          = reg_reg_o1         ;
assign reg_o2          = reg_reg_o2         ;
                                            
assign alu_res         = reg_alu_res        ;
assign data_write_mem  = reg_data_write_mem ;
assign data_read_mem   = reg_data_read_mem  ;

assign hi              = reg_hi             ;
assign lo              = reg_lo             ;
assign muldiv_res      = reg_muldiv_res     ;
assign div_res         = reg_div_res        ;
                                            
assign sig_regdst      = reg_sig_regdst     ;
assign sig_alusrc      = reg_sig_alusrc     ;
assign sig_aluop       = reg_sig_aluop      ;
assign sig_memen       = reg_sig_memen      ;
assign sig_memtoreg    = reg_sig_memtoreg   ;
assign sig_regen       = reg_sig_regen      ;
assign sig_branch      = reg_sig_branch     ;
assign sig_shamt       = reg_sig_shamt      ;
assign sig_hilo_rwen   = reg_sig_hilo_rwen  ;
assign sig_mul_sign    = reg_sig_mul_sign   ;
assign sig_div         = reg_sig_div        ;
assign sig_exc         = reg_sig_exc        ;
assign sig_exc_cmd     = reg_sig_exc_cmd    ;

reg        is_valid           ;//当前级有效
wire       cur_ready_go       ;//当前级准备好发射

assign reg_valid       = is_valid;
assign cur_ready_go    = !cur_stall;
assign cur_allowin     = !(is_valid || goon_stall) || (cur_ready_go && post_allowin);
assign goon_valid      = (is_valid && cur_ready_go);

always @(posedge clk) begin
	if(reset) begin
		is_valid <= 1'b0;                           
	end
	else if(cur_allowin) begin
		is_valid <= pre_valid;                            
	end

	if(pre_valid && cur_allowin) begin
		reg_instruction    <= pre_instruction    ;                                       
	    reg_pc             <= pre_pc             ;
	                                             
	    reg_rs             <= pre_rs             ;                
	    reg_rt             <= pre_rt             ;                
	    reg_rd             <= pre_rd             ;
		reg_shamt          <= pre_shamt          ;
		reg_wreg_addr      <= pre_wreg_addr      ;
		reg_extend         <= pre_extend         ;
		reg_zextend        <= pre_zextend        ;
	                                             
	    reg_reg_o1         <= pre_reg_o1         ;                    
	    reg_reg_o2         <= pre_reg_o2         ;                    
	                                             
	    reg_alu_res        <= pre_alu_res        ;                     
	    reg_data_write_mem <= pre_data_write_mem ;                            
	    reg_data_read_mem  <= pre_data_read_mem  ;
		
		reg_hi             <= pre_hi             ;
		reg_lo             <= pre_lo             ;
		reg_muldiv_res     <= pre_muldiv_res     ;
		reg_div_res        <= pre_div_res        ;
		
	    reg_sig_regdst     <= pre_sig_regdst     ;                        
	    reg_sig_alusrc     <= pre_sig_alusrc     ;                        
	    reg_sig_aluop      <= pre_sig_aluop      ;                       
	    reg_sig_memen      <= pre_sig_memen      ;                       
	    reg_sig_memtoreg   <= pre_sig_memtoreg   ;                          
	    reg_sig_regen      <= pre_sig_regen      ;
		reg_sig_branch     <= pre_sig_branch     ;
		reg_sig_shamt      <= pre_sig_shamt      ;
		reg_sig_hilo_rwen  <= pre_sig_hilo_rwen  ;
		reg_sig_mul_sign   <= pre_sig_mul_sign   ;
		reg_sig_div        <= pre_sig_div        ;
		reg_sig_exc        <= pre_sig_exc        ;
		reg_sig_exc_cmd    <= pre_sig_exc_cmd    ;
	end

end

endmodule