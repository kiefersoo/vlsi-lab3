module mac (
    input logic clk,
    input logic rst_n,
    input logic [31:0] a,
    input logic [31:0] w,
    input logic push,
    output logic [31:0] result,
    output logic done
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            result <= 32'b0;
            done <= 1'b0;
        end else if (push) begin
            result <= a * w; // simple multiply operation
            done <= 1'b1; // indicate that the operation is done
        end else begin
            done <= 1'b0; // reset done signal when not pushing
        end
    end

endmodule