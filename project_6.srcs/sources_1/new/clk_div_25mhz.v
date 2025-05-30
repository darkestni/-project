module clk_div_25mhz(
    input wire clk_in,        // 100 MHz 时钟输入
    input wire rst,           // 异步复位
    output reg clk_out        // 25 MHz 时钟输出
);

    reg [4:0] count;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count   <= 4'b0000;
            clk_out <= 1'b0;
        end else begin
            if (count >= 4'b0011) begin
                count <= 4'b0000;
                clk_out <= ~clk_out;
            end else begin
                count <= count + 1'b1;
            end
        end
    end

endmodule
