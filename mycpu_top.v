module mycpu_top(
    input         clk,
    input         resetn,
    // inst sram interface
    output        inst_sram_en,
    output [ 3:0] inst_sram_wen,
    output [31:0] inst_sram_addr, //直接assign nextpc
    output [31:0] inst_sram_wdata,
    input  [31:0] inst_sram_rdata,//读取的指令，
    // data sram interface
    output        data_sram_en,
    output [ 3:0] data_sram_wen,
    output [31:0] data_sram_addr,
    output [31:0] data_sram_wdata,
    input  [31:0] data_sram_rdata,
    // trace debug interface
    output [31:0] debug_wb_pc,
    output [ 3:0] debug_wb_rf_wen,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata
);
reg         reset;
always @(posedge clk) reset <= ~resetn;

//五级流水线需要增加控制信号，否则出现数据冲突。

wire [31:0] seq_pc;
wire [31:0] nextpc;
// fs_ -- IF  stage  捕获指令 instruction fetch
wire        fs_allowin;
wire        fs_ready_go;
wire        fs_to_ds_valid;
reg         fs_valid;
reg  [31:0] fs_pc;
wire [31:0] inst;
// ds_ -- ID  stage
wire        ds_stall;
wire        ds_allowin;//可以接受前一级的数据
wire        ds_ready_go;//可以传递到后一级了
wire        ds_to_es_valid;//ready_go && valid
reg         ds_valid;//此级流水线有效，免去清空流水线的开销
reg  [31:0] ds_pc;
reg  [31:0] ds_inst;//指令寄存器
wire [ 5:0] op;
wire [ 4:0] rs;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] sa;
wire [ 5:0] func;
wire [15:0] imm;
wire [25:0] jidx;
wire [63:0] op_d;
wire [31:0] rs_d;
wire [31:0] rt_d;
wire [31:0] rd_d;
wire [31:0] sa_d;
wire [63:0] func_d;
wire        inst_addu;
wire        inst_subu;
wire        inst_slt;
wire        inst_sltu;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_nor;
wire        inst_sll;
wire        inst_srl;
wire        inst_sra;
wire        inst_addiu;
wire        inst_lui;
wire        inst_lw;
wire        inst_sw;
wire        inst_beq;
wire        inst_bne;
wire        inst_jal;
wire        inst_jr;
wire [11:0] alu_op;
wire        src1_is_sa;  
wire        src1_is_pc;
wire        src2_is_imm; 
wire        src2_is_8;
wire        res_from_mem;
wire        dst_is_r31;  
wire        dst_is_rt;   
wire        gr_we;       
wire        mem_we;      
wire [ 4:0] dest;
wire        is_load_op;
wire [ 4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [ 4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire        rs_mch_es_dst;
wire        rt_mch_es_dst;
wire        rs_mch_ms_dst;
wire        rt_mch_ms_dst;
wire        rs_mch_ws_dst;
wire        rt_mch_ws_dst;
wire [31:0] rs_value;
wire [31:0] rt_value;
wire        rs_eq_rt;
wire        br_taken;
wire [31:0] br_target;
// es_ -- EXE stage
wire        es_allowin;
wire        es_ready_go;
wire        es_to_ms_valid;
reg         es_valid;
reg  [31:0] es_pc;
reg  [31:0] es_rs_value;
reg  [31:0] es_rt_value;
reg  [15:0] es_imm;
reg  [11:0] es_alu_op;
reg         es_src1_is_sa;  
reg         es_src1_is_pc;
reg         es_src2_is_imm; 
reg         es_src2_is_8;
reg         es_res_from_mem;
reg         es_gr_we;
reg         es_mem_we;
reg  [ 4:0] es_dest;
reg         es_is_load_op;
wire [31:0] alu_src1;
wire [31:0] alu_src2;
wire [31:0] alu_result;
// ms_ -- MEM stage  访存
wire        ms_allowin;
wire        ms_ready_go;
wire        ms_to_ws_valid;
reg         ms_valid;
reg  [31:0] ms_pc;
reg  [ 4:0] ms_dest;
reg         ms_res_from_mem;
reg         ms_gr_we;
reg  [31:0] ms_alu_result;
wire [31:0] mem_result;
wire [31:0] final_result;
// ws_ -- WB  stage  写回到寄存器
wire        ws_allowin;
wire        ws_ready_go;
reg         ws_valid;
reg  [31:0] ws_pc;
reg         ws_gr_we;
reg  [ 4:0] ws_dest;
reg  [31:0] ws_final_result;
wire        rf_we;
wire [ 4:0] rf_waddr;
wire [31:0] rf_wdata;


//考虑：
//nextpc直接放在指令寄存器的地址写入端口 
//inst_sram_en = to_fs_valid && fs_allowin; 当fs允许指令进来之后，读是0拍，指令马上就出来了
//

// pre-IF stage
assign to_fs_valid  = ~reset;    //就是复位信号 to_fs_valid rst_n 复位之后，可以进入取指级
assign seq_pc = fs_pc + 3'h4;   //c0               //顺序执行时,fs_pc的值加4 
assign nextpc = br_taken ? br_target : seq_pc; //nextpc直接放在指令寄存器的地址写入端口  
//br_taken 判断程序是否跳转还是顺序执行
//br_target 表示跳转的地址

// IF stage（取指）
//取指阶段如果需要多拍（比如除法指令），则在最后一拍拉高，
//如果取指阶段只需要1拍，就直接为1了。
assign fs_ready_go    = 1'b1;//取指阶段只有1拍，为高点平即可

//两个握手信号，
//取指阶段允许下一条指令进入自身的条件：
//空 或者fs准备好了 并且下一级允许
assign fs_allowin     = !fs_valid || fs_ready_go && ds_allowin;

//fs自身可以进入ds的有效信号：
//fs不为空 并且数据已经准备好
assign fs_to_ds_valid = fs_valid && fs_ready_go;

//valid为1表示动作有效，指令在阻塞的时候，该信号也为1，如果本级的数据进入下一级 而上一级的数据还没有传来，则是无效的 
always @(posedge clk) begin
    if (reset) begin
        fs_valid <= 1'b0; 
    end
    else if (fs_allowin) begin
        fs_valid <= to_fs_valid;//fs允许指令进入之后，fs就在执行有效的指令
    end

    if (reset) begin
        fs_pc <= 32'hbfbffffc;  //trick: to make nextpc be 0xbfc00000 during reset 
    end
    else if (to_fs_valid && fs_allowin) begin//
        fs_pc <= nextpc; 
    end
end


assign inst_sram_en    = to_fs_valid && fs_allowin;//指令存储器使能：复位之后，并且fs允许下一条指令进入。
assign inst_sram_wen   = 4'h0;//指令存储器没有写 只控制读
assign inst_sram_addr  = nextpc;//指令存储器的地址
assign inst_sram_wdata = 32'b0;
assign inst            = inst_sram_rdata; //读取的指令
    
// ID stage（译码） （stall表示阻塞）

//阻塞的条件：取字操作（从译码阶段打一拍传到执行阶段）   ???
//执行阶段正在执行有效的指令，并且加载的是取字操作，执行阶段的目的寄存器不是0，且不是无条件跳转指令     //如果目的不是rt，就把译码阶段源当成rt。
assign ds_stall = (es_valid && es_is_load_op && (es_dest!=5'b0) && !inst_jal && (es_dest==rs || (es_dest==rt && !dst_is_rt)));
                                                                    //执行阶段目的寄存器是译码阶段的源寄存器
																	//执行阶段目的寄存器是译码阶段的目标寄存器并且结果不是rt寄存器
assign ds_ready_go    = !ds_stall;

//ds允许fs进入的条件是：ds指令已经执行完毕或者ds指令已经执行到最后一拍了 并且es允许ds进入
assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
//ds自身可以进入下一级的条件是有效指令的执行并且已经执行到最后一拍了。 
assign ds_to_es_valid = ds_valid && ds_ready_go;

always @(posedge clk) begin
    if (reset) begin
        ds_valid <= 1'b0;
    end
    else if (ds_allowin) begin //ds允许fs进入了，
        ds_valid <= fs_to_ds_valid;//ds是否会有有效的执行指令，取决于fs是否进来了，如果进来了 fs_to_ds_valid为1 否则为0。
    end

    if (fs_to_ds_valid && ds_allowin) begin //fs自身能够进入ds 并且ds允许其进入了
        ds_pc   <= fs_pc; 
		
        ds_inst <= inst;//读取到的指令，进行译码。
    end
end

//将读取到的指令分三类进行译码。
assign op   = ds_inst[31:26];//6位
assign rs   = ds_inst[25:21];          //源寄存器  
assign rt   = ds_inst[20:16];          //目标寄存器
assign rd   = ds_inst[15:11];          //计算结果寄存器，比较 置位和复位寄存器
assign sa   = ds_inst[10: 6];          //sa 指定移位量
assign func = ds_inst[ 5: 0];//6位    //func是对寄存器操作时特有的
assign imm  = ds_inst[15: 0];
assign jidx = ds_inst[25: 0];//第2类跳转

decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));//译码的结果变成独热码的形式  
decoder_6_64 u_dec1(.in(func), .out(func_d));
decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(sa  ), .out(sa_d  ));

//assign赋值语句的左边是一位的  op_d[6'h00]中的6表示二进制的位数是6，
//取op_d的第0位，判断独热码                                    //结果存放在：   
assign inst_addu   = op_d[6'h00] & func_d[6'h21] & sa_d[5'h00];//rd            取op_d的第0位，func_d的第33位，sa_d的第0位 如果三者都是1，则是addu指令
assign inst_subu   = op_d[6'h00] & func_d[6'h23] & sa_d[5'h00];//rd            35
assign inst_slt    = op_d[6'h00] & func_d[6'h2a] & sa_d[5'h00];//rd            42
assign inst_sltu   = op_d[6'h00] & func_d[6'h2b] & sa_d[5'h00];//rd       	 43
assign inst_and    = op_d[6'h00] & func_d[6'h24] & sa_d[5'h00];//rd			 36
assign inst_or     = op_d[6'h00] & func_d[6'h25] & sa_d[5'h00];//rd       	 37
assign inst_xor    = op_d[6'h00] & func_d[6'h26] & sa_d[5'h00];//rd			 38
assign inst_nor    = op_d[6'h00] & func_d[6'h27] & sa_d[5'h00];//rd			 39
assign inst_sll    = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];//rd			 00
assign inst_srl    = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];//rd		 	 2
assign inst_sra    = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];//rd		 	 3
assign inst_addiu  = op_d[6'h09];//rt
assign inst_lui    = op_d[6'h0f] & rs_d[5'h00];//rt
assign inst_lw     = op_d[6'h23];//rt      取字指令  将源寄存器的值加上符号扩展后的得到访存的虚地址 并且放在目标寄存器  
assign inst_sw     = op_d[6'h2b];// 写字指令  101011 -> 2b
assign inst_beq    = op_d[6'h04];//没有在alu_op中出现   相等转移   有条件跳转 
assign inst_bne    = op_d[6'h05];//没有在alu_op中出现   不等转移   有条件跳转
assign inst_jal    = op_d[6'h03];//无条件直接跳转指令
assign inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];//没有在alu_op中出现

//19条指令，12条运算操作
assign alu_op[ 0] = inst_addu | inst_addiu | inst_lw | inst_sw | inst_jal;
//为什么lw sw jal执行的都是加法操作？
//lw和sw分别是写寄存器和读寄存器  相加得到地址
//jal无条件跳转，pc+偏移地址。

assign alu_op[ 1] = inst_subu;
assign alu_op[ 2] = inst_slt;
assign alu_op[ 3] = inst_sltu;
assign alu_op[ 4] = inst_and;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or;
assign alu_op[ 7] = inst_xor;
assign alu_op[ 8] = inst_sll;
assign alu_op[ 9] = inst_srl;
assign alu_op[10] = inst_sra;
assign alu_op[11] = inst_lui;


//运算的第一个数是由sa指定（移位量）
//运算的第一个数是由pc指定
//运算的第二个数是立即数
//运算的第二个数是固定值8，
assign src1_is_sa   = inst_sll   | inst_srl | inst_sra; //逻辑左移，逻辑右移， 算术右移（由sa指定移位量，将rt的值进行移位，放在rd中）
assign src1_is_pc   = inst_jal;//无条件跳转，将pc的最高4位与立即数左移两位拼接得到 
assign src2_is_imm  = inst_addiu | inst_lui | inst_lw | inst_sw;//加符号扩展后的立即数，立即数写入寄存器的高16位，写寄存器 读寄存器
assign src2_is_8    = inst_jal;

//数来自于存储器
assign res_from_mem = inst_lw;
//结果放在31号寄存器
assign dst_is_r31   = inst_jal;
//结果放在rt寄存器
assign dst_is_rt    = inst_addiu | inst_lui | inst_lw;
      
//如果不是这四条指令的其中一条  需要产生向寄存器堆里面写命令
assign gr_we        = ~inst_sw & ~inst_beq & ~inst_bne & ~inst_jr;

assign mem_we       = inst_sw;

//指令的目的寄存器
assign dest         = dst_is_r31 ? 5'd31 :     //指令运算的结果存放的位置
                      dst_is_rt  ? rt    : 
                                   rd;
assign is_load_op   = inst_lw;//取字指令，将数据写到寄存器

assign rf_raddr1 = rs;
assign rf_raddr2 = rt;
regfile u_regfile(  //寄存器堆
    .clk    (clk      ),
    .raddr1 (rf_raddr1),//读rs寄存器的数据
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),//读rt寄存器的数据
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),//寄存器的写使能
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

//  
assign rs_mch_es_dst = es_valid && es_gr_we && !es_is_load_op && (es_dest!=5'b0) && (es_dest==rs);
assign rt_mch_es_dst = es_valid && es_gr_we && !es_is_load_op && (es_dest!=5'b0) && (es_dest==rt) && !dst_is_rt;
assign rs_mch_ms_dst = ms_valid && ms_gr_we && (ms_dest!=5'b0) && (ms_dest==rs);
assign rt_mch_ms_dst = ms_valid && ms_gr_we && (ms_dest!=5'b0) && (ms_dest==rt) && !dst_is_rt;
assign rs_mch_ws_dst = ws_valid && ws_gr_we && (ws_dest!=5'b0) && (ws_dest==rs);
assign rt_mch_ws_dst = ws_valid && ws_gr_we && (ws_dest!=5'b0) && (ws_dest==rt) && !dst_is_rt;

//译码阶段取出通用寄存器里面的数。

//源寄存器里面的值可能是： 先前的指令会在执行、访存、写回三个阶段将数据送到源寄存器，
//(1)源寄存器匹配上执行级的目标寄存器，阻塞；源寄存器的值是执行阶段的运行结果
//(2)源寄存器匹配上访存级的目标寄存器，阻塞；源寄存器的值是访存阶段的运行结果
//(3)源寄存器匹配上写回级的目标寄存器，阻塞；源寄存器的值是写回阶段的运行结果
assign rs_value = rs_mch_es_dst ? alu_result      : //ALU运行产生的结果（执行阶段）
                  rs_mch_ms_dst ? final_result    : //写到寄存器中的数据（访存阶段） 数据寄存器的数据 传到ms阶段的alu的运算结果
                  rs_mch_ws_dst ? ws_final_result : //写到寄存器中的数据（写回阶段）
                                  rf_rdata1;        //直接从寄存器中读出的数据（没有阻塞）

assign rt_value = rt_mch_es_dst ? alu_result      :
                  rt_mch_ms_dst ? final_result    :
                  rt_mch_ws_dst ? ws_final_result :
                                  rf_rdata2;

assign rs_eq_rt = (rs_value == rt_value);
assign br_taken = (   inst_beq  &&  rs_eq_rt //有条件跳转，必须加上条件才能确定是否发生跳转
                   || inst_bne  && !rs_eq_rt
                   || inst_jal               //无条件跳转
                   || inst_jr                //无条件跳转，跳转到rs指定的值
                  ) && ds_valid;             //????
assign br_target = (inst_beq || inst_bne) ? (fs_pc + {{14{imm[15]}}, imm[15:0], 2'b0}) ://偏移量左移两位，且有符号扩展，再加上pc的值
                   (inst_jr)              ? rs_value ://直接跳转到rs寄存器指定的值
                  /*inst_jal*/              {fs_pc[31:28], jidx[25:0], 2'b0};//偏移量左移两位并且与pc高四位进行拼接 获取新的值

// EXE stage
assign es_ready_go    = 1'b1;
assign es_allowin     = !es_valid || es_ready_go && ms_allowin;
assign es_to_ms_valid = es_valid && es_ready_go;

always @(posedge clk) begin
    if (reset) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        es_pc           <= ds_pc;
        es_rs_value     <= rs_value;
        es_rt_value     <= rt_value;
        es_imm          <= imm;
        es_alu_op       <= alu_op;
        es_src1_is_sa   <= src1_is_sa; //延迟了一拍  多生成1级
        es_src1_is_pc   <= src1_is_pc;
        es_src2_is_imm  <= src2_is_imm;
        es_src2_is_8    <= src2_is_8;
        es_res_from_mem <= res_from_mem;
        es_gr_we        <= gr_we;
        es_mem_we       <= mem_we;
        es_dest         <= dest;
        es_is_load_op   <= is_load_op;
    end
end

//alu的第一个运算数
//(1)如果是逻辑运算(sa)第一个操作数来自于立即数的第[10:6] rt移sa放在rd中，故sa当成是rs。
//(2)如果是无条件跳转指令，pc的值+offset。pc当成是rs。
//(3)否则，rs寄存器本身的值
assign alu_src1 = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                  es_src1_is_pc  ? es_pc[31:0] :
                                   es_rs_value;

//alu的第二个运算数
//(1)rs与立即数操作放在rd中 故立即数看成是 rt
//(2)无条件跳转 +8，偏移量当成是第二个操作数
//(3)rt本身的值，
//								   
assign alu_src2 = es_src2_is_imm ? {{16{es_imm[15]}}, es_imm[15:0]} : //32位操作数，前面16位是符号扩展位
                  es_src2_is_8   ? 32'd8 :
                                   es_rt_value;

alu u_alu(
    .alu_op     (es_alu_op ),
    .alu_src1   (alu_src1  ),
    .alu_src2   (alu_src2  ),
    .alu_result (alu_result)//得到运算的结果
    );

assign data_sram_en    = 1'b1;                             //执行阶段打开sram的写使能
assign data_sram_wen   = es_mem_we&&es_valid ? 4'hf : 4'h0;//
assign data_sram_addr  = alu_result;//如果需要将数据写到数据存储器里面去，运算的结果是数据存储器的地址，需要写的存储器在rt中
assign data_sram_wdata = es_rt_value;//待写入存储器的数据

// MEM stage
assign ms_ready_go    = 1'b1;
assign ms_allowin     = !ms_valid || ms_ready_go && ws_allowin;
assign ms_to_ws_valid = ms_valid && ms_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ms_valid <= 1'b0;
    end
    else if (ms_allowin) begin
        ms_valid <= es_to_ms_valid;
    end

    if (es_to_ms_valid && ms_allowin) begin
        ms_pc           <= es_pc;
        ms_dest         <= es_dest;
        ms_res_from_mem <= es_res_from_mem;
        ms_gr_we        <= es_gr_we;
        ms_alu_result   <= alu_result;
    end
end

assign mem_result = data_sram_rdata;//从数据存储器读出的数据

//写到寄存器堆中的数据是来自于数据寄存器or ALU的运算结果
assign final_result = ms_res_from_mem ? mem_result : ms_alu_result;// 数据存储器读出的数据，执行阶段的运行结果

// WB stage
assign ws_ready_go = 1'b1;
assign ws_allowin  = !ws_valid || ws_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
    end
    else if (ws_allowin) begin //ws允许的情况下 并且ms进来了，ws_valid为1 表示进入该级。
        ws_valid <= ms_to_ws_valid;
    end

    if (ms_to_ws_valid && ws_allowin) begin
        ws_pc           <= ms_pc;
        ws_gr_we        <= ms_gr_we;
        ws_dest         <= ms_dest;
        ws_final_result <= final_result;
    end
end

assign rf_we    = ws_gr_we&&ws_valid; //向寄存器堆里面写，满足的两个条件：（1）指令满足（2）指令在ws级  
assign rf_waddr = ws_dest;            //目的寄存器地址
assign rf_wdata = ws_final_result;    //需要写入的数据

// debug info generate
assign debug_wb_pc       = ws_pc;
assign debug_wb_rf_wen   = {4{rf_we}};
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = ws_final_result;

endmodule

