`timescale 1ns / 1ps

module MemOrIO (
    input mRead,
    input mWrite,
    input ioRead,
    input ioWrite,
    input [31:0] addr_in,
    output [31:0] addr_out,
    input [31:0] m_rdata,
    input [15:0] io_rdata,
    input [31:0] r_rdata,
    output [31:0] r_wdata,
    output reg [31:0] write_data,
    output LEDCtrl,
    output SwitchCtrl
);

    // 地址分配
    // 数据存储器：0x00000000 - 0x0000FFFF
    // IO 设备：0xFFFFFC00 - 0xFFFFFFFF
    wire isDMem = (addr_in <= 32'h0000FFFF);
    wire isIO = (addr_in >= 32'hFFFFFC00 && addr_in <= 32'hFFFFFFFF);

    // 地址直接传递
    assign addr_out = addr_in;

    // 数据路由：写回寄存器文件的数据来源
    assign r_wdata = (ioRead && isIO) ? {16'd0, io_rdata} : // 从 IO 设备读取
                     (mRead && isDMem) ? m_rdata :          // 从数据存储器读取
                     32'hZZZZZZZZ;                          // 默认值

    // 控制信号生成
    assign LEDCtrl = (ioWrite && addr_in == 32'hFFFFFC60) ? 1'b1 : 1'b0;
    assign SwitchCtrl = (ioRead && (addr_in == 32'hFFFFFC70 || addr_in == 32'hFFFFFC72)) ? 1'b1 : 1'b0;

    // 写数据路由
    always @(*) begin
        if (mWrite && isDMem) begin
            write_data = r_rdata;
        end else if (ioWrite && isIO) begin
            write_data = r_rdata;
        end else begin
            write_data = 32'hZZZZZZZZ;
        end
    end

endmodule