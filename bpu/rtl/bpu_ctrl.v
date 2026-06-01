//--------------------------------------------------------------------------------
// 
// Module: bpu_ctrl.v
//
//-------------------------------------------------------------------------------

`timescale 1ns / 1ps

module bpu_ctrl(
	 input 	[31:0] 	pc			         
	,input 	[31:0] 	nxpc
	// pre-compute	
	,input 	[6:0]   fetch_opcode		 
	,input 	[1:0]   flush_in		  
 	// flush	
	,input       	btb_valid_pc		 
	,input       	is_branch		     
	,input       	branch_taken		 
	,input       	predict_taken_pc	 
	,output [1:0] 	bpu_flush		     
	// specculation    	                    
	,input       	predict_taken_nxpc	 
	,input       	btb_valid_nxpc		 
	,input 	[31:0]  btb_target_nxpc	 
	,input 	[31:0]  branch_target_fetch
	// correction	                    
	,input 	[31:0]	btb_target_pc		 
	// output MUX	                    
	,output [31:0]  bpu_nxpc2		     
    ,output        	bpu_nxpc2_valid	 
);

// pre-compute
wire fetch_is_branch = (fetch_opcode == 7'b1100011);
wire fetch_ready     = ((flush_in == 2'd0) || (flush_in == 2'd1));

// flush
assign bpu_flush 	 = 	(!is_branch)		? 2'b0							:
						(!btb_valid_pc)		? (branch_taken ? 2'd1 : 2'd2)	:
						predict_taken_pc	? (branch_taken	? 2'd1 : 2'd2)	:
					  						  (branch_taken	? 2'd2 : 2'd0)	;

// Speculation
wire [31:0]	spec_nxpc2;
wire 		spec_valid;
wire s1, s2, s3;

assign s1 = (fetch_is_branch && !btb_valid_nxpc 	&& fetch_ready);
assign s2 = (fetch_is_branch && predict_taken_nxpc  && fetch_ready);
assign s3 = (fetch_is_branch && !predict_taken_nxpc && btb_valid_pc	&& fetch_ready);

assign spec_valid = (s1 || s2 || s3);
assign spec_nxpc2 = s1 	? (nxpc + branch_target_fetch)	:
				   	s2	? btb_target_nxpc				:
		 			s3	? (pc + 4)						:
	  					  32'b0							;

// Correction
wire [31:0] corr_nxpc2;
wire		corr_valid;	
wire c1, c2, c3;

assign c1 = (is_branch	&& !branch_taken	&& !btb_valid_pc)						;
assign c2 = (is_branch	&& branch_taken		&& !predict_taken_pc	&& btb_valid_pc);
assign c3 = (is_branch	&& !branch_taken	&& predict_taken_pc)					;

assign corr_valid = (c1 || c2 || c3);
assign corr_nxpc2 =	c1	? (nxpc + 4)	:
					c2	? btb_target_pc	:
		  			c3	? (nxpc + 4)	:
						  32'b0			;

// Output MUX
assign bpu_nxpc2_valid = (spec_valid || corr_valid)		;
assign bpu_nxpc2 	   =	corr_valid	? corr_nxpc2	:
							spec_valid	? spec_nxpc2	:
										  32'b0			;	
								  

endmodule
