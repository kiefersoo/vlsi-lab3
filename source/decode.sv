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

** can come from FIFO modules directly
tinyml_afull	1	output	This is a flag from TinyML which sets if the activation FIFO is full
tinyml_wfull	1	output	This is a flag from TinyML which sets if the weight FIFO is full

*/

module decode (
    // input/output signals that interface with the bus
    input wire CLEAR_B,
    input wire PCLK, PSEL, PWRITE,
    input wire [25:0] PADDR,
    input wire [31:0] PWDATA,

    output wire [31:0] PRDATA,

    // input/output signals that interface with the rest of the design
    // the decode logic serves as MASTER to FIFOs
    // PUSHes, but POPs will come from CTRL logic
    output logic [31:0] a_fifo_input,
    output logic push_a_fifo,

    output logic [31:0] w_fifo_input,
    output logic push_w_fifo, 

    // command going to the control block
    output logic [1:0] ctrl_command,
    output logic push_command 
    
    

);
    // decode the command coming from the bus in PADDR[2:0]
    typedef enum logic [2:0] { 

        A_DATA = 3'b000,
        W_DATA = 3'b001,
        COMMAND = 3'b010,
        STATUS = 3'b100,
        RESULT = 3'b101

    } address_t;

    always @ (posedge PCLK) begin
        case (PADDR[2:0])
            A_DATA: begin
                // write to the Activation FIFO
                push_a_fifo <= 1; a_fifo_input <= PWDATA;
                push_w_fifo <= 0; w_fifo_input <= 32'h0000;
                push_command <= 0; ctrl_command <= 2'b00;
            end
            W_DATA: begin
                // write to the Weight FIFO 
                push_a_fifo <= 0; a_fifo_input <= 32'h0000;
                push_w_fifo <= 1; w_fifo_input <= PWDATA;
                push_command <= 0; ctrl_command <= 2'b00;
            end
            COMMAND: begin
                // write a command to control logic buffer 
                push_a_fifo <= 0; a_fifo_input <= 32'h0000;
                push_w_fifo <= 0; w_fifo_input <= 32'h0000;
                push_command <= 1; ctrl_command <= PWDATA[1:0];
            end
            STATUS: begin
                // read status register (in control logic block?) 
            end
            RESULT: begin
                // read result from end of MAC
            end
            default: begin
                // shouldn't get here
            end
        endcase
    end

endmodule