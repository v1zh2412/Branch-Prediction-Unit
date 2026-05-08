//--------------------------------------------------------------------------------
// 
// Module: bpu_top.v
//
//-------------------------------------------------------------------------------

`timescale 1ns / 1ps

module bpu_top(
	 input			clk
	,input			rst_n
	,input         	halt
   	,input	[6:0]  	fetch_opcode
   	,input  [31:0] 	branch_target_fetch
   	,input  [31:0] 	nxpc
   	,input  [31:0] 	pc
   	,input          is_branch
   	,input         	branch_taken
   	,input  [31:0] 	branch_offset
   	,input  [1:0]  	flush_in
   	,output [31:0] 	bpu_nxpc2
   	,output        	bpu_nxpc2_valid
   	,output [1:0]  	bpu_flush
);
	
//  BTB 
wire 	       	btb_valid_pc	,btb_valid_nxpc;
wire 	[31:0] 	btb_target_pc	,btb_target_nxpc;
wire 	       	btb_wr_en;
wire 	[31:0] 	btb_wr_target;

// Local BHT	
wire 	[5:0]  	local_bht_data_pc;
wire 	[5:0]  	local_bht_data_nxpc;
wire 	       	local_bht_wr_en;
wire 	[5:0]  	local_bht_wr_data;
// Local PHT	 
wire 	[1:0]  	local_pht_data_pc	,local_pht_data_nxpc;
wire 	       	local_pht_wr_en;
wire 	[1:0]  	local_pht_wr_data;

// Global PHT 
wire 	[1:0]  	global_pht_data_pc	,global_pht_data_nxpc;
wire 	       	global_pht_wr_en;
wire 	[1:0]  	global_pht_wr_data;

// Choice 
wire 	[1:0]  	choice_data_pc	,choice_data_nxpc;
wire 	       	choice_wr_en;
wire 	[1:0]  	choice_wr_data;
// GHR 
wire 	[9:0]  	ghr_out;
wire 	       	ghr_wr_en;
wire 	[9:0]  	ghr_wr_data;

// Prediction 
wire            predict_taken_pc	,predict_taken_nxpc;

//  Register File
bpu_reg u_bpu_reg(
 	 .clk		    	    (clk			        )
	,.rst_n					(rst_n					)
	,.halt		    	    (halt			        ) 
	,.pc		    	    (pc			            )
	,.nxpc		    	    (nxpc			        )
    // BTB
    ,.btb_valid_pc		    (btb_valid_pc		    )
	,.btb_target_pc		    (btb_target_pc		    )
	,.btb_valid_nxpc	    (btb_valid_nxpc		    )
	,.btb_target_nxpc	    (btb_target_nxpc	    )
	,.btb_wr_en		        (btb_wr_en		        )
	,.btb_wr_target		    (btb_wr_target		    )
    // Local BHT 
    ,.local_bht_data_pc	    (local_bht_data_pc	    )
    ,.local_bht_data_nxpc	(local_bht_data_nxpc	)
    ,.local_bht_wr_en	    (local_bht_wr_en	    )
    ,.local_bht_wr_data	    (local_bht_wr_data	    )
    // Local PHT
    ,.local_pht_data_pc	    (local_pht_data_pc	    )
    ,.local_pht_data_nxpc	(local_pht_data_nxpc	)
    ,.local_pht_wr_en	    (local_pht_wr_en	    )
    ,.local_pht_wr_data	    (local_pht_wr_data	    )
    // Global PHT
    ,.global_pht_data_pc	(global_pht_data_pc	    )
    ,.global_pht_data_nxpc	(global_pht_data_nxpc	)
    ,.global_pht_wr_en	    (global_pht_wr_en	    )
    ,.global_pht_wr_data	(global_pht_wr_data	    )
    // Choice
    ,.choice_data_pc	    (choice_data_pc		    )
	,.choice_data_nxpc	    (choice_data_nxpc	    )
    ,.choice_wr_en		    (choice_wr_en		    )
	,.choice_wr_data	    (choice_wr_data		    )
    // GHR
    ,.ghr_out		        (ghr_out		        )
	,.ghr_wr_en		        (ghr_wr_en		        )
	,.ghr_wr_data		    (ghr_wr_data		    )
);

//  Predictor 
bpu_predictor u_bpu_predictor(
	 .pc			        (pc			            )       
	,.is_branch		        (is_branch		        )
    // BTB
	,.branch_offset		    (branch_offset		    )   
	,.btb_wr_en		        (btb_wr_en		        )
	,.btb_wr_target		    (btb_wr_target		    )
    // Local BHT 
    ,.branch_taken		    (branch_taken		    )
	,.local_bht_data_pc	    (local_bht_data_pc	    )
    //,.local_bht_data_nxpc	(local_bht_data_nxpc	)
    ,.local_bht_wr_en	    (local_bht_wr_en	    )
    ,.local_bht_wr_data	    (local_bht_wr_data	    )
    // Local PHT
    ,.local_pht_data_pc	    (local_pht_data_pc	    )
    ,.local_pht_data_nxpc	(local_pht_data_nxpc	)
    ,.local_pht_wr_en	    (local_pht_wr_en	    )
    ,.local_pht_wr_data	    (local_pht_wr_data	    )
    // Global PHT
    ,.global_pht_data_pc	(global_pht_data_pc	    )
    ,.global_pht_data_nxpc	(global_pht_data_nxpc	)
    ,.global_pht_wr_en	    (global_pht_wr_en	    )
    ,.global_pht_wr_data	(global_pht_wr_data	    )
    // Choice
	,.btb_valid_pc		    (btb_valid_pc		    )
    ,.choice_data_pc	    (choice_data_pc		    )
	,.choice_data_nxpc	    (choice_data_nxpc	    )
    ,.choice_wr_en		    (choice_wr_en		    )
	,.choice_wr_data	    (choice_wr_data		    )
    // GHR
    ,.ghr_out		        (ghr_out		        )
	,.ghr_wr_en		        (ghr_wr_en		        )
	,.ghr_wr_data	    	(ghr_wr_data		    )
	//predic
	,.predict_taken_pc	    (predict_taken_pc	    )
	,.predict_taken_nxpc	(predict_taken_nxpc	    )
);
    
//  BPU controll
bpu_ctrl u_bpu_ctrl(
	 .pc			        (pc			            )					
	,.nxpc			        (nxpc			        )	
	// pre-compute			
	,.fetch_opcode		    (fetch_opcode		    )	
	,.flush_in		        (flush_in		        )	
	// flush		
	,.btb_valid_pc		    (btb_valid_pc		    )	
	,.is_branch		        (is_branch		        )	
	,.branch_taken		    (branch_taken		    )	
	,.predict_taken_pc	    (predict_taken_pc	    )	
	,.bpu_flush		        (bpu_flush		        )	
	// specculation			
	,.predict_taken_nxpc	(predict_taken_nxpc	    )		
	,.btb_valid_nxpc	    (btb_valid_nxpc		    )	
	,.btb_target_nxpc	    (btb_target_nxpc	    )		
	,.branch_target_fetch	(branch_target_fetch    )
	// correction			
	,.btb_target_pc		    (btb_target_pc		    )	
	// output MUX			
	,.bpu_nxpc2		        (bpu_nxpc2		        )	
	,.bpu_nxpc2_valid	    (bpu_nxpc2_valid	    )	
);

endmodule
