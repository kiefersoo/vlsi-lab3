/*
decode logic

need to send the values from APB to the correct latches within the design

CLEAR_B	        1	input	This is the reset signal to the TinyML module. It is a negative level sensitive synchronous reset
PCLK	        1	input	This is the clock to the APB interface.
PSEL	        1	input	This is the APB slave select - when this is is high during a PCLK edge, expect a read/write to TinyML
PWRITE	        1	input	This is the write enable - 1: write, 0:read
PADDR	    [25:0]	input	This is the address input to TinyML, which will be deocded by the decoder module
PWDATA	    [31:0]	input	This is the 32-bit write data from the master
PRDATA	    [31:0]	output	This is the 32-bit read data from the TinyML
tinyml_afull	1	output	This is a flag from TinyML which sets if the activation FIFO is full
tinyml_wfull	1	output	This is a flag from TinyML which sets if the weight FIFO is full

*/

module decode (
    // input/output signals that interface with the bus
    input wire CLEAR_B,
    input wire PCLK, PSEL, PWRITE,
    input wire [25:0] PADDR,
    input wire [32:0] PWDATA,

    output wire [32:0] PRDATA

    // input/output signals that interface with the rest of the design
    

);
    typedef enum logic [2:0] { 

        A_DATA = 2'b000,
        W_DATA = 2'b001,
        COMMAND = 2'b010,
        STATUS = 2'b100,
        RESULT = 2'b101

    } address_t;

endmodule