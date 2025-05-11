//==============================================================================
// Module: EXMEM_PipelineRegister
// Author: [Your Name]
// Date: [Current Date]
// Description:
//     EX/MEM 流水线寄存器。
//     在执行(EX)阶段和访存(MEM)阶段之间锁存数据和控制信号。
//     支持复位、冲刷和写使能控制。
//==============================================================================
module EXMEM_PipelineRegister (
    input clk,
    input reset,
    input enable_write, // 写使能信号 (通常是 !stall_mem_stage)
    input flush_exmem,  // 冲刷信号 (例如，分支预测错误或异常发生时)

    // --- 输入信号 (来自EX阶段的输出) ---
    // 数据通路值
    input [31:0] alu_result_from_ex,            // ALU运算结果
    input [31:0] branch_target_addr_from_ex,    // 分支/跳转目标地址 (EX级计算得到)
    input [31:0] rdata2_for_store_from_ex,      // 用于Store指令的源操作数2的数据
    input [4:0]  rd_addr_from_ex,               // 目标寄存器地址
    input [31:0] pc_from_ex,                    // 当前指令的PC值 (来自EX级)
    input [31:0] pc_plus_4_from_ex,             // 当前指令的PC+4值 (来自EX级, 用于JAL/JALR写回)

    // 控制信号 (来自EX阶段的Controller_EX_Logic或透传)
    input        final_RegWrite_ctrl_from_ex, // 最终的寄存器写使能信号
    input        MemRead_ctrl_from_ex,        // 内存读使能
    input        MemWrite_ctrl_from_ex,       // 内存写使能
    input        IORead_ctrl_from_ex,         // I/O读使能
    input        IOWrite_ctrl_from_ex,        // I/O写使能
    input        MemToReg_ctrl_from_ex,       // 选择写回寄存器的数据来源 (ALU结果 vs 内存/IO数据)


    // --- 输出信号 (送往MEM阶段) ---
    // 数据通路值
    output reg [31:0] alu_result_to_mem,
    output reg [31:0] branch_target_addr_to_mem,
    output reg [31:0] rdata2_for_store_to_mem,
    output reg [4:0]  rd_addr_to_mem,
    output reg [31:0] pc_to_mem,
    output reg [31:0] pc_plus_4_to_mem,

    // 控制信号
    output reg        final_RegWrite_ctrl_to_mem,
    output reg        MemRead_ctrl_to_mem,
    output reg        MemWrite_ctrl_to_mem,
    output reg        IORead_ctrl_to_mem,
    output reg        IOWrite_ctrl_to_mem,
    output reg        MemToReg_ctrl_to_mem
);

    // 定义用于冲刷或复位时的NOP（无操作）控制信号值
    localparam CTL_NOP_REGWRITE  = 1'b0;
    localparam CTL_NOP_MEMREAD   = 1'b0;
    localparam CTL_NOP_MEMWRITE  = 1'b0;
    localparam CTL_NOP_IOREAD    = 1'b0;
    localparam CTL_NOP_IOWRITE   = 1'b0;
    localparam CTL_NOP_MEMTOREG  = 1'b0; // 若RegWrite为0，此值不重要

    // 定义用于冲刷或复位时的数据通路默认值
    localparam DATA_NOP_DEFAULT  = 32'd0;
    localparam ADDR_NOP_DEFAULT  = 5'd0;


    always @(posedge clk or posedge reset) begin
        if (reset || flush_exmem) begin
            // 复位或冲刷时，所有输出设置为NOP或默认值
            // 数据通路值
            alu_result_to_mem         <= DATA_NOP_DEFAULT;
            branch_target_addr_to_mem <= DATA_NOP_DEFAULT; // 目标地址设为0
            rdata2_for_store_to_mem   <= DATA_NOP_DEFAULT;
            rd_addr_to_mem            <= ADDR_NOP_DEFAULT; // 目标寄存器地址设为x0
            pc_to_mem                 <= DATA_NOP_DEFAULT; // PC值设为0
            pc_plus_4_to_mem          <= DATA_NOP_DEFAULT; // PC+4值设为0 (或4)

            // 控制信号
            final_RegWrite_ctrl_to_mem <= CTL_NOP_REGWRITE;
            MemRead_ctrl_to_mem        <= CTL_NOP_MEMREAD;
            MemWrite_ctrl_to_mem       <= CTL_NOP_MEMWRITE;
            IORead_ctrl_to_mem         <= CTL_NOP_IOREAD;
            IOWrite_ctrl_to_mem        <= CTL_NOP_IOWRITE;
            MemToReg_ctrl_to_mem       <= CTL_NOP_MEMTOREG;

        end else if (enable_write) begin
            // 如果允许写入 (MEM阶段没有暂停)，则锁存来自EX阶段的信号
            // 数据通路值
            alu_result_to_mem         <= alu_result_from_ex;
            branch_target_addr_to_mem <= branch_target_addr_from_ex;
            rdata2_for_store_to_mem   <= rdata2_for_store_from_ex;
            rd_addr_to_mem            <= rd_addr_from_ex;
            pc_to_mem                 <= pc_from_ex;
            pc_plus_4_to_mem          <= pc_plus_4_from_ex;

            // 控制信号
            final_RegWrite_ctrl_to_mem <= final_RegWrite_ctrl_from_ex;
            MemRead_ctrl_to_mem        <= MemRead_ctrl_from_ex;
            MemWrite_ctrl_to_mem       <= MemWrite_ctrl_from_ex;
            IORead_ctrl_to_mem         <= IORead_ctrl_from_ex;
            IOWrite_ctrl_to_mem        <= IOWrite_ctrl_from_ex;
            MemToReg_ctrl_to_mem       <= MemToReg_ctrl_from_ex;
        end
        // else if (!enable_write), 寄存器保持不变 (stall)
    end

endmodule
