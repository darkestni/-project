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
    input [31:0] jalrTarget,
    input [31:0] testScenario,
    output reg [31:0] instruction,
    output reg [31:0] pc
);
    parameter RESET_PC = 32'h00000000;
    // PC 寄存器
    reg [31:0] nextPc;
    reg stepPrev;

    // BRAM 指令存储器
    wire [31:0] bramInstruction;
    blk_mem_gen_0 instMemBram (
        .clka(clk),
        .wea(1'b0),               // 只读
        .addra(pc[11:2]),         // 地址（PC 索引）
        .dina(32'h0),             // 写数据（不使用）
        .douta(bramInstruction),  // 读数据（指令）
        .MUX_RST(reset)           // 连接复位信号
    );

    // PC 更新逻辑
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= RESET_PC;
            stepPrev <= 0;
        end else begin
            stepPrev <= step;
            if (debugMode) begin
                if (step && !stepPrev) begin // 检测 step 的上升沿
                    pc <= nextPc;
                end
            end else begin
                pc <= nextPc;
            end
        end
    end

    // 计算下一条 PC
    always @(*) begin
        if (branch && zero) begin
            nextPc = pc + imm32; // 分支跳转
        end else if (jump) begin
            if (imm32 != 32'd0) begin
                nextPc = pc + imm32; // jal
            end else begin
                nextPc = jalrTarget; // jalr
            end
        end else begin
            nextPc = pc + 4; // 正常 PC + 4
        end
    end

    // 指令读取
    always @(*) begin
        if (testScenario != 32'd0) begin
            instruction = testScenario; // UART 输入覆盖指令
        end else begin
            instruction = bramInstruction; // 从 BRAM 读取指令
        end
    end

endmodule
