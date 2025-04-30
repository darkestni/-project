`timescale 1ns / 1ps

module PipelineCPU_tb;

    // �����ź�
    reg clk;
    reg reset;
    reg debugMode;
    reg step;
    reg [7:0] dipSwitch;
    reg button;
    reg uart_rx;
    reg [1:0] baud_select;

    // ����ź�
    wire [7:0] led;
    wire [6:0] seg;
    wire [3:0] an;
    wire [3:0] vga_r, vga_g, vga_b;
    wire vga_hs, vga_vs;

    // ʵ���� PipelineCPU ģ��
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

    // ʱ������ (100 MHz, ���� 10 ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // ��������
    initial begin
        // ��ʼ�������ź�
        reset = 1;
        debugMode = 0;
        step = 0;
        dipSwitch = 8'b00000000;
        button = 0;
        uart_rx = 1;  // UART ����״̬Ϊ�ߵ�ƽ
        baud_select = 2'b00;  // 115200 ������

        // ��λ
        #20;
        reset = 0;

        // ���� 1: ��������ģʽ
        #100;
        debugMode = 0;  // �رյ���ģʽ
        step = 0;
        dipSwitch = 8'b10101010;  // ���ò��뿪��
        #1000;  // ����һ��ʱ�䣬�۲� LED ���߶���������

        // ���� 2: ����ģʽ
        debugMode = 1;  // ��������ģʽ
        #100;
        step = 1;  // ����ִ��
        #20;
        step = 0;
        #100;
        step = 1;  // �ٵ���ִ��
        #20;
        step = 0;
        #500;

        // ���� 3: ��ť����
        button = 1;
        #100;
        button = 0;
        #500;

        // ���� 4: UART ���� (ģ��һ���ֽڵĴ��䣬������ 115200)
        // ����һ���ֽ� 0x55 (01010101)����ʼλ + 8 ����λ + ֹͣλ
        uart_rx = 0;  // ��ʼλ
        #8680;  // 1 bit ʱ�� (115200 ������, 1 bit = 8.68 us = 8680 ns)
        uart_rx = 1;  #8680;  // Bit 0
        uart_rx = 0;  #8680;  // Bit 1
        uart_rx = 1;  #8680;  // Bit 2
        uart_rx = 0;  #8680;  // Bit 3
        uart_rx = 1;  #8680;  // Bit 4
        uart_rx = 0;  #8680;  // Bit 5
        uart_rx = 1;  #8680;  // Bit 6
        uart_rx = 0;  #8680;  // Bit 7
        uart_rx = 1;  #8680;  // ֹͣλ
        #10000;

        // ���� 5: �л�������
        baud_select = 2'b01;  // 57600 ������
        #10000;

        // ��������
        $finish;
    end

    // �������
    initial begin
        $monitor("Time=%0t | reset=%b | debugMode=%b | step=%b | dipSwitch=%b | button=%b | led=%b | seg=%b | an=%b",
                 $time, reset, debugMode, step, dipSwitch, button, led, seg, an);
    end

endmodule