
`timescale 1ns / 1ps

module Execute (
    input [31:0] ReadData1,
    input [31:0] ReadData2,
    input [31:0] imm32,
    input ALUSrc,
    input [1:0] ALUOp,
    input [2:0] funct3,
    input [6:0] funct7,
    input [1:0] ecall,
    output reg [31:0] ALUResult,
    output reg zero
);
    wire [31:0] operand2 = ALUSrc ? imm32 : ReadData2;
    always @(*) begin
        zero = 0;
        if (ecall != 2'b00) begin
            if (ecall == 2'b01) begin
                ALUResult = ReadData1;
            end else begin
                ALUResult = 0;
            end
        end else begin
            case (ALUOp)
                2'b00: ALUResult = ReadData1 + operand2;  // 加法
                2'b01: begin  // 分支
                    ALUResult = ReadData1 - operand2;
                    case (funct3)
                        3'b000: zero = (ALUResult == 0);  // beq
                        3'b001: zero = (ALUResult != 0);  // bne
                        3'b100: zero = ($signed(ReadData1) < $signed(ReadData2));  // blt
                        default: zero = 0;
                    endcase
                end
                2'b10: begin  // R 型
                    case (funct3)
                        3'b000: ALUResult = (funct7 == 7'b0000000) ? (ReadData1 + operand2) : (ReadData1 - operand2);
                        3'b111: ALUResult = ReadData1 & operand2;
                        3'b110: ALUResult = ReadData1 | operand2;
                        default: ALUResult = 0;
                    endcase
                end
                default: ALUResult = 0;
            endcase
        end
    end
endmodule