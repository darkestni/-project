module PipelineReg #(parameter WIDTH = 32) (
    input clk,
    input flush,
    input stall,
    input [WIDTH-1:0] in,
    output reg [WIDTH-1:0] out
);
    always @(posedge clk) begin
        if (flush) out <= 0;
        else if (!stall) out <= in;
    end
endmodule