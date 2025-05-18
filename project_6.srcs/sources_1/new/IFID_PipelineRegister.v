// 当 enable_write 为低时（检测到冒险），IFID_PipelineRegister 会保持其当前存储的值，
// 不会从 IF 阶段锁存新的值。 当 reset 或 flush_ifid (例如，由于分支预测错误需要冲刷
// 流水线) 激活时，它会将输出设置为有意义的默认值：NOP_INSTRUCTION
//   (addi x0, x0, 0) 和复位PC值。

module IFID_PipelineRegister (
    input clk,
    input reset,
    input enable_write, 
    input flush_ifid,   // 冲刷信号，当为1时，寄存器内容被清为NOP或复位值

    input  [31:0] instruction_from_if,
    input  [31:0] pc_current_from_if,
    input  [31:0] pc_plus_4_from_if,

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