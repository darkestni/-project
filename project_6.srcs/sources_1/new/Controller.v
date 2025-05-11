`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/05/09 18:26:55
// Design Name: 
// Module Name: Controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module Controller (
    input [6:0] opcode,
    input [1:0] ecall,
    input [21:0] Alu_resultHigh, // ALU ����ĸ� 22 λ
    output reg RegWrite,
    output reg ALUSrc,
    output reg [1:0] ALUOp,
    output reg branch,
    output reg jump,
    output reg MemorIOtoReg,
    output reg MemRead,
    output reg MemWrite,
    output reg IORead,
    output reg IOWrite
);

    always @(*) begin
        // Ĭ��ֵ
        RegWrite = 0;
        ALUSrc = 0;
        ALUOp = 2'b00;
        branch = 0;
        jump = 0;
        MemorIOtoReg = 0;
        MemRead = 0;
        MemWrite = 0;
        IORead = 0;
        IOWrite = 0;

        case (opcode)
            7'b0110011: begin // R �� (add, sub, and, or)
                RegWrite = 1;
                ALUSrc = 0;
                ALUOp = 2'b10;
            end
            7'b0010011: begin // I �� (addi)
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0000011: begin // I �� (lw)
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
                if (Alu_resultHigh == 22'h3FFFFF) begin
                    IORead = 1; // ��ַ�� IO ��Χ��
                end else begin
                    MemRead = 1; // ��ַ�ڴ洢����Χ��
                end
            end
            7'b0100011: begin // S �� (sw)
                ALUSrc = 1;
                ALUOp = 2'b00;
                if (Alu_resultHigh == 22'h3FFFFF) begin
                    IOWrite = 1; // ��ַ�� IO ��Χ��
                end else begin
                    MemWrite = 1; // ��ַ�ڴ洢����Χ��
                end
            end
            7'b1100011: begin // SB �� (beq, bne, blt)
                branch = 1;
                ALUOp = 2'b01;
            end
            7'b1101111: begin // UJ �� (jal)
                RegWrite = 1;
                jump = 1;
                ALUOp = 2'b00;
            end
            7'b1100111: begin // I �� (jalr)
                RegWrite = 1;
                jump = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0010111: begin // U �� (auipc)
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0110111: begin // U �� (lui)
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b1110011: begin // ecall
                if (ecall == 2'b01) begin
                    RegWrite = 1;
                    ALUOp = 2'b00;
                end else if (ecall == 2'b10) begin
                    IOWrite = 1; // ecall ���� 2��д LED
                end
            end
        endcase

        // MemorIOtoReg �߼�
        MemorIOtoReg = IORead || MemRead;
    end

endmodule
