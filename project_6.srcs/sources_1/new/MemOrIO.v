`timescale 1ns / 1ps

//==============================================================================
// Description:
//     This module acts as a memory and I/O data router for load and store 
//     instructions. Based on control signals, it determines whether to perform
//     memory access or I/O access, and routes addresses and data accordingly.
//     It supports reads and writes to both memory and I/O devices like LEDs and
//     switches.
//
//     Functionality includes:
//       - Selecting the proper address output based on the instruction
//       - Muxing read data from memory or I/O into the register file
//       - Selecting the correct data to write to memory or I/O
//       - Enabling control signals for I/O devices (LEDs, switches)
//==============================================================================
module MemOrIO (
    input mRead,                    // Memory read enable signal
    input mWrite,                   // Memory write enable signal
    input ioRead,                   // I/O read enable signal
    input ioWrite,                  // I/O write enable signal
    input [31:0] addr_in,           // Address input from ALU (for memory or I/O access)
    output [31:0] addr_out,         // Address output to memory or I/O (usually same as addr_in)
    input [31:0] m_rdata,           // Data read from memory
    input [15:0] io_rdata,          // Data read from I/O device (e.g., switches)
    input [31:0] r_rdata,           // Data from register file to be written
    output [31:0] memToRegData,          // Data to write back to register file (from memory or I/O)
    output reg [31:0] regToMemData,   // Data to write to memory or I/O
    output LEDCtrl,                 // Output control signal to enable writing to LEDs
    output SwitchCtrl              // Output control signal to enable reading from switches
);

    // 地址分配
    // 数据存储器：0x00000000 - 0x0000FFFF
    // IO 设备：0xFFFFFC00 - 0xFFFFFFFF
    wire isDMem = (addr_in <= 32'h0000FFFF);
    wire isIO = (addr_in >= 32'hFFFFFC00 && addr_in <= 32'hFFFFFFFF);

    // 地址直接传递
    assign addr_out = addr_in;

    // 数据路由：写回寄存器文件的数据来源
    assign memToRegData = (ioRead && isIO) ? {16'd0, io_rdata} : // 从 IO 设备读取
                     (mRead && isDMem) ? m_rdata :          // 从数据存储器读取
                     32'hZZZZZZZZ;                          // 默认值

    // 控制信号生成
    assign LEDCtrl = (ioWrite && addr_in == 32'hFFFFFC60) ? 1'b1 : 1'b0;
    assign SwitchCtrl = (ioRead && (addr_in == 32'hFFFFFC70 || addr_in == 32'hFFFFFC72)) ? 1'b1 : 1'b0;

    // 写数据路由
    always @(*) begin
        if (mWrite && isDMem) begin
            regToMemData = r_rdata;
        end else if (ioWrite && isIO) begin
            regToMemData = r_rdata;
        end else begin
            regToMemData = 32'hZZZZZZZZ;
        end
    end

endmodule