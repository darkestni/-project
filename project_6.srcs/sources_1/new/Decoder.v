`timescale 1ns / 1ps



module Decoder (
    input clk,
    input reset,  // 添加复位信号
    input regWrite,
    input [31:0] instruction,
    input [4:0] writeAddress,
    input [31:0] writeData,
    input [31:0] pc,
    output [31:0] rdata1,
    output [31:0] rdata2,
    output reg [31:0] imm32,
    output [2:0] funct3,
    output [6:0] funct7,
    output [4:0] rd,
    output reg [1:0] ecall   
);

    reg [31:0] registers [31:0];
    integer i;

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end else if (regWrite && writeAddress != 5'd0) begin
            registers[writeAddress] <= writeData;
        end
    end

    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    assign rdata1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign rdata2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];

    always @(*) begin
        ecall = 2'b00;
        case (opcode)
            7'b0110011: imm32 = 32'd0;  // R 型
            7'b0010011, 7'b0000011, 7'b1100111:  // I 型
                imm32 = {{20{instruction[31]}}, instruction[31:20]};
            7'b0100011:  // S 型
                imm32 = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            7'b1100011:  // SB 型
                imm32 = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            7'b1101111:  // UJ 型
                imm32 = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            7'b0010111:  // auipc
                imm32 = {instruction[31:12], 12'd0} + pc;
            7'b1110011: begin  // ecall
                imm32 = 32'd0;
                if (funct3 == 3'b000) begin
                    if (instruction[31:20] == 12'd0)
                        ecall = 2'b01;
                    else if (instruction[31:20] == 12'd1)
                        ecall = 2'b10;
                end
            end
            default: imm32 = 32'd0;
        endcase
    end

endmodule