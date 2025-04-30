`timescale 1ns / 1ps

module IFetch (
    input clk,
    input reset,
    input debugMode,
    input step,
    input branch,
    input jump,
    input zero,
    input [31:0] imm32,
    input [31:0] jalr_target,
    input [31:0] test_scenario,
    output reg [31:0] instruction,
    output reg [31:0] pc
);

    // PC 寄存器
    reg [31:0] next_pc;
    reg step_prev;

    // BRAM 指令存储器
    wire [31:0] bram_instruction;
    blk_mem_gen_0 inst_mem_bram (
        .clka(clk),
        .wea(1'b0),               // 只读
        .addra(pc[11:2]),         // 地址（PC 索引）
        .dina(32'h0),             // 写数据（不使用）
        .douta(bram_instruction), // 读数据（指令）
        .MUX_RST(reset)           // 连接复位信号
    );

    // PC 更新逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;
            step_prev <= 0;
        end else begin
            step_prev <= step;
            if (debugMode) begin
                if (step && !step_prev) begin // 检测 step 的上升沿
                    pc <= next_pc;
                end
            end else begin
                pc <= next_pc;
            end
        end
    end

    // 计算下一条 PC
    always @(*) begin
        if (branch && zero) begin
            next_pc = pc + imm32; // 分支跳转
        end else if (jump) begin
            if (imm32 != 32'd0) begin
                next_pc = pc + imm32; // jal
            end else begin
                next_pc = jalr_target; // jalr
            end
        end else begin
            next_pc = pc + 4; // 正常 PC + 4
        end
    end

    // 指令读取
    always @(*) begin
        if (test_scenario != 32'd0) begin
            instruction = test_scenario; // UART 输入覆盖指令
        end else begin
            instruction = bram_instruction; // 从 BRAM 读取指令
        end
    end

endmodule