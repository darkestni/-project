`timescale 1ns / 1ps

//==============================================================================
// Module: WriteBack_Stage
// Description:
//     此模块实现CPU五级流水线的写回 (Write Back - WB) 阶段逻辑。
//     它负责从MEM/WB流水线寄存器接收数据和控制信号，
//     根据控制信号选择正确的数据源（ALU结果或内存/IO读取的数据），
//     并将数据和相应的控制信号传递给寄存器堆进行写回操作。
//==============================================================================
module WriteBack_Stage (
    // --- 输入信号 (来自MEM/WB流水线寄存器) ---
    input [31:0] alu_result_from_memwb,          // 来自ALU的计算结果
    input [31:0] data_read_from_mem_from_memwb,  // 从内存或I/O读取的数据
    input [4:0]  rd_addr_from_memwb,             // 目标寄存器的地址 (rd)
    input        final_RegWrite_ctrl_from_memwb, // 最终的寄存器写使能控制信号
    input        MemToReg_ctrl_from_memwb,       // 选择写回数据来源的控制信号
                                                 //   0: 数据来自ALU结果
                                                 //   1: 数据来自内存/IO读取结果

    // --- 输出信号 (送往RegisterFile的写端口) ---
    output reg [31:0] write_data_to_regfile,     // 最终要写入寄存器堆的数据
    output reg [4:0]  write_addr_to_regfile,     // 最终要写入寄存器堆的目标地址
    output reg        reg_write_enable_to_regfile // 最终的寄存器写使能信号
);

    // 写回数据选择逻辑
    // 根据 MemToReg_ctrl_from_memwb 信号选择数据源
    always @(*) begin
        if (MemToReg_ctrl_from_memwb) begin
            // MemToReg = 1: 数据来自内存或I/O的读取结果 (例如LW指令)
            write_data_to_regfile = data_read_from_mem_from_memwb;
        end else begin
            // MemToReg = 0: 数据来自ALU的计算结果 (例如R-type, I-type ALU指令)
            write_data_to_regfile = alu_result_from_memwb;
        end
    end

    // 目标寄存器地址和写使能信号直接透传
    // (在流水线设计中，这些信号在MEM/WB寄存器中已经是最终确定的值)
    always @(*) begin
        write_addr_to_regfile       = rd_addr_from_memwb;
        reg_write_enable_to_regfile = final_RegWrite_ctrl_from_memwb;
    end

    // 可选：添加调试信息输出
    // always @(*) begin
    //     $display("WB_STAGE: Time=%0t, RegWrite=%b, MemToReg=%b, RdAddr=%h, ALURes=%h, MemData=%h, WriteData=%h",
    //              $time, final_RegWrite_ctrl_from_memwb, MemToReg_ctrl_from_memwb, rd_addr_from_memwb,
    //              alu_result_from_memwb, data_read_from_mem_from_memwb, write_data_to_regfile);
    // end

endmodule
