module cpu_axi_interface(
    input         clk,
    input         resetn, 

    //inst sram-like 
    input         inst_req     ,
    input         inst_wr      ,
    input  [1 :0] inst_size    ,
    input  [31:0] inst_addr    ,
    input  [31:0] inst_wdata   ,
    output [31:0] inst_rdata   ,
    output        inst_addr_ok ,
    output        inst_data_ok ,
    
    //data sram-like 
    input         data_req     ,
    input         data_wr      ,
    input  [1 :0] data_size    ,
    input  [31:0] data_addr    ,
    input  [31:0] data_wdata   ,
    output [31:0] data_rdata   ,
    output        data_addr_ok ,
    output        data_data_ok ,

    //axi
    //ar
    output [3 :0] arid         ,
    output [31:0] araddr       ,
    output [7 :0] arlen        ,
    output [2 :0] arsize       ,
    output [1 :0] arburst      ,
    output [1 :0] arlock        ,
    output [3 :0] arcache      ,
    output [2 :0] arprot       ,
    output        arvalid      ,
    input         arready      ,
    //r           
    input  [3 :0] rid          ,
    input  [31:0] rdata        ,
    input  [1 :0] rresp        ,
    input         rlast        ,
    input         rvalid       ,
    output        rready       ,
    //aw          
    output [3 :0] awid         ,
    output [31:0] awaddr       ,
    output [7 :0] awlen        ,
    output [2 :0] awsize       ,
    output [1 :0] awburst      ,
    output [1 :0] awlock       ,
    output [3 :0] awcache      ,
    output [2 :0] awprot       ,
    output        awvalid      ,
    input         awready      ,
    //w          
    output [3 :0] wid          ,
    output [31:0] wdata        ,
    output [3 :0] wstrb        ,
    output        wlast        ,
    output        wvalid       ,
    input         wready       ,
    //b           
    input  [3 :0] bid          ,
    input  [1 :0] bresp        ,
    input         bvalid       ,
    output        bready       
);
reg reset;
always @(posedge clk) reset <= ~resetn;
// data
wire        dram_write_finish;
reg         dram_write_idle;
reg  [31:0] dram_write_addr;
reg  [31:0] dram_write_data;
reg  [ 1:0] dram_write_size;

wire        dram_read_finish;
reg         dram_read_idle;
reg  [31:0] dram_read_addr;
reg  [ 1:0] dram_read_size;

// inst
wire        iram_read_finish;
reg         iram_read_idle;
reg  [31:0] iram_read_addr;
reg  [ 1:0] iram_read_size;


always @(posedge clk) begin
	if(reset) begin
		dram_write_idle <= 1'b1;
		dram_read_idle <= 1'b1;
	end
	else begin
		if(data_req) begin
			if(data_wr & data_addr_ok) begin
				dram_write_addr <= data_addr;
				dram_write_data <= data_wdata;
				dram_write_size <= data_size;
				dram_write_idle <= 1'b0;
			end
			else if(~data_wr & data_addr_ok)begin
				dram_read_addr <= data_addr;
				dram_read_size <= data_size;
				dram_read_idle <= 1'b0;
			end
		end
		
		if(~dram_read_idle & dram_read_finish) begin
			dram_read_idle <= 1'b1;
		end
		else if(~dram_write_idle & dram_write_finish) begin
			dram_write_idle <= 1'b1;
		end
	end
end

assign data_rdata = rdata;
assign data_addr_ok = dram_read_idle & dram_write_idle & iram_read_idle;
assign data_data_ok = (~dram_write_idle & dram_write_finish) | (~dram_read_idle & dram_read_finish);




always @(posedge clk) begin
	if(reset) begin
		iram_read_idle <= 1'b1;
	end
	else begin
		if(inst_req) begin
			if(~inst_wr && inst_addr_ok)begin
				iram_read_addr <= inst_addr;
				iram_read_size <= inst_size;
				iram_read_idle <= 1'b0;
			end
		end
		
		if(inst_data_ok) begin
			iram_read_idle <= 1'b1;
		end
	end
end

assign inst_rdata = rdata;
assign inst_addr_ok = iram_read_idle & dram_read_idle & dram_write_idle;
assign inst_data_ok = ~iram_read_idle & iram_read_finish;


// axi
reg read_addr_finish;

reg write_addr_finish;
reg write_data_finish;

always @(posedge clk) begin
	if(reset) begin
		read_addr_finish <= 1'b0;
		write_addr_finish <= 1'b0;
		write_data_finish <= 1'b0;
	end
	else begin
		if((~iram_read_idle | ~dram_read_idle) & arready & arvalid)
			read_addr_finish <= 1'b1;
		else if(iram_read_finish | dram_read_finish)
			read_addr_finish <= 1'b0;
		
		if(~dram_write_idle & awready & awvalid)
			write_addr_finish <= 1'b1;
		else if(dram_write_finish)
			write_addr_finish <= 1'b0;
		
		if(~dram_write_idle & wready & wvalid & wlast & write_addr_finish)
			write_data_finish <= 1'b1;
		else if(dram_write_finish)
			write_data_finish <= 1'b0;
		

	end
end

assign iram_read_finish  = ~iram_read_idle & rvalid & rready & rlast;
assign dram_read_finish  = ~dram_read_idle & iram_read_idle & rvalid & rready & rlast;//choose iram when both reading
assign dram_write_finish =  ~dram_write_idle & bvalid & bready;


// write
assign awid = 4'b1;
assign awaddr = dram_write_addr;
assign awlen = 8'b0;
assign awsize = {1'b0,dram_write_size};
assign awburst = 2'b01;
assign awlock = 2'b00;
assign awcache = 4'b0;
assign awprot = 3'b0;
assign awvalid = ~dram_write_idle & ~write_addr_finish;

assign wid = 4'b1;
assign wdata = dram_write_data;
assign wstrb = dram_write_size == 2'b00 ? 4'b0001<<dram_write_addr[1:0] :
			   dram_write_size == 2'b01 ? 4'b0011<<dram_write_addr[1:0] :
										                        4'b1111 ;
assign wlast = 1'b1;
assign wvalid = ~dram_write_idle & ~write_data_finish;

assign bready = ~dram_write_idle;

// read
assign arid = 4'b1;
assign araddr = ~iram_read_idle ? iram_read_addr : dram_read_addr;//choose iram when both reading
assign arlen = 8'b0;
assign arsize = ~iram_read_idle ? {1'b0,iram_read_size} : {1'b0,dram_read_size};//choose iram when both reading
assign arburst = 2'd0;
assign arlock  = 2'd0;
assign arcache = 4'd0;
assign arprot  = 3'd0;
assign arvalid = (~iram_read_idle | ~dram_read_idle) & ~read_addr_finish;

assign rready = ~iram_read_idle | ~dram_read_idle;
endmodule