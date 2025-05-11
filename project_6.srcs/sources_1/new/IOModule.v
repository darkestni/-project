`timescale 1ns / 1ps
//==============================================================================
// Module: IOModule (适配流水线MEM阶段的I/O设备逻辑)
// Author: [Your Name/Original Author]
// Date: [Current Date]
// Description:
//     此模块实现内存映射I/O外设的逻辑，如DIP开关、按钮、LED和七段数码管。
//     它接收来自MEM阶段主控逻辑(如MemOrIO)的完整I/O地址和通用的I/O读/写使能信号。
//     本模块内部根据传入的io_address进行最终的设备选择和操作。
//
//     与流水线集成:
//       - io_address, io_writeData, io_access_write_enable, io_access_read_enable
//         信号由MEM阶段的MemOrIO模块在确认是I/O访问后提供。
//       - 读出的数据返回给MemOrIO模块。
//==============================================================================
module IOModule (
    input clk,                      // 系统时钟
    // input reset,                 // 复位信号，根据需要添加

    // --- 输入信号 (通常来自MemOrIO或等效的MEM阶段I/O控制器) ---
    input [31:0] io_address,        // I/O设备地址 (由MemOrIO传递的原始ALU结果)
    input [31:0] io_writeData,      // 要写入I/O设备的数据 (由MemOrIO传递)
    input        io_access_write_enable, // 通用I/O写操作使能 (当MemOrIO确认是I/O写时为高)
    input        io_access_read_enable,  // 通用I/O读操作使能 (当MemOrIO确认是I/O读时为高)

    // --- 实际的物理I/O端口 ---
    input [7:0]  dipSwitch_physical_in, // 来自DIP开关的物理输入 (8位)
    input        button_physical_in,    // 来自按钮的物理输入

    output reg [31:0] io_readData_out,  // 从选定I/O设备读取的数据 (送回MemOrIO)
    output reg [7:0]  led_physical_out, // 输出到8位LED阵列的物理信号
    output reg [6:0]  seg_physical_out, // 输出到七段数码管段码的物理信号 (a–g)
    output reg [3:0]  an_physical_out   // 输出到七段数码管位选的物理信号
);

    // I/O设备绝对地址映射
    // 这些地址应与CPU设计中为I/O设备规划的地址完全一致
    localparam DIP_ADDR    = 32'hFFFF0000;
    localparam BUTTON_ADDR = 32'hFFFF0004;
    localparam LED_ADDR    = 32'hFFFF0008;
    localparam SEG_ADDR    = 32'hFFFF000C;

    // 七段数码管编码 (0-9)
    reg [6:0] seg_codes [0:9];
    initial begin
        // 共阳极数码管编码示例 (低电平有效)
        seg_codes[0] = 7'b1000000; // 0
        seg_codes[1] = 7'b1111001; // 1
        seg_codes[2] = 7'b0100100; // 2
        seg_codes[3] = 7'b0110000; // 3
        seg_codes[4] = 7'b0011001; // 4
        seg_codes[5] = 7'b0010010; // 5
        seg_codes[6] = 7'b0000010; // 6
        seg_codes[7] = 7'b1111000; // 7
        seg_codes[8] = 7'b0000000; // 8
        seg_codes[9] = 7'b0010000; // 9
    end

    // I/O读操作 (组合逻辑)
    // 当 io_access_read_enable 有效时，根据 io_address 决定从哪个设备读取数据
    always @(*) begin
        io_readData_out = 32'd0; // 默认无读数据或无效读取
        if (io_access_read_enable) begin
            case (io_address)
                DIP_ADDR:    io_readData_out = {24'd0, dipSwitch_physical_in};
                BUTTON_ADDR: io_readData_out = {31'd0, button_physical_in};
                // default: io_readData_out = 32'd0; // 已在外部设置默认值
            endcase
        end
    end

    // I/O写操作 (同步逻辑)
    // 当 io_access_write_enable 有效时，根据 io_address 决定向哪个设备写入数据
    always @(posedge clk) begin
        // 如果需要复位LED和数码管的状态，可以在这里添加reset逻辑
        // if (reset) begin
        //    led_physical_out <= 8'd0;
        //    seg_physical_out <= 7'b1111111; // 例如：共阳极全灭
        //    an_physical_out  <= 4'b1111;    // 例如：全不选通
        // end else
        if (io_access_write_enable) begin
            case (io_address)
                LED_ADDR:  led_physical_out <= io_writeData[7:0];
                SEG_ADDR: begin
                    // 假设 io_writeData[3:0] 是要显示的数字 (0-9)
                    // 假设 io_writeData[7:4] 控制位选 an (如果需要更复杂的控制)
                    // 这里简化为只显示一位，并固定位选
                    if (io_writeData[3:0] < 10) begin // 检查输入是否在0-9范围内
                        seg_physical_out <= seg_codes[io_writeData[3:0]];
                    end else begin
                        // 对于无效数字，可以显示空白、错误指示，或保持上一个有效状态
                        seg_physical_out <= 7'b1111111; // 例如：显示空白 (共阳极)
                    end
                    // 数码管位选逻辑
                    // 如果是单个数码管，可以固定一个位选，例如选中第一个：
                    an_physical_out  <= 4'b1110; // 假设使能第一个数码管 (AN0低电平有效)
                    // 如果需要根据 io_writeData 的某几位来选择哪个数码管，可以在这里添加逻辑
                    // 例如: an_physical_out <= ~io_writeData[7:4]; (假设writeData的高位控制位选)
                    // 如果是动态扫描，此处的 an_physical_out 和 seg_physical_out 的更新会更复杂，
                    // 通常需要一个独立的扫描控制器或在更高频率的时钟下更新。
                end
                // default: no operation for other addresses within I/O space
            endcase
        // } else { // 当 io_access_write_enable 为低时，可以选择保持输出或赋默认值
            // 如果不希望在非写周期改变LED/数码管状态，则此else块可以省略，寄存器会保持值
        // }
        end
    end

endmodule
