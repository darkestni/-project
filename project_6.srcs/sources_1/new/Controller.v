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
    input [21:0] Alu_resultHigh, // ALU 结果的高 22 位
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
        // 默认值
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
            7'b0110011: begin // R 型 (add, sub, and, or)
                RegWrite = 1;
                ALUSrc = 0;
                ALUOp = 2'b10;
            end
            7'b0010011: begin // I 型 (addi)
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0000011: begin // I 型 (lw)
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
                if (Alu_resultHigh == 22'h3FFFFF) begin
                    IORead = 1; // 地址在 IO 范围内
                end else begin
                    MemRead = 1; // 地址在存储器范围内
                end
            end
            7'b0100011: begin // S 型 (sw)
                ALUSrc = 1;
                ALUOp = 2'b00;
                if (Alu_resultHigh == 22'h3FFFFF) begin
                    IOWrite = 1; // 地址在 IO 范围内
                end else begin
                    MemWrite = 1; // 地址在存储器范围内
                end
            end
            7'b1100011: begin // SB 型 (beq, bne, blt)
                branch = 1;
                ALUOp = 2'b01;
            end
            7'b1101111: begin // UJ 型 (jal)
                RegWrite = 1;
                jump = 1;
                ALUOp = 2'b00;
            end
            7'b1100111: begin // I 型 (jalr)
                RegWrite = 1;
                jump = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0010111: begin // U 型 (auipc)
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b0110111: begin // U 型 (lui)
                RegWrite = 1;
                ALUSrc = 1;
                ALUOp = 2'b00;
            end
            7'b1110011: begin // ecall
                if (ecall == 2'b01) begin
                    RegWrite = 1;
                    ALUOp = 2'b00;
                end else if (ecall == 2'b10) begin
                    IOWrite = 1; // ecall 功能 2，写 LED
                end
            end
        endcase

        // MemorIOtoReg 逻辑
        MemorIOtoReg = IORead || MemRead;
    end

endmodule
