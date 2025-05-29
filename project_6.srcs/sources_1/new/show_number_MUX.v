module show_number_clk_count_MUX(
    input mux,
    input clk,
    input reset,
    input [15:0] led_data,
    input [31:0] data1,
    output wire [31:0] to_show_number,
);
    reg [31:0] clk_count;
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_count <= 32'b0;
        end else if (led_data[0]) begin
            clk_count <= clk_count + 1;
        end else begin
            clk_count <= clk_count;
        end
    end
    assign to_show_number = mux ? clk_count : data1;

endmodule