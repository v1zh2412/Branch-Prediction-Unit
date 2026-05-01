//--------------------------------------------------------------------------------
// 
// Module: bpu_top.v
//
//-------------------------------------------------------------------------------

`timescale 1ns / 1ps

module bpu_reg(
    	 input         	clk                       
    	,input         	halt                      
    	,input 	[31:0] 	pc                       
    	,input	[31:0] 	nxpc                      
    	// BTB 	
    	,output        	btb_valid_pc             
    	,output [31:0] 	btb_target_pc             
    	,output        	btb_valid_nxpc            
    	,output [31:0] 	btb_target_nxpc           
    	,input         	btb_wr_en                 
    	,input  [31:0] 	btb_wr_target             
    	// Local BHT
    	,output [5:0]  	local_bht_data_pc
    	,output [5:0]  	local_bht_data_nxpc       
    	,input         	local_bht_wr_en           
    	,input  [5:0]  	local_bht_wr_data         
    	// Local PHT 
    	,output [1:0]  	local_pht_data_pc         
    	,output [1:0]  	local_pht_data_nxpc       
    	,input         	local_pht_wr_en           
    	,input  [1:0]  	local_pht_wr_data         
    	// Global PHT 
    	,output [1:0]  	global_pht_data_pc        
    	,output [1:0]  	global_pht_data_nxpc      
    	,input         	global_pht_wr_en          
    	,input  [1:0]  	global_pht_wr_data        
    	// Choice
    	,output [1:0]  	choice_data_pc           
    	,output [1:0]  	choice_data_nxpc          
    	,input         	choice_wr_en             
    	,input  [1:0]  	choice_wr_data            
    	// GHR
    	,output [9:0]  	ghr_out                   
    	,input         	ghr_wr_en                 
    	,input  [9:0]  	ghr_wr_data                
);

// index
wire [9:0] pc_index	= pc[11:2];
wire [9:0] nxpc_index	= nxpc[11:2];

// reg
reg 	   btb_valid	[0:1023];
reg [31:0] btb_target	[0:1023];
reg [5:0]  local_bht	[0:1023];
reg [1:0]  local_pht	[0:63];
reg [1:0]  global_pht	[0:1023];
reg [1:0]  choice	[0:1023];
reg [9:0]  ghr;

// === BTB === 
// BTB read
assign btb_target_pc   = btb_target[pc_index];
assign btb_target_nxpc = btb_target[nxpc_index];

assign btb_valid_pc   = btb_valid[pc_index];
assign btb_valid_nxpc = btb_valid[nxpc_index];

// BTB write
always @(posedge clk) begin
	if(btb_wr_en && !halt) begin
		btb_target[pc_index] <= btb_wr_target;
		btb_valid[pc_index]  <= 1'b1;  
	end else begin
		btb_target[pc_index] <= btb_target[pc_index];
		btb_valid[pc_index]  <= btb_valid[pc_index];
	end
end


// === Local BHT === 
// Read
assign local_bht_data_pc   = local_bht[pc_index];
assign local_bht_data_nxpc = local_bht[nxpc_index];

// Write
always @(posedge clk) begin
	if(local_bht_wr_en && !halt) begin
		local_bht[pc_index] <= local_bht_wr_data;
	end else begin
		local_bht[pc_index] <= local_bht[pc_index];	
	end
end


// === Local PHT === 
wire local_pht_index_pc   = local_bht[pc_index];
wire local_pht_index_nxpc = local_bht[nxpc_index];

// Read
assign local_pht_data_pc   = local_pht[local_pht_index_pc];
assign local_pht_data_nxpc = local_pht[local_pht_index_nxpc];

// Write
always @(posedge clk) begin
	if(local_pht_wr_en && !halt) begin
		local_pht[local_pht_index_pc] <= local_bht_wr_data;
	end else begin
		local_pht[local_pht_index_pc] <= local_pht[local_pht_index_pc];	
	end
end

// === Global PHT === 
wire global_pc_index   = pc_index   ^ ghr;
wire global_nxpc_index = nxpc_index ^ ghr;

// Read
assign global_pht_data_pc   = global_pht[global_pc_index];
assign global_pht_data_nxpc = global_pht[global_nxpc_index];

// Write
always @(posedge clk) begin
	if(global_pht_wr_en && !halt) begin
		global_pht[global_pc_index] <= global_pht_wr_data;
	end else begin
		global_pht[global_pc_index] <= global_pht[global_pc_index];	
	end
end

// === Choice === 
// Read
assign choice_data_pc   = choice[pc_index];
assign choice_data_nxpc = choice[nxpc_index];

// Write
always @(posedge clk) begin
	if(choice_wr_en && !halt) begin
		choice[pc_index] <= choice_wr_data;
	end else begin
		choice[pc_index] <= choice[pc_index];	
	end
end

// === GHR === 
// Read
assign ghr_out = ghr;

// Write
always @(posedge clk) begin
	if(ghr_wr_en && !halt) begin
		ghr <= ghr_wr_data;
	end else begin
		ghr <= ghr;
	end
end
endmodule
