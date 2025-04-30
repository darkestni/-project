`timescale 1ns / 1ps

module SingleCycleCPU_tb;

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

    // ʵ���� SingleCycleCPU ģ��
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

        // ���� 1: ��������ģʽ��ִ��ָ��
        // ���� inst_mem.mem ��������ָ�
        // 0x00000000: addi x1, x0, 5      (00000293)
        // 0x00000004: addi x2, x0, 10     (00A00113)
        // 0x00000008: add x3, x1, x2      (002081B3)
        // 0x0000000C: sw x3, 0(x0)        (00302023)
        // 0x00000010: lw x4, 0(x0)        (00002203)
        #50;  // ���� 5 �����ڣ���� 5 ��ָ��
        $display("Test 1: Normal execution - LED=%h, Seg=%h, An=%h", led, seg, an);

        // ���� 2: ����ģʽ������ִ��
        debugMode = 1;  // ��������ģʽ
        #10;
        step = 1;  // ����ִ�е�һ��ָ��
        #10;
        step = 0;
        #10;
        step = 1;  // ����ִ�еڶ���ָ��
        #10;
        step = 0;
        #10;
        $display("Test 2: Debug mode - LED=%h, Seg=%h, An=%h", led, seg, an);
        debugMode = 0;  // �رյ���ģʽ

        // ���� 3: IO ���� - ���뿪�غͰ�ť
        dipSwitch = 8'b10101010;  // ���ò��뿪��
        #20;
        button = 1;  // ���°�ť
        #20;
        button = 0;  // �ͷŰ�ť
        #20;
        $display("Test 3: IO - DipSwitch=%b, Button=%b, LED=%h, Seg=%h, An=%h", dipSwitch, button, led, seg, an);

        // ���� 4: ecall ���� 2 - д LED
        // ���赱ǰָ��Ϊ ecall ���� 2���Ĵ��� x10 (a0) = 0xFF
        // ��Ҫ�ֶ����� inst_mem.mem ���� ecall ָ��
        #20;
        $display("Test 4: ecall function 2 - LED=%h", led);

        // ���� 5: UART ����
        // ģ��һ���ֽڵĴ��䣬������ 115200 (1 bit = 8680 ns)
        uart_rx = 0;  // ��ʼλ
        #8680;
        uart_rx = 1;  #8680;  // Bit 0
        uart_rx = 0;  #8680;  // Bit 1
        uart_rx = 1;  #8680;  // Bit 2
        uart_rx = 0;  #8680;  // Bit 3
        uart_rx = 1;  #8680;  // Bit 4
        uart_rx = 0;  #8680;  // Bit 5
        uart_rx = 1;  #8680;  // Bit 6
        uart_rx = 0;  #8680;  // Bit 7
        uart_rx = 1;  #8680;  // ֹͣλ
        #1000;
        $display("Test 5: UART - LED=%h, Seg=%h, An=%h", led, seg, an);

        // ���� 6: VGA ���
        // ����д�� VGA ��ַ 0xFFFF1000
        #50;
        $display("Test 6: VGA - R=%h, G=%h, B=%h, HS=%b, VS=%b", vga_r, vga_g, vga_b, vga_hs, vga_vs);

        // ��������
        $finish;
    end

    // �������
    initial begin
        $monitor("Time=%0t | reset=%b | debugMode=%b | step=%b | dipSwitch=%b | button=%b | led=%b | seg=%b | an=%b",
                 $time, reset, debugMode, step, dipSwitch, button, led, seg, an);
    end

endmodule