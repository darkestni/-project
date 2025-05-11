`timescale 1ns / 1ps

module MEMWB_PipelineRegister (
    input clk,
    input reset,
    // input enable_write, // 通常WB阶段不暂停，除非整个流水线暂停
    // input flush_memwb,  // WB阶段通常不被刷新，因为指令已执行到最后

    // --- 输入信号 (来自MEM阶段的输出) ---
    // 数据通路
    input [31:0] alu_result_from_mem,
    input [31:0] data_read_from_mem, // 来自MemOrIO的data_read_to_memwb
    input [4:0]  rd_addr_from_mem,

    // 控制信号
    input        final_RegWrite_ctrl_from_mem,
    input        MemToReg_ctrl_from_mem,
    // input [31:0] pc_plus_4_from_mem, // 如果JAL/JALR的返回地址在这里处理或调试用
    // input        is_ecall_from_mem,    // 如果ecall需要在WB阶段特殊处理（通常不需要）


    // --- 输出信号 (送往WB阶段) ---
    // 数据通路
    output reg [31:0] alu_result_to_wb,
    output reg [31:0] data_read_from_mem_to_wb,
    output reg [4:0]  rd_addr_to_wb,

    // 控制信号
    output reg        final_RegWrite_ctrl_to_wb,
    output reg        MemToReg_ctrl_to_wb
    // output reg [31:0] pc_plus_4_to_wb,
    // output reg        is_ecall_to_wb
);

    // NOP/Flush时的默认控制信号值 (通常WB不被flush，但reset时需要默认值)
    localparam CTL_NOP_REGWRITE  = 1'b0;
    localparam CTL_NOP_MEMTOREG  = 1'b0; // 不重要，因为RegWrite为0

    always @(posedge clk or posedge reset) begin
        if (reset) begin //  || flush_memwb
            // 数据通路值复位 (可以设为0或不确定值)
            alu_result_to_wb         <= 32'd0;
            data_read_from_mem_to_wb <= 32'd0;
            rd_addr_to_wb            <= 5'd0;
            // pc_plus_4_to_wb          <= 32'd0;

            // 控制信号复位为NOP状态
            final_RegWrite_ctrl_to_wb  <= CTL_NOP_REGWRITE;
            MemToReg_ctrl_to_wb      <= CTL_NOP_MEMTOREG;
            // is_ecall_to_wb           <= 1'b0;

        // end else if (enable_write) begin // 如果有写使能
        end else begin // 假设MEM/WB寄存器总是写入（除非整个流水线暂停）
            // 传递来自MEM阶段的数据和控制信号
            alu_result_to_wb         <= alu_result_from_mem;
            data_read_from_mem_to_wb <= data_read_from_mem;
            rd_addr_to_wb            <= rd_addr_from_mem;
            // pc_plus_4_to_wb          <= pc_plus_4_from_mem;

            final_RegWrite_ctrl_to_wb  <= final_RegWrite_ctrl_from_mem;
            MemToReg_ctrl_to_wb      <= MemToReg_ctrl_from_mem;
            // is_ecall_to_wb           <= is_ecall_from_mem;
        // end
        // 如果 enable_write 为0 (流水线暂停), 寄存器保持原值
        end
    end
endmodule
