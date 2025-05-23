module clk_div_25mhz(
    input wire clk_in,        // 100 MHz 时钟输入
    input wire rst,           // 异步复位
    output reg clk_out        // 25 MHz 时钟输出
);

    reg [1:0] count;

    always @(posedge clk_in or posedge rst) begin
        if (rst) begin
            count   <= 2'b00;
            clk_out <= 1'b0;
        end else begin
            count <= count + 1;
            if (count == 2'b01 || count == 2'b11)
                clk_out <= ~clk_out;
        end
    end

endmodule
