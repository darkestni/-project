`timescale 1ns / 1ps

module ALU (
    input [31:0] read_data1,
    input [31:0] read_data2,
    input [31:0] imm32,
    input [1:0] ALUOp,
    input [2:0] funct3,
    input [6:0] funct7,
    input ALUSrc,
    output reg [31:0] ALU_result,
    output zero
);

reg [3:0] ALUControl;
wire [31:0] operand2 = ALUSrc ? imm32 : read_data2;

// ALU Control decoding
always @* begin
    case (ALUOp)
        2'b00: begin // I-type: addi, andi, ori, xori, slti, sltiu, slli, srli, srai
            case (funct3)
                3'b000: ALUControl = 4'b0010; // addi
                3'b010: ALUControl = 4'b0010; // lw: 强制使用加法
                3'b111: ALUControl = 4'b0000; // andi
                3'b110: ALUControl = 4'b0001; // ori
                3'b100: ALUControl = 4'b0011; // xori
                3'b001: ALUControl = 4'b1000; // slli
                3'b101: begin
                    if (funct7 == 7'b0000000) ALUControl = 4'b1001; // srli
                    else                      ALUControl = 4'b1010; // srai
                end
                default: ALUControl = 4'b1111;
            endcase
        end
        2'b01: ALUControl = 4'b0110; // branch use sub
        2'b10: begin // R-type
            case ({funct7, funct3})
                {7'b0000000, 3'b000}: ALUControl = 4'b0010; // add
                {7'b0100000, 3'b000}: ALUControl = 4'b0110; // sub
                {7'b0000000, 3'b111}: ALUControl = 4'b0000; // and
                {7'b0000000, 3'b110}: ALUControl = 4'b0001; // or
                {7'b0000000, 3'b100}: ALUControl = 4'b0011; // xor
                {7'b0000000, 3'b010}: ALUControl = 4'b0100; // slt
                {7'b0000000, 3'b011}: ALUControl = 4'b0101; // sltu
                {7'b0000000, 3'b001}: ALUControl = 4'b1000; // sll
                {7'b0000000, 3'b101}: ALUControl = 4'b1001; // srl
                {7'b0100000, 3'b101}: ALUControl = 4'b1010; // sra
                default: ALUControl = 4'b1111;
            endcase
        end
        2'b11: ALUControl=4'b1011;
        default: ALUControl = 4'b1111;
    endcase
end

// ALU operation logic
always @* begin
    case (ALUControl)
        4'b0010: ALU_result = read_data1 + operand2;                   // add, addi
        4'b0110: ALU_result = read_data1 - operand2;                   // sub
        4'b0000: ALU_result = read_data1 & operand2;                   // and, andi
        4'b0001: ALU_result = read_data1 | operand2;                   // or, ori
        4'b0011: ALU_result = read_data1 ^ operand2;                   // xor, xori
        4'b0100: ALU_result = ($signed(read_data1) < $signed(operand2)) ? 32'b1 : 32'b0; // slt, slti
        4'b0101: ALU_result = (read_data1 < operand2) ? 32'b1 : 32'b0; // sltu, sltiu
        4'b1000: ALU_result = read_data1 << operand2[4:0];             // sll, slli
        4'b1001: ALU_result = read_data1 >> operand2[4:0];             // srl, srli
        4'b1010: ALU_result = $signed(read_data1) >>> operand2[4:0];   // sra, srai
        4'b1011: ALU_result = imm32;
        default: ALU_result = 32'b0;
    endcase
end

assign zero = (ALU_result == 32'b0);

endmodule
