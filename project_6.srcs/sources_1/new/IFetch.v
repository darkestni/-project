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

    // PC �Ĵ���
    reg [31:0] next_pc;
    reg step_prev;

    // BRAM ָ��洢��
    wire [31:0] bram_instruction;
    blk_mem_gen_0 inst_mem_bram (
        .clka(clk),
        .wea(1'b0),               // ֻ��
        .addra(pc[11:2]),         // ��ַ��PC ������
        .dina(32'h0),             // д���ݣ���ʹ�ã�
        .douta(bram_instruction), // �����ݣ�ָ�
        .MUX_RST(reset)           // ���Ӹ�λ�ź�
    );

    // PC �����߼�
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= 32'h00000000;
            step_prev <= 0;
        end else begin
            step_prev <= step;
            if (debugMode) begin
                if (step && !step_prev) begin // ��� step ��������
                    pc <= next_pc;
                end
            end else begin
                pc <= next_pc;
            end
        end
    end

    // ������һ�� PC
    always @(*) begin
        if (branch && zero) begin
            next_pc = pc + imm32; // ��֧��ת
        end else if (jump) begin
            if (imm32 != 32'd0) begin
                next_pc = pc + imm32; // jal
            end else begin
                next_pc = jalr_target; // jalr
            end
        end else begin
            next_pc = pc + 4; // ���� PC + 4
        end
    end

    // ָ���ȡ
    always @(*) begin
        if (test_scenario != 32'd0) begin
            instruction = test_scenario; // UART ���븲��ָ��
        end else begin
            instruction = bram_instruction; // �� BRAM ��ȡָ��
        end
    end

endmodule