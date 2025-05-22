module ClockCount(
    input clk,
    input reset,
    output reg [31:0] clk_count
);
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_count <= 32'b0;
        end else begin
            clk_count <= clk_count + 1;
        end
    end
endmodule