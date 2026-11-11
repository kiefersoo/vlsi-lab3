////////////////////////////////////////////////////
// This is a basic test case to test 
// a single dot product of vec_len = 1
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
			
		//read initial status
		cmd(STATUS);
		cmd(STATUS);
		PSEL = 0;
		
		//populate inputs
		cmd(A_DATA, {8'h04, 8'h03, 8'h02, 8'h01});
		cmd(W_DATA, {8'h04, 8'h03, 8'h02, 8'h01});

		//trigger dot product
		cmd(COMMAND, {23'b0, 2'b00});
	
		//read status during compute
		cmd(STATUS);
		cmd(STATUS);
		cmd(STATUS);
		cmd(STATUS);

		//wait 3 cycles
		@(posedge PCLK) PSEL = 0;
		repeat(3) @(posedge PCLK);
		
		//read status after compute
		cmd(STATUS);
	
		//read result
		cmd(RESULT); //'h 0000001E
		cmd(RESULT); //'h 0000001E

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
