`timescale 1ns / 1ps

module IOModule #(
    parameter BUTTON_WIDTH = 3,
    parameter DIP_WIDTH = 16,
    parameter LED_WIDTH = 16
)
(
    //顶层模块的16位DIP输入，15:13 样例选择 12:4 数值 3:0 DebugMode
    input clk,                      // 系统时钟
    input reset,                 // 复位信号，根据需要添加

    // --- 输入信号 (通常来自MemOrIO或等效的MEM阶段I/O控制器) ---
    input [31:0] io_address,        // I/O设备地址 (由MemOrIO传递的原始ALU结果)
    input [31:0] io_writeData,      // 要写入I/O设备的数据 (由MemOrIO传递)
    input        io_access_write_enable, // 通用I/O写操作使能 (当MemOrIO确认是I/O写时为高)
    input        io_access_read_enable,  // 通用I/O读操作使能 (当MemOrIO确认是I/O读时为高)
    input  [BUTTON_WIDTH-1:0]  button_physical_in,    // 来自按钮的物理输入
    input led_write_enable,
    input switch_read_enable,

    // --- 实际的物理I/O端口 ---
    input [DIP_WIDTH-1:0]  dipSwitch_physical_in, // 来自DIP开关的物理输入

    output reg [31:0] io_readData_out,  // 从选定I/O设备读取的数据 (送回MemOrIO)
    output reg [LED_WIDTH-1:0]  led_physical_out, // 输出到8位LED阵列的物理信号
    output reg [31:0]  seg_data_out // 输出到数码管

);


    // I/O设备绝对地址映射
    // 这些地址应与CPU设计中为I/O设备规划的地址完全一致
    localparam DIP_ADDR    = 32'hFFFF_F010;
    localparam DIP_ADDR_NUMBER_CTRL = 32'hFFFF_F020; 
    localparam BUTTON_ADDR = 32'hFFFF0004;
    localparam LED_ADDR    = 32'hFFFF_F000;
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
            if (io_address == DIP_ADDR && switch_read_enable) begin
                io_readData_out = {24'b0, dipSwitch_physical_in[12:4]};
            end 
            // else if (io_address == BUTTON_ADDR && switch_read_enable) begin
            //     io_readData_out ={{(32-BUTTON_WIDTH){1'b0}}, dipSwitch_physical_in};
            // end
            else if (io_address == DIP_ADDR_NUMBER_CTRL && switch_read_enable) begin
                io_readData_out = {29'b0, dipSwitch_physical_in[3:1]};
            end
            else if (io_address == BUTTON_ADDR) begin
                io_readData_out = {29'b0, button_physical_in};
            end
            else if (io_address == LED_ADDR) begin
                io_readData_out = {{(32-LED_WIDTH){1'b0}}, led_physical_out};
            end
            else if (io_address == SEG_ADDR) begin
                io_readData_out = seg_data_out;
            end
        end
    end

    // I/O写操作 (同步逻辑)
    // 当 io_access_write_enable 有效时，根据 io_address 决定向哪个设备写入数据
    // always @(posedge clk or posedge reset) begin
    //     // 如果需要复位LED和数码管的状态，可以在这里添加reset逻辑
    //     if (reset) begin
    //        led_physical_out <= {LED_WIDTH{1'b0}}; // 例如：全灭
    //        seg_data_out <= 32'b0; // 例如：共阳极全灭
    //     end else
    //     led_physical_out <= led_physical_out; // 保持LED状态
    //     if (io_access_write_enable) begin
    //         case (io_address)
    //             LED_ADDR:  if (led_write_enable) led_physical_out <= io_writeData[LED_WIDTH-1:0];
    //             SEG_ADDR: begin
    //                 seg_data_out <= io_writeData[31:0]; // 直接写入数码管数据
    //             end
    //             // default: no operation for other addresses within I/O space
    //         endcase
    //     // } else { // 当 io_access_write_enable 为低时，可以选择保持输出或赋默认值
    //         // 如果不希望在非写周期改变LED/数码管状态，则此else块可以省略，寄存器会保持值
    //     // }
    //     end
    // end
        // I/O写操作 (同步逻辑)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            led_physical_out <= {LED_WIDTH{1'b0}};
            seg_data_out     <= 32'b0;
        end else begin
            // 默认保持上一个周期的值，除非有写操作覆盖
            // led_physical_out <= led_physical_out; // Verilog中reg默认会保持值
            // seg_data_out     <= seg_data_out;

            if (io_access_write_enable) begin
                if (io_address == LED_ADDR && led_write_enable) begin
                    led_physical_out <= io_writeData[LED_WIDTH-1:0];
                end
                // No else for led_physical_out here, means it holds if condition not met

                if (io_address == SEG_ADDR) begin
                    seg_data_out <= io_writeData[31:0];
                end
                // No else for seg_data_out here, means it holds if condition not met
            end
            // 如果 io_access_write_enable 为0, led_physical_out 和 seg_data_out 都会保持它们的值
        end
    end


endmodule
