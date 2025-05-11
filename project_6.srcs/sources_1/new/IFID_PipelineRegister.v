module IFID_PipelineRegister (
    input clk,
    input reset,
    input enable_write, // 写使能，通常是 `!stall_id` (ID阶段的暂停信号反相)
    input flush_ifid,   // 冲刷信号，当为1时，寄存器内容被清为NOP或复位值

    // 从IF阶段来的输入
    input  [31:0] instruction_from_if,
    input  [31:0] pc_current_from_if,
    input  [31:0] pc_plus_4_from_if,

    // 输出到ID阶段
    output reg [31:0] instruction_to_id,
    output reg [31:0] pc_current_to_id,
    output reg [31:0] pc_plus_4_to_id
);
    parameter NOP_INSTRUCTION = 32'h00000013; // 定义一个NOP指令 (例如: addi x0, x0, 0)
    parameter RESET_PC_VAL  = 32'h00000000; // 复位时的PC值

    always @(posedge clk or posedge reset) begin
        if (reset || flush_ifid) begin // 如果复位或需要冲刷
            instruction_to_id <= NOP_INSTRUCTION;
            pc_current_to_id  <= RESET_PC_VAL; // 或者一个特定的无效PC值
            pc_plus_4_to_id   <= RESET_PC_VAL + 4;
        end else if (enable_write) begin // 如果允许写入
            instruction_to_id <= instruction_from_if;
            pc_current_to_id  <= pc_current_from_if;
            pc_plus_4_to_id   <= pc_plus_4_from_if;
        end
        // 如果 enable_write 为0 (例如ID阶段暂停), 则寄存器保持原值
    end
endmodule