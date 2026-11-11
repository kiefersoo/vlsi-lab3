////////////////////////////////////////////////////
// This tests 2 continuous dot products of each 
// vec_len = 2.  
////////////////////////////////////////////////////

`timescale 1ns / 1ps
module tinyml_test;
	//reg/wire decs
	reg         PCLK;
	reg         CLEAR_B;
	reg         PSEL;
	reg         PWRITE;
	reg  [25:0] PADDR;
	reg  [31:0] PWDATA;
	wire [31:0] PRDATA;
	wire        tinyml_afull;
	wire        tinyml_wfull;

    localparam A_DATA   = 3'b000,
               W_DATA   = 3'b001,
               COMMAND  = 3'b010,
               STATUS   = 3'b011,
               RESULT   = 3'b100;


task automatic cmd (
	input [2:0] cmd,
	input [31:0] data = 32'b0
);
	@(posedge PCLK);
	case (cmd)
		A_DATA: begin
			PWRITE <= 1'b1;
			PWDATA <= data;
		end
		W_DATA: begin
			PWRITE <= 1'b1;
			PWDATA <= data;
		end
		COMMAND: begin
		 	PWRITE <= 1'b1;
			PWDATA <= data;
		end
		STATUS: begin
			PWRITE <= 1'b0;
		end
		RESULT: begin
			PWRITE <= 1'b0;
		end
	endcase
		PADDR <= {23'b0, cmd};
		PSEL <= 1;
endtask

	initial begin
		//initialize		
		PCLK = 1'b0;
		PSEL = 1'b0;
		PWRITE = 1'b0;
		PADDR = 26'b0;
		PWDATA = 32'b0;

		//reset
		CLEAR_B = 0;
		#(20) CLEAR_B = 1;	
		@(posedge PCLK);
			
		// Pop 1 
		cmd(A_DATA, {8'hFF,   8'h7F,   8'h80,   8'h80});  //   -1        127       -128      -128
		cmd(W_DATA, {8'hFF,   8'h7F,   8'h7F,   8'h80});  //   -1        127       127       -128
		                                                    // products:  1(0x1)   16129(0x3F01) -16256(0xFFFFC080) 16384(0x4000)
		                                                    // pop sum = 16258 (0x00003F82)
		
		// Pop 2 
		cmd(A_DATA, {8'hF9,   8'h0A,   8'hFD,   8'h05});  //   -7         10        -3         5
		cmd(W_DATA, {8'h06,   8'hFF,   8'h04,   8'h02});  //   6          -1        4          2
		                                                    // products: -42(0xFFFFFFD6) -10(0xFFFFFFF6) -12(0xFFFFFFF4) 10(0xA)
		                                                    // pop sum = -54 (0xFFFFFFCA)
		                                                    // expected acc = 16258 + (-54) = 16204 (0x00003F4C)
		
		// Pop 3 
		cmd(A_DATA, {8'hFB,   8'h08,   8'h0F,   8'hEC});  //   -5         8          15        -20
		cmd(W_DATA, {8'h09,   8'h07,   8'hFE,   8'h03});  //   9          7          -2        3
		                                                    // products: -45(0xFFFFFFD3) 56(0x38) -30(0xFFFFFFE2) -60(0xFFFFFFC4)
		                                                    // pop sum = -79 (0xFFFFFFB1)
		
		// Pop 4 
		cmd(A_DATA, {8'h9C,   8'h19,   8'hCE,   8'h64});  //   -100       25         -50        100
		cmd(W_DATA, {8'h04,   8'hFD,   8'h02,   8'h01});  //   4          -3         2          1
		                                                    // products: -400(0xFFFFFE70) -75(0xFFFFFFB5) -100(0xFFFFFF9C) 100(0x64)
		                                                    // pop sum = -475 (0xFFFFFE25)
		                                                    // expected acc = -79 + (-475) = -554 (0xFFFFFDD6)
		
		// Trigger dot products
		cmd(COMMAND, {23'b0, 2'b01});   // vec_length = 2
		cmd(COMMAND, {23'b0, 2'b01});   // vec_length = 2

	
		//monitor status 
		cmd(STATUS);
		cmd(STATUS);
		cmd(STATUS);
		cmd(STATUS);
		cmd(STATUS);
		cmd(STATUS);
		cmd(STATUS);
		cmd(STATUS);
	
		//read results
		cmd(RESULT); // 0x00003F4C
		cmd(RESULT); // 0xFFFFFDD6
		cmd(RESULT); // 0xFFFFFDD6

		//wait 6 cycles
		@(posedge PCLK) PSEL = 0;
		repeat(6) @(posedge PCLK);
		
		//Terminate
		$finish;
	end
	
	always 
	#10 PCLK = ~PCLK;


	// DUT instantiation
	tinyml u_tinyml (
	    .PCLK         (PCLK),
	    .CLEAR_B      (CLEAR_B),
	    .PSEL         (PSEL),
	    .PWRITE       (PWRITE),
	    .PADDR        (PADDR),
	    .PWDATA       (PWDATA),
	    .PRDATA       (PRDATA),
	    .tinyml_afull (tinyml_afull),
	    .tinyml_wfull (tinyml_wfull)
	);
endmodule
