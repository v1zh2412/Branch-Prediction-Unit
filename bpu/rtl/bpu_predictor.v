//--------------------------------------------------------------------------------
// 
// Module: bpu_top.v
//
//-------------------------------------------------------------------------------

`timescale 1ns / 1ps

module bpu_predictor(
     input 	[31:0] 	pc                        
    ,input         	is_branch              
    ,input         	branch_taken              
    ,input  [31:0] 	branch_offset             
    // BTB
    ,input         	btb_valid_pc      
	,output         btb_wr_en    
    ,output [31:0]  btb_wr_target
    // Local BHT 
    ,input  [5:0]  	local_bht_data_pc    
    ,output       	local_bht_wr_en    
    ,output [5:0]   local_bht_wr_data	
    // Local PHT
    ,input  [1:0]  	local_pht_data_pc         
    ,input  [1:0]  	local_pht_data_nxpc 
  	,output         local_pht_wr_en    
    ,output [1:0]   local_pht_wr_data 	
    // Global PHT 
    ,input  [1:0]  	global_pht_data_pc        
    ,input  [1:0]  	global_pht_data_nxpc     
    ,output         global_pht_wr_en
    ,output [1:0]   global_pht_wr_data	
    // Choice 
    ,input  [1:0]  	choice_data_pc          
    ,input  [1:0]  	choice_data_nxpc          
	,output         choice_wr_en
    ,output [1:0]   choice_wr_data
    // GHR
    ,input  [9:0]  	ghr_out                   
	,output         ghr_wr_en
    ,output [9:0]   ghr_wr_data
    // Prediction output
    ,output        	predict_taken_pc          
    ,output        	predict_taken_nxpc        
);

parameter SNT = 2'b00;
parameter WNT = 2'b01;
parameter WT  = 2'b10;
parameter ST  = 2'b11;

// predic taken
assign predict_taken_pc   = choice_data_pc[1]   ? global_pht_data_pc[1]   : local_pht_data_pc[1];
assign predict_taken_nxpc = choice_data_nxpc[1] ? global_pht_data_nxpc[1] : local_pht_data_nxpc[1];

// saturating counter
function [1:0] update_counter;
	input [1:0] current;
	input taken;
	begin
		case(current)
			ST:  update_counter = taken ? ST  : WT ;
			WT:  update_counter = taken ? ST  : WNT;
			WNT: update_counter = taken ? WT  : SNT;
			SNT: update_counter = taken ? WNT : SNT;
			default: update_counter = WT;
		endcase
	end
endfunction

// BTB
assign btb_wr_en 	 = is_branch;
assign btb_wr_target = pc + branch_offset;

// Local BHT
assign local_bht_wr_en 	 = is_branch;
assign local_bht_wr_data = is_branch	? {local_bht_data_pc[4:0], branch_taken}	:
									 	  local_bht_data_pc;

// Local PHT
assign local_pht_wr_en 	 = is_branch;
assign local_pht_wr_data = btb_valid_pc	? update_counter(local_pht_data_pc, branch_taken)	:
										  WT;

// Global PHT
assign global_pht_wr_en   = is_branch;
assign global_pht_wr_data = btb_valid_pc	? update_counter(global_pht_data_pc, branch_taken)	:
											  WT;

// Choice
wire   disagree       = (local_pht_data_pc != global_pht_data_pc);
wire   local_correct  = (local_pht_data_pc[1]  == branch_taken);
wire   global_correct = (global_pht_data_pc[1] == branch_taken);

assign choice_wr_en   = disagree && is_branch && btb_valid_pc;

assign choice_wr_data = (!local_correct && global_correct)	? update_counter(choice_data_pc, 1'b1)	:
						(local_correct && !global_correct)	? update_counter(choice_data_pc, 1'b0)	:
										   					  choice_data_pc						;

// GHR
assign ghr_wr_en   = is_branch;
assign ghr_wr_data = is_branch	? {ghr_out[8:0], branch_taken}	:
								  ghr_out						;


															


endmodule
