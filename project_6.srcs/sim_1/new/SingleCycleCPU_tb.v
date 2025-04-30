`timescale 1ns / 1ps

module SingleCycleCPU_tb;

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

    // 实例化 SingleCycleCPU 模块
    SingleCycleCPU uut (
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

        // 测试 1: 正常运行模式，执行指令
        // 假设 inst_mem.mem 包含以下指令：
        // 0x00000000: addi x1, x0, 5      (00000293)
        // 0x00000004: addi x2, x0, 10     (00A00113)
        // 0x00000008: add x3, x1, x2      (002081B3)
        // 0x0000000C: sw x3, 0(x0)        (00302023)
        // 0x00000010: lw x4, 0(x0)        (00002203)
        #50;  // 运行 5 个周期，完成 5 条指令
        $display("Test 1: Normal execution - LED=%h, Seg=%h, An=%h", led, seg, an);

        // 测试 2: 调试模式，单步执行
        debugMode = 1;  // 开启调试模式
        #10;
        step = 1;  // 单步执行第一条指令
        #10;
        step = 0;
        #10;
        step = 1;  // 单步执行第二条指令
        #10;
        step = 0;
        #10;
        $display("Test 2: Debug mode - LED=%h, Seg=%h, An=%h", led, seg, an);
        debugMode = 0;  // 关闭调试模式

        // 测试 3: IO 操作 - 拨码开关和按钮
        dipSwitch = 8'b10101010;  // 设置拨码开关
        #20;
        button = 1;  // 按下按钮
        #20;
        button = 0;  // 释放按钮
        #20;
        $display("Test 3: IO - DipSwitch=%b, Button=%b, LED=%h, Seg=%h, An=%h", dipSwitch, button, led, seg, an);

        // 测试 4: ecall 功能 2 - 写 LED
        // 假设当前指令为 ecall 功能 2，寄存器 x10 (a0) = 0xFF
        // 需要手动设置 inst_mem.mem 加载 ecall 指令
        #20;
        $display("Test 4: ecall function 2 - LED=%h", led);

        // 测试 5: UART 输入
        // 模拟一个字节的传输，波特率 115200 (1 bit = 8680 ns)
        uart_rx = 0;  // 起始位
        #8680;
        uart_rx = 1;  #8680;  // Bit 0
        uart_rx = 0;  #8680;  // Bit 1
        uart_rx = 1;  #8680;  // Bit 2
        uart_rx = 0;  #8680;  // Bit 3
        uart_rx = 1;  #8680;  // Bit 4
        uart_rx = 0;  #8680;  // Bit 5
        uart_rx = 1;  #8680;  // Bit 6
        uart_rx = 0;  #8680;  // Bit 7
        uart_rx = 1;  #8680;  // 停止位
        #1000;
        $display("Test 5: UART - LED=%h, Seg=%h, An=%h", led, seg, an);

        // 测试 6: VGA 输出
        // 假设写入 VGA 地址 0xFFFF1000
        #50;
        $display("Test 6: VGA - R=%h, G=%h, B=%h, HS=%b, VS=%b", vga_r, vga_g, vga_b, vga_hs, vga_vs);

        // 结束仿真
        $finish;
    end

    // 监视输出
    initial begin
        $monitor("Time=%0t | reset=%b | debugMode=%b | step=%b | dipSwitch=%b | button=%b | led=%b | seg=%b | an=%b",
                 $time, reset, debugMode, step, dipSwitch, button, led, seg, an);
    end

endmodule