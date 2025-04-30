`timescale 1ns / 1ps

module PipelineCPU_tb;

    // 输入信号
    reg clk;
    reg reset;
    reg debugMode;
    reg step;
    reg [7:0] dipSwitch;
    reg button;
    reg uart_rx;
    reg [1:0] baud_select;

    // 输出信号
    wire [7:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hs, vga_vs;

    // 实例化 PipelineCPU 模块
    PipelineCPU uut (
        .clk(clk),
        .reset(reset),
        .debugMode(debugMode),
        .step(step),
        .dipSwitch(dipSwitch),
        .button(button),
        .uart_rx(uart_rx),
        .baud_select(baud_select),
        .led(led),
        .seg(seg),
        .an(an),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .vga_hs(vga_hs),
        .vga_vs(vga_vs)
    );

    // 时钟生成 (100 MHz, 周期 10 ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // 测试序列
    initial begin
        // 初始化输入信号
        reset = 1;
        debugMode = 0;
        step = 0;
        dipSwitch = 8'b00000000;
        button = 0;
        uart_rx = 1;  // UART 空闲状态为高电平
        baud_select = 2'b00;  // 115200 波特率

        // 复位
        #20;
        reset = 0;

        // 测试 1: 正常运行模式
        #100;
        debugMode = 0;  // 关闭调试模式
        step = 0;
        dipSwitch = 8'b10101010;  // 设置拨码开关
        #1000;  // 运行一段时间，观察 LED 和七段数码管输出

        // 测试 2: 调试模式
        debugMode = 1;  // 开启调试模式
        #100;
        step = 1;  // 单步执行
        #20;
        step = 0;
        #100;
        step = 1;  // 再单步执行
        #20;
        step = 0;
        #500;

        // 测试 3: 按钮输入
        button = 1;
        #100;
        button = 0;
        #500;

        // 测试 4: UART 输入 (模拟一个字节的传输，波特率 115200)
        // 发送一个字节 0x55 (01010101)，起始位 + 8 数据位 + 停止位
        uart_rx = 0;  // 起始位
        #8680;  // 1 bit 时间 (115200 波特率, 1 bit = 8.68 us = 8680 ns)
        uart_rx = 1;  #8680;  // Bit 0
        uart_rx = 0;  #8680;  // Bit 1
        uart_rx = 1;  #8680;  // Bit 2
        uart_rx = 0;  #8680;  // Bit 3
        uart_rx = 1;  #8680;  // Bit 4
        uart_rx = 0;  #8680;  // Bit 5
        uart_rx = 1;  #8680;  // Bit 6
        uart_rx = 0;  #8680;  // Bit 7
        uart_rx = 1;  #8680;  // 停止位
        #10000;

        // 测试 5: 切换波特率
        baud_select = 2'b01;  // 57600 波特率
        #10000;

        // 结束仿真
        $finish;
    end

    // 监视输出
    initial begin
        $monitor("Time=%0t | reset=%b | debugMode=%b | step=%b | dipSwitch=%b | button=%b | led=%b | seg=%b | an=%b",
                 $time, reset, debugMode, step, dipSwitch, button, led, seg, an);
    end

endmodule