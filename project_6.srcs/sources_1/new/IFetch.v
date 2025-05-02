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
    // PC �Ĵ���
    reg [31:0] nextPc;
    reg stepPrev;

    // BRAM ָ��洢��
    wire [31:0] bramInstruction;
    blk_mem_gen_0 instMemBram (
        .clka(clk),
        .wea(1'b0),               // ֻ��
        .addra(pc[11:2]),         // ��ַ��PC ������
        .dina(32'h0),             // д���ݣ���ʹ�ã�
        .douta(bramInstruction),  // �����ݣ�ָ�
        .MUX_RST(reset)           // ���Ӹ�λ�ź�
    );

    // PC �����߼�
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc <= RESET_PC;
            stepPrev <= 0;
        end else begin
            stepPrev <= step;
            if (debugMode) begin
                if (step && !stepPrev) begin // ��� step ��������
                    pc <= nextPc;
                end
            end else begin
                pc <= nextPc;
            end
        end
    end

    // ������һ�� PC
    always @(*) begin
        if (branch && zero) begin
            nextPc = pc + imm32; // ��֧��ת
        end else if (jump) begin
            if (imm32 != 32'd0) begin
                nextPc = pc + imm32; // jal
            end else begin
                nextPc = jalrTarget; // jalr
            end
        end else begin
            nextPc = pc + 4; // ���� PC + 4
        end
    end

    // ָ���ȡ
    always @(*) begin
        if (testScenario != 32'd0) begin
            instruction = testScenario; // UART ���븲��ָ��
        end else begin
            instruction = bramInstruction; // �� BRAM ��ȡָ��
        end
    end

endmodule
