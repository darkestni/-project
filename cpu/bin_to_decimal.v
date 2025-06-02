module bin_to_decimal(
    input wire [31:0] input_signal, // 输入的二进制信号（两位十六进制有效）
    input wire to_decimal,          // 控制信号，高电平表示要进行转换
    output reg [31:0] output_decimal // 输出的十进制数（32 位二进制表示）
);

    // 用于存储输入的两位十六进制数
    reg [7:0] hex_value;

    // 用于存储转换后的十进制值
    reg [31:0] decimal_value;

    // 触发转换的信号
    always @(*) begin
        if(to_decimal) begin
            // 提取输入信号中的两位十六进制数（这里假设输入信号的低 8 位是两位十六进制数，可根据实际情况调整）
            hex_value = input_signal[7:0];

            // 将两位十六进制数转换为十进制值
            case(hex_value)
                8'h00: decimal_value = 32'h0;
                8'h01: decimal_value = 32'h1;
                8'h02: decimal_value = 32'h2;
                8'h03: decimal_value = 32'h3;
                8'h04: decimal_value = 32'h4;
                8'h05: decimal_value = 32'h5;
                8'h06: decimal_value = 32'h6;
                8'h07: decimal_value = 32'h7;
                8'h08: decimal_value = 32'h8;
                8'h09: decimal_value = 32'h9;
                8'h0A: decimal_value = 32'h10;
                8'h0B: decimal_value = 32'h11;
                8'h0C: decimal_value = 32'h12;
                8'h0D: decimal_value = 32'h13;
                8'h0E: decimal_value = 32'h14;
                8'h0F: decimal_value = 32'h15;
                8'h10: decimal_value = 32'h16;
                8'h11: decimal_value = 32'h17;
                8'h12: decimal_value = 32'h18;
                8'h13: decimal_value = 32'h19;
                8'h14: decimal_value = 32'h20;
                8'h15: decimal_value = 32'h21;
                8'h16: decimal_value = 32'h22;
                8'h17: decimal_value = 32'h23;
                8'h18: decimal_value = 32'h24;
                8'h19: decimal_value = 32'h25;
                8'h1A: decimal_value = 32'h26;
                8'h1B: decimal_value = 32'h27;
                8'h1C: decimal_value = 32'h28;
                8'h1D: decimal_value = 32'h29;
                8'h1E: decimal_value = 32'h30;
                8'h1F: decimal_value = 32'h31;
                8'h20: decimal_value = 32'h32;
                8'h21: decimal_value = 32'h33;
                8'h22: decimal_value = 32'h34;
                8'h23: decimal_value = 32'h35;
                8'h24: decimal_value = 32'h36;
                8'h25: decimal_value = 32'h37;
                8'h26: decimal_value = 32'h38;
                8'h27: decimal_value = 32'h39;
                8'h28: decimal_value = 32'h40;
                8'h29: decimal_value = 32'h41;
                8'h2A: decimal_value = 32'h42;
                8'h2B: decimal_value = 32'h43;
                8'h2C: decimal_value = 32'h44;
                8'h2D: decimal_value = 32'h45;
                8'h2E: decimal_value = 32'h46;
                8'h2F: decimal_value = 32'h47;
                8'h30: decimal_value = 32'h48;
                8'h31: decimal_value = 32'h49;
                8'h32: decimal_value = 32'h50;
                8'h33: decimal_value = 32'h51;
                8'h34: decimal_value = 32'h52;
                8'h35: decimal_value = 32'h53;
                8'h36: decimal_value = 32'h54;
                8'h37: decimal_value = 32'h55;
                8'h38: decimal_value = 32'h56;
                8'h39: decimal_value = 32'h57;
                8'h3A: decimal_value = 32'h58;
                8'h3B: decimal_value = 32'h59;
                8'h3C: decimal_value = 32'h60;
                8'h3D: decimal_value = 32'h61;
                8'h3E: decimal_value = 32'h62;
                8'h3F: decimal_value = 32'h63;
                default: decimal_value = 32'h0; // 默认值，处理非法输入
            endcase

            // 更新输出
            output_decimal = decimal_value;
        end
    end

endmodule