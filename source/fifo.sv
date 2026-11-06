/*

fifo implementation

using a shifter based approach where pushes shift values to a deeper register
control signals coming from control unit determine whether a push or pop occurs on this cycle

using the terms push and pop confused me and i made a stack at first

*/

module fifo (
    input wire clk,
    input wire rst_n,

    input wire [31:0] in,
    output wire [31:0] out,

    output wire empty, full,
    input wire push, pop
);

    reg [3:0][31:0] data;
    reg [2:0] size; // keep track of how many elements are stored in FIFO


    assign empty = (size == 0);
    assign full = (size == 4);
    assign out = data[0];

    // this fifo is synchronous
    always @ (posedge clk or negedge rst_n) begin

        if (!rst_n) begin
            size <= 0;
        end else begin
            // push     
            if (!full && push && !pop) begin
                data[size] <= in;
                size <= size + 1;
            end

            // pop
            // need to see if pop can latch the value of out before it is shifted out...
            if (!empty && pop && !push) begin
               data [0] <= data [1];
               data [1] <= data [2];
               data [2] <= data [3];
               size <= size - 1;
            end

            // handling the case of simultaneous push and pop
            if (!empty && push && pop) begin
                // size doesn't change
                for (int i = 1; i < size; i++) begin
                    data [i - 1] <= data [i];
                end
                data [size - 1] <= in;
            end
        end
    end
    

endmodule