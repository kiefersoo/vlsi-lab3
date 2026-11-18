`timescale 1ps/1ps
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

    output logic [31:0] PRDATA,

    output wire [31:0] a_fifo_input,
    output wire        push_a_fifo,
    output wire [31:0] w_fifo_input,
    output wire        push_w_fifo,
    output wire [1:0]  ctrl_command,
    output wire        push_command,

    input  wire        busy,
    input  wire        result_fifo_empty,
    input  wire        result_fifo_full,
    input  wire [31:0] result_fifo_output,
    output wire        pop_result_fifo
);
    localparam logic [2:0] A_DATA  = 3'b000,
                           W_DATA  = 3'b001,
                           COMMAND = 3'b010,
                           STATUS  = 3'b011,
                           RESULT  = 3'b100;

    wire write_transfer = CLEAR_B && PSEL && PWRITE;
    wire read_transfer  = CLEAR_B && PSEL && !PWRITE;
    logic [31:0] last_result;

    assign a_fifo_input = PWDATA;
    assign w_fifo_input = PWDATA;
    assign ctrl_command = PWDATA[1:0];
    assign push_a_fifo  = write_transfer && (PADDR[2:0] == A_DATA);
    assign push_w_fifo  = write_transfer && (PADDR[2:0] == W_DATA);
    assign push_command = write_transfer && (PADDR[2:0] == COMMAND);
    assign pop_result_fifo = read_transfer && (PADDR[2:0] == RESULT)
                                           && !result_fifo_empty;

    // Register the head before the FIFO advances. Empty result reads return
    // the last result read, matching the repeated reads in the supplied tests.
    always_ff @(posedge PCLK) begin
        if (!CLEAR_B) begin
            PRDATA <= 32'd0;
            last_result <= 32'd0;
        end else if (read_transfer) begin
            case (PADDR[2:0])
                STATUS: PRDATA <= {29'd0, result_fifo_full, result_fifo_empty, busy};
                RESULT: begin
                    if (!result_fifo_empty) begin
                        PRDATA <= result_fifo_output;
                        last_result <= result_fifo_output;
                    end else begin
                        PRDATA <= last_result;
                    end
                end
                default: PRDATA <= 32'd0;
            endcase
        end
    end
endmodule
